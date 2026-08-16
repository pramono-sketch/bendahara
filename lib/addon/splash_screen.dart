import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SimpleSplashScreen extends StatefulWidget {
  final Widget nextPage;
  final Future<void> Function() startupTask;

  const SimpleSplashScreen({
    super.key,
    required this.nextPage,
    required this.startupTask,
  });

  @override
  State<SimpleSplashScreen> createState() => _SimpleSplashScreenState();
}

class _SimpleSplashScreenState extends State<SimpleSplashScreen>
    with SingleTickerProviderStateMixin {
  static const String _lottieAsset =
      'assets/animations/splash_animation.json';

  late final AnimationController _lottieController;
  LottieComposition? _lottieComposition;

  bool _lottieLoaded = false;
  bool _startupCompleted = false;
  bool _minimumTimeCompleted = false;
  bool _hasNavigated = false;
  bool _startupStarted = false;

  Object? _startupError;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startLottieLoading();
      _startApplicationStartup();
    });

    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!mounted) return;
      setState(() => _minimumTimeCompleted = true);
      _checkReadyToNavigate();
    });
  }

  Future<void> _startLottieLoading() async {
    try {
      final composition = await AssetLottie(_lottieAsset).load();
      if (!mounted) return;

      _lottieComposition = composition;
      _lottieController.duration = composition.duration;
      _lottieController.repeat();

      setState(() => _lottieLoaded = true);
      _checkReadyToNavigate();
    } catch (error) {
      if (!mounted) return;
      setState(() => _lottieLoaded = false);
    }
  }

  Future<void> _startApplicationStartup() async {
    if (_startupStarted) return;
    _startupStarted = true;

    try {
      await widget.startupTask();
      if (!mounted) return;

      setState(() => _startupCompleted = true);
      _checkReadyToNavigate();
    } catch (error) {
      if (!mounted) return;
      setState(() => _startupError = error);
    }
  }

  void _checkReadyToNavigate() {
    if (!mounted || _hasNavigated) return;
    if (!_startupCompleted || !_minimumTimeCompleted) return;

    _hasNavigated = true;

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _lottieController.stop();
      _goToNextPage();
    });
  }

  void _goToNextPage() {
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.nextPage,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _retry() {
    if (_startupError == null) return;

    setState(() {
      _startupError = null;
      _startupCompleted = false;
      _startupStarted = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startApplicationStartup();
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animationSize = screenWidth > 420 ? 280.0 : screenWidth * 0.68;

    return Scaffold(
      // Background menggunakan gradient (Lebih kaya & ringan di GPU)
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ANIMATION AREA
                  RepaintBoundary(
                    child: SizedBox(
                      width: animationSize,
                      height: animationSize,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _lottieLoaded && _lottieComposition != null
                            ? Lottie(
                                key: const ValueKey('lottie'),
                                composition: _lottieComposition!,
                                controller: _lottieController,
                                fit: BoxFit.contain,
                                repeat: true,
                                renderCache: RenderCache.drawingCommands,
                              )
                            : const _SplashLoadingAnimation(
                                key: ValueKey('loading'),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // APP NAME
                  const Text(
                    'Eduvest Finance',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // TAGLINE
                  Text(
                    'Kelola keuangan dengan lebih mudah',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // STATUS / ERROR
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

  Widget _buildLoadingStatus() {
    String statusText;
    if (!_lottieLoaded) {
      statusText = 'Menyiapkan tampilan...';
    } else if (!_startupCompleted) {
      statusText = 'Menyiapkan aplikasi...';
    } else if (!_minimumTimeCompleted) {
      statusText = 'Hampir selesai...';
    } else {
      statusText = 'Membuka aplikasi...';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        statusText,
        key: ValueKey(statusText),
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.72),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Colors.white.withValues(alpha: 0.9),
          size: 28,
        ),
        const SizedBox(height: 10),
        Text(
          'Gagal menyiapkan aplikasi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _retry,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
          child: const Text('Coba lagi'),
        ),
      ],
    );
  }
}

// ============================================================
// ================ SPLASH LOADING WIDGET =======================
// ============================================================
//
// Fallback UI sebelum JSON Lottie selesai termuat.
// Dibuat sangat minimalis agar tidak membebani HP kentang
// saat proses awal pembacaan aset.

class _SplashLoadingAnimation extends StatefulWidget {
  const _SplashLoadingAnimation({super.key});

  @override
  State<_SplashLoadingAnimation> createState() =>
      _SplashLoadingAnimationState();
}

class _SplashLoadingAnimationState extends State<_SplashLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticInOut),
      ),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}