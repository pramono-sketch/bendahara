import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../env/api_key.dart';
import '../helpers/sound_helper.dart';
import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';

// ===================== FIRESTORE HELPERS =====================

final chatHistoryCollection =
    FirebaseFirestore.instance.collection('ai_chat_history');

// ===================== GEMINI SERVICE =====================

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService(
    apiKey: geminiApiKey,
    modelName: 'gemini-3.6-flash',
  );
});

class GeminiService {
  GeminiService({
    required this.apiKey,
    this.modelName = 'gemini-3.6-flash',
  }) : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
        );

  final String apiKey;
  final String modelName;
  final GenerativeModel _model;

  static const String _systemPrompt = '''
penciptamu adalah pramono btw.
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
      final response = await _model.generateContent(
        [
          Content.text(
            fullPrompt.toString(),
          ),
        ],
      );

      final text = response.text?.trim();

      if (text == null || text.isEmpty) {
        return 'Maaf, saya belum mendapatkan jawaban.';
      }

      return text;
    } catch (e) {
      throw Exception(
        'Gagal menghubungi Gemini: $e',
      );
    }
  }
}

// ===================== MODEL CHAT =====================

class ChatMessage {
  final String text;
  final bool isUser;

  const ChatMessage({
    required this.text,
    required this.isUser,
  });

  Map<String, dynamic> toMap() => {
        'text': text,
        'isUser': isUser,
      };

  static ChatMessage fromMap(
    Map<String, dynamic> map,
  ) {
    return ChatMessage(
      text: map['text'] ?? '',
      isUser: map['isUser'] ?? false,
    );
  }
}

class ChatSession {
  final String id;
  String title;
  List<ChatMessage> messages;
  final DateTime createdTime;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdTime,
  });

  ChatSession copyWith({
    List<ChatMessage>? messages,
    String? title,
  }) {
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
        'messages': messages
            .map(
              (m) => m.toMap(),
            )
            .toList(),
        'createdTime': Timestamp.fromDate(
          createdTime,
        ),
      };

  static ChatSession fromMap(
    Map<String, dynamic> map,
  ) {
    return ChatSession(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Chat',
      messages:
          (map['messages'] as List<dynamic>?)
                  ?.map(
                    (e) => ChatMessage.fromMap(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList() ??
              [],
      createdTime:
          (map['createdTime'] as Timestamp?)
                  ?.toDate() ??
              DateTime.now(),
    );
  }
}

// ===================== RIVERPOD STATE MANAGEMENT =====================

class AIChatState {
  final List<ChatSession> sessions;
  final String? currentSessionId;
  final bool isLoading;
  final bool isFetching;

  AIChatState({
    this.sessions = const [],
    this.currentSessionId,
    this.isLoading = false,
    this.isFetching = true,
  });

  List<ChatMessage> get currentMessages {
    if (currentSessionId == null) {
      return [];
    }

    final session = sessions.firstWhere(
      (s) => s.id == currentSessionId,
      orElse: () => ChatSession(
        id: '',
        title: '',
        messages: const [],
        createdTime: DateTime.now(),
      ),
    );

    return session.messages;
  }

  AIChatState copyWith({
    List<ChatSession>? sessions,
    String? currentSessionId,
    bool? isLoading,
    bool? isFetching,
    bool clearSessionId = false,
  }) {
    return AIChatState(
      sessions: sessions ?? this.sessions,
      currentSessionId: clearSessionId
          ? null
          : (currentSessionId ?? this.currentSessionId),
      isLoading: isLoading ?? this.isLoading,
      isFetching: isFetching ?? this.isFetching,
    );
  }
}

class AIChatNotifier
    extends StateNotifier<AIChatState> {
  final Ref ref;

  AIChatNotifier(this.ref)
      : super(
          AIChatState(),
        ) {
    _loadSessionsFromFirestore();
  }

  List<ChatMessage> get currentMessages {
    if (state.currentSessionId == null) {
      return [];
    }

    final session = state.sessions.firstWhere(
      (s) => s.id == state.currentSessionId,
      orElse: () => ChatSession(
        id: '',
        title: '',
        messages: const [],
        createdTime: DateTime.now(),
      ),
    );

    return session.messages;
  }

  Future<void> _loadSessionsFromFirestore() async {
    try {
      final snapshot =
          await chatHistoryCollection.get();

      final sessions = snapshot.docs
          .map(
            (doc) => ChatSession.fromMap(
              doc.data(),
            ),
          )
          .toList();

      sessions.sort(
        (a, b) => b.createdTime.compareTo(
          a.createdTime,
        ),
      );

      state = state.copyWith(
        sessions: sessions,
        isFetching: false,
        clearSessionId: true,
      );
    } catch (e) {
      state = state.copyWith(
        isFetching: false,
        clearSessionId: true,
      );
    }
  }

  Future<void> _saveSessionToFirestore(
    ChatSession session,
  ) async {
    try {
      await chatHistoryCollection
          .doc(session.id)
          .set(
            session.toMap(),
          );
    } catch (e) {
      debugPrint(
        "Error saving chat: $e",
      );
    }
  }

  Future<void> _deleteSessionFromFirestore(
    String id,
  ) async {
    try {
      await chatHistoryCollection
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint(
        "Error deleting chat: $e",
      );
    }
  }

  void startNewChat() {
    state = state.copyWith(
      clearSessionId: true,
    );
  }

  void switchSession(
    String sessionId,
  ) {
    state = state.copyWith(
      currentSessionId: sessionId,
    );
  }

  void _createNewSessionForMessage() {
    final now = DateTime.now();

    final id =
        'session_${now.millisecondsSinceEpoch}';

    final newSession = ChatSession(
      id: id,
      title: 'Chat baru',
      messages: [],
      createdTime: now,
    );

    state = state.copyWith(
      sessions: [
        newSession,
        ...state.sessions,
      ],
      currentSessionId: id,
    );
  }

  void _updateSessionTitle(
    String sessionId,
  ) {
    final sessions = state.sessions;

    final index = sessions.indexWhere(
      (s) => s.id == sessionId,
    );

    if (index == -1) {
      return;
    }

    final session = sessions[index];

    if (session.messages.isNotEmpty &&
        session.title == 'Chat baru') {
      final firstUserMsg =
          session.messages.firstWhere(
        (m) => m.isUser,
        orElse: () => ChatMessage(
          text: 'Percakapan',
          isUser: false,
        ),
      );

      if (firstUserMsg.isUser) {
        String newTitle =
            firstUserMsg.text;

        if (newTitle.length > 30) {
          newTitle =
              '${newTitle.substring(0, 30)}...';
        }

        sessions[index] =
            session.copyWith(
          title: newTitle,
        );
      }
    }
  }

  Future<void> deleteSession(
    String sessionId,
  ) async {
    await _deleteSessionFromFirestore(
      sessionId,
    );

    final sessions = state.sessions
        .where(
          (s) => s.id != sessionId,
        )
        .toList();

    state = state.copyWith(
      sessions: sessions,
      clearSessionId:
          state.currentSessionId == sessionId,
    );
  }

  Future<void> sendMessage(
    String prompt,
  ) async {
    if (state.isLoading) {
      return;
    }

    if (prompt.trim().isEmpty) {
      return;
    }

    if (state.currentSessionId == null ||
        !state.sessions.any(
          (s) => s.id == state.currentSessionId,
        )) {
      _createNewSessionForMessage();
    }

    final currentId =
        state.currentSessionId!;

    final userMsg = ChatMessage(
      text: prompt,
      isUser: true,
    );

    List<ChatSession> updatedSessions =
        List.from(
      state.sessions,
    );

    int sessionIndex =
        updatedSessions.indexWhere(
      (s) => s.id == currentId,
    );

    if (sessionIndex != -1) {
      final targetSession =
          updatedSessions[sessionIndex];

      final newMessages = [
        ...targetSession.messages,
        userMsg,
      ];

      updatedSessions[sessionIndex] =
          targetSession.copyWith(
        messages: newMessages,
      );

      _updateSessionTitle(
        currentId,
      );

      final activeSession =
          updatedSessions.removeAt(
        sessionIndex,
      );

      updatedSessions.insert(
        0,
        activeSession,
      );

      state = state.copyWith(
        sessions: updatedSessions,
        isLoading: true,
      );

      _saveSessionToFirestore(
        updatedSessions.first,
      );
    }

    try {
      final gemini =
          ref.read(geminiServiceProvider);

      final answer =
          await gemini.ask(prompt);

      final aiMsg = ChatMessage(
        text: answer,
        isUser: false,
      );

      updatedSessions =
          List.from(state.sessions);

      sessionIndex =
          updatedSessions.indexWhere(
        (s) => s.id == currentId,
      );

      if (sessionIndex != -1) {
        updatedSessions[sessionIndex] =
            updatedSessions[sessionIndex]
                .copyWith(
          messages: [
            ...updatedSessions[
                    sessionIndex]
                .messages,
            aiMsg,
          ],
        );

        state = state.copyWith(
          sessions: updatedSessions,
        );

        _saveSessionToFirestore(
          updatedSessions[sessionIndex],
        );
      }
    } catch (e) {
      updatedSessions =
          List.from(state.sessions);

      sessionIndex =
          updatedSessions.indexWhere(
        (s) => s.id == currentId,
      );

      if (sessionIndex != -1) {
        updatedSessions[sessionIndex] =
            updatedSessions[sessionIndex]
                .copyWith(
          messages: [
            ...updatedSessions[
                    sessionIndex]
                .messages,
            ChatMessage(
              text:
                  '❌ Gagal menghubungi AI.\n$e',
              isUser: false,
            ),
          ],
        );

        state = state.copyWith(
          sessions: updatedSessions,
        );

        _saveSessionToFirestore(
          updatedSessions[sessionIndex],
        );
      }
    } finally {
      state = state.copyWith(
        isLoading: false,
      );
    }
  }
}

final aiChatProvider =
    StateNotifierProvider<
        AIChatNotifier,
        AIChatState>(
  (ref) {
    return AIChatNotifier(ref);
  },
);

// ===================== MAIN PAGE =====================

class AIAssistantPage
    extends ConsumerStatefulWidget {
  const AIAssistantPage({
    super.key,
  });

  @override
  ConsumerState<AIAssistantPage>
      createState() =>
          _AIAssistantPageState();
}

class _AIAssistantPageState
    extends ConsumerState<AIAssistantPage> {
  final TextEditingController
      _controller =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  final GlobalKey<ScaffoldState>
      _scaffoldKey =
      GlobalKey<ScaffoldState>();

  static const List<String> _suggestions = [
    'Prediksi pemasukan bulan depan',
    'Siswa paling berisiko menunggak',
    'Rekomendasi efisiensi anggaran',
    'Analisis tren pembayaran',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController
                  .position
                  .maxScrollExtent +
              120,
          duration:
              const Duration(
            milliseconds: 250,
          ),
          curve: Curves.easeOut,
        );
      },
    );
  }

  Future<void> _sendMessage([
    String? quickPrompt,
  ]) async {
    final prompt =
        (quickPrompt ??
                _controller.text)
            .trim();

    if (prompt.isEmpty) {
      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    _controller.clear();

    await ref
        .read(
          aiChatProvider.notifier,
        )
        .sendMessage(prompt);

    _scrollToBottom();
  }

  // ============================================================
  // THEMED COLORS
  // ============================================================

  Color _getPrimaryTextColor(
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    if (ThemeHelper.isNeo(
      themeMode,
    )) {
      return AppColors.neoTextPrimary;
    }

    if (ThemeHelper.isGlass(
      themeMode,
    )) {
      return AppColors.glassTextPrimary;
    }

    if (ThemeHelper.isModern(
      themeMode,
    )) {
      return AppColors.modernTextPrimary;
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return AppColors.auroraTextPrimary;
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return AppColors.cyberTextPrimary;
    }

    return colors.onSurface;
  }

  Color _getSecondaryTextColor(
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    if (ThemeHelper.isNeo(
      themeMode,
    )) {
      return AppColors.neoTextSecondary;
    }

    if (ThemeHelper.isGlass(
      themeMode,
    )) {
      return AppColors.glassTextSecondary;
    }

    if (ThemeHelper.isModern(
      themeMode,
    )) {
      return AppColors.modernTextSecondary;
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return AppColors.auroraTextSecondary;
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return AppColors.cyberTextSecondary;
    }

    return colors.onSurfaceVariant;
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildAssistantBackground(
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final isNeo =
        ThemeHelper.isNeo(
      themeMode,
    );

    final isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final isModern =
        ThemeHelper.isModern(
      themeMode,
    );

    final isAurora =
        ThemeHelper.isAurora(
      themeMode,
    );

    final isCyber =
        ThemeHelper.isCyber(
      themeMode,
    );

    Color baseColor;

    if (isNeo) {
      baseColor = AppColors.neoBase;
    } else if (isGlass) {
      baseColor = AppColors.glassBg1;
    } else if (isModern) {
      baseColor = AppColors.modernBg;
    } else if (isAurora) {
      baseColor = AppColors.auroraSurface;
    } else if (isCyber) {
      baseColor = AppColors.cyberBg;
    } else {
      baseColor = colors.surface;
    }

    final secondaryGlow =
        isAurora || isCyber
            ? colors.secondary
            : accentColor;

    final tertiaryGlow =
        isAurora
            ? colors.tertiary
            : colors.primary;

    final glowOpacity =
        isGlass
            ? 0.14
            : isCyber
                ? 0.10
                : isAurora
                    ? 0.18
                    : 0.08;

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: baseColor,
              gradient: LinearGradient(
                begin:
                    Alignment.topLeft,
                end:
                    Alignment.bottomRight,
                colors: [
                  baseColor,
                  Color.lerp(
                        baseColor,
                        accentColor,
                        isAurora
                            ? 0.08
                            : 0.035,
                      ) ??
                      baseColor,
                  baseColor,
                ],
              ),
            ),
          ),

          Positioned(
            top: -150,
            left: -120,
            child: _buildGlow(
              size: 340,
              color: accentColor,
              opacity: glowOpacity,
            ),
          ),

          Positioned(
            top: 70,
            right: -180,
            child: _buildGlow(
              size: 390,
              color: secondaryGlow,
              opacity:
                  glowOpacity * 0.85,
            ),
          ),

          Positioned(
            bottom: -210,
            left: -150,
            child: _buildGlow(
              size: 420,
              color: tertiaryGlow,
              opacity:
                  glowOpacity * 0.70,
            ),
          ),

          Positioned(
            bottom: -170,
            right: -120,
            child: _buildGlow(
              size: 360,
              color: accentColor,
              opacity:
                  glowOpacity * 0.65,
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    RadialGradient(
                  center:
                      Alignment.center,
                  radius: 1.15,
                  colors: [
                    accentColor
                        .withValues(
                      alpha:
                          isAurora
                              ? 0.035
                              : 0.018,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          if (isCyber)
            Positioned.fill(
              child: CustomPaint(
                painter:
                    _CyberBackgroundPainter(
                  lineColor:
                      accentColor
                          .withValues(
                    alpha: 0.035,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlow({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        gradient:
            RadialGradient(
          colors: [
            color.withValues(
              alpha: opacity,
            ),
            color.withValues(
              alpha:
                  opacity * 0.35,
            ),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  BoxDecoration _getThemedBubbleDecoration(
    AppThemeMode themeMode,
    ColorScheme colors,
    bool isUser,
  ) {
    if (isUser) {
      return BoxDecoration(
        color: ThemeHelper.getAccentColor(
          themeMode,
          colors,
        ),
        borderRadius:
            const BorderRadius.only(
          topLeft:
              Radius.circular(20),
          topRight:
              Radius.circular(20),
          bottomLeft:
              Radius.circular(20),
          bottomRight:
              Radius.circular(4),
        ),
      );
    }

    if (ThemeHelper.isNeo(
      themeMode,
    )) {
      return neumorphismDecoration(
        borderRadius: 20,
        isPressed: true,
      );
    }

    if (ThemeHelper.isGlass(
      themeMode,
    )) {
      return glassmorphismDecoration(
        borderRadius: 20,
      );
    }

    if (ThemeHelper.isModern(
      themeMode,
    )) {
      return modernDecoration(
        borderRadius: 20,
      );
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return auroraDecoration(
        borderRadius: 20,
      );
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return cyberpunkDecoration(
        borderRadius: 12,
      );
    }

    return BoxDecoration(
      color:
          colors.surfaceContainerHighest,
      borderRadius:
          const BorderRadius.only(
        topLeft:
            Radius.circular(4),
        topRight:
            Radius.circular(20),
        bottomLeft:
            Radius.circular(20),
        bottomRight:
            Radius.circular(20),
      ),
    );
  }

  // ============================================================
  // BUILD UI
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode =
        ref.watch(themeModeProvider);

    final colors =
        Theme.of(context)
            .colorScheme;

    final chatState =
        ref.watch(aiChatProvider);

    ref.listen(
      aiChatProvider,
      (prev, next) {
        if (prev?.currentMessages
                .length !=
            next.currentMessages
                .length) {
          _scrollToBottom();
        }
      },
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildAssistantBackground(
          themeMode,
          colors,
        ),

        Scaffold(
          key: _scaffoldKey,
          backgroundColor:
              Colors.transparent,

          appBar: AppBar(
            backgroundColor:
                Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor:
                Colors.transparent,

            title: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color:
                      ThemeHelper
                          .getAccentColor(
                    themeMode,
                    colors,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    color:
                        primaryText,
                  ),
                ),
              ],
            ),

            leading: IconButton(
              icon: Icon(
                Icons.menu,
                color:
                    primaryText,
              ),
              onPressed: () async {
                await SoundHelper()
                    .playClick();

                _scaffoldKey.currentState
                    ?.openDrawer();
              },
              tooltip: 'Riwayat Chat',
            ),
          ),

          drawer: _buildDrawer(
            themeMode,
            chatState,
          ),

          body: SafeArea(
            child: chatState.isFetching
                ? Center(
                    child:
                        CircularProgressIndicator(
                      color:
                          ThemeHelper
                              .getAccentColor(
                        themeMode,
                        colors,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: chatState
                                .currentMessages
                                .isEmpty
                            ? _buildEmptyState(
                                themeMode,
                              )
                            : ListView.builder(
                                controller:
                                    _scrollController,
                                padding:
                                    const EdgeInsets
                                        .fromLTRB(
                                  16,
                                  16,
                                  16,
                                  24,
                                ),
                                itemCount:
                                    chatState
                                            .currentMessages
                                            .length +
                                        (chatState
                                                .isLoading
                                            ? 1
                                            : 0),
                                itemBuilder:
                                    (
                                  context,
                                  index,
                                ) {
                                  if (index <
                                      chatState
                                          .currentMessages
                                          .length) {
                                    return _buildMessageBubble(
                                      chatState
                                              .currentMessages[
                                          index],
                                      themeMode,
                                    );
                                  }

                                  return _buildTypingIndicator(
                                    themeMode,
                                  );
                                },
                              ),
                      ),

                      _buildComposer(
                        themeMode,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DRAWER
  // ============================================================

  Widget _buildDrawer(
    AppThemeMode themeMode,
    AIChatState chatState,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final bool isNeo =
        ThemeHelper.isNeo(
      themeMode,
    );

    final Widget drawerContent =
        Column(
      children: [
        Container(
          padding: EdgeInsets.only(
            top:
                MediaQuery.of(context)
                        .padding
                        .top +
                    16,
            bottom: 16,
            left: 16,
            right: 16,
          ),
          width: double.infinity,
          decoration:
              BoxDecoration(
            color: isGlass
                ? AppColors.glassBg1
                    .withValues(
                    alpha: 0.78,
                  )
                : isNeo
                    ? AppColors.neoBaseAlt
                    : accentColor,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Riwayat Chat',
                style: TextStyle(
                  color: isGlass
                      ? Colors.white
                      : isNeo
                          ? AppColors
                              .neoTextPrimary
                          : colors.onPrimary,
                  fontSize: 20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 4,
              ),
              Text(
                '${chatState.sessions.length} sesi tersimpan',
                style: TextStyle(
                  color: isGlass
                      ? Colors.white70
                      : isNeo
                          ? AppColors
                              .neoTextSecondary
                          : colors.onPrimary
                              .withValues(
                              alpha: 0.8,
                            ),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: chatState
                  .sessions.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada history chat',
                    style: TextStyle(
                      color:
                          secondaryText,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount:
                      chatState.sessions
                          .length,
                  itemBuilder:
                      (
                    context,
                    index,
                  ) {
                    final session =
                        chatState
                            .sessions[
                                index];

                    final isActive =
                        session.id ==
                            chatState
                                .currentSessionId;

                    final activeColor =
                        isGlass
                            ? Colors.white
                            : accentColor;

                    return ListTile(
                      tileColor:
                          isActive
                              ? activeColor
                                  .withValues(
                                  alpha:
                                      isGlass
                                          ? 0.14
                                          : 0.08,
                                )
                              : null,

                      leading: Icon(
                        Icons
                            .chat_bubble_outline,
                        color:
                            isActive
                                ? activeColor
                                : secondaryText,
                      ),

                      title: Text(
                        session.title,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style: TextStyle(
                          fontWeight:
                              isActive
                                  ? FontWeight
                                      .bold
                                  : null,
                          color:
                              isActive
                                  ? activeColor
                                  : primaryText,
                        ),
                      ),

                      subtitle: Text(
                        _formatTime(
                          session
                              .createdTime,
                        ),
                        style:
                            TextStyle(
                          fontSize: 12,
                          color:
                              secondaryText,
                        ),
                      ),

                      trailing:
                          IconButton(
                        icon:
                            const Icon(
                          Icons
                              .delete_outline,
                          size: 20,
                        ),
                        onPressed:
                            () async {
                          await SoundHelper()
                              .playClick();

                          ref
                              .read(
                                aiChatProvider
                                    .notifier,
                              )
                              .deleteSession(
                                session.id,
                              );
                        },
                        color:
                            secondaryText,
                      ),

                      onTap:
                          () async {
                        await SoundHelper()
                            .playClick();

                        ref
                            .read(
                              aiChatProvider
                                  .notifier,
                            )
                            .switchSession(
                              session.id,
                            );

                        if (mounted) {
                          Navigator.pop(
                            context,
                          );
                        }
                      },
                    );
                  },
                ),
        ),

        Divider(
          height: 1,
          color:
              ThemeHelper.dividerColor(
            themeMode,
          ),
        ),

        Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child:
              _buildDrawerNewChatButton(
            themeMode: themeMode,
            colors: colors,
            accentColor:
                accentColor,
            primaryText:
                primaryText,
          ),
        ),
      ],
    );

    if (isNeo) {
      return Drawer(
        backgroundColor:
            AppColors.neoBase,
        child: drawerContent,
      );
    }

    if (isGlass) {
      return Drawer(
        backgroundColor:
            AppColors.glassBg1,
        child: drawerContent,
      );
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return Drawer(
        backgroundColor:
            AppColors.auroraSurface,
        child: drawerContent,
      );
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return Drawer(
        backgroundColor:
            AppColors.cyberBg,
        child: drawerContent,
      );
    }

    return Drawer(
      backgroundColor:
          ThemeHelper
              .getScaffoldBackgroundColor(
        themeMode,
        colors,
      ),
      child: drawerContent,
    );
  }

  Widget _buildDrawerNewChatButton({
    required AppThemeMode themeMode,
    required ColorScheme colors,
    required Color accentColor,
    required Color primaryText,
  }) {
    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    return ElevatedButton.icon(
      onPressed: () async {
        await SoundHelper().playClick();

        ref
            .read(
              aiChatProvider.notifier,
            )
            .startNewChat();

        if (mounted) {
          Navigator.pop(context);
        }
      },
      icon: const Icon(
        Icons.add,
      ),
      label: const Text(
        'Chat Baru',
      ),
      style: ElevatedButton.styleFrom(
        minimumSize:
            const Size(
          double.infinity,
          48,
        ),
        backgroundColor:
            isGlass
                ? Colors.white
                    .withValues(
                    alpha: 0.22,
                  )
                : accentColor,
        foregroundColor:
            isGlass
                ? Colors.white
                : colors.onPrimary,
        elevation: 0,
        shadowColor:
            Colors.transparent,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            ThemeHelper.isCyber(
                    themeMode)
                ? 10
                : 14,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState(
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final theme =
        Theme.of(context);

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: Lottie.asset(
                'assets/animations/ai animation Flow 1.json',
                fit:
                    BoxFit.contain,
              ),
            ),

            const SizedBox(
              height: 24,
            ),

            Text(
              'Halo, Aku AI Assistant',
              textAlign:
                  TextAlign.center,
              style: theme.textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                    FontWeight.bold,
                color:
                    primaryText,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              'Mau analisis apa hari ini? Pilih topik di bawah atau ketik sendiri.',
              textAlign:
                  TextAlign.center,
              style: theme.textTheme
                  .bodyMedium
                  ?.copyWith(
                color:
                    secondaryText,
              ),
            ),

            const SizedBox(
              height: 32,
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment:
                  WrapAlignment.center,
              children:
                  _suggestions.map(
                (q) {
                  final chipBackground =
                      ThemeHelper.isNeo(
                        themeMode,
                      )
                          ? accentColor
                              .withValues(
                              alpha: 0.10,
                            )
                          : ThemeHelper.isGlass(
                              themeMode,
                            )
                              ? Colors.white
                                  .withValues(
                                  alpha: 0.14,
                                )
                              : accentColor
                                  .withValues(
                                  alpha: 0.08,
                                );

                  final chipBorder =
                      ThemeHelper.isGlass(
                        themeMode,
                      )
                          ? Colors.white
                              .withValues(
                              alpha: 0.30,
                            )
                          : accentColor
                              .withValues(
                              alpha: 0.20,
                            );

                  final chipText =
                      ThemeHelper.isGlass(
                        themeMode,
                      )
                          ? Colors.white
                          : primaryText;

                  return ActionChip(
                    avatar:
                        Icon(
                      Icons
                          .auto_awesome_outlined,
                      size: 18,
                      color:
                          accentColor,
                    ),
                    label: Text(
                      q,
                    ),
                    backgroundColor:
                        chipBackground,
                    side: BorderSide(
                      color:
                          chipBorder,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                    ),
                    labelStyle:
                        TextStyle(
                      color:
                          chipText,
                      fontWeight:
                          FontWeight.w500,
                    ),
                    onPressed: () async {
                      await SoundHelper()
                          .playClick();

                      _sendMessage(q);
                    },
                  );
                },
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE BUBBLE
  // ============================================================

  Widget _buildMessageBubble(
    ChatMessage message,
    AppThemeMode themeMode,
  ) {
    final isUser =
        message.isUser;

    final colors =
        Theme.of(context)
            .colorScheme;

    final textColor =
        isUser
            ? colors.onPrimary
            : _getPrimaryTextColor(
                themeMode,
                colors,
              );

    final alignment =
        isUser
            ? Alignment.centerRight
            : Alignment.centerLeft;

    return Align(
      alignment:
          alignment,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(
                    context,
                  ).size.width *
                  0.82,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration:
            _getThemedBubbleDecoration(
          themeMode,
          colors,
          isUser,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            Flexible(
              child:
                  SelectableText(
                message.text,
                style:
                    TextStyle(
                  color:
                      textColor,
                  height: 1.4,
                  fontSize:
                      14.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TYPING INDICATOR
  // ============================================================

  Widget _buildTypingIndicator(
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final textColor =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    return Align(
      alignment:
          Alignment.centerLeft,
      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        decoration:
            _getThemedBubbleDecoration(
          themeMode,
          colors,
          false,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color:
                    accentColor,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Text(
              'AI sedang berpikir...',
              style:
                  TextStyle(
                color:
                    textColor,
                fontSize:
                    13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COMPOSER
  // ============================================================

  Widget _buildComposer(
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final bool isNeo =
        ThemeHelper.isNeo(
      themeMode,
    );

    final bool isAurora =
        ThemeHelper.isAurora(
      themeMode,
    );

    final bool isCyber =
        ThemeHelper.isCyber(
      themeMode,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    // ==========================================================
    // COMPOSER BACKGROUND
    // ==========================================================

    Color composerBackground;

    if (isGlass) {
      composerBackground =
          AppColors.glassBg1.withValues(
        alpha: 0.70,
      );
    } else if (isNeo) {
      composerBackground =
          AppColors.neoBase;
    } else if (ThemeHelper.isModern(
      themeMode,
    )) {
      composerBackground =
          AppColors.modernBg;
    } else if (isAurora) {
      composerBackground =
          AppColors.auroraSurface;
    } else if (isCyber) {
      composerBackground =
          AppColors.cyberBg;
    } else {
      composerBackground =
          colors.surface;
    }

    // ==========================================================
    // INPUT COLORS
    // ==========================================================

    final Color inputBackground;

    if (isGlass) {
      inputBackground =
          Colors.white.withValues(
        alpha: 0.12,
      );
    } else if (isNeo) {
      inputBackground =
          AppColors.neoBaseAlt;
    } else if (isAurora) {
      inputBackground =
          AppColors.auroraSurface
              .withValues(
        alpha: 0.72,
      );
    } else if (isCyber) {
      inputBackground =
          AppColors.cyberSurface
              .withValues(
        alpha: 0.85,
      );
    } else {
      inputBackground =
          colors.surfaceContainerHighest
              .withValues(
        alpha: 0.90,
      );
    }

    final Color inputBorder;

    if (isGlass) {
      inputBorder =
          Colors.white.withValues(
        alpha: 0.20,
      );
    } else if (isNeo) {
      inputBorder =
          AppColors.neoShadow.withValues(
        alpha: 0.15,
      );
    } else if (isCyber) {
      inputBorder =
          accentColor.withValues(
        alpha: 0.20,
      );
    } else {
      inputBorder =
          colors.outlineVariant
              .withValues(
        alpha: 0.40,
      );
    }

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            composerBackground,
        border: Border(
          top: BorderSide(
            color:
                ThemeHelper.dividerColor(
              themeMode,
            ).withValues(
              alpha: 0.45,
            ),
          ),
        ),
      ),
      child: Container(
        decoration:
            BoxDecoration(
          color:
              inputBackground,
          borderRadius:
              BorderRadius.circular(
            isCyber ? 18 : 28,
          ),
          border: Border.all(
            color:
                inputBorder,
            width: 1,
          ),
          boxShadow:
              isNeo
                  ? [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha:
                              0.08,
                        ),
                        blurRadius:
                            12,
                        offset:
                            const Offset(
                          3,
                          3,
                        ),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color:
                            Colors.black
                                .withValues(
                          alpha:
                              isGlass
                                  ? 0.06
                                  : 0.04,
                        ),
                        blurRadius:
                            14,
                        offset:
                            const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
        ),
        padding:
            const EdgeInsets.only(
          left: 16,
          right: 6,
          top: 6,
          bottom: 6,
        ),
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.end,
          children: [
            // ==================================================
            // TEXT FIELD
            // ==================================================

            Expanded(
              child:
                  TextField(
                controller:
                    _controller,
                minLines: 1,
                maxLines: 4,
                textCapitalization:
                    TextCapitalization
                        .sentences,
                style:
                    TextStyle(
                  color:
                      primaryText,
                  fontSize: 14.5,
                  height: 1.35,
                ),
                cursorColor:
                    accentColor,

                // Tidak lagi menggunakan kotak
                // OutlineInputBorder bawaan.
                decoration:
                    InputDecoration(
                  hintText:
                      'Tulis pertanyaan kamu...',
                  hintStyle:
                      TextStyle(
                    color:
                        secondaryText
                            .withValues(
                      alpha: 0.78,
                    ),
                    fontSize:
                        14.5,
                  ),
                  border:
                      InputBorder.none,
                  enabledBorder:
                      InputBorder.none,
                  focusedBorder:
                      InputBorder.none,
                  disabledBorder:
                      InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 10,
                    horizontal: 0,
                  ),
                ),
                onSubmitted:
                    (_) =>
                        _sendMessage(),
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // ==================================================
            // SEND BUTTON
            // ==================================================

            AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 180,
              ),
              height: 46,
              width: 46,
              decoration:
                  BoxDecoration(
                color:
                    accentColor,
                shape:
                    BoxShape.circle,
                boxShadow:
                    [
                  BoxShadow(
                    color: accentColor
                        .withValues(
                      alpha:
                          0.22,
                    ),
                    blurRadius:
                        10,
                    offset:
                        const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child:
                  Material(
                color:
                    Colors.transparent,
                child:
                    InkWell(
                  customBorder:
                      const CircleBorder(),
                  onTap:
                      ref
                              .read(
                                aiChatProvider,
                              )
                              .isLoading
                          ? null
                          : () async {
                              await SoundHelper()
                                  .playClick();

                              _sendMessage();
                            },
                  child:
                      Center(
                    child: ref
                            .watch(
                              aiChatProvider,
                            )
                            .isLoading
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  isGlass
                                      ? AppColors
                                          .glassBg1
                                      : colors
                                          .onPrimary,
                            ),
                          )
                        : Icon(
                            Icons
                                .arrow_upward_rounded,
                            size: 22,
                            color:
                                isGlass
                                    ? AppColors
                                        .glassBg1
                                    : colors
                                        .onPrimary,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT TIME
  // ============================================================

  String _formatTime(
    DateTime dt,
  ) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ================================================================
// CYBER BACKGROUND PAINTER
// ================================================================

class _CyberBackgroundPainter
    extends CustomPainter {
  final Color lineColor;

  _CyberBackgroundPainter({
    required this.lineColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const double spacing = 42;

    for (double x = 0;
        x <= size.width;
        x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0;
        y <= size.height;
        y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _CyberBackgroundPainter oldDelegate,
  ) {
    return oldDelegate.lineColor !=
        lineColor;
  }
}