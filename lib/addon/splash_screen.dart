// lib/addon/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SimpleSplashScreen extends StatefulWidget {
  final Widget nextPage;
  final Future<void> startupFuture;

  const SimpleSplashScreen({
    super.key,
    required this.nextPage,
    required this.startupFuture,
  });

  @override
  State<SimpleSplashScreen> createState() =>
      _SimpleSplashScreenState();
}

class _SimpleSplashScreenState
    extends State<SimpleSplashScreen>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final AnimationController _lottieController;

  // ============================================================
  // STATE
  // ============================================================

  bool _lottieLoaded = false;
  bool _startupCompleted = false;
  bool _minimumTimeCompleted = false;
  bool _hasNavigated = false;

  Object? _startupError;

  @override
  void initState() {
    super.initState();

    // ==========================================================
    // LOTTIE CONTROLLER
    // ==========================================================

    _lottieController = AnimationController(
      vsync: this,
    );

    // ==========================================================
    // MINIMUM SPLASH TIME
    // ==========================================================
    //
    // Walaupun Firebase selesai sangat cepat, splash tetap tampil
    // minimal 3.5 detik agar animasi terlihat lebih estetik.

    Future.delayed(
      const Duration(milliseconds: 3500),
      () {
        if (!mounted) return;

        setState(() {
          _minimumTimeCompleted = true;
        });

        _checkReadyToNavigate();
      },
    );

    // ==========================================================
    // WAIT STARTUP
    // ==========================================================

    _waitForStartup();
  }

  // ============================================================
  // WAIT FIREBASE + FIRESTORE
  // ============================================================

  Future<void> _waitForStartup() async {
    try {
      await widget.startupFuture;

      if (!mounted) return;

      setState(() {
        _startupCompleted = true;
      });

      _checkReadyToNavigate();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _startupError = error;
      });
    }
  }

  // ============================================================
  // LOTTIE LOADED
  // ============================================================

  void _onLottieLoaded(
    LottieComposition composition,
  ) {
    if (!mounted) return;
    if (_lottieLoaded) return;

    setState(() {
      _lottieLoaded = true;
    });

    // Gunakan durasi asli animasi.
    _lottieController.duration =
        composition.duration;

    // ==========================================================
    // LOOP
    // ==========================================================
    //
    // Animasi tetap berjalan selama Firebase/Firestore loading.
    // Ini lebih baik daripada animasi selesai lalu layar diam.

    _lottieController.repeat();

    _checkReadyToNavigate();
  }

  // ============================================================
  // CHECK READY
  // ============================================================

  void _checkReadyToNavigate() {
    if (!mounted) return;

    // Jangan navigate lebih dari sekali.
    if (_hasNavigated) return;

    // Firebase belum selesai.
    if (!_startupCompleted) return;

    // Waktu minimal belum selesai.
    if (!_minimumTimeCompleted) return;

    // Lottie belum siap.
    //
    // Jika animasi masih diparse, tunggu supaya transisi tidak
    // langsung pindah ketika animasi belum pernah tampil.
    if (!_lottieLoaded) return;

    _hasNavigated = true;

    // Beri sedikit waktu agar loop berhenti secara halus.
    Future.delayed(
      const Duration(milliseconds: 250),
      () {
        if (!mounted) return;

        _lottieController.stop();

        _goToNextPage();
      },
    );
  }

  // ============================================================
  // NAVIGATE
  // ============================================================

  void _goToNextPage() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (
          context,
          animation,
          secondaryAnimation,
        ) {
          return widget.nextPage;
        },

        transitionsBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
        ) {
          final fadeAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );

          return FadeTransition(
            opacity: fadeAnimation,
            child: child,
          );
        },

        transitionDuration:
            const Duration(milliseconds: 600),
      ),
    );
  }

  // ============================================================
  // RETRY
  // ============================================================

  void _retry() {
    if (_startupError == null) return;

    setState(() {
      _startupError = null;
    });

    // Catatan:
    // startupFuture dari main tidak bisa dibuat ulang di sini.
    //
    // Untuk sekarang aplikasi cukup menampilkan error secara aman.
    // Jika error terjadi terus, restart aplikasi lebih tepat
    // untuk inisialisasi Firebase yang gagal.
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _lottieController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    // ==========================================================
    // UKURAN ADAPTIF
    // ==========================================================
    //
    // Maksimum 280 px.
    // Membatasi ukuran render membantu perangkat lama.

    final animationSize =
        screenWidth > 420 ? 280.0 : screenWidth * 0.68;

    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics:
                const NeverScrollableScrollPhysics(),

            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),

              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  // ==================================================
                  // LOTTIE
                  // ==================================================

                  RepaintBoundary(
                    child: SizedBox(
                      width: animationSize,
                      height: animationSize,

                      child: Lottie.asset(
                        // Pastikan nama file sama.
                        'assets/animations/splash_animation.json',

                        controller:
                            _lottieController,

                        fit: BoxFit.contain,

                        // Controller yang mengatur loop.
                        repeat: false,

                        // =================================================
                        // PERFORMANCE
                        // =================================================
                        //
                        // Parsing JSON dilakukan di background isolate.
                        //
                        // Berguna untuk animasi besar/kompleks agar UI
                        // tidak terlalu tersendat saat pertama dimuat.

                        backgroundLoading: true,

                        // Cache hasil render frame.
                        //
                        // Subsequent frames lebih ringan saat animasi
                        // diputar ulang, tetapi menggunakan RAM lebih.
                        renderCache: RenderCache.drawingCommands,

                        onLoaded: _onLottieLoaded,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // APP NAME
                  // ==================================================

                  const Text(
                    'Eduvest Finance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================================
                  // TAGLINE
                  // ==================================================

                  Text(
                    'Kelola keuangan dengan lebih mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ==================================================
                  // STATUS
                  // ==================================================

                  if (_startupError != null)
                    _buildError()
                  else
                    _buildLoadingStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATUS
  // ============================================================

  Widget _buildLoadingStatus() {
    String statusText;

    if (!_lottieLoaded) {
      statusText = 'Menyiapkan animasi...';
    } else if (!_startupCompleted) {
      statusText = 'Menyiapkan aplikasi...';
    } else if (!_minimumTimeCompleted) {
      statusText = 'Hampir selesai...';
    } else {
      statusText = 'Membuka aplikasi...';
    }

    return Column(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          statusText,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Column(
      children: [
        const Icon(
          Icons.cloud_off_rounded,
          color: Colors.white,
          size: 28,
        ),

        const SizedBox(height: 10),

        Text(
          'Gagal menyiapkan aplikasi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.9),
          ),
        ),

        const SizedBox(height: 10),

        TextButton(
          onPressed: _retry,
          child: const Text(
            'Coba lagi',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}