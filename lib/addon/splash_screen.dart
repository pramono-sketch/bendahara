// lib/addon/splash_screen.dart

import 'dart:math';
import 'dart:ui';
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
    with TickerProviderStateMixin {
  static const String _lottieAsset =
      'assets/animations/splash_animation.json';

  late final AnimationController _lottieController;
  LottieComposition? _lottieComposition;

  // Controller tambahan untuk efek visual premium
  late final AnimationController _bgController;
  late final AnimationController _shimmerController;

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

    // Controller untuk animasi background dan bintang
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    // Controller untuk efek shimmer teks
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startLottieLoading();
      _startApplicationStartup();
    });

    Future.delayed(const Duration(milliseconds: 11000), () {
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
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.05, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
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
    _bgController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final animationSize = screenWidth > 420 ? 280.0 : screenWidth * 0.68;

    return Scaffold(
      body: Stack(
        children: [
          // 1. ANIMATED GRADIENT BACKGROUND
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              final value = _bgController.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(value * 2 - 1, -1),
                    end: Alignment(-value * 2 + 1, 1),
                    colors: const [
                      Color(0xFF0A1A2F),
                      Color(0xFF0D47A1),
                      Color(0xFF1565C0),
                      Color(0xFF0A1A2F),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. TWINKLE STARS EFFECT (Custom Painter)
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              return CustomPaint(
                size: Size.infinite,
                painter: _StarfieldPainter(
                  animationValue: _bgController.value,
                ),
              );
            },
          ),

          // 3. MAIN CONTENT
          SafeArea(
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // GLASSMORPHISM CARD
                    ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // ANIMATION AREA
                              RepaintBoundary(
                                child: SizedBox(
                                  width: animationSize,
                                  height: animationSize,
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 400),
                                    child: _lottieLoaded &&
                                            _lottieComposition != null
                                        ? Lottie(
                                            key: const ValueKey('lottie'),
                                            composition: _lottieComposition!,
                                            controller: _lottieController,
                                            fit: BoxFit.contain,
                                            repeat: true,
                                            renderCache:
                                                RenderCache.drawingCommands,
                                          )
                                        : const _SplashLoadingAnimation(
                                            key: ValueKey('loading'),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // APP NAME DENGAN SHIMMER EFFECT
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return LinearGradient(
                                    begin: Alignment(
                                        -1.0 + _shimmerController.value * 2,
                                        0.0),
                                    end: Alignment(
                                        0.0 + _shimmerController.value * 2,
                                        0.0),
                                    colors: [
                                      Colors.white,
                                      Colors.cyanAccent.withValues(alpha: 0.9),
                                      Colors.white,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'Eduvest Finance',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // TAGLINE
                              const Text(
                                'Kelola keuangan dengan lebih mudah',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.white70,
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
                  ],
                ),
              ),
            ),
          ),
        ],
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
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.5),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Row(
        key: ValueKey(statusText),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.cloud_off_rounded,
          color: Colors.redAccent.withValues(alpha: 0.9),
          size: 32,
        ),
        const SizedBox(height: 12),
        const Text(
          'Gagal menyiapkan aplikasi',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _retry,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Coba lagi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ===================== STARFIELD PAINTER =====================
// ============================================================
// Custom painter untuk menggambar bintang berkelap-kelip

class _StarfieldPainter extends CustomPainter {
  final double animationValue;

  _StarfieldPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42); // Seed tetap agar posisi tidak berubah
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.5 + 0.5;

      // Efek kelap-kelip berdasarkan nilai animasi
      final phase = i * 0.2;
      final opacity =
          (sin(animationValue * pi * 2 + phase) + 1) / 2 * 0.5 + 0.1;

      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

// ============================================================
// ================ SPLASH LOADING WIDGET =======================
// ============================================================
//
// Fallback UI modern (3 titik memantul) sebelum JSON Lottie termuat.

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
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = (_controller.value - delay) % 1.0;
              
              // Animasi melompat menggunakan sine wave
              final jumpValue = sin(value * pi) * 20.0;
              final scaleValue = (sin(value * pi) * 0.5 + 0.5).clamp(0.5, 1.0);

              return Transform.translate(
                offset: Offset(0, -jumpValue),
                child: Transform.scale(
                  scale: scaleValue,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}