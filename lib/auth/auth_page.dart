// lib/auth/auth_page.dart

import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../env/api_key.dart';
import '../firebase/firestore_service.dart';
import '../helpers/custom_animation.dart'; // Import Lottie animations

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
    return _googleInitialization ??= GoogleSignIn.instance.initialize();
  }

  // ============================================================
  // EMAIL ADMIN SEKOLAH
  // ============================================================
  static const String _adminApprovalEmail = 'newpramono79@gmail.com';

  // ============================================================
  // FORM CONTROLLERS & STATE
  // ============================================================
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _isLoading = false;
  bool _isLoginMode = true;
  
  // Default role saat pertama kali buka form pendaftaran
  String _selectedRole = 'guru'; 

  // ============================================================
  // VALIDASI URL
  // ============================================================
  void _validateOtpServiceUrl() {
    final String url = otpServiceUrl.trim();
    if (url.isEmpty) throw Exception('otpServiceUrl kosong.');
    if (url.startsWith('GANTI_')) throw Exception('otpServiceUrl belum diisi.');
    if (!url.startsWith('https://'))
      throw Exception('URL OTP harus menggunakan HTTPS.');
    if (!url.contains('/exec'))
      throw Exception(
        'URL OTP harus merupakan URL Web App Google Apps Script dan berakhiran /exec.',
      );
  }

  // ============================================================
  // HTTP GET + MANUAL REDIRECT
  // ============================================================
  Future<http.Response> _getFollowingRedirects(Uri initialUri) async {
    final http.Client client = http.Client();
    Uri currentUri = initialUri;
    try {
      const int maxRedirects = 8;
      for (int attempt = 0; attempt <= maxRedirects; attempt++) {
        final http.Request request = http.Request('GET', currentUri)
          ..followRedirects = false;
        final http.StreamedResponse streamedResponse = await client
            .send(request)
            .timeout(const Duration(seconds: 30));
        final http.Response response = await http.Response.fromStream(
          streamedResponse,
        );

        if (!_isRedirectStatus(response.statusCode)) return response;

        final String? location = response.headers['location'];
        if (location == null || location.trim().isEmpty) {
          throw Exception(
            'Server mengembalikan HTTP ${response.statusCode}, tetapi header Location tidak tersedia.\n\nResponse:\n${_preview(response.body, 1200)}',
          );
        }
        currentUri = currentUri.resolve(location);
      }
      throw Exception(
        'Redirect server terlalu banyak (${maxRedirects + 1} kali).',
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

  String _preview(String body, int maxLength) {
    final String value = body.trim();
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  Map<String, dynamic> _parseOtpResponse(http.Response response) {
    final String body = response.body.trim();
    if (body.isEmpty)
      throw Exception(
        'Response OTP kosong.\n\nHTTP: ${response.statusCode}\nURL: ${response.request?.url}',
      );

    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw Exception(
        'Response OTP bukan JSON.\n\nHTTP: ${response.statusCode}\nContent-Type: ${response.headers['content-type'] ?? '-'}\n\nResponse server:\n${_preview(body, 1600)}',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'Format JSON dari server OTP tidak sesuai.\n\nHTTP: ${response.statusCode}\n\nResponse:\n${_preview(body, 1600)}',
      );
    }
    return decoded;
  }

  Exception _otpHttpError(http.Response response) {
    return Exception(
      'Server OTP mengembalikan HTTP ${response.statusCode}.\n\nURL akhir:\n${response.request?.url}\n\nContent-Type:\n${response.headers['content-type'] ?? '-'}\n\nLocation:\n${response.headers['location'] ?? '-'}\n\nResponse server:\n${_preview(response.body, 1600)}',
    );
  }

  Future<Map<String, dynamic>> _checkOtpService() async {
    _validateOtpServiceUrl();
    final String requestId = 'health-${DateTime.now().millisecondsSinceEpoch}';
    final Uri uri = Uri.parse(
      otpServiceUrl,
    ).replace(queryParameters: {'action': 'health', 'requestId': requestId});
    final http.Response response = await _getFollowingRedirects(uri);

    if (response.statusCode < 200 || response.statusCode >= 300)
      throw _otpHttpError(response);
    final Map<String, dynamic> decoded = _parseOtpResponse(response);
    if (decoded['ok'] != true)
      throw Exception(
        decoded['message']?.toString() ?? 'Health check OTP gagal.',
      );
    return decoded;
  }

  Future<Map<String, dynamic>> _sendRegistrationOtp({
    required String applicantEmail,
    required String applicantName,
  }) async {
    _validateOtpServiceUrl();
    await _checkOtpService();
    final String requestId = 'send-${DateTime.now().millisecondsSinceEpoch}';
    final Uri uri = Uri.parse(otpServiceUrl).replace(
      queryParameters: {
        'action': 'sendOtp',
        'email': applicantEmail,
        'name': applicantName,
        'requestId': requestId,
      },
    );
    final http.Response response = await _getFollowingRedirects(uri);

    if (response.statusCode < 200 || response.statusCode >= 300)
      throw _otpHttpError(response);
    final Map<String, dynamic> decoded = _parseOtpResponse(response);
    if (decoded['ok'] != true)
      throw Exception(
        decoded['message']?.toString() ?? 'Server gagal mengirim OTP.',
      );
    return decoded;
  }

  Future<Map<String, dynamic>> _verifyRegistrationOtp({
    required String applicantEmail,
    required String code,
  }) async {
    _validateOtpServiceUrl();
    final String requestId = 'verify-${DateTime.now().millisecondsSinceEpoch}';
    final Uri uri = Uri.parse(otpServiceUrl).replace(
      queryParameters: {
        'action': 'verifyOtp',
        'email': applicantEmail,
        'code': code,
        'requestId': requestId,
      },
    );
    final http.Response response = await _getFollowingRedirects(uri);

    if (response.statusCode < 200 || response.statusCode >= 300)
      throw _otpHttpError(response);
    return _parseOtpResponse(response);
  }

  // ============================================================
  // GOOGLE AUTH
  // ============================================================
  Future<UserCredential> _signInWithGoogle() async {
    await _initializeGoogle();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    if (!GoogleSignIn.instance.supportsAuthenticate())
      throw Exception('Google Sign-In tidak tersedia pada platform ini.');

    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty)
      throw Exception('Google tidak memberikan ID Token.');

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );
    return await _firebaseAuth.signInWithCredential(credential);
  }

  // ============================================================
  // LOGIN
  // ============================================================
  Future<void> _login() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    bool sessionOpened = false;

    try {
      final UserCredential credential = await _signInWithGoogle();
      sessionOpened = true;
      final User? user = credential.user;
      if (user == null) throw Exception('User Firebase tidak ditemukan.');

      final bool registered = await isUserAccountRegistered(user.uid);
      if (!registered) {
        await _signOut();
        sessionOpened = false;
        if (!mounted) return;
        _showError(
          'Akun Google ini belum terdaftar.\n\nSilakan gunakan menu Daftar terlebih dahulu.',
        );
        return;
      }

      final DocumentSnapshot<Map<String, dynamic>> account =
          await fetchUserAccount(user.uid);
      if (!account.exists) {
        await _signOut();
        sessionOpened = false;
        if (!mounted) return;
        _showError('Data akun tidak ditemukan di Firestore.');
        return;
      }

      final Map<String, dynamic> data = account.data() ?? {};
      final String nama =
          data['nama'] as String? ?? user.displayName ?? 'Pengguna';
      final String role = data['role'] as String? ?? 'guru';

      if (!mounted) return;
      
      // Tampilkan AwesomeDialog dan navigasi langsung dari tombol OK
      await _showLoginSuccess(nama: nama, role: role);
      
    } on FirebaseAuthException catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError(_firebaseAuthErrorMessage(e));
    } on GoogleSignInException catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError(_googleSignInErrorMessage(e));
    } catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError('Login gagal.\n\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // REGISTER
  // ============================================================
  Future<void> _register() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    bool sessionOpened = false;

    try {
      final UserCredential credential = await _signInWithGoogle();
      sessionOpened = true;
      final User? user = credential.user;
      if (user == null) throw Exception('User Firebase tidak ditemukan.');

      final String email = user.email?.trim() ?? '';
      if (email.isEmpty)
        throw Exception('Akun Google tidak memiliki alamat email.');

      final bool registered = await isUserAccountRegistered(user.uid);
      if (registered) {
        await _signOut();
        sessionOpened = false;
        if (!mounted) return;
        _showError(
          'Akun Google ini sudah terdaftar.\n\nSilakan gunakan Login.',
        );
        return;
      }

      // Set default values untuk form pendaftaran
      _namaController.text = user.displayName?.trim() ?? '';
      if (_namaController.text.isEmpty)
        _namaController.text = email.split('@').first;

      _nisController.clear();
      _phoneController.clear();
      _addressController.clear();
      _selectedRole = 'guru'; // Reset role ke default setiap kali buka form

      if (!mounted) return;

      final Map<String, dynamic>? registrationData = await _showRegisterDialog(
        user,
      );
      if (registrationData == null) {
        await _signOut();
        sessionOpened = false;
        return;
      }

      final String nama = registrationData['nama'] as String;
      final String nis = registrationData['nis'] as String;
      final String nomorTelepon = registrationData['nomorTelepon'] as String;
      final String alamat = registrationData['alamat'] as String;
      final String role = registrationData['role'] as String; // Ambil role dari form

      final bool? result = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _AdminOtpVerificationPage(
            user: user,
            nama: nama,
            nis: nis,
            nomorTelepon: nomorTelepon,
            alamat: alamat,
            role: role, // Kirim role ke halaman OTP
            adminEmail: _adminApprovalEmail,
            sendOtp: _sendRegistrationOtp,
            verifyOtp: _verifyRegistrationOtp,
          ),
        ),
      );

      if (!mounted) return;

      if (result == true) {
        sessionOpened = false;
        // Tampilkan AwesomeDialog dan navigasi langsung dari tombol OK
        await _showRegisterSuccess(role);
      } else {
        await _signOut();
        sessionOpened = false;
      }
    } on FirebaseAuthException catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError(_firebaseAuthErrorMessage(e));
    } on GoogleSignInException catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError(_googleSignInErrorMessage(e));
    } catch (e) {
      if (sessionOpened) await _signOut();
      if (!mounted) return;
      _showError('Pendaftaran gagal.\n\n$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // REGISTER DIALOG (MODERN UI)
  // ============================================================
  Future<Map<String, dynamic>?> _showRegisterDialog(User user) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: colorScheme.primaryContainer,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Icon(
                            Icons.person,
                            size: 40,
                            color: colorScheme.primary,
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Lengkapi Profil',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '-',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lengkapi data berikut. Data ini akan digunakan sebagai informasi profil akun Anda.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildTextField(
                  dialogContext,
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  dialogContext,
                  controller: _nisController,
                  label: 'NIS/NIK',
                  icon: Icons.badge_outlined,
                ),
                const SizedBox(height: 16),
                
                // DROPDOWN PILIHAN ROLE (GURU / BENDAHARA)
                _buildRoleDropdown(dialogContext),
                
                const SizedBox(height: 16),
                _buildTextField(
                  dialogContext,
                  controller: _phoneController,
                  label: 'Nomor Telepon',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  dialogContext,
                  controller: _addressController,
                  label: 'Alamat',
                  icon: Icons.location_on_outlined,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_outlined,
                        color: colorScheme.tertiary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Kode OTP akan dikirim ke:\n$_adminApprovalEmail\n\nMasa berlaku OTP: 3 menit.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext, null),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final String nama = _namaController.text.trim();
                          final String nis = _nisController.text.trim();
                          final String nomorTelepon = _phoneController.text.trim();
                          final String alamat = _addressController.text.trim();

                          if (nama.isEmpty || nama.length < 3) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama lengkap wajib diisi (min 3 karakter).',
                                ),
                              ),
                            );
                            return;
                          }
                          if (nis.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('NIS/NIK wajib diisi.'),
                              ),
                            );
                            return;
                          }
                          if (nomorTelepon
                                  .replaceAll(RegExp(r'[^0-9+]'), '')
                                  .length <
                              8) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Nomor telepon tidak valid.'),
                              ),
                            );
                            return;
                          }
                          if (alamat.isEmpty) {
                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              const SnackBar(
                                content: Text('Alamat wajib diisi.'),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(dialogContext, {
                            'nama': nama,
                            'nis': nis,
                            'nomorTelepon': nomorTelepon,
                            'alamat': alamat,
                            'role': _selectedRole, // Sertakan role yang dipilih
                          });
                        },
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper TextField for Dialog
  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1
            ? Icon(icon)
            : Padding(
                padding: const EdgeInsets.only(bottom: 42),
                child: Icon(icon),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      ),
    );
  }

  // Helper Dropdown Role for Dialog
  Widget _buildRoleDropdown(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Role / Jabatan',
        prefixIcon: Icon(Icons.school_outlined, color: theme.colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
      ),
      items: const [
        DropdownMenuItem(value: 'guru', child: Text('Guru')),
        DropdownMenuItem(value: 'bendahara', child: Text('Bendahara')),
      ],
      onChanged: (val) {
        if (val != null) {
          _selectedRole = val;
        }
      },
    );
  }

  // ============================================================
  // SIGN OUT
  // ============================================================
  Future<void> _signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await _firebaseAuth.signOut();
    } catch (_) {}
  }

  // ============================================================
  // LOGIN SUCCESS (AWESOME DIALOG)
  // ============================================================
  Future<void> _showLoginSuccess({
    required String nama,
    required String role,
  }) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: 'Login Berhasil',
      desc: 'Selamat datang, $nama.\n\nRole: ${role.toUpperCase()}',
      btnOkText: 'Masuk',
      btnOkOnPress: () {
        widget.onAuthSuccess?.call();
      },
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
    ).show();
  }

  // ============================================================
  // REGISTER SUCCESS (AWESOME DIALOG)
  // ============================================================
  Future<void> _showRegisterSuccess(String role) async {
    await AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.rightSlide,
      title: 'Pendaftaran Berhasil',
      desc: 'Akun $role berhasil dibuat.\n\nPersetujuan admin berhasil diverifikasi melalui OTP.\n\nData profil telah disimpan ke akun Firebase.',
      btnOkText: 'Selesai',
      btnOkOnPress: () {
        widget.onAuthSuccess?.call();
      },
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
    ).show();
  }

  // ============================================================
  // ERROR HANDLERS
  // ============================================================
  String _googleSignInErrorMessage(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
        return 'Konfigurasi Google Sign-In Android belum benar.';
      case GoogleSignInExceptionCode.canceled:
        return 'Login Google dibatalkan.';
      default:
        return e.description ?? 'Terjadi kesalahan Google Sign-In.';
    }
  }

  String _firebaseAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'Tidak ada koneksi internet.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      case 'operation-not-allowed':
        return 'Provider Firebase belum diaktifkan.';
      case 'invalid-credential':
        return 'Credential Google tidak valid.';
      case 'account-exists-with-different-credential':
        return 'Email tersebut sudah digunakan oleh provider lain.';
      case 'email-already-in-use':
        return 'Email tersebut sudah digunakan.';
      case 'invalid-email':
        return 'Alamat email tidak valid.';
      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  // ============================================================
  // MAIN UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Lottie Animation Header
                  LottieDashboard(size: 180.0),
                  const SizedBox(height: 24),

                  Text(
                    'Manajemen Bendahara',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _isLoginMode
                          ? 'Masuk menggunakan akun Google'
                          : 'Daftarkan akun dengan persetujuan admin',
                      key: ValueKey(_isLoginMode),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Login / Register Toggle
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.5,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _ModeButton(
                            text: 'Login',
                            selected: _isLoginMode,
                            onTap: _isLoading
                                ? null
                                : () => setState(() => _isLoginMode = true),
                          ),
                        ),
                        Expanded(
                          child: _ModeButton(
                            text: 'Daftar',
                            selected: !_isLoginMode,
                            onTap: _isLoading
                                ? null
                                : () => setState(() => _isLoginMode = false),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Main Card Content
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _isLoginMode
                              ? 'Selamat datang kembali'
                              : 'Daftar Akun Baru',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLoginMode
                              ? 'Gunakan akun Google yang sudah terdaftar di aplikasi.'
                              : 'Gunakan akun Google kamu dan lengkapi data profil sebelum melanjutkan persetujuan admin.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (!_isLoginMode) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withOpacity(
                                0.3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.admin_panel_settings_outlined,
                                  color: colorScheme.primary,
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Pendaftaran akun memerlukan persetujuan admin melalui kode OTP.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Google Button
                        SizedBox(
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : (_isLoginMode ? _login : _register),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: colorScheme.surface,
                              side: BorderSide(color: colorScheme.outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isLoading
                                ? LottieLoadingCircle(size: 24)
                                : const Text(
                                    'G',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                            label: Text(
                              _isLoading
                                  ? 'Memproses...'
                                  : (_isLoginMode
                                      ? 'Masuk dengan Google'
                                      : 'Daftar dengan Google'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(color: colorScheme.outlineVariant),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                'Google Account',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: colorScheme.outlineVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _isLoginMode
                        ? 'Login hanya berhasil jika akun sudah terdaftar.'
                        : 'Data profil akan disimpan setelah OTP admin berhasil diverifikasi.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
    _nisController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}

// ============================================================
// MODE BUTTON WIDGET
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
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ADMIN OTP VERIFICATION PAGE (MODERN UI)
// ============================================================
class _AdminOtpVerificationPage extends StatefulWidget {
  const _AdminOtpVerificationPage({
    required this.user,
    required this.nama,
    required this.nis,
    required this.nomorTelepon,
    required this.alamat,
    required this.role, // Tambahan parameter role
    required this.adminEmail,
    required this.sendOtp,
    required this.verifyOtp,
  });

  final User user;
  final String nama;
  final String nis;
  final String nomorTelepon;
  final String alamat;
  final String role; // Role dinamis (guru / bendahara)
  final String adminEmail;

  final Future<Map<String, dynamic>> Function({
    required String applicantEmail,
    required String applicantName,
  }) sendOtp;
  final Future<Map<String, dynamic>> Function({
    required String applicantEmail,
    required String code,
  }) verifyOtp;

  @override
  State<_AdminOtpVerificationPage> createState() =>
      _AdminOtpVerificationPageState();
}

class _AdminOtpVerificationPageState extends State<_AdminOtpVerificationPage> {
  static const String _accountCollection = 'manajemen account';
  static const int otpDurationSeconds = 3 * 60;

  Timer? _timer;
  final TextEditingController _otpController = TextEditingController();

  int _remainingSeconds = otpDurationSeconds;
  bool _isSendingOtp = false;
  bool _isVerifying = false;
  bool _otpSent = false;
  bool _expired = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp());
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;
    if (!mounted) return;

    setState(() {
      _isSendingOtp = true;
      _otpSent = false;
      _expired = false;
      _errorMessage = null;
      _remainingSeconds = otpDurationSeconds;
      _otpController.clear();
    });

    _timer?.cancel();

    try {
      final Map<String, dynamic> result = await widget.sendOtp(
        applicantEmail: widget.user.email!,
        applicantName: widget.nama,
      );
      if (!mounted) return;

      final int expiresIn =
          int.tryParse(result['expiresInSeconds']?.toString() ?? '') ??
              otpDurationSeconds;

      setState(() {
        _isSendingOtp = false;
        _otpSent = true;
        _expired = false;
        _remainingSeconds = expiresIn.clamp(1, otpDurationSeconds);
      });
      _startTimer();
    } catch (e) {
      if (!mounted) return;
      final String message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isSendingOtp = false;
        _errorMessage = message;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
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
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  Future<void> _verifyOtp() async {
    if (_isVerifying) return;
    if (_expired) {
      _showError('OTP sudah kedaluwarsa. Kirim OTP baru.');
      return;
    }

    final String code = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('OTP harus terdiri dari 6 angka.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final Map<String, dynamic> result = await widget.verifyOtp(
        applicantEmail: widget.user.email!,
        code: code,
      );
      if (!mounted) return;

      final bool verified = result['verified'] == true;

      if (result['ok'] != true || !verified) {
        final String message =
            result['message']?.toString() ?? 'OTP tidak valid.';
        setState(() {
          _isVerifying = false;
          _errorMessage = message;
        });
        return;
      }

      // Simpan akun dengan role yang dipilih dari form
      await createUserAccount(
        uid: widget.user.uid,
        nama: widget.nama,
        email: widget.user.email,
        photoUrl: widget.user.photoURL,
        role: widget.role, // Gunakan widget.role
        nomorTelepon: widget.nomorTelepon,
        nomorTerverifikasi: false,
        provider: 'google.com',
      );

      await FirebaseFirestore.instance
          .collection(_accountCollection)
          .doc(widget.user.uid)
          .set({
        'nis': widget.nis,
        'nomorTelepon': widget.nomorTelepon,
        'alamat': widget.alamat,
        'role': widget.role, // Simpan role dinamis ke Firestore
        'provider': 'google.com',
        'photoUrl': widget.user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
        'tanggalBergabung': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _timer?.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      final String message = e.toString().replaceFirst('Exception: ', '');
      setState(() {
        _isVerifying = false;
        _errorMessage = message;
      });
    }
  }

  String _formatTimer() {
    final int minutes = _remainingSeconds ~/ 60;
    final int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _maskedAdminEmail() {
    final String email = widget.adminEmail;
    final int at = email.indexOf('@');
    if (at <= 2) return email;
    final String name = email.substring(0, at);
    final String domain = email.substring(at);
    final int maskLength = name.length - 2;
    final String mask = List<String>.filled(maskLength, '*').join();
    return '${name.substring(0, 2)}$mask$domain';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Persetujuan Admin'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    if (_isSendingOtp) ...[
                      const LottieLoading(size: 120),
                      const SizedBox(height: 16),
                      Text(
                        'Mengirim OTP ke email admin...',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ] else if (!_otpSent) ...[
                      Icon(
                        Icons.error_outline,
                        size: 60,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'OTP belum tersedia.',
                        style: theme.textTheme.titleMedium,
                      ),
                    ] else ...[
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_outlined,
                          color: colorScheme.tertiary,
                          size: 35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Masukkan OTP Admin',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kode OTP dikirim ke email admin sekolah:',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _maskedAdminEmail(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Data Pendaftar:\n\n'
                          '${widget.user.email}\n'
                          'Nama: ${widget.nama}\n'
                          'NIS/NIK: ${widget.nis}\n'
                          'Telepon: ${widget.nomorTelepon}\n'
                          'Alamat: ${widget.alamat}\n'
                          'Role: ${widget.role.toUpperCase()}', // Tampilkan role secara dinamis
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Timer Indicator
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: _expired
                              ? colorScheme.errorContainer.withOpacity(0.5)
                              : colorScheme.tertiaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _expired
                                  ? Icons.timer_off_outlined
                                  : Icons.timer_outlined,
                              size: 20,
                              color: _expired
                                  ? colorScheme.error
                                  : colorScheme.tertiary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _expired
                                  ? 'OTP Kedaluwarsa'
                                  : 'Sisa waktu: ${_formatTimer()}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _expired
                                    ? colorScheme.error
                                    : colorScheme.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // OTP Input Field
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        enabled: !_expired && !_isVerifying,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '------',
                          counterText: '',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: colorScheme.outline),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _expired || _isVerifying ? null : _verifyOtp,
                          icon: _isVerifying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle_outline),
                          label: Text(
                            _isVerifying
                                ? 'Memverifikasi...'
                                : 'Verifikasi OTP',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Resend Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _expired && !_isSendingOtp ? _sendOtp : null,
                          child: const Text('Kirim OTP Baru'),
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.security_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'OTP berlaku 3 menit dan hanya dapat digunakan satu kali.',
                            style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }
}