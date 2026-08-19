// features/ai_assistant.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../env/api_key.dart';
import '../templates/sound_helper.dart';
import '../constants/appearance.dart';

// ===================== FIRESTORE HELPERS =====================
final chatHistoryCollection = FirebaseFirestore.instance.collection('ai_chat_history');

// ===================== GEMINI SERVICE =====================
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: geminiApiKey, modelName: 'gemini-1.5-flash');
});

class GeminiService {
  GeminiService({required this.apiKey, this.modelName = 'gemini-1.5-flash'})
      : _model = GenerativeModel(model: modelName, apiKey: apiKey);

  final String apiKey;
  final String modelName;
  final GenerativeModel _model;

  static const String _systemPrompt = '''penciptamu adalah pramono btw.
AI Eduvest Finance. Jawab dengan SANGAT SINGKAT (maksimal 3 kalimat) dalam bahasa Indonesia. 
Bantu analisis pembayaran, prediksi pemasukan, rekomendasi anggaran, dan analisis tren. 
Jika data kurang, beri asumsi. Pertanyaan di luar Eduvest tetap dijawab sopan.
''';

  Future<String> ask(String userPrompt) async {
    final fullPrompt = StringBuffer()
      ..writeln(_systemPrompt)
      ..writeln()
      ..writeln('Pertanyaan pengguna:')
      ..writeln(userPrompt.trim())
      ..writeln()
      ..writeln('Jawaban singkat AI:');

    try {
      final response = await _model.generateContent([Content.text(fullPrompt.toString())]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) return 'Maaf, saya belum mendapatkan jawaban.';
      return text;
    } catch (e) {
      throw Exception('Gagal menghubungi Gemini: $e');
    }
  }
}

// ===================== MODEL CHAT =====================
class ChatMessage {
  final String text;
  final bool isUser;
  const ChatMessage({required this.text, required this.isUser});
  Map<String, dynamic> toMap() => {'text': text, 'isUser': isUser};
  static ChatMessage fromMap(Map<String, dynamic> map) => ChatMessage(text: map['text'] ?? '', isUser: map['isUser'] ?? false);
}

class ChatSession {
  final String id;
  String title;
  List<ChatMessage> messages;
  final DateTime createdTime;

  ChatSession({required this.id, required this.title, required this.messages, required this.createdTime});

  ChatSession copyWith({List<ChatMessage>? messages, String? title}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdTime: createdTime,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toMap()).toList(),
        'createdTime': Timestamp.fromDate(createdTime),
      };

  static ChatSession fromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Chat',
      messages: (map['messages'] as List<dynamic>?)?.map((e) => ChatMessage.fromMap(e as Map<String, dynamic>)).toList() ?? [],
      createdTime: (map['createdTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ===================== MAIN PAGE =====================
class AIAssistantPage extends ConsumerStatefulWidget {
  const AIAssistantPage({super.key});
  @override
  ConsumerState<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends ConsumerState<AIAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<ChatSession> _sessions = [];
  String? _currentSessionId;
  bool _isLoading = false;
  bool _isFetching = true;

  List<ChatMessage> get _messages {
    if (_currentSessionId == null) return [];
    final session = _sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => ChatSession(id: '', title: '', messages: const [], createdTime: DateTime.now()),
    );
    return session.messages;
  }

  static const List<String> _suggestions = [
    'Prediksi pemasukan bulan depan',
    'Siswa paling berisiko menunggak',
    'Rekomendasi efisiensi anggaran',
    'Analisis tren pembayaran',
  ];

  @override
  void initState() {
    super.initState();
    _loadSessionsFromFirestore();
  }

  // ==================== FIRESTORE INTEGRATION ====================
  Future<void> _loadSessionsFromFirestore() async {
    try {
      final snapshot = await chatHistoryCollection.get();
      if (snapshot.docs.isEmpty) {
        setState(() => _currentSessionId = null); // Tidak buat sesi kosong
      } else {
        _sessions = snapshot.docs.map((doc) => ChatSession.fromMap(doc.data())).toList();
        _sessions.sort((a, b) => b.createdTime.compareTo(a.createdTime));
        setState(() => _currentSessionId = _sessions.first.id);
      }
    } catch (e) {
      setState(() => _currentSessionId = null);
    } finally {
      if (mounted) {
        setState(() => _isFetching = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _saveSessionToFirestore(ChatSession session) async {
    try {
      await chatHistoryCollection.doc(session.id).set(session.toMap());
    } catch (e) {
      debugPrint("Error saving chat: $e");
    }
  }

  Future<void> _deleteSessionFromFirestore(String id) async {
    try {
      await chatHistoryCollection.doc(id).delete();
    } catch (e) {
      debugPrint("Error deleting chat: $e");
    }
  }

  // ==================== MANAJEMEN SESI ====================
  void _startNewChat() {
    setState(() {
      _currentSessionId = null; // Set null agar history menyembunyikan chat kosong
    });
    Navigator.pop(context); // Tutup drawer
  }

  ChatSession _createNewSessionForMessage() {
    final now = DateTime.now();
    final id = 'session_${now.millisecondsSinceEpoch}';
    final newSession = ChatSession(
      id: id,
      title: 'Chat baru',
      messages: [],
      createdTime: now,
    );
    _sessions.insert(0, newSession);
    _currentSessionId = id;
    return newSession;
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _switchSession(String sessionId) async {
    if (_currentSessionId == sessionId) return;
    await SoundHelper().playClick();
    setState(() => _currentSessionId = sessionId);
    Navigator.pop(context);
    _scrollToBottom();
  }

  void _updateSessionTitle(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = _sessions[index];
    if (session.messages.isNotEmpty && session.title == 'Chat baru') {
      final firstUserMsg = session.messages.firstWhere((m) => m.isUser, orElse: () => ChatMessage(text: 'Percakapan', isUser: false));
      if (firstUserMsg.isUser) {
        String newTitle = firstUserMsg.text;
        if (newTitle.length > 30) newTitle = newTitle.substring(0, 30) + '...';
        _sessions[index] = session.copyWith(title: newTitle);
      }
    }
  }

  void _deleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus sesi'),
        content: const Text('Yakin ingin menghapus percakapan ini?'),
        actions: [
          TextButton(
            onPressed: () async { await SoundHelper().playClick(); if (mounted) Navigator.pop(ctx, false); },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async { await SoundHelper().playClick(); if (mounted) Navigator.pop(ctx, true); },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await _deleteSessionFromFirestore(sessionId);

    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_sessions.isEmpty) {
        _currentSessionId = null;
      } else if (_currentSessionId == sessionId) {
        _currentSessionId = _sessions.first.id;
      }
    });
    _scrollToBottom();
  }

  // ==================== KIRIM PESAN ====================
  Future<void> _sendMessage([String? quickPrompt]) async {
    if (_isLoading) return;

    final prompt = (quickPrompt ?? _controller.text).trim();
    if (prompt.isEmpty) return;

    FocusScope.of(context).unfocus();

    // Buat sesi baru HANYA saat pesan pertama dikirim
    bool isNewSession = false;
    if (_currentSessionId == null || !_sessions.any((s) => s.id == _currentSessionId)) {
      _createNewSessionForMessage();
      isNewSession = true;
    }

    final userMsg = ChatMessage(text: prompt, isUser: true);
    int sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
    
    if (sessionIndex != -1) {
      setState(() {
        _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
          messages: [..._sessions[sessionIndex].messages, userMsg],
        );
        _isLoading = true;
        _controller.clear();
      });
      _updateSessionTitle(_currentSessionId!);
      _saveSessionToFirestore(_sessions[sessionIndex]);
    }
    _scrollToBottom();

    try {
      final gemini = ref.read(geminiServiceProvider);
      final answer = await gemini.ask(prompt);

      if (!mounted) return;

      final aiMsg = ChatMessage(text: answer, isUser: false);
      sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (sessionIndex != -1) {
        setState(() {
          _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
            messages: [..._sessions[sessionIndex].messages, aiMsg],
          );
        });
        _saveSessionToFirestore(_sessions[sessionIndex]);
      }
    } catch (e) {
      if (!mounted) return;
      sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (sessionIndex != -1) {
        setState(() {
          _sessions[sessionIndex] = _sessions[sessionIndex].copyWith(
            messages: [
              ..._sessions[sessionIndex].messages,
              ChatMessage(text: '❌ Gagal menghubungi AI.\n$e', isUser: false),
            ],
          );
        });
        _saveSessionToFirestore(_sessions[sessionIndex]);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  // ==================== THEME HELPERS ====================
  bool _isNeo(AppThemeMode mode) => mode == AppThemeMode.neumorphism;
  bool _isGlass(AppThemeMode mode) => mode == AppThemeMode.glassmorphism;
  bool _isModern(AppThemeMode mode) => mode == AppThemeMode.modern;
  bool _isAurora(AppThemeMode mode) => mode == AppThemeMode.aurora;
  bool _isCyber(AppThemeMode mode) => mode == AppThemeMode.cyberpunk;

  Widget _buildThemedBackground(AppThemeMode themeMode, Widget child) {
    if (_isGlass(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.glassBg1, AppColors.glassBg2, AppColors.glassBg3],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }
    if (_isAurora(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.auroraBg, AppColors.auroraBg2, AppColors.auroraBg3],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }
    if (_isCyber(themeMode)) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.8,
            colors: [AppColors.cyberBg, AppColors.cyberSurface.withValues(alpha: 0.5), AppColors.cyberBg],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: child,
      );
    }
    return child;
  }

  Color _dividerColor(AppThemeMode mode) {
    if (_isNeo(mode)) return AppColors.neoShadow.withValues(alpha: 0.20);
    if (_isGlass(mode)) return Colors.white.withValues(alpha: 0.2);
    if (_isModern(mode)) return AppColors.modernDivider.withValues(alpha: 0.6);
    if (_isAurora(mode)) return AppColors.auroraAccent1.withValues(alpha: 0.12);
    if (_isCyber(mode)) return AppColors.cyberAccent1.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  BoxDecoration _getThemedBubbleDecoration(AppThemeMode themeMode, ColorScheme colors, bool isUser) {
    if (isUser) {
      return BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: const Radius.circular(20),
          bottomRight: const Radius.circular(4),
        ),
      );
    }

    // AI Bubble mengikuti tema
    if (_isNeo(themeMode)) {
      return neumorphismDecoration(borderRadius: 20, isPressed: true);
    }
    if (_isGlass(themeMode)) {
      return glassmorphismDecoration(borderRadius: 20);
    }
    if (_isModern(themeMode)) {
      return modernDecoration(borderRadius: 20);
    }
    if (_isAurora(themeMode)) {
      return auroraDecoration(borderRadius: 20);
    }
    if (_isCyber(themeMode)) {
      return cyberpunkDecoration(borderRadius: 12);
    }

    // Default Light/Dark
    return BoxDecoration(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.only(
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(20),
        bottomLeft: const Radius.circular(20),
        bottomRight: const Radius.circular(20),
      ),
    );
  }

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    return _buildThemedBackground(
      themeMode,
      Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Icon(Icons.auto_awesome, color: colors.primary),
              const SizedBox(width: 8),
              const Text('AI Assistant'),
            ],
          ),
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () async {
              await SoundHelper().playClick();
              _scaffoldKey.currentState?.openDrawer();
            },
            tooltip: 'Riwayat Chat',
          ),
        ),
        drawer: _buildDrawer(themeMode),
        body: SafeArea(
          child: _isFetching
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: _messages.isEmpty
                          ? _buildEmptyState(themeMode)
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                              itemCount: _messages.length + (_isLoading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index < _messages.length) {
                                  return _buildMessageBubble(_messages[index], themeMode);
                                }
                                return _buildTypingIndicator(themeMode);
                              },
                            ),
                    ),
                    _buildComposer(themeMode),
                  ],
                ),
        ),
      ),
    );
  }

  // ==================== DRAWER RIWAYAT CHAT ====================
  Widget _buildDrawer(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: _buildThemedBackground(
        themeMode,
        Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 16, left: 16, right: 16),
              width: double.infinity,
              color: colors.primary.withOpacity(0.9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Riwayat Chat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${_sessions.length} sesi tersimpan', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: _sessions.isEmpty
                  ? Center(child: Text('Belum ada history chat', style: theme.textTheme.bodyMedium))
                  : ListView.builder(
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        final isActive = session.id == _currentSessionId;
                        return ListTile(
                          leading: Icon(Icons.chat_bubble_outline, color: isActive ? colors.primary : colors.outline),
                          title: Text(
                            session.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: isActive ? FontWeight.bold : null, color: isActive ? colors.primary : null),
                          ),
                          subtitle: Text(_formatTime(session.createdTime), style: const TextStyle(fontSize: 12)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20),
                            onPressed: () async {
                              await SoundHelper().playClick();
                              _deleteSession(session.id);
                            },
                            color: colors.outline,
                          ),
                          onTap: () => _switchSession(session.id),
                        );
                      },
                    ),
            ),
            Divider(height: 1, color: _dividerColor(themeMode)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await SoundHelper().playClick();
                  _startNewChat();
                },
                icon: const Icon(Icons.add),
                label: const Text('Chat Baru'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animations/ai animation Flow 1.json', 
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Halo, Aku AI Assistant',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              'Mau analisis apa hari ini? Pilih topik di bawah atau ketik sendiri.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _suggestions.map((q) {
                return ActionChip(
                  avatar: Icon(Icons.auto_awesome_outlined, size: 18, color: colors.primary),
                  label: Text(q),
                  backgroundColor: colors.primary.withOpacity(0.08),
                  side: BorderSide(color: colors.primary.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () async {
                    await SoundHelper().playClick();
                    _sendMessage(q);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MESSAGE BUBBLE ====================
  Widget _buildMessageBubble(ChatMessage message, AppThemeMode themeMode) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final bgColor = isUser ? colors.primary : colors.surfaceContainerHighest;
    final textColor = isUser ? colors.onPrimary : colors.onSurfaceVariant;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: _getThemedBubbleDecoration(themeMode, colors, isUser),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: SelectableText(
                message.text,
                style: TextStyle(color: textColor, height: 1.4, fontSize: 14.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TYPING INDICATOR ====================
  Widget _buildTypingIndicator(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: _getThemedBubbleDecoration(themeMode, colors, false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
            const SizedBox(width: 12),
            Text('AI sedang berpikir...', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ==================== COMPOSER ====================
  Widget _buildComposer(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12), // Hapus perhitungan keyboard manual
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor.withOpacity(0.95),
        border: Border(top: BorderSide(color: _dividerColor(themeMode))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan kamu...',
                filled: true,
                fillColor: colors.surfaceContainerHighest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      await SoundHelper().playClick();
                      _sendMessage();
                    },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              child: _isLoading
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimary))
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}