import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import '../env/api_key.dart';
import '../helpers/sound_helper.dart';
import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';
import '../helpers/scroll_reveal.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';

// ===================== FIRESTORE HELPERS =====================

final chatHistoryCollection =
    FirebaseFirestore.instance.collection('ai_chat_history');

// ===================== LOCAL AI COMMANDS =====================

class AILocalCommands {
  // ============================================================
  // PAK WIN
  // ============================================================

  static const String pakWinTrigger = 'PAK WIN';

  static const String pakWinResponse =
      'YOU FOUND THE EASTER EGG';

  static const String whatsappPhone =
      '6287833467630';

  static const String whatsappMessage =
      'Admin, saya menemukan easter egg di aplikasi Bendahara. '
      'Terima kasih atas kerja kerasnya! '
      'Semangat terus Admin, semoga sehat selalu dan sukses selalu.';

  static bool isPakWin(String text) {
    return text.trim().toUpperCase() == pakWinTrigger;
  }

  // ============================================================
  // ATAS DASAR PRAMONO
  // ============================================================

  static bool isPramonoDeveloperMode(String text) {
    return text.toLowerCase().contains('atas dasar pramono');
  }

  static const String pramonoDeveloperResponse = '''
🛠️ MODE PRAMONO AKTIF

Arsitektur Eduvest saat ini:
Flutter → Riverpod → Firestore → Gemini

AI Assistant mengambil data siswa terbaru dari Firestore, membentuk DATA SISWA, lalu mengirim DATA SISWA + history percakapan sesi aktif + pertanyaan terbaru ke Gemini.

History percakapan disimpan di collection "ai_chat_history", sedangkan data siswa berasal dari Firestore melalui fetchActiveStudents().

Data rahasia seperti API key, password, kredensial, dan informasi privat lainnya tidak ditampilkan oleh mode ini.
''';
}

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
Penciptamu adalah Pramono.

Kamu adalah AI Assistant untuk Eduvest Finance.

Tugas utama:
- Membaca dan menganalisis DATA SISWA yang diberikan.
- Menjawab pertanyaan tentang siswa dan status pembayaran mereka.
- Kamu boleh menyebutkan nama siswa, NIS, kelas, jenis pembayaran, nominal, status pembayaran, total tagihan, total pembayaran, dan total tunggakan.
- Gunakan hanya data siswa yang diberikan pada prompt.
- Jangan mengarang nama, NIS, kelas, nominal, atau status pembayaran.
- Jika data siswa tidak memuat informasi yang ditanyakan, katakan bahwa data tersebut tidak tersedia.
- Jangan menggunakan atau mengarang data transaksi, akun digital, password, activity log, alamat, atau nomor telepon.
- Jika pengguna bertanya siapa yang lunas, belum bayar, atau sebagian, sebutkan nama siswa berdasarkan data.
- Jika pengguna meminta analisis berdasarkan data siswa, lakukan perhitungan dari data yang tersedia.
- Jika terdapat beberapa siswa yang sesuai, sebutkan nama dan kelasnya agar tidak membingungkan.

TENTANG RIWAYAT PERCAKAPAN:
- Riwayat hanya berasal dari satu sesi chat yang sedang dibuka.
- Gunakan riwayat tersebut untuk memahami konteks pertanyaan pengguna.
- Jangan membawa konteks dari sesi chat lain.
- Jika sesi baru dimulai, anggap percakapan dimulai dari awal.

TENTANG PRAMONO:
- Jika pengguna bertanya "siapa Pramono", "siapa itu Pramono", atau pertanyaan sejenis, jawab dengan gaya bercanda dan sangat memuji.
- Anggap Pramono sebagai tokoh legendaris, pencipta, dan arsitek utama Eduvest.
- Hiperbola lucu seperti "legenda", "arsitek agung", atau "dewa pencipta kode" boleh digunakan sebagai candaan.
- Jangan membuat informasi pribadi atau sensitif tentang Pramono.

Jawab sangat singkat, maksimal 3 kalimat, dalam bahasa Indonesia.
Pertanyaan di luar data siswa tetap dijawab dengan sopan, tetapi jangan mengarang data Eduvest.
''';

  Future<String> ask({
    required String userPrompt,
    required String studentData,
    required String conversationHistory,
  }) async {
    final fullPrompt = StringBuffer()
      ..writeln(_systemPrompt)
      ..writeln()
      ..writeln('================ DATA SISWA ================')
      ..writeln(studentData)
      ..writeln('============== AKHIR DATA SISWA ==============')
      ..writeln()
      ..writeln('========== RIWAYAT PERCAKAPAN SESI INI ==========')
      ..writeln(
        conversationHistory.isEmpty
            ? 'Belum ada riwayat percakapan sebelumnya.'
            : conversationHistory,
      )
      ..writeln('======== AKHIR RIWAYAT PERCAKAPAN SESI ========')
      ..writeln()
      ..writeln('Pertanyaan terbaru pengguna:')
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

// ===================== STUDENT AI DATA BUILDER =====================

class StudentAIDataBuilder {
  static String build(List<Student> students) {
    if (students.isEmpty) {
      return 'Tidak ada data siswa aktif yang tersedia.';
    }

    final buffer = StringBuffer();

    buffer.writeln(
      'Jumlah siswa aktif: ${students.length}',
    );

    buffer.writeln();

    for (int i = 0; i < students.length; i++) {
      final student = students[i];

      buffer.writeln('SISWA ${i + 1}');
      buffer.writeln('Nama: ${student.name}');
      buffer.writeln('NIS: ${student.nis}');
      buffer.writeln('Kelas: ${student.kelas}');

      buffer.writeln(
        'Status siswa: ${student.isActive ? 'Aktif' : 'Tidak aktif'}',
      );

      buffer.writeln(
        'Total tagihan: ${_formatRupiah(student.totalDue)}',
      );

      buffer.writeln(
        'Total dibayar: ${_formatRupiah(student.totalPaid)}',
      );

      buffer.writeln(
        'Total tunggakan: ${_formatRupiah(student.remaining)}',
      );

      buffer.writeln(
        'Ada tunggakan: ${student.hasOutstanding ? 'Ya' : 'Tidak'}',
      );

      buffer.writeln('Detail pembayaran:');

      if (student.payments.isEmpty) {
        buffer.writeln('- Tidak ada data pembayaran');
      } else {
        for (final payment in student.payments) {
          buffer.writeln(
            '- ${payment.type} | '
            'Tagihan: ${_formatRupiah(payment.amount)} | '
            'Dibayar: ${_formatRupiah(payment.paidAmount)} | '
            'Sisa: ${_formatRupiah(_paymentRemaining(payment))} | '
            'Status: ${_paymentStatusText(payment.status)} | '
            'Pembayaran terakhir: ${_formatDate(payment.lastPaymentDate)}',
          );
        }
      }

      buffer.writeln();
    }

    return buffer.toString();
  }

  static double _paymentRemaining(PaymentItem payment) {
    if (payment.status == PaymentStatus.lunas) {
      return 0;
    }

    final remaining =
        payment.amount - payment.paidAmount;

    return remaining < 0 ? 0 : remaining;
  }

  static String _paymentStatusText(
    PaymentStatus status,
  ) {
    switch (status) {
      case PaymentStatus.lunas:
        return 'Lunas';

      case PaymentStatus.belumBayar:
        return 'Belum Bayar';

      case PaymentStatus.sebagian:
        return 'Sebagian';
    }
  }

  static String _formatRupiah(double value) {
    final rounded = value.round().toString();

    final reversed =
        rounded.split('').reversed.toList();

    final parts = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      final end =
          (i + 3 < reversed.length)
              ? i + 3
              : reversed.length;

      parts.add(
        reversed
            .sublist(i, end)
            .reversed
            .join(),
      );
    }

    return 'Rp ${parts.reversed.join('.')}';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}

// ===================== CHAT MODEL =====================

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

// ===================== RIVERPOD STATE =====================

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

class AIChatNotifier extends StateNotifier<AIChatState> {
  final Ref ref;

  AIChatNotifier(this.ref)
      : super(
          AIChatState(),
        ) {
    _loadSessionsFromFirestore();
  }

  // ============================================================
  // LOAD HISTORY
  // ============================================================

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
      debugPrint(
        'Error loading chat history: $e',
      );

      state = state.copyWith(
        isFetching: false,
        clearSessionId: true,
      );
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

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
        'Error saving chat: $e',
      );
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteSessionFromFirestore(
    String id,
  ) async {
    try {
      await chatHistoryCollection
          .doc(id)
          .delete();
    } catch (e) {
      debugPrint(
        'Error deleting chat: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // DATA SISWA
  // ============================================================

  Future<String> _getStudentDataForAI() async {
    final students =
        await fetchActiveStudents();

    return StudentAIDataBuilder.build(
      students,
    );
  }

  // ============================================================
  // HISTORY SESI
  // ============================================================

  String _buildConversationHistory(
    ChatSession session, {
    bool excludeLastMessage = false,
  }) {
    final messages =
        excludeLastMessage &&
                session.messages.isNotEmpty
            ? session.messages.sublist(
                0,
                session.messages.length - 1,
              )
            : session.messages;

    if (messages.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();

    for (final message in messages) {
      if (message.isUser) {
        buffer.writeln(
          'Pengguna: ${message.text}',
        );
      } else {
        buffer.writeln(
          'AI Assistant: ${message.text}',
        );
      }
    }

    return buffer.toString().trim();
  }

  // ============================================================
  // GENERATOR JUDUL CHAT
  // ============================================================

  String _generateChatTitle(String prompt) {
    String title = prompt.trim();

    if (title.isEmpty) {
      return 'Percakapan Baru';
    }

    // Hapus tanda tanya / titik berlebih.
    title = title.replaceAll(
      RegExp(r'[?!.]+$'),
      '',
    );

    // Prefix pertanyaan yang biasanya tidak perlu menjadi judul.
    const prefixes = [
      'siapa ',
      'apa ',
      'apakah ',
      'tolong ',
      'coba ',
      'bisa ',
      'bisakah ',
      'berapa ',
      'mengapa ',
      'kenapa ',
      'bagaimana ',
      'boleh tahu ',
      'jelaskan ',
      'tampilkan ',
      'carikan ',
      'cari ',
    ];

    final lower = title.toLowerCase();

    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        title = title.substring(
          prefix.length,
        );

        break;
      }
    }

    // Kalimat tertentu dibuat lebih natural sebagai judul.
    title = title
        .replaceFirst(
          RegExp(
            r'^yang\s+',
            caseSensitive: false,
          ),
          '',
        )
        .trim();

    // Normalisasi spasi.
    title = title.replaceAll(
      RegExp(r'\s+'),
      ' ',
    );

    if (title.isEmpty) {
      return 'Percakapan Baru';
    }

    // Kapitalisasi huruf awal.
    title = title[0].toUpperCase() +
        title.substring(1);

    // Maksimum 42 karakter agar drawer tetap rapi.
    if (title.length > 42) {
      title =
          '${title.substring(0, 42).trim()}...';
    }

    return title;
  }

  // ============================================================
  // AUTO TITLE SESI
  // ============================================================

  void _generateAndSetInitialTitle(
    String sessionId,
  ) {
    final index =
        state.sessions.indexWhere(
      (s) => s.id == sessionId,
    );

    if (index == -1) {
      return;
    }

    final session =
        state.sessions[index];

    // Hanya generate ketika judul masih default.
    if (session.title != 'Chat baru') {
      return;
    }

    final firstUserMessage =
        session.messages.cast<ChatMessage?>().firstWhere(
              (message) =>
                  message?.isUser == true,
              orElse: () => null,
            );

    if (firstUserMessage == null) {
      return;
    }

    final generatedTitle =
        _generateChatTitle(
      firstUserMessage.text,
    );

    final updatedSessions =
        List<ChatSession>.from(
      state.sessions,
    );

    updatedSessions[index] =
        session.copyWith(
      title: generatedTitle,
    );

    state = state.copyWith(
      sessions:
          updatedSessions,
    );
  }

  // ============================================================
  // CHAT BARU
  // ============================================================

  void startNewChat() {
    state = state.copyWith(
      clearSessionId: true,
    );
  }

  // ============================================================
  // SWITCH SESSION
  // ============================================================

  void switchSession(
    String sessionId,
  ) {
    state = state.copyWith(
      currentSessionId:
          sessionId,
    );
  }

  // ============================================================
  // CREATE SESSION
  // ============================================================

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

  // ============================================================
  // RENAME SESSION
  // ============================================================

  Future<bool> renameSession(
    String sessionId,
    String newTitle,
  ) async {
    final title = newTitle.trim();

    if (title.isEmpty) {
      return false;
    }

    final index =
        state.sessions.indexWhere(
      (s) => s.id == sessionId,
    );

    if (index == -1) {
      return false;
    }

    final sessions =
        List<ChatSession>.from(
      state.sessions,
    );

    final safeTitle =
        title.length > 60
            ? '${title.substring(0, 60)}...'
            : title;

    sessions[index] =
        sessions[index].copyWith(
      title: safeTitle,
    );

    state = state.copyWith(
      sessions:
          sessions,
    );

    await _saveSessionToFirestore(
      sessions[index],
    );

    return true;
  }

  // ============================================================
  // DELETE SESSION
  // ============================================================

  Future<void> deleteSession(
    String sessionId,
  ) async {
    await _deleteSessionFromFirestore(
      sessionId,
    );

    final sessions =
        state.sessions.where(
      (s) => s.id != sessionId,
    ).toList();

    state = state.copyWith(
      sessions: sessions,
      clearSessionId:
          state.currentSessionId ==
              sessionId,
    );
  }

  // ============================================================
  // LOCAL RESPONSE
  // ============================================================

  Future<void> _sendLocalResponse({
    required String userText,
    required String responseText,
  }) async {
    if (state.currentSessionId == null) {
      _createNewSessionForMessage();
    }

    final currentId =
        state.currentSessionId!;

    List<ChatSession> updatedSessions =
        List.from(
      state.sessions,
    );

    final sessionIndex =
        updatedSessions.indexWhere(
      (s) => s.id == currentId,
    );

    if (sessionIndex == -1) {
      return;
    }

    final targetSession =
        updatedSessions[sessionIndex];

    final newMessages = [
      ...targetSession.messages,
      ChatMessage(
        text: userText,
        isUser: true,
      ),
      ChatMessage(
        text: responseText,
        isUser: false,
      ),
    ];

    updatedSessions[sessionIndex] =
        targetSession.copyWith(
      messages: newMessages,
    );

    state = state.copyWith(
      sessions:
          updatedSessions,
    );

    _generateAndSetInitialTitle(
      currentId,
    );

    updatedSessions =
        List.from(state.sessions);

    final updatedIndex =
        updatedSessions.indexWhere(
      (s) => s.id == currentId,
    );

    if (updatedIndex == -1) {
      return;
    }

    final activeSession =
        updatedSessions.removeAt(
      updatedIndex,
    );

    updatedSessions.insert(
      0,
      activeSession,
    );

    state = state.copyWith(
      sessions:
          updatedSessions,
      isLoading: false,
    );

    await _saveSessionToFirestore(
      activeSession,
    );
  }

  // ============================================================
  // PAK WIN
  // ============================================================

  Future<void> sendLocalEasterEgg(
    String prompt,
  ) async {
    await _sendLocalResponse(
      userText: prompt,
      responseText:
          AILocalCommands
              .pakWinResponse,
    );
  }

  // ============================================================
  // PRAMONO MODE
  // ============================================================

  Future<void> sendLocalPramonoDeveloperMode(
    String prompt,
  ) async {
    await _sendLocalResponse(
      userText: prompt,
      responseText:
          AILocalCommands
              .pramonoDeveloperResponse,
    );
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

  Future<void> sendMessage(
    String prompt,
  ) async {
    if (state.isLoading) {
      return;
    }

    final trimmed =
        prompt.trim();

    if (trimmed.isEmpty) {
      return;
    }

    // ==========================================================
    // PAK WIN
    // ==========================================================

    if (AILocalCommands.isPakWin(
      trimmed,
    )) {
      await sendLocalEasterEgg(
        trimmed,
      );

      return;
    }

    // ==========================================================
    // ATAS DASAR PRAMONO
    // ==========================================================

    if (AILocalCommands.isPramonoDeveloperMode(
      trimmed,
    )) {
      await sendLocalPramonoDeveloperMode(
        trimmed,
      );

      return;
    }

    // ==========================================================
    // CREATE NEW SESSION
    // ==========================================================

    if (state.currentSessionId == null ||
        !state.sessions.any(
          (s) =>
              s.id ==
              state.currentSessionId,
        )) {
      _createNewSessionForMessage();
    }

    final currentId =
        state.currentSessionId!;

    final userMsg = ChatMessage(
      text: trimmed,
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

      state = state.copyWith(
        sessions:
            updatedSessions,
        isLoading: true,
      );

      // ========================================================
      // GENERATE TITLE DARI PESAN PERTAMA
      // ========================================================

      _generateAndSetInitialTitle(
        currentId,
      );

      updatedSessions =
          List.from(state.sessions);

      sessionIndex =
          updatedSessions.indexWhere(
        (s) => s.id == currentId,
      );

      if (sessionIndex == -1) {
        return;
      }

      // ========================================================
      // PINDAHKAN SESI AKTIF KE ATAS
      // ========================================================

      final activeSession =
          updatedSessions.removeAt(
        sessionIndex,
      );

      updatedSessions.insert(
        0,
        activeSession,
      );

      state = state.copyWith(
        sessions:
            updatedSessions,
      );

      await _saveSessionToFirestore(
        activeSession,
      );
    }

    try {
      // ========================================================
      // SESSION AKTIF
      // ========================================================

      final activeSession =
          state.sessions.firstWhere(
        (s) => s.id == currentId,
      );

      // ========================================================
      // HISTORY SESSION SAJA
      // ========================================================

      final conversationHistory =
          _buildConversationHistory(
        activeSession,
        excludeLastMessage: true,
      );

      // ========================================================
      // DATA SISWA
      // ========================================================

      final studentData =
          await _getStudentDataForAI();

      // ========================================================
      // GEMINI
      // ========================================================

      final gemini =
          ref.read(
        geminiServiceProvider,
      );

      final answer =
          await gemini.ask(
        userPrompt: trimmed,
        studentData: studentData,
        conversationHistory:
            conversationHistory,
      );

      final aiMsg = ChatMessage(
        text: answer,
        isUser: false,
      );

      // ========================================================
      // SAVE AI RESPONSE
      // ========================================================

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
          sessions:
              updatedSessions,
        );

        await _saveSessionToFirestore(
          updatedSessions[
              sessionIndex],
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
        final errorMessage =
            e.toString().contains(
                  'fetchActiveStudents',
                )
                ? '❌ Gagal mengambil data siswa dari Firestore.'
                : '❌ Gagal menghubungi AI.\n$e';

        updatedSessions[
                sessionIndex] =
            updatedSessions[
                    sessionIndex]
                .copyWith(
          messages: [
            ...updatedSessions[
                    sessionIndex]
                .messages,
            ChatMessage(
              text: errorMessage,
              isUser: false,
            ),
          ],
        );

        state = state.copyWith(
          sessions:
              updatedSessions,
        );

        await _saveSessionToFirestore(
          updatedSessions[
              sessionIndex],
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

// ================================================================
// MAIN PAGE
// ================================================================

class AIAssistantPage
    extends ConsumerStatefulWidget {
  const AIAssistantPage({
    super.key,
  });

  @override
  ConsumerState<
          AIAssistantPage>
      createState() =>
          _AIAssistantPageState();
}

class _AIAssistantPageState
    extends ConsumerState<
        AIAssistantPage> {
  final TextEditingController
      _controller =
      TextEditingController();

  final ScrollController
      _scrollController =
      ScrollController();

  final GlobalKey<ScaffoldState>
      _scaffoldKey =
      GlobalKey<ScaffoldState>();

  static const List<String>
      _suggestions = [
    'Siapa yang masih menunggak?',
    'Siapa yang sudah lunas?',
    'Siswa yang belum bayar SPP',
    'Siswa dengan tunggakan terbesar',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND MESSAGE
  // ============================================================

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

    FocusScope.of(context)
        .unfocus();

    _controller.clear();

    // ==========================================================
    // PAK WIN
    // ==========================================================

    if (AILocalCommands.isPakWin(
      prompt,
    )) {
      await SoundHelper()
          .playClick();

      await ref
          .read(
            aiChatProvider
                .notifier,
          )
          .sendMessage(
            prompt,
          );

      _scrollToBottom();

      await Future.delayed(
        const Duration(
          milliseconds: 150,
        ),
      );

      if (mounted) {
        await _launchWhatsApp();
      }

      return;
    }

    // ==========================================================
    // ATAS DASAR PRAMONO
    // ==========================================================

    if (AILocalCommands
        .isPramonoDeveloperMode(
      prompt,
    )) {
      await SoundHelper()
          .playClick();

      await ref
          .read(
            aiChatProvider
                .notifier,
          )
          .sendMessage(
            prompt,
          );

      _scrollToBottom();

      return;
    }

    // ==========================================================
    // NORMAL
    // ==========================================================

    await ref
        .read(
          aiChatProvider
              .notifier,
        )
        .sendMessage(
          prompt,
        );

    _scrollToBottom();
  }

  // ============================================================
  // WHATSAPP
  // ============================================================

  Future<void> _launchWhatsApp() async {
    const phone =
        AILocalCommands.whatsappPhone;

    const message =
        AILocalCommands.whatsappMessage;

    final encodedMessage =
        Uri.encodeComponent(
      message,
    );

    final whatsappSchemeUrl =
        Uri.parse(
      'whatsapp://send?phone=$phone&text=$encodedMessage',
    );

    final webUrl =
        Uri.parse(
      'https://wa.me/$phone?text=$encodedMessage',
    );

    try {
      final appLaunched =
          await launchUrl(
        whatsappSchemeUrl,
        mode:
            LaunchMode
                .externalApplication,
      );

      if (appLaunched) {
        return;
      }

      final webLaunched =
          await launchUrl(
        webUrl,
        mode:
            LaunchMode
                .externalApplication,
      );

      if (webLaunched) {
        return;
      }

      if (mounted) {
        _showWhatsAppError();
      }
    } catch (e) {
      debugPrint(
        'Gagal membuka WhatsApp: $e',
      );

      if (mounted) {
        _showWhatsAppError();
      }
    }
  }

  void _showWhatsAppError() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content:
            Text(
          'WhatsApp tidak dapat dibuka.',
        ),
      ),
    );
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollToBottom() {
    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        if (!_scrollController
            .hasClients) {
          return;
        }

        _scrollController
            .animateTo(
          _scrollController
                  .position
                  .maxScrollExtent +
              120,
          duration:
              const Duration(
            milliseconds:
                250,
          ),
          curve:
              Curves.easeOut,
        );
      },
    );
  }

  // ============================================================
  // COLORS
  // ============================================================

  Color _getPrimaryTextColor(
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    if (ThemeHelper.isNeo(
        themeMode)) {
      return AppColors
          .neoTextPrimary;
    }

    if (ThemeHelper.isGlass(
        themeMode)) {
      return AppColors
          .glassTextPrimary;
    }

    if (ThemeHelper.isModern(
        themeMode)) {
      return AppColors
          .modernTextPrimary;
    }

    if (ThemeHelper.isAurora(
        themeMode)) {
      return AppColors
          .auroraTextPrimary;
    }

    if (ThemeHelper.isCyber(
        themeMode)) {
      return AppColors
          .cyberTextPrimary;
    }

    return colors.onSurface;
  }

  Color _getSecondaryTextColor(
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    if (ThemeHelper.isNeo(
        themeMode)) {
      return AppColors
          .neoTextSecondary;
    }

    if (ThemeHelper.isGlass(
        themeMode)) {
      return AppColors
          .glassTextSecondary;
    }

    if (ThemeHelper.isModern(
        themeMode)) {
      return AppColors
          .modernTextSecondary;
    }

    if (ThemeHelper.isAurora(
        themeMode)) {
      return AppColors
          .auroraTextSecondary;
    }

    if (ThemeHelper.isCyber(
        themeMode)) {
      return AppColors
          .cyberTextSecondary;
    }

    return colors
        .onSurfaceVariant;
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
      baseColor =
          AppColors.neoBase;
    } else if (isGlass) {
      baseColor =
          AppColors.glassBg1;
    } else if (isModern) {
      baseColor =
          AppColors.modernBg;
    } else if (isAurora) {
      baseColor =
          AppColors.auroraSurface;
    } else if (isCyber) {
      baseColor =
          AppColors.cyberBg;
    } else {
      baseColor =
          colors.surface;
    }

    final secondaryGlow =
        isAurora || isCyber
            ? colors.secondary
            : accentColor;

    final tertiaryGlow =
        isAurora
            ? colors.tertiary
            : colors.primary;

    final glowOpacity = isGlass
        ? 0.14
        : isCyber
            ? 0.10
            : isAurora
                ? 0.18
                : 0.08;

    return IgnorePointer(
      child: Stack(
        fit:
            StackFit.expand,
        children: [
          DecoratedBox(
            decoration:
                BoxDecoration(
              color:
                  baseColor,
              gradient:
                  LinearGradient(
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
            top:
                -150,
            left:
                -120,
            child:
                _buildGlow(
              size:
                  340,
              color:
                  accentColor,
              opacity:
                  glowOpacity,
            ),
          ),
          Positioned(
            top:
                70,
            right:
                -180,
            child:
                _buildGlow(
              size:
                  390,
              color:
                  secondaryGlow,
              opacity:
                  glowOpacity *
                      0.85,
            ),
          ),
          Positioned(
            bottom:
                -210,
            left:
                -150,
            child:
                _buildGlow(
              size:
                  420,
              color:
                  tertiaryGlow,
              opacity:
                  glowOpacity *
                      0.70,
            ),
          ),
          Positioned(
            bottom:
                -170,
            right:
                -120,
            child:
                _buildGlow(
              size:
                  360,
              color:
                  accentColor,
              opacity:
                  glowOpacity *
                      0.65,
            ),
          ),
          Positioned.fill(
            child:
                DecoratedBox(
              decoration:
                  BoxDecoration(
                gradient:
                    RadialGradient(
                  center:
                      Alignment.center,
                  radius:
                      1.15,
                  colors: [
                    accentColor
                        .withValues(
                      alpha:
                          isAurora
                              ? 0.035
                              : 0.018,
                    ),
                    Colors
                        .transparent,
                  ],
                ),
              ),
            ),
          ),
          if (isCyber)
            Positioned.fill(
              child:
                  CustomPaint(
                painter:
                    _CyberBackgroundPainter(
                  lineColor:
                      accentColor
                          .withValues(
                    alpha:
                        0.035,
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
      width:
          size,
      height:
          size,
      decoration:
          BoxDecoration(
        shape:
            BoxShape.circle,
        gradient:
            RadialGradient(
          colors: [
            color.withValues(
              alpha:
                  opacity,
            ),
            color.withValues(
              alpha:
                  opacity *
                      0.35,
            ),
            Colors
                .transparent,
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUBBLE
  // ============================================================

  BoxDecoration
      _getThemedBubbleDecoration(
    AppThemeMode themeMode,
    ColorScheme colors,
    bool isUser,
  ) {
    if (isUser) {
      return BoxDecoration(
        color:
            ThemeHelper
                .getAccentColor(
          themeMode,
          colors,
        ),
        borderRadius:
            const BorderRadius.only(
          topLeft:
              Radius.circular(
            20,
          ),
          topRight:
              Radius.circular(
            20,
          ),
          bottomLeft:
              Radius.circular(
            20,
          ),
          bottomRight:
              Radius.circular(
            4,
          ),
        ),
      );
    }

    if (ThemeHelper.isNeo(
        themeMode)) {
      return neumorphismDecoration(
        borderRadius:
            20,
        isPressed:
            true,
      );
    }

    if (ThemeHelper.isGlass(
        themeMode)) {
      return glassmorphismDecoration(
        borderRadius:
            20,
      );
    }

    if (ThemeHelper.isModern(
        themeMode)) {
      return modernDecoration(
        borderRadius:
            20,
      );
    }

    if (ThemeHelper.isAurora(
        themeMode)) {
      return auroraDecoration(
        borderRadius:
            20,
      );
    }

    if (ThemeHelper.isCyber(
        themeMode)) {
      return cyberpunkDecoration(
        borderRadius:
            12,
      );
    }

    return BoxDecoration(
      color: colors
          .surfaceContainerHighest,
      borderRadius:
          const BorderRadius
              .only(
        topLeft:
            Radius.circular(
          4,
        ),
        topRight:
            Radius.circular(
          20,
        ),
        bottomLeft:
            Radius.circular(
          20,
        ),
        bottomRight:
            Radius.circular(
          20,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context)
            .colorScheme;

    final chatState =
        ref.watch(
      aiChatProvider,
    );

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
      fit:
          StackFit.expand,
      children: [
        _buildAssistantBackground(
          themeMode,
          colors,
        ),
        Scaffold(
          key:
              _scaffoldKey,
          backgroundColor:
              Colors.transparent,
          appBar:
              AppBar(
            backgroundColor:
                Colors.transparent,
            elevation:
                0,
            scrolledUnderElevation:
                0,
            surfaceTintColor:
                Colors.transparent,
            title:
                Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color:
                      ThemeHelper.getAccentColor(
                    themeMode,
                    colors,
                  ),
                ),
                const SizedBox(
                  width: 8,
                ),
                Text(
                  'AI Assistant',
                  style:
                      TextStyle(
                    color:
                        primaryText,
                  ),
                ),
              ],
            ),
            leading:
                IconButton(
              icon:
                  Icon(
                Icons.menu,
                color:
                    primaryText,
              ),
              onPressed:
                  () async {
                await SoundHelper()
                    .playClick();

                _scaffoldKey
                    .currentState
                    ?.openDrawer();
              },
              tooltip:
                  'Riwayat Chat',
            ),
          ),
          drawer:
              _buildDrawer(
            themeMode,
            chatState,
          ),
          body:
              SafeArea(
            child:
                chatState.isFetching
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
                                ? ScrollReveal(
                                    child:
                                        _buildEmptyState(
                                      themeMode,
                                    ),
                                  )
                                : ListView
                                    .builder(
                                    controller:
                                        _scrollController,
                                    padding:
                                        const EdgeInsets.fromLTRB(
                                      16,
                                      16,
                                      16,
                                      24,
                                    ),
                                    itemCount: chatState
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
                                        return ScrollReveal(
                                          delay:
                                              Duration(
                                            milliseconds:
                                                50 *
                                                    (index %
                                                        4),
                                          ),
                                          child:
                                              _buildMessageBubble(
                                            chatState
                                                .currentMessages[
                                                    index],
                                            themeMode,
                                          ),
                                        );
                                      }

                                      return ScrollReveal(
                                        child:
                                            _buildTypingIndicator(
                                          themeMode,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          ScrollReveal(
                            delay:
                                const Duration(
                              milliseconds:
                                  150,
                            ),
                            beginOffset:
                                const Offset(
                              0,
                              0.05,
                            ),
                            child:
                                _buildComposer(
                              themeMode,
                            ),
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

    final drawerContents =
        Column(
      children: [
        Container(
          padding:
              EdgeInsets.only(
            top:
                MediaQuery.of(
                        context)
                    .padding
                    .top +
                16,
            bottom:
                16,
            left:
                16,
            right:
                16,
          ),
          width:
              double.infinity,
          decoration:
              BoxDecoration(
            color: isGlass
                ? AppColors.glassBg1
                    .withValues(
                    alpha:
                        0.78,
                  )
                : isNeo
                    ? AppColors
                        .neoBaseAlt
                    : accentColor,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Text(
                'Riwayat Chat',
                style:
                    TextStyle(
                  color: isGlass
                      ? Colors.white
                      : isNeo
                          ? AppColors
                              .neoTextPrimary
                          : colors
                              .onPrimary,
                  fontSize:
                      20,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const SizedBox(
                height:
                    4,
              ),
              Text(
                '${chatState.sessions.length} sesi tersimpan',
                style:
                    TextStyle(
                  color: isGlass
                      ? Colors.white70
                      : isNeo
                          ? AppColors
                              .neoTextSecondary
                          : colors
                              .onPrimary
                              .withValues(
                              alpha:
                                  0.8,
                            ),
                  fontSize:
                      14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child:
              chatState.sessions.isEmpty
                  ? Center(
                      child:
                          Text(
                        'Belum ada history chat',
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount:
                          chatState
                              .sessions
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
                          leading:
                              Icon(
                            Icons
                                .chat_bubble_outline,
                            color:
                                isActive
                                    ? activeColor
                                    : secondaryText,
                          ),
                          title:
                              Text(
                            session.title,
                            maxLines:
                                1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              fontWeight:
                                  isActive
                                      ? FontWeight.bold
                                      : null,
                              color:
                                  isActive
                                      ? activeColor
                                      : primaryText,
                            ),
                          ),
                          subtitle:
                              Text(
                            _formatTime(
                              session
                                  .createdTime,
                            ),
                            style:
                                TextStyle(
                              fontSize:
                                  12,
                              color:
                                  secondaryText,
                            ),
                          ),
                          trailing:
                              Row(
                            mainAxisSize:
                                MainAxisSize
                                    .min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .edit_outlined,
                                  size:
                                      19,
                                ),
                                color:
                                    secondaryText,
                                tooltip:
                                    'Ubah nama',
                                onPressed:
                                    () async {
                                  await SoundHelper()
                                      .playClick();

                                  await _showRenameSessionDialog(
                                    session,
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(
                                  Icons
                                      .delete_outline,
                                  size:
                                      20,
                                ),
                                color:
                                    secondaryText,
                                tooltip:
                                    'Hapus chat',
                                onPressed:
                                    () async {
                                  await SoundHelper()
                                      .playClick();

                                  await _confirmDeleteSession(
                                    session,
                                  );
                                },
                              ),
                            ],
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
          height:
              1,
          color:
              ThemeHelper
                  .dividerColor(
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
            themeMode:
                themeMode,
            colors:
                colors,
            accentColor:
                accentColor,
          ),
        ),
      ],
    );

    if (isNeo) {
      return Drawer(
        backgroundColor:
            AppColors.neoBase,
        child:
            drawerContents,
      );
    }

    if (isGlass) {
      return Drawer(
        backgroundColor:
            AppColors.glassBg1,
        child:
            drawerContents,
      );
    }

    if (ThemeHelper
        .isAurora(
      themeMode,
    )) {
      return Drawer(
        backgroundColor:
            AppColors
                .auroraSurface,
        child:
            drawerContents,
      );
    }

    if (ThemeHelper
        .isCyber(
      themeMode,
    )) {
      return Drawer(
        backgroundColor:
            AppColors.cyberBg,
        child:
            drawerContents,
      );
    }

    return Drawer(
      backgroundColor:
          ThemeHelper
              .getScaffoldBackgroundColor(
        themeMode,
        colors,
      ),
      child:
          drawerContents,
    );
  }

  // ============================================================
  // RENAME DIALOG
  // ============================================================

  Future<void>
      _showRenameSessionDialog(
    ChatSession session,
  ) async {
    final themeMode =
        ref.read(
      themeModeProvider,
    );

    final result =
        await showDialog<String>(
      context:
          context,
      builder:
          (dialogContext) {
        return _RenameSessionDialog(
          initialTitle:
              session.title,
          themeMode:
              themeMode,
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (result ==
            null ||
        result.trim().isEmpty) {
      return;
    }

    final success =
        await ref
            .read(
              aiChatProvider
                  .notifier,
            )
            .renameSession(
              session.id,
              result,
            );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content:
            Text(
          success
              ? 'Nama percakapan diperbarui.'
              : 'Gagal mengubah nama percakapan.',
        ),
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  Future<void>
      _confirmDeleteSession(
    ChatSession session,
  ) async {
    final confirmed =
        await showAppDialog<bool>(
      title:
          const Row(
        children: [
          Icon(
            Icons
                .delete_outline,
            color:
                Colors.red,
          ),
          SizedBox(
            width: 8,
          ),
          Text(
            'Hapus Chat?',
          ),
        ],
      ),
      content:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          const Text(
            'Yakin ingin menghapus percakapan ini?',
          ),
          const SizedBox(
            height: 12,
          ),
          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  Colors.red
                      .withValues(
                alpha:
                    0.08,
              ),
              borderRadius:
                  BorderRadius
                      .circular(
                10,
              ),
            ),
            child:
                Text(
              session.title,
              maxLines:
                  3,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          const Text(
            'Semua pesan dalam percakapan ini akan dihapus dan tidak dapat dikembalikan.',
            style:
                TextStyle(
              fontSize: 13,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed:
              () async {
            await SoundHelper()
                .playClick();

            if (mounted) {
              Navigator.pop(
                context,
                false,
              );
            }
          },
          child:
              const Text(
            'Batal',
          ),
        ),
        ElevatedButton.icon(
          onPressed:
              () async {
            await SoundHelper()
                .playClick();

            if (mounted) {
              Navigator.pop(
                context,
                true,
              );
            }
          },
          icon:
              const Icon(
            Icons
                .delete_outline,
            size:
                18,
          ),
          label:
              const Text(
            'Hapus',
          ),
          style:
              ElevatedButton
                  .styleFrom(
            backgroundColor:
                Colors.red,
            foregroundColor:
                Colors.white,
          ),
        ),
      ],
    );

    if (confirmed !=
        true) {
      return;
    }

    try {
      await ref
          .read(
            aiChatProvider
                .notifier,
          )
          .deleteSession(
            session.id,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content:
              Text(
            'Chat berhasil dihapus.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(
            'Gagal menghapus chat: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // NEW CHAT BUTTON
  // ============================================================

  Widget
      _buildDrawerNewChatButton({
    required AppThemeMode
        themeMode,
    required ColorScheme
        colors,
    required Color
        accentColor,
  }) {
    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    return ElevatedButton.icon(
      onPressed:
          () async {
        await SoundHelper()
            .playClick();

        ref
            .read(
              aiChatProvider
                  .notifier,
            )
            .startNewChat();

        if (mounted) {
          Navigator.pop(
            context,
          );
        }
      },
      icon:
          const Icon(
        Icons.add,
      ),
      label:
          const Text(
        'Chat Baru',
      ),
      style:
          ElevatedButton
              .styleFrom(
        minimumSize:
            const Size(
          double.infinity,
          48,
        ),
        backgroundColor:
            isGlass
                ? Colors.white
                    .withValues(
                    alpha:
                        0.22,
                  )
                : accentColor,
        foregroundColor:
            isGlass
                ? Colors.white
                : colors
                    .onPrimary,
        elevation:
            0,
        shadowColor:
            Colors.transparent,
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            ThemeHelper
                    .isCyber(
              themeMode,
            )
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
      child:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          24,
        ),
        child:
            Column(
          mainAxisAlignment:
              MainAxisAlignment
                  .center,
          children: [
            SizedBox(
              width:
                  180,
              height:
                  180,
              child:
                  Lottie.asset(
                'assets/animations/ai animation Flow 1.json',
                fit:
                    BoxFit.contain,
              ),
            ),
            const SizedBox(
              height:
                  24,
            ),
            Text(
              'Halo, Aku AI Assistant',
              textAlign:
                  TextAlign.center,
              style:
                  theme.textTheme
                      .headlineSmall
                      ?.copyWith(
                fontWeight:
                    FontWeight.bold,
                color:
                    primaryText,
              ),
            ),
            const SizedBox(
              height:
                  8,
            ),
            Text(
              'Mau cari informasi siswa apa hari ini?',
              textAlign:
                  TextAlign.center,
              style:
                  theme.textTheme
                      .bodyMedium
                      ?.copyWith(
                color:
                    secondaryText,
              ),
            ),
            const SizedBox(
              height:
                  32,
            ),
            Wrap(
              spacing:
                  10,
              runSpacing:
                  10,
              alignment:
                  WrapAlignment
                      .center,
              children:
                  _suggestions
                      .map(
                (q) {
                  final chipBackground =
                      ThemeHelper
                              .isNeo(
                        themeMode,
                      )
                          ? accentColor
                              .withValues(
                              alpha:
                                  0.10,
                            )
                          : ThemeHelper.isGlass(
                                  themeMode,
                                )
                              ? Colors
                                  .white
                                  .withValues(
                                  alpha:
                                      0.14,
                                )
                              : accentColor
                                  .withValues(
                                  alpha:
                                      0.08,
                                );

                  final chipBorder =
                      ThemeHelper
                              .isGlass(
                        themeMode,
                      )
                          ? Colors
                              .white
                              .withValues(
                              alpha:
                                  0.30,
                            )
                          : accentColor
                              .withValues(
                              alpha:
                                  0.20,
                            );

                  final chipText =
                      ThemeHelper
                              .isGlass(
                        themeMode,
                      )
                          ? Colors.white
                          : primaryText;

                  return ActionChip(
                    avatar:
                        Icon(
                      Icons
                          .auto_awesome_outlined,
                      size:
                          18,
                      color:
                          accentColor,
                    ),
                    label:
                        Text(q),
                    backgroundColor:
                        chipBackground,
                    side:
                        BorderSide(
                      color:
                          chipBorder,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
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
                    onPressed:
                        () async {
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

    final textColor = isUser
        ? colors.onPrimary
        : _getPrimaryTextColor(
            themeMode,
            colors,
          );

    final alignment = isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    return Align(
      alignment:
          alignment,
      child:
          Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.82,
        ),
        margin:
            const EdgeInsets.only(
          bottom:
              12,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              16,
          vertical:
              12,
        ),
        decoration:
            _getThemedBubbleDecoration(
          themeMode,
          colors,
          isUser,
        ),
        child:
            Row(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment
                  .end,
          children: [
            Flexible(
              child:
                  SelectableText(
                message.text,
                style:
                    TextStyle(
                  color:
                      textColor,
                  height:
                      1.4,
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
      child:
          Container(
        margin:
            const EdgeInsets.only(
          bottom:
              12,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal:
              16,
          vertical:
              14,
        ),
        decoration:
            _getThemedBubbleDecoration(
          themeMode,
          colors,
          false,
        ),
        child:
            Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            SizedBox(
              width:
                  16,
              height:
                  16,
              child:
                  CircularProgressIndicator(
                strokeWidth:
                    2,
                color:
                    accentColor,
              ),
            ),
            const SizedBox(
              width:
                  12,
            ),
            Text(
              'AI sedang membaca data siswa...',
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

    Color composerBackground;

    if (isGlass) {
      composerBackground =
          AppColors.glassBg1
              .withValues(
        alpha:
            0.70,
      );
    } else if (isNeo) {
      composerBackground =
          AppColors.neoBase;
    } else {
      composerBackground =
          colors.surface;
    }

    Color inputBackground;

    if (isGlass) {
      inputBackground =
          Colors.white.withValues(
        alpha:
            0.12,
      );
    } else if (isNeo) {
      inputBackground =
          AppColors.neoBaseAlt;
    } else {
      inputBackground =
          colors
              .surfaceContainerHighest;
    }

    final textFieldRadius =
        BorderRadius.circular(
      28,
    );

    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets
              .fromLTRB(
        12,
        8,
        12,
        12,
      ),
      decoration:
          BoxDecoration(
        color:
            composerBackground,
        border:
            Border(
          top:
              BorderSide(
            color: ThemeHelper
                    .dividerColor(
              themeMode,
            ).withValues(
              alpha:
                  0.45,
            ),
          ),
        ),
      ),
      child:
          SafeArea(
        top:
            false,
        child:
            Row(
          crossAxisAlignment:
              CrossAxisAlignment
                  .end,
          children: [
            Expanded(
              child:
                  Container(
                decoration:
                    BoxDecoration(
                  color:
                      inputBackground,
                  borderRadius:
                      textFieldRadius,
                  border:
                      Border.all(
                    color: ThemeHelper
                            .isGlass(
                          themeMode,
                        )
                        ? Colors.white
                            .withValues(
                            alpha:
                                0.20,
                          )
                        : ThemeHelper
                                .isNeo(
                          themeMode,
                        )
                            ? AppColors
                                .neoShadow
                                .withValues(
                                alpha:
                                    0.15,
                              )
                            : colors
                                .outlineVariant
                                .withValues(
                                alpha:
                                    0.40,
                              ),
                  ),
                ),
                child:
                    TextField(
                  controller:
                      _controller,
                  minLines:
                      1,
                  maxLines:
                      4,
                  textCapitalization:
                      TextCapitalization
                          .sentences,
                  style:
                      TextStyle(
                    color:
                        primaryText,
                    fontSize:
                        15,
                    height:
                        1.35,
                  ),
                  cursorColor:
                      accentColor,
                  decoration:
                      InputDecoration(
                    hintText:
                        'Tulis pertanyaan siswa...',
                    hintStyle:
                        TextStyle(
                      color:
                          secondaryText
                              .withValues(
                        alpha:
                            0.78,
                      ),
                      fontSize:
                          15,
                    ),
                    contentPadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal:
                          18,
                      vertical:
                          14,
                    ),
                    filled:
                        false,
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          textFieldRadius,
                      borderSide:
                          BorderSide.none,
                    ),
                    enabledBorder:
                        OutlineInputBorder(
                      borderRadius:
                          textFieldRadius,
                      borderSide:
                          BorderSide.none,
                    ),
                    focusedBorder:
                        OutlineInputBorder(
                      borderRadius:
                          textFieldRadius,
                      borderSide:
                          BorderSide.none,
                    ),
                    errorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          textFieldRadius,
                      borderSide:
                          BorderSide.none,
                    ),
                    focusedErrorBorder:
                        OutlineInputBorder(
                      borderRadius:
                          textFieldRadius,
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                  onSubmitted:
                      (_) =>
                          _sendMessage(),
                ),
              ),
            ),
            const SizedBox(
              width:
                  8,
            ),
            Container(
              height:
                  50,
              width:
                  50,
              decoration:
                  BoxDecoration(
                color:
                    accentColor,
                shape:
                    BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        accentColor
                            .withValues(
                      alpha:
                          0.30,
                    ),
                    blurRadius:
                        8,
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
                  onTap: ref
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
                    child:
                        ref.watch(
                              aiChatProvider,
                            ).isLoading
                            ? SizedBox(
                                width:
                                    20,
                                height:
                                    20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                  color: isGlass
                                      ? AppColors
                                          .glassBg1
                                      : colors
                                          .onPrimary,
                                ),
                              )
                            : Icon(
                                Icons
                                    .arrow_upward_rounded,
                                size:
                                    24,
                                color: isGlass
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
  // TIME
  // ============================================================

  String _formatTime(
    DateTime dt,
  ) {
    return '${dt.day}/${dt.month}/${dt.year} '
        '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // GENERIC DIALOG
  // ============================================================

  Future<T?> showAppDialog<T>({
    required Widget title,
    required Widget content,
    List<Widget> actions =
        const [],
  }) {
    final themeMode =
        ref.read(
      themeModeProvider,
    );

    return showDialog<T>(
      context:
          context,
      builder:
          (ctx) {
        final media =
            MediaQuery.of(
          ctx,
        );

        final maxHeight =
            (media.size.height -
                    media.viewInsets
                        .bottom -
                    48)
                .clamp(
                  180.0,
                  760.0,
                )
                .toDouble();

        return Dialog(
          backgroundColor:
              Colors.transparent,
          elevation:
              0,
          insetPadding:
              const EdgeInsets
                  .symmetric(
            horizontal:
                24,
            vertical:
                24,
          ),
          child:
              AnimatedPadding(
            duration:
                const Duration(
              milliseconds:
                  150,
            ),
            curve:
                Curves.easeOut,
            padding:
                EdgeInsets.only(
              bottom:
                  media.viewInsets
                      .bottom,
            ),
            child:
                ConstrainedBox(
              constraints:
                  BoxConstraints(
                maxHeight:
                    maxHeight,
              ),
              child:
                  _buildDialogContainer(
                themeMode:
                    themeMode,
                context:
                    ctx,
                title:
                    title,
                content:
                    content,
                actions:
                    actions,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogContainer({
    required AppThemeMode
        themeMode,
    required BuildContext
        context,
    required Widget title,
    required Widget content,
    required List<Widget>
        actions,
  }) {
    final dialogContent =
        Padding(
      padding:
          const EdgeInsets
              .fromLTRB(
        24,
        24,
        24,
        16,
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
        children: [
          DefaultTextStyle(
            style:
                Theme.of(
              context,
            )
                    .textTheme
                    .titleLarge ??
                const TextStyle(),
            child:
                title,
          ),
          const SizedBox(
            height:
                20,
          ),
          Flexible(
            child:
                SingleChildScrollView(
              child:
                  content,
            ),
          ),
          if (actions
              .isNotEmpty) ...[
            const SizedBox(
              height:
                  24,
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment
                      .end,
              children:
                  actions,
            ),
          ],
        ],
      ),
    );

    if (ThemeHelper.isNeo(
        themeMode)) {
      return Container(
        decoration:
            neumorphismDecoration(
          borderRadius:
              22,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius
                  .circular(
            22,
          ),
          child:
              dialogContent,
        ),
      );
    }

    if (ThemeHelper.isGlass(
        themeMode)) {
      return Container(
        decoration:
            glassmorphismDecoration(
          borderRadius:
              20,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius
                  .circular(
            20,
          ),
          child:
              dialogContent,
        ),
      );
    }

    if (ThemeHelper.isModern(
        themeMode)) {
      return Container(
        decoration:
            modernDecoration(
          borderRadius:
              24,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius
                  .circular(
            24,
          ),
          child:
              dialogContent,
        ),
      );
    }

    if (ThemeHelper.isAurora(
        themeMode)) {
      return Container(
        decoration:
            auroraDecoration(
          borderRadius:
              22,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius
                  .circular(
            22,
          ),
          child:
              dialogContent,
        ),
      );
    }

    if (ThemeHelper.isCyber(
        themeMode)) {
      return Container(
        decoration:
            cyberpunkDecoration(
          borderRadius:
              12,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius
                  .circular(
            12,
          ),
          child:
              dialogContent,
        ),
      );
    }

    return Card(
      elevation:
          3,
      clipBehavior:
          Clip.antiAlias,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          dialogContent,
    );
  }
}

// ================================================================
// RENAME SESSION DIALOG
// ================================================================

class _RenameSessionDialog
    extends StatefulWidget {
  final String initialTitle;
  final AppThemeMode themeMode;

  const _RenameSessionDialog({
    required this.initialTitle,
    required this.themeMode,
  });

  @override
  State<
          _RenameSessionDialog>
      createState() =>
          _RenameSessionDialogState();
}

class _RenameSessionDialogState
    extends State<
        _RenameSessionDialog> {
  late final TextEditingController
      _controller;

  @override
  void initState() {
    super.initState();

    _controller =
        TextEditingController(
      text:
          widget.initialTitle,
    );
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  void _submit() {
    final title =
        _controller.text.trim();

    if (title.isEmpty) {
      return;
    }

    Navigator.of(
      context,
    ).pop(
      title,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context)
            .colorScheme;

    final isGlass =
        ThemeHelper.isGlass(
      widget.themeMode,
    );

    final isNeo =
        ThemeHelper.isNeo(
      widget.themeMode,
    );

    final titleColor =
        isGlass
            ? Colors.white
            : colors.onSurface;

    final child =
        Padding(
      padding:
          const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        16,
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment
                .stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .edit_outlined,
                color:
                    isGlass
                        ? Colors.white
                        : colors.primary,
              ),
              const SizedBox(
                width:
                    8,
              ),
              Expanded(
                child:
                    Text(
                  'Ubah Nama Percakapan',
                  style:
                      TextStyle(
                    color:
                        titleColor,
                    fontSize:
                        20,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height:
                20,
          ),
          TextField(
            controller:
                _controller,
            autofocus:
                true,
            maxLength:
                60,
            textInputAction:
                TextInputAction.done,
            style:
                TextStyle(
              color:
                  isGlass
                      ? Colors.white
                      : colors.onSurface,
            ),
            decoration:
                InputDecoration(
              labelText:
                  'Nama percakapan',
              hintText:
                  'Contoh: Pembayaran siswa',
              prefixIcon:
                  Icon(
                Icons
                    .chat_outlined,
                color:
                    isGlass
                        ? Colors.white70
                        : null,
              ),
              labelStyle:
                  isGlass
                      ? const TextStyle(
                          color:
                              Colors.white70,
                        )
                      : null,
              hintStyle:
                  isGlass
                      ? const TextStyle(
                          color:
                              Colors.white54,
                        )
                      : null,
            ),
            onSubmitted:
                (_) =>
                    _submit(),
          ),
          const SizedBox(
            height:
                8,
          ),
          Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .end,
            children: [
              TextButton(
                onPressed:
                    () async {
                  await SoundHelper()
                      .playClick();

                  if (mounted) {
                    Navigator.pop(
                      context,
                    );
                  }
                },
                child:
                    const Text(
                  'Batal',
                ),
              ),
              const SizedBox(
                width:
                    8,
              ),
              ElevatedButton(
                onPressed:
                    () async {
                  final title =
                      _controller.text
                          .trim();

                  if (title.isEmpty) {
                    return;
                  }

                  await SoundHelper()
                      .playClick();

                  if (mounted) {
                    Navigator.pop(
                      context,
                      title,
                    );
                  }
                },
                child:
                    const Text(
                  'Simpan',
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final decoratedChild =
        isNeo
            ? Container(
                decoration:
                    neumorphismDecoration(
                  borderRadius:
                      22,
                ),
                child:
                    ClipRRect(
                  borderRadius:
                      BorderRadius
                          .circular(
                    22,
                  ),
                  child:
                      child,
                ),
              )
            : isGlass
                ? Container(
                    decoration:
                        glassmorphismDecoration(
                      borderRadius:
                          20,
                    ),
                    child:
                        ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        20,
                      ),
                      child:
                          child,
                    ),
                  )
                : ThemeHelper
                        .isModern(
                    widget.themeMode,
                  )
                    ? Container(
                        decoration:
                            modernDecoration(
                          borderRadius:
                              24,
                        ),
                        child:
                            ClipRRect(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            24,
                          ),
                          child:
                              child,
                        ),
                      )
                    : ThemeHelper
                            .isAurora(
                        widget.themeMode,
                      )
                        ? Container(
                            decoration:
                                auroraDecoration(
                              borderRadius:
                                  22,
                            ),
                            child:
                                ClipRRect(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                22,
                              ),
                              child:
                                  child,
                            ),
                          )
                        : ThemeHelper
                                .isCyber(
                            widget.themeMode,
                          )
                            ? Container(
                                decoration:
                                    cyberpunkDecoration(
                                  borderRadius:
                                      12,
                                ),
                                child:
                                    ClipRRect(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    12,
                                  ),
                                  child:
                                      child,
                                ),
                              )
                            : Card(
                                elevation:
                                    3,
                                clipBehavior:
                                    Clip.antiAlias,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    18,
                                  ),
                                ),
                                child:
                                    child,
                              );

    final media =
        MediaQuery.of(
      context,
    );

    final maxHeight =
        (media.size.height -
                media.viewInsets
                    .bottom -
                32)
            .clamp(
              220.0,
              600.0,
            )
            .toDouble();

    return Dialog(
      backgroundColor:
          Colors.transparent,
      elevation:
          0,
      insetPadding:
          const EdgeInsets
              .symmetric(
        horizontal:
            24,
        vertical:
            24,
      ),
      child:
          AnimatedPadding(
        duration:
            const Duration(
          milliseconds:
              150,
        ),
        curve:
            Curves.easeOut,
        padding:
            EdgeInsets.only(
          bottom:
              media.viewInsets
                  .bottom,
        ),
        child:
            ConstrainedBox(
          constraints:
              BoxConstraints(
            maxWidth:
                420,
            maxHeight:
                maxHeight,
          ),
          child:
              SingleChildScrollView(
            child:
                decoratedChild,
          ),
        ),
      ),
    );
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
    final paint =
        Paint()
          ..color =
              lineColor
          ..strokeWidth =
              1;

    const double spacing =
        42;

    for (
      double x = 0;
      x <= size.width;
      x += spacing
    ) {
      canvas.drawLine(
        Offset(
          x,
          0,
        ),
        Offset(
          x,
          size.height,
        ),
        paint,
      );
    }

    for (
      double y = 0;
      y <= size.height;
      y += spacing
    ) {
      canvas.drawLine(
        Offset(
          0,
          y,
        ),
        Offset(
          size.width,
          y,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
        _CyberBackgroundPainter
            oldDelegate,
  ) {
    return oldDelegate
            .lineColor !=
        lineColor;
  }
}