// lib/pages/auth_page.dart

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../env/api_key.dart';
import '../firebase/firestore_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.onAuthSuccess});

  final VoidCallback? onAuthSuccess;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // ============================================================
  // FIREBASE AUTH
  // ============================================================

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // ============================================================
  // GOOGLE SIGN IN
  // ============================================================

  static Future<void>? _googleInitialization;

  Future<void> _initializeGoogle() {
    return _googleInitialization ??=
        GoogleSignIn.instance.initialize();
  }

  // ============================================================
  // EMAIL ADMIN SEKOLAH
  // ============================================================

  static const String _adminApprovalEmail =
      'newpramono79@gmail.com';

  // ============================================================
  // FORM
  // ============================================================

  final TextEditingController _namaController =
      TextEditingController();

  bool _isLoading = false;

  bool _isLoginMode = true;

  // ============================================================
  // DEBUG LOG
  // ============================================================

  void _debugLog(String message) {
    final String text =
        '[AUTH ${DateTime.now().toIso8601String()}] $message';

    debugPrint(text);
  }

  // ============================================================
  // VALIDASI URL
  // ============================================================

  void _validateOtpServiceUrl() {
    final String url = otpServiceUrl.trim();

    if (url.isEmpty) {
      throw Exception(
        'otpServiceUrl kosong.',
      );
    }

    if (url.startsWith('GANTI_')) {
      throw Exception(
        'otpServiceUrl belum diisi.',
      );
    }

    if (!url.startsWith('https://')) {
      throw Exception(
        'URL OTP harus menggunakan HTTPS.',
      );
    }

    if (!url.contains('/exec')) {
      throw Exception(
        'URL OTP harus merupakan URL Web App '
        'Google Apps Script dan berakhiran /exec.',
      );
    }

    _debugLog(
      'OTP service URL valid: $url',
    );
  }

  // ============================================================
  // HTTP GET + MANUAL REDIRECT
  // ============================================================
  //
  // Google Apps Script Web App dapat mengembalikan redirect.
  //
  // Kita sengaja tidak menganggap HTTP 302 sebagai error.
  // Flutter akan mengikuti Location sampai mendapatkan
  // response final.
  // ============================================================

  Future<http.Response> _getFollowingRedirects(
    Uri initialUri,
  ) async {
    final http.Client client = http.Client();

    Uri currentUri = initialUri;

    try {
      const int maxRedirects = 8;

      for (int attempt = 0;
          attempt <= maxRedirects;
          attempt++) {
        _debugLog(
          'GET attempt ${attempt + 1}: $currentUri',
        );

        final http.Request request =
            http.Request(
          'GET',
          currentUri,
        )..followRedirects = false;

        final http.StreamedResponse streamedResponse =
            await client
                .send(request)
                .timeout(
                  const Duration(seconds: 30),
                );

        final http.Response response =
            await http.Response.fromStream(
          streamedResponse,
        );

        _debugLog(
          'HTTP ${response.statusCode} '
          'from $currentUri',
        );

        // --------------------------------------------------------
        // RESPONSE FINAL
        // --------------------------------------------------------

        if (!_isRedirectStatus(
          response.statusCode,
        )) {
          return response;
        }

        // --------------------------------------------------------
        // REDIRECT
        // --------------------------------------------------------

        final String? location =
            response.headers['location'];

        if (location == null ||
            location.trim().isEmpty) {
          throw Exception(
            'Server mengembalikan HTTP '
            '${response.statusCode}, tetapi header '
            'Location tidak tersedia.\n\n'
            'Response:\n'
            '${_preview(response.body, 1200)}',
          );
        }

        final Uri nextUri =
            currentUri.resolve(location);

        _debugLog(
          'Redirect ${response.statusCode} → $nextUri',
        );

        currentUri = nextUri;
      }

      throw Exception(
        'Redirect server terlalu banyak '
        '(${maxRedirects + 1} kali).',
      );
    } finally {
      client.close();
    }
  }

  bool _isRedirectStatus(int statusCode) {
    return statusCode == 301 ||
        statusCode == 302 ||
        statusCode == 303 ||
        statusCode == 307 ||
        statusCode == 308;
  }

  // ============================================================
  // PREVIEW RESPONSE
  // ============================================================

  String _preview(
    String body,
    int maxLength,
  ) {
    final String value = body.trim();

    if (value.length <= maxLength) {
      return value;
    }

    return '${value.substring(0, maxLength)}...';
  }

  // ============================================================
  // PARSE JSON
  // ============================================================

  Map<String, dynamic> _parseOtpResponse(
    http.Response response,
  ) {
    final String body = response.body.trim();

    if (body.isEmpty) {
      throw Exception(
        'Response OTP kosong.\n\n'
        'HTTP: ${response.statusCode}\n'
        'URL: ${response.request?.url}',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception(
        'Response OTP bukan JSON.\n\n'
        'HTTP: ${response.statusCode}\n'
        'Content-Type: '
        '${response.headers['content-type'] ?? '-'}\n\n'
        'Response server:\n'
        '${_preview(body, 1600)}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Format JSON dari server OTP tidak sesuai.\n\n'
        'HTTP: ${response.statusCode}\n\n'
        'Response:\n'
        '${_preview(body, 1600)}',
      );
    }

    return decoded;
  }

  // ============================================================
  // HTTP ERROR DETAIL
  // ============================================================

  Exception _otpHttpError(
    http.Response response,
  ) {
    return Exception(
      'Server OTP mengembalikan HTTP '
      '${response.statusCode}.\n\n'
      'URL akhir:\n'
      '${response.request?.url}\n\n'
      'Content-Type:\n'
      '${response.headers['content-type'] ?? '-'}\n\n'
      'Location:\n'
      '${response.headers['location'] ?? '-'}\n\n'
      'Response server:\n'
      '${_preview(response.body, 1600)}',
    );
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================
  //
  // Digunakan untuk memastikan Flutter benar-benar dapat
  // mencapai deployment Apps Script.
  // ============================================================

  Future<Map<String, dynamic>> _checkOtpService() async {
    _validateOtpServiceUrl();

    final String requestId =
        'health-${DateTime.now().millisecondsSinceEpoch}';

    final Uri uri =
        Uri.parse(otpServiceUrl).replace(
      queryParameters: {
        'action': 'health',
        'requestId': requestId,
      },
    );

    _debugLog(
      'Health check dimulai. requestId=$requestId',
    );

    final http.Response response =
        await _getFollowingRedirects(uri);

    _debugLog(
      'Health final HTTP ${response.statusCode}. '
      'requestId=$requestId',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _otpHttpError(response);
    }

    final Map<String, dynamic> decoded =
        _parseOtpResponse(response);

    if (decoded['ok'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Health check OTP gagal.',
      );
    }

    _debugLog(
      'Health check berhasil. '
      'service=${decoded['service']}',
    );

    return decoded;
  }

  // ============================================================
  // SEND REGISTRATION OTP
  // ============================================================

  Future<Map<String, dynamic>>
      _sendRegistrationOtp({
    required String applicantEmail,
    required String applicantName,
  }) async {
    _validateOtpServiceUrl();

    // ----------------------------------------------------------
    // HEALTH CHECK
    // ----------------------------------------------------------

    await _checkOtpService();

    // ----------------------------------------------------------
    // REQUEST ID
    // ----------------------------------------------------------

    final String requestId =
        'send-${DateTime.now().millisecondsSinceEpoch}';

    // ----------------------------------------------------------
    // URL
    // ----------------------------------------------------------

    final Uri uri =
        Uri.parse(otpServiceUrl).replace(
      queryParameters: {
        'action': 'sendOtp',
        'email': applicantEmail,
        'name': applicantName,
        'requestId': requestId,
      },
    );

    _debugLog(
      'Mengirim request OTP. '
      'requestId=$requestId '
      'email=$applicantEmail',
    );

    // ----------------------------------------------------------
    // GET
    // ----------------------------------------------------------

    final http.Response response =
        await _getFollowingRedirects(uri);

    _debugLog(
      'Response sendOtp: '
      'HTTP ${response.statusCode} '
      'requestId=$requestId',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _otpHttpError(response);
    }

    // ----------------------------------------------------------
    // PARSE
    // ----------------------------------------------------------

    final Map<String, dynamic> decoded =
        _parseOtpResponse(response);

    _debugLog(
      'JSON sendOtp: '
      '${_preview(jsonEncode(decoded), 1200)}',
    );

    if (decoded['ok'] != true) {
      throw Exception(
        decoded['message']?.toString() ??
            'Server gagal mengirim OTP.',
      );
    }

    _debugLog(
      'OTP berhasil diproses oleh server. '
      'requestId=${decoded['requestId'] ?? requestId}',
    );

    return decoded;
  }

  // ============================================================
  // VERIFY REGISTRATION OTP
  // ============================================================

  Future<Map<String, dynamic>>
      _verifyRegistrationOtp({
    required String applicantEmail,
    required String code,
  }) async {
    _validateOtpServiceUrl();

    final String requestId =
        'verify-${DateTime.now().millisecondsSinceEpoch}';

    final Uri uri =
        Uri.parse(otpServiceUrl).replace(
      queryParameters: {
        'action': 'verifyOtp',
        'email': applicantEmail,
        'code': code,
        'requestId': requestId,
      },
    );

    _debugLog(
      'Verifikasi OTP dimulai. '
      'requestId=$requestId '
      'email=$applicantEmail',
    );

    final http.Response response =
        await _getFollowingRedirects(uri);

    _debugLog(
      'Response verifyOtp: '
      'HTTP ${response.statusCode} '
      'requestId=$requestId',
    );

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw _otpHttpError(response);
    }

    final Map<String, dynamic> decoded =
        _parseOtpResponse(response);

    _debugLog(
      'JSON verifyOtp: '
      '${_preview(jsonEncode(decoded), 1200)}',
    );

    return decoded;
  }

  // ============================================================
  // GOOGLE AUTH
  // ============================================================

  Future<UserCredential> _signInWithGoogle() async {
    _debugLog(
      'Google Sign-In dimulai.',
    );

    await _initializeGoogle();

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw Exception(
        'Google Sign-In tidak tersedia pada platform ini.',
      );
    }

    final GoogleSignInAccount googleUser =
        await GoogleSignIn.instance.authenticate();

    _debugLog(
      'Google account dipilih: '
      '${googleUser.email}',
    );

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final String? idToken =
        googleAuth.idToken;

    if (idToken == null ||
        idToken.isEmpty) {
      throw Exception(
        'Google tidak memberikan ID Token.',
      );
    }

    final AuthCredential credential =
        GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final UserCredential credentialResult =
        await _firebaseAuth.signInWithCredential(
      credential,
    );

    _debugLog(
      'Firebase Google Sign-In berhasil. '
      'uid=${credentialResult.user?.uid}',
    );

    return credentialResult;
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> _login() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    bool sessionOpened = false;

    try {
      final UserCredential credential =
          await _signInWithGoogle();

      sessionOpened = true;

      final User? user =
          credential.user;

      if (user == null) {
        throw Exception(
          'User Firebase tidak ditemukan.',
        );
      }

      _debugLog(
        'Memeriksa akun Firestore untuk login.',
      );

      final bool registered =
          await isUserAccountRegistered(
        user.uid,
      );

      if (!registered) {
        await _signOut();

        sessionOpened = false;

        if (!mounted) return;

        _showError(
          'Akun Google ini belum terdaftar.\n\n'
          'Silakan gunakan menu Daftar terlebih dahulu.',
        );

        return;
      }

      final DocumentSnapshot<
          Map<String, dynamic>> account =
          await fetchUserAccount(
        user.uid,
      );

      if (!account.exists) {
        await _signOut();

        sessionOpened = false;

        if (!mounted) return;

        _showError(
          'Data akun tidak ditemukan di Firestore.',
        );

        return;
      }

      final Map<String, dynamic> data =
          account.data() ?? {};

      final String nama =
          data['nama'] as String? ??
              user.displayName ??
              'Pengguna';

      final String role =
          data['role'] as String? ??
              'guru';

      _debugLog(
        'Login berhasil untuk $nama. role=$role',
      );

      if (!mounted) return;

      await _showLoginSuccess(
        nama: nama,
        role: role,
      );

      if (!mounted) return;

      widget.onAuthSuccess?.call();
    } on FirebaseAuthException catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        _firebaseAuthErrorMessage(e),
      );
    } on GoogleSignInException catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        _googleSignInErrorMessage(e),
      );
    } catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        'Login gagal.\n\n$e',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> _register() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    bool sessionOpened = false;

    try {
      final UserCredential credential =
          await _signInWithGoogle();

      sessionOpened = true;

      final User? user =
          credential.user;

      if (user == null) {
        throw Exception(
          'User Firebase tidak ditemukan.',
        );
      }

      final String email =
          user.email?.trim() ?? '';

      if (email.isEmpty) {
        throw Exception(
          'Akun Google tidak memiliki alamat email.',
        );
      }

      _debugLog(
        'Pendaftaran dimulai untuk $email.',
      );

      // --------------------------------------------------------
      // CEK SUDAH TERDAFTAR
      // --------------------------------------------------------

      final bool registered =
          await isUserAccountRegistered(
        user.uid,
      );

      if (registered) {
        await _signOut();

        sessionOpened = false;

        if (!mounted) return;

        _showError(
          'Akun Google ini sudah terdaftar.\n\n'
          'Silakan gunakan Login.',
        );

        return;
      }

      // --------------------------------------------------------
      // DEFAULT NAMA
      // --------------------------------------------------------

      _namaController.text =
          user.displayName?.trim() ?? '';

      if (_namaController.text.isEmpty) {
        _namaController.text =
            email.split('@').first;
      }

      if (!mounted) return;

      // --------------------------------------------------------
      // FORM REGISTRASI
      // --------------------------------------------------------

      final Map<String, dynamic>?
          registrationData =
          await _showRegisterDialog(user);

      if (registrationData == null) {
        await _signOut();

        sessionOpened = false;

        return;
      }

      final String nama =
          registrationData['nama'] as String;

      _debugLog(
        'Form pendaftaran diterima. '
        'nama=$nama',
      );

      // --------------------------------------------------------
      // MASUK HALAMAN OTP
      // --------------------------------------------------------

      _debugLog(
        'Navigasi ke halaman OTP.',
      );

      final bool? result =
          await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) =>
              _AdminOtpVerificationPage(
            user: user,
            nama: nama,
            adminEmail:
                _adminApprovalEmail,
            sendOtp:
                _sendRegistrationOtp,
            verifyOtp:
                _verifyRegistrationOtp,
            debugLog: _debugLog,
          ),
        ),
      );

      _debugLog(
        'Halaman OTP selesai. result=$result',
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // OTP BERHASIL
      // --------------------------------------------------------

      if (result == true) {
        sessionOpened = false;

        await _showRegisterSuccess();

        if (!mounted) return;

        widget.onAuthSuccess?.call();
      } else {
        await _signOut();

        sessionOpened = false;
      }
    } on FirebaseAuthException catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        _firebaseAuthErrorMessage(e),
      );
    } on GoogleSignInException catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        _googleSignInErrorMessage(e),
      );
    } catch (e) {
      if (sessionOpened) {
        await _signOut();
      }

      if (!mounted) return;

      _showError(
        'Pendaftaran gagal.\n\n$e',
      );
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // REGISTER DIALOG
  // ============================================================

  Future<Map<String, dynamic>?>
      _showRegisterDialog(
    User user,
  ) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),
          title: const Text(
            'Daftar sebagai Guru',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      user.photoURL != null
                          ? NetworkImage(
                              user.photoURL!,
                            )
                          : null,
                  child: user.photoURL == null
                      ? const Icon(
                          Icons.person,
                          size: 32,
                        )
                      : null,
                ),

                const SizedBox(height: 16),

                Text(
                  user.email ?? '-',
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration:
                      BoxDecoration(
                    color: Colors.blue
                        .withValues(
                      alpha: 0.07,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons
                            .admin_panel_settings_outlined,
                        color: Colors.blue,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Setelah dilanjutkan, '
                          'sistem akan mengirim OTP '
                          'persetujuan ke email admin sekolah.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                TextField(
                  controller:
                      _namaController,
                  textCapitalization:
                      TextCapitalization.words,
                  decoration:
                      InputDecoration(
                    labelText: 'Nama Guru',
                    hintText:
                        'Masukkan nama',
                    prefixIcon:
                        const Icon(
                      Icons.person_outline,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration:
                      BoxDecoration(
                    border: Border.all(
                      color: Colors.grey
                          .shade300,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Role',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color: Colors
                                    .black54,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Guru',
                              style:
                                  TextStyle(
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.orange
                        .withValues(
                      alpha: 0.08,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.schedule_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'OTP akan dikirim ke:\n'
                          '$_adminApprovalEmail\n\n'
                          'Masa berlaku OTP: 3 menit.',
                          style:
                              const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  null,
                );
              },
              child:
                  const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final String nama =
                    _namaController.text
                        .trim();

                if (nama.isEmpty) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Nama tidak boleh kosong.',
                      ),
                    ),
                  );

                  return;
                }

                Navigator.pop(
                  dialogContext,
                  {
                    'nama': nama,
                  },
                );
              },
              child:
                  const Text('Kirim OTP'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> _signOut() async {
    _debugLog(
      'Sign out Firebase + Google.',
    );

    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  // ============================================================
  // LOGIN SUCCESS
  // ============================================================

  Future<void> _showLoginSuccess({
    required String nama,
    required String role,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Text('Login Berhasil'),
            ],
          ),
          content: Text(
            'Selamat datang, $nama.\n\n'
            'Role: ${role.toUpperCase()}',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('Masuk'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // REGISTER SUCCESS
  // ============================================================

  Future<void> _showRegisterSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.verified,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child:
                    Text(
                  'Pendaftaran Berhasil',
                ),
              ),
            ],
          ),
          content:
              const Text(
            'Akun guru berhasil dibuat.\n\n'
            'Persetujuan admin berhasil '
            'diverifikasi melalui OTP.\n\n'
            'Data akun telah disimpan ke '
            'collection manajemen account.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child:
                  const Text('Selesai'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // GOOGLE ERROR
  // ============================================================

  String _googleSignInErrorMessage(
    GoogleSignInException e,
  ) {
    switch (e.code) {
      case GoogleSignInExceptionCode
            .clientConfigurationError:
        return 'Konfigurasi Google Sign-In '
            'Android belum benar.';

      case GoogleSignInExceptionCode.canceled:
        return 'Login Google dibatalkan.';

      default:
        return e.description ??
            'Terjadi kesalahan Google Sign-In.';
    }
  }

  // ============================================================
  // FIREBASE AUTH ERROR
  // ============================================================

  String _firebaseAuthErrorMessage(
    FirebaseAuthException e,
  ) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';

      case 'too-many-requests':
        return 'Terlalu banyak percobaan. '
            'Coba lagi beberapa saat.';

      case 'operation-not-allowed':
        return 'Provider Firebase belum diaktifkan.';

      case 'invalid-credential':
        return 'Credential Google tidak valid.';

      case 'account-exists-with-different-credential':
        return 'Email tersebut sudah digunakan '
            'oleh provider lain.';

      case 'email-already-in-use':
        return 'Email tersebut sudah digunakan.';

      case 'invalid-email':
        return 'Alamat email tidak valid.';

      default:
        return e.message ??
            'Terjadi kesalahan autentikasi.';
    }
  }

  // ============================================================
  // GENERAL ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 8),
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Container(
                    width: 86,
                    height: 86,
                    decoration:
                        BoxDecoration(
                      color: Colors.blue,
                      borderRadius:
                          BorderRadius.circular(
                        26,
                      ),
                    ),
                    child: const Icon(
                      Icons
                          .account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Manajemen Bendahara',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _isLoginMode
                        ? 'Masuk menggunakan akun Google'
                        : 'Daftarkan akun guru dengan persetujuan admin',
                    textAlign:
                        TextAlign.center,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    padding:
                        const EdgeInsets.all(6),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child:
                              _ModeButton(
                            text: 'Login',
                            selected:
                                _isLoginMode,
                            onTap:
                                _isLoading
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _isLoginMode =
                                                true;
                                          },
                                        );
                                      },
                          ),
                        ),
                        Expanded(
                          child:
                              _ModeButton(
                            text: 'Daftar',
                            selected:
                                !_isLoginMode,
                            onTap:
                                _isLoading
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _isLoginMode =
                                                false;
                                          },
                                        );
                                      },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        26,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .stretch,
                        children: [
                          Text(
                            _isLoginMode
                                ? 'Selamat datang kembali'
                                : 'Daftar sebagai Guru',
                            style:
                                const TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            _isLoginMode
                                ? 'Gunakan akun Google yang sudah '
                                      'terdaftar di aplikasi.'
                                : 'Gunakan akun Google kamu. '
                                      'Pendaftaran harus disetujui '
                                      'admin melalui OTP email.',
                            style:
                                const TextStyle(
                              color:
                                  Colors.black54,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Container(
                            padding:
                                const EdgeInsets.all(
                              14,
                            ),
                            decoration:
                                BoxDecoration(
                              color: Colors.blue
                                  .withValues(
                                alpha: 0.07,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                            child:
                                const Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Icon(
                                  Icons
                                      .admin_panel_settings_outlined,
                                  color:
                                      Colors.blue,
                                  size: 22,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Expanded(
                                  child: Text(
                                    'Pendaftaran guru '
                                    'memerlukan persetujuan '
                                    'admin melalui kode OTP.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 56,
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : _isLoginMode
                                          ? _login
                                          : _register,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'G',
                                      style:
                                          TextStyle(
                                        fontSize: 22,
                                        fontWeight:
                                            FontWeight
                                                .bold,
                                      ),
                                    ),
                              label: Text(
                                _isLoading
                                    ? 'Memproses...'
                                    : _isLoginMode
                                        ? 'Masuk dengan Google'
                                        : 'Daftar dengan Google',
                              ),
                              style:
                                  OutlinedButton
                                      .styleFrom(
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    16,
                                  ),
                                ),
                                textStyle:
                                    const TextStyle(
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 22),

                          Row(
                            children: [
                              Expanded(
                                child:
                                    Divider(
                                  color:
                                      Colors.grey
                                          .shade300,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 12,
                                ),
                                child:
                                    Text(
                                  'Google Account',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey
                                            .shade500,
                                    fontSize:
                                        12,
                                  ),
                                ),
                              ),
                              Expanded(
                                child:
                                    Divider(
                                  color:
                                      Colors.grey
                                          .shade300,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    _isLoginMode
                        ? 'Login hanya berhasil jika akun sudah terdaftar.'
                        : 'OTP persetujuan dikirim ke email admin sekolah.',
                    textAlign:
                        TextAlign.center,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }
}

// ============================================================
// MODE BUTTON
// ============================================================

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 220),
        padding:
            const EdgeInsets.symmetric(
          vertical: 13,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? Colors.blue
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign:
              TextAlign.center,
          style:
              TextStyle(
            fontWeight:
                FontWeight.w600,
            color: selected
                ? Colors.white
                : Colors.black54,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN OTP PAGE
// ============================================================

class _AdminOtpVerificationPage
    extends StatefulWidget {
  const _AdminOtpVerificationPage({
    required this.user,
    required this.nama,
    required this.adminEmail,
    required this.sendOtp,
    required this.verifyOtp,
    required this.debugLog,
  });

  final User user;
  final String nama;
  final String adminEmail;

  final Future<Map<String, dynamic>> Function({
    required String applicantEmail,
    required String applicantName,
  }) sendOtp;

  final Future<Map<String, dynamic>> Function({
    required String applicantEmail,
    required String code,
  }) verifyOtp;

  final void Function(String message) debugLog;

  @override
  State<_AdminOtpVerificationPage> createState() =>
      _AdminOtpVerificationPageState();
}

class _AdminOtpVerificationPageState
    extends State<_AdminOtpVerificationPage> {
  // ============================================================
  // OTP
  // ============================================================

  static const int otpDurationSeconds =
      3 * 60;

  static const int maxVisibleLogs = 15;

  Timer? _timer;

  final TextEditingController
      _otpController =
      TextEditingController();

  int _remainingSeconds =
      otpDurationSeconds;

  bool _isSendingOtp = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  bool _expired = false;

  String? _errorMessage;

  final List<String> _logs = [];

  // ============================================================
  // LOCAL LOG
  // ============================================================

  void _addLog(String message) {
    final String line =
        '${_timeNow()}  $message';

    widget.debugLog(message);

    if (!mounted) return;

    setState(() {
      _logs.insert(0, line);

      if (_logs.length >
          maxVisibleLogs) {
        _logs.removeLast();
      }
    });
  }

  String _timeNow() {
    final DateTime now =
        DateTime.now();

    final String h =
        now.hour.toString().padLeft(2, '0');

    final String m =
        now.minute.toString().padLeft(2, '0');

    final String s =
        now.second.toString().padLeft(2, '0');

    return '$h:$m:$s';
  }

  @override
  void initState() {
    super.initState();

    _addLog(
      'HALAMAN OTP BERHASIL DIBUKA.',
    );

    _addLog(
      'Pendaftar: ${widget.user.email}',
    );

    _addLog(
      'OTP akan dikirim ke ${widget.adminEmail}',
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _sendOtp();
    });
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;

    if (!mounted) return;

    setState(() {
      _isSendingOtp = true;
      _otpSent = false;
      _expired = false;
      _errorMessage = null;
      _remainingSeconds =
          otpDurationSeconds;
      _otpController.clear();
    });

    _timer?.cancel();

    _addLog(
      'Memulai pengiriman OTP...',
    );

    try {
      final Map<String, dynamic> result =
          await widget.sendOtp(
        applicantEmail:
            widget.user.email!,
        applicantName:
            widget.nama,
      );

      if (!mounted) return;

      final bool alreadyActive =
          result['alreadyActive'] == true;

      final int expiresIn =
          int.tryParse(
                result['expiresInSeconds']
                    ?.toString() ??
                    '',
              ) ??
              otpDurationSeconds;

      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
        _expired = false;
        _remainingSeconds =
            expiresIn.clamp(
          1,
          otpDurationSeconds,
        );
      });

      if (alreadyActive) {
        _addLog(
          'OTP lama masih aktif. '
          'Tidak membuat OTP baru.',
        );
      } else {
        _addLog(
          'Server menyatakan OTP berhasil dikirim.',
        );
      }

      _addLog(
        'Halaman input OTP siap.',
      );

      _startTimer();
    } catch (e) {
      if (!mounted) return;

      final String message =
          e.toString()
              .replaceFirst(
                'Exception: ',
                '',
              );

      setState(() {
        _isSendingOtp = false;
        _errorMessage = message;
      });

      _addLog(
        'GAGAL SEND OTP: $message',
      );
    }
  }

  // ============================================================
  // TIMER
  // ============================================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();

          setState(() {
            _remainingSeconds = 0;
            _expired = true;
          });

          _addLog(
            'Timer OTP habis.',
          );

          return;
        }

        setState(() {
          _remainingSeconds--;
        });
      },
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;

    if (_expired) {
      _showError(
        'OTP sudah kedaluwarsa. '
        'Kirim OTP baru.',
      );

      _addLog(
        'Percobaan verifikasi ditolak karena OTP expired.',
      );

      return;
    }

    final String code =
        _otpController.text.trim();

    if (!RegExp(
      r'^\d{6}$',
    ).hasMatch(code)) {
      _showError(
        'OTP harus terdiri dari 6 angka.',
      );

      _addLog(
        'Format OTP tidak valid.',
      );

      return;
    }

    if (!mounted) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    _addLog(
      'Mengirim kode OTP ke server untuk verifikasi...',
    );

    try {
      final Map<String, dynamic> result =
          await widget.verifyOtp(
        applicantEmail:
            widget.user.email!,
        code: code,
      );

      if (!mounted) return;

      final bool verified =
          result['verified'] == true;

      if (result['ok'] != true ||
          !verified) {
        final String message =
            result['message']
                    ?.toString() ??
                'OTP tidak valid.';

        setState(() {
          _isVerifying = false;
          _errorMessage = message;
        });

        _addLog(
          'OTP DITOLAK SERVER: $message',
        );

        return;
      }

      // ========================================================
      // OTP BENAR
      // ========================================================

      _addLog(
        'OTP DITERIMA SERVER.',
      );

      _addLog(
        'Membuat akun guru di Firestore...',
      );

      await createUserAccount(
        uid: widget.user.uid,
        nama: widget.nama,
        email: widget.user.email,
        photoUrl: widget.user.photoURL,
        role: 'guru',
        nomorTelepon: '',
        nomorTerverifikasi: false,
        provider: 'google.com',
      );

      if (!mounted) return;

      _addLog(
        'AKUN BERHASIL DIBUAT DI FIRESTORE.',
      );

      _timer?.cancel();

      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      final String message =
          e.toString()
              .replaceFirst(
                'Exception: ',
                '',
              );

      setState(() {
        _isVerifying = false;
        _errorMessage = message;
      });

      _addLog(
        'GAGAL VERIFY OTP: $message',
      );
    }
  }

  // ============================================================
  // TIMER FORMAT
  // ============================================================

  String _formatTimer() {
    final int minutes =
        _remainingSeconds ~/ 60;

    final int seconds =
        _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // MASK EMAIL
  // ============================================================

  String _maskedAdminEmail() {
    final String email =
        widget.adminEmail;

    final int at =
        email.indexOf('@');

    if (at <= 2) {
      return email;
    }

    final String name =
        email.substring(0, at);

    final String domain =
        email.substring(at);

    final int maskLength =
        name.length - 2;

    final String mask =
        List<String>.filled(
          maskLength,
          '*',
        ).join();

    return '${name.substring(0, 2)}'
        '$mask'
        '$domain';
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // DEBUG LOG CARD
  // ============================================================

  Widget _buildDebugLogCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.terminal,
                  color: Colors.white,
                  size: 19,
                ),
                SizedBox(width: 8),
                Text(
                  'Log Pengujian',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            if (_logs.isEmpty)
              const Text(
                'Belum ada log.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              )
            else
              ..._logs.map(
                (log) => Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Text(
                    log,
                    style:
                        const TextStyle(
                      color:
                          Colors.white70,
                      fontSize: 11,
                      height: 1.35,
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
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F7FB),

      appBar: AppBar(
        title:
            const Text(
          'Persetujuan Admin',
        ),
        backgroundColor:
            Colors.transparent,
        elevation: 0,
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 430,
              ),
              child: Card(
                elevation: 0,
                color:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    26,
                  ),
                ),
                child:
                    Padding(
                  padding:
                      const EdgeInsets.all(
                    24,
                  ),
                  child:
                      Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration:
                            BoxDecoration(
                          color:
                              Colors.orange,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .admin_panel_settings_outlined,
                          color:
                              Colors.white,
                          size: 40,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      const Text(
                        'Masukkan OTP Admin',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          fontSize: 26,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      const Text(
                        'Kode OTP dikirim ke email '
                        'admin sekolah:',
                        textAlign:
                            TextAlign.center,
                        style:
                            TextStyle(
                          color:
                              Colors.black54,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Text(
                        _maskedAdminEmail(),
                        textAlign:
                            TextAlign.center,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      Container(
                        width:
                            double.infinity,
                        padding:
                            const EdgeInsets
                                .all(15),
                        decoration:
                            BoxDecoration(
                          color: Colors.blue
                              .withValues(
                            alpha: 0.07,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),
                        ),
                        child:
                            Text(
                          'Akun yang mendaftar:\n'
                          '${widget.user.email}\n\n'
                          'Nama: ${widget.nama}\n'
                          'Role: Guru',
                          textAlign:
                              TextAlign.center,
                          style:
                              const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      if (_isSendingOtp)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(
                              height: 12,
                            ),
                            Text(
                              'Mengirim OTP ke email admin...',
                            ),
                          ],
                        )
                      else if (!_otpSent)
                        const Text(
                          'OTP belum tersedia.',
                        )
                      else ...[
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                            horizontal: 16,
                          ),
                          decoration:
                              BoxDecoration(
                            color: _expired
                                ? Colors.red
                                    .withValues(
                                    alpha:
                                        0.07,
                                  )
                                : Colors.orange
                                    .withValues(
                                    alpha:
                                        0.07,
                                  ),
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                          child:
                              Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Icon(
                                _expired
                                    ? Icons
                                        .timer_off_outlined
                                    : Icons
                                        .timer_outlined,
                                size: 21,
                                color: _expired
                                    ? Colors.red
                                    : Colors.orange,
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                _expired
                                    ? 'OTP Kedaluwarsa'
                                    : 'Sisa waktu: ${_formatTimer()}',
                                style:
                                    TextStyle(
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      _expired
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        TextField(
                          controller:
                              _otpController,
                          keyboardType:
                              TextInputType.number,
                          textAlign:
                              TextAlign.center,
                          maxLength: 6,
                          enabled:
                              !_expired &&
                                  !_isVerifying,
                          style:
                              const TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 8,
                          ),
                          decoration:
                              InputDecoration(
                            hintText:
                                '000000',
                            counterText:
                                '',
                            border:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 54,
                          child:
                              FilledButton(
                            onPressed:
                                _expired ||
                                        _isVerifying
                                    ? null
                                    : _verifyOtp,
                            child:
                                _isVerifying
                                    ? const SizedBox(
                                        width: 23,
                                        height: 23,
                                        child:
                                            CircularProgressIndicator(
                                          strokeWidth:
                                              2,
                                          color:
                                              Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Verifikasi OTP',
                                      ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        SizedBox(
                          width:
                              double.infinity,
                          height: 48,
                          child:
                              OutlinedButton(
                            onPressed:
                                _expired &&
                                        !_isSendingOtp
                                    ? _sendOtp
                                    : null,
                            child:
                                const Text(
                              'Kirim OTP Baru',
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage !=
                          null) ...[
                        const SizedBox(
                          height: 18,
                        ),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(13),
                          decoration:
                              BoxDecoration(
                            color: Colors.red
                                .withValues(
                              alpha: 0.07,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                          ),
                          child:
                              Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              const Icon(
                                Icons
                                    .error_outline,
                                color:
                                    Colors.red,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child:
                                    Text(
                                  _errorMessage!,
                                  style:
                                      const TextStyle(
                                    color:
                                        Colors.red,
                                    fontSize:
                                        13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(
                        height: 20,
                      ),

                      _buildDebugLogCard(),

                      const SizedBox(
                        height: 20,
                      ),

                      const Divider(),

                      const SizedBox(
                        height: 16,
                      ),

                      const Row(
                        children: [
                          Icon(
                            Icons
                                .security_outlined,
                            size: 20,
                            color:
                                Colors.green,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              'OTP berlaku 3 menit dan '
                              'hanya dapat digunakan satu kali.',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    Colors.black54,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }
}