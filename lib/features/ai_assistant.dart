// features/ai_assistant.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// import '../data.dart';
import '../env/api_key.dart';
import '../templates/sound_helper.dart'; // 🔥 import suara
import '../constants/appearance.dart'; // 🔥 import warna

// ===================== GEMINI SERVICE (tanpa konteks) =====================
final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(apiKey: geminiApiKey, modelName: 'gemini-3.6-flash');
});

class GeminiService {
  GeminiService({required this.apiKey, this.modelName = 'gemini-3.6-flash'})
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
      final response = await _model.generateContent([
        Content.text(fullPrompt.toString()),
      ]);
      final text = response.text?.trim();
      if (text == null || text.isEmpty) {
        return 'Maaf, saya belum mendapatkan jawaban.';
      }
      return text;
    } catch (e) {
      throw Exception('Gagal menghubungi Gemini: $e');
    }
  }
}

// ===================== MODEL CHAT SESSION =====================
class ChatSession {
  final String id;
  String title;
  final List<_ChatMessage> messages;
  final DateTime createdTime;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdTime,
  });

  ChatSession copyWith({List<_ChatMessage>? messages, String? title}) {
    return ChatSession(
      id: id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdTime: createdTime,
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

  List<_ChatMessage> get _messages {
    final session = _sessions.firstWhere(
      (s) => s.id == _currentSessionId,
      orElse: () => _createNewSession(),
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
    _createNewSession();
  }

  // ==================== MANAJEMEN SESI ====================
  ChatSession _createNewSession() {
    final now = DateTime.now();
    final id = 'session_${now.millisecondsSinceEpoch}';
    final newSession = ChatSession(
      id: id,
      title: 'Chat baru ${_formatTime(now)}',
      messages: [],
      createdTime: now,
    );
    setState(() {
      _sessions.insert(0, newSession);
      _currentSessionId = id;
    });
    return newSession;
  }

  String _formatTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _switchSession(String sessionId) {
    if (_currentSessionId == sessionId) return;
    SoundHelper().playClick(); // 🔥 suara
    setState(() {
      _currentSessionId = sessionId;
      _updateSessionTitle(sessionId);
      Navigator.pop(context);
    });
    _scrollToBottom();
  }

  void _updateSessionTitle(String sessionId) {
    final index = _sessions.indexWhere((s) => s.id == sessionId);
    if (index == -1) return;
    final session = _sessions[index];
    if (session.messages.isNotEmpty && session.title.startsWith('Chat baru')) {
      final firstUserMsg = session.messages.firstWhere(
        (m) => m.isUser,
        orElse: () => _ChatMessage(text: 'Percakapan', isUser: false),
      );
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
            onPressed: () {
              SoundHelper().playClick(); // 🔥 suara
              Navigator.pop(ctx, false);
            },
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              SoundHelper().playClick(); // 🔥 suara
              Navigator.pop(ctx, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() {
      _sessions.removeWhere((s) => s.id == sessionId);
      if (_sessions.isEmpty) {
        _createNewSession();
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

    if (_sessions.isEmpty || _currentSessionId == null) {
      _createNewSession();
    }

    // Tambahkan pesan user
    final userMsg = _ChatMessage(text: prompt, isUser: true);
    setState(() {
      final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (index != -1) {
        _sessions[index] = _sessions[index].copyWith(
          messages: [..._sessions[index].messages, userMsg],
        );
      }
      _isLoading = true;
      _controller.clear();
    });
    _updateSessionTitle(_currentSessionId!);
    _scrollToBottom();

    try {
      final gemini = ref.read(geminiServiceProvider);
      final answer = await gemini.ask(prompt);

      if (!mounted) return;

      final aiMsg = _ChatMessage(text: answer, isUser: false);
      setState(() {
        final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
        if (index != -1) {
          _sessions[index] = _sessions[index].copyWith(
            messages: [..._sessions[index].messages, aiMsg],
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        final index = _sessions.indexWhere((s) => s.id == _currentSessionId);
        if (index != -1) {
          _sessions[index] = _sessions[index].copyWith(
            messages: [
              ..._sessions[index].messages,
              _ChatMessage(text: '❌ Gagal menghubungi AI.\n$e', isUser: false),
            ],
          );
        }
      });
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

  // ==================== BUILD UI ====================
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('AI Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            SoundHelper().playClick(); // 🔥 suara
            _scaffoldKey.currentState?.openDrawer();
          },
          tooltip: 'Riwayat Chat',
        ),
      ),
      drawer: _buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _messages.length) {
                          return _buildMessageBubble(_messages[index]);
                        }
                        return _buildTypingIndicator();
                      },
                    ),
            ),
            _buildComposer(bottomPadding),
          ],
        ),
      ),
    );
  }

  // ==================== DRAWER RIWAYAT CHAT ====================
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
            width: double.infinity,
            color: AppColors.primary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Riwayat Chat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_sessions.length} sesi',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: _sessions.isEmpty
                ? const Center(child: Text('Belum ada chat'))
                : ListView.builder(
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) {
                      final session = _sessions[index];
                      final isActive = session.id == _currentSessionId;
                      return ListTile(
                        leading: Icon(
                          Icons.chat_bubble_outline,
                          color: isActive ? AppColors.primary : Colors.grey,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : null,
                            color: isActive ? AppColors.primary : null,
                          ),
                        ),
                        subtitle: Text(
                          _formatTime(session.createdTime),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            SoundHelper().playClick(); // 🔥 suara
                            _deleteSession(session.id);
                          },
                          color: Colors.grey,
                        ),
                        onTap: () => _switchSession(session.id),
                      );
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                SoundHelper().playClick(); // 🔥 suara
                _createNewSession();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chat baru dibuat')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Chat Baru'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 28),
        Icon(
          Icons.auto_awesome,
          size: 84,
          color: AppColors.primary.withOpacity(0.45),
        ),
        const SizedBox(height: 20),
        Text(
          'AI Assistant siap dipakai.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Coba kirim pertanyaan untuk analisis pembayaran, prediksi pemasukan, atau ringkasan data.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((q) {
            return ActionChip(
              avatar: const Icon(Icons.help_outline, size: 18),
              label: Text(q),
              backgroundColor: AppColors.primary.withOpacity(0.06),
              onPressed: () {
                SoundHelper().playClick(); // 🔥 suara
                _sendMessage(q);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ==================== MESSAGE BUBBLE ====================
  Widget _buildMessageBubble(_ChatMessage message) {
    final isUser = message.isUser;
    final theme = Theme.of(context);

    final bgColor = isUser
        ? AppColors.primary
        : theme.colorScheme.surfaceContainerHighest;

    final textColor = isUser
        ? Colors.white
        : theme.colorScheme.onSurfaceVariant;

    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Align(
      alignment: alignment,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.06),
            ),
          ],
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(color: textColor, height: 1.35, fontSize: 14.5),
        ),
      ),
    );
  }

  // ==================== TYPING INDICATOR ====================
  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI sedang menulis...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== COMPOSER ====================
  Widget _buildComposer(double bottomPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.35),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Tulis pertanyaan kamu...',
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 52,
            width: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                SoundHelper().playClick(); // 🔥 suara
                _sendMessage();
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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

// ===================== MODEL PESAN =====================
class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}