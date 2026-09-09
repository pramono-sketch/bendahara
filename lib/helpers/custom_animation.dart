// lib/helpers/custom_animation.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// ============================================================
// REUSABLE LOTTIE WIDGETS
// ============================================================

class LottieLoading extends StatelessWidget {
  final double size;

  const LottieLoading({
    super.key,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/circle_loading.json',
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: true,
      ),
    );
  }
}

// ============================================================
// LOADING CIRCLE
// ============================================================

class LottieLoadingCircle extends StatelessWidget {
  final double size;

  const LottieLoadingCircle({
    super.key,
    this.size = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/circle_loading.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// DASHBOARD
// ============================================================

class LottieDashboard extends StatelessWidget {
  final double size;

  const LottieDashboard({
    super.key,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/Dashboard.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class LottieError extends StatelessWidget {
  final double size;
  final String? message;

  const LottieError({
    super.key,
    this.size = 200.0,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/Error 404.json',
            width: size,
            height: size,
            fit: BoxFit.contain,
            repeat: true,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.redAccent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// AI ANIMATION
// ============================================================

class LottieAiAnimation extends StatelessWidget {
  final double size;

  const LottieAiAnimation({
    super.key,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/ai animation Flow 1.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// BENEFITS ANIMATION
// ============================================================

class LottieBenefits extends StatelessWidget {
  final double size;

  const LottieBenefits({
    super.key,
    this.size = 180.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/Benefits.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// GAME CONTROLLER
// ============================================================

class LottieGameController extends StatelessWidget {
  final double size;

  const LottieGameController({
    super.key,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/Game Controller.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// GAMING
// ============================================================

class LottieGaming extends StatelessWidget {
  final double size;

  const LottieGaming({
    super.key,
    this.size = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/gaming.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}

// ============================================================
// SPLASH
// ============================================================

class LottieSplash extends StatelessWidget {
  final double size;

  const LottieSplash({
    super.key,
    this.size = 250.0,
  });

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/splash_animation.json',
      width: size,
      height: size,
      fit: BoxFit.contain,
      repeat: false,
    );
  }
}

// ============================================================
// ANIMATION MODEL
// ============================================================
//
// Model ini dipisahkan dari halaman gallery agar dapat dipakai
// kembali oleh halaman lain tanpa membuat ulang strukturnya.
//

class LottieAnimationItem {
  final String name;
  final String description;
  final String assetPath;
  final String category;
  final Color primaryColor;

  const LottieAnimationItem({
    required this.name,
    required this.description,
    required this.assetPath,
    required this.category,
    required this.primaryColor,
  });
}

// ============================================================
// ANIMATION CATALOG
// ============================================================
//
// Semua daftar asset Lottie gallery disimpan di satu tempat.
// Menambah animasi baru cukup dilakukan di sini.
//

class LottieAnimationCatalog {
  const LottieAnimationCatalog._();

  static const List<LottieAnimationItem> animations = [
    // ==========================================================
    // SPLASH
    // ==========================================================

    LottieAnimationItem(
      name: 'Splash Animation',
      description: 'Animasi pembuka aplikasi',
      assetPath:
          'assets/animations/splash_animation.json',
      category: 'Splash',
      primaryColor: Color(0xFF1976D2),
    ),

    // ==========================================================
    // LOADING
    // ==========================================================

    LottieAnimationItem(
      name: 'Loading',
      description: 'Indikator loading',
      assetPath:
          'assets/animations/loading.json',
      category: 'Loading',
      primaryColor: Color(0xFFFF9800),
    ),

    LottieAnimationItem(
      name: 'Circle Loading',
      description:
          'Animasi loading berbentuk lingkaran',
      assetPath:
          'assets/animations/circle_loading.json',
      category: 'Loading',
      primaryColor: Color(0xFF42A5F5),
    ),

    // ==========================================================
    // ERROR
    // ==========================================================

    LottieAnimationItem(
      name: 'Error 404',
      description: 'Halaman tidak ditemukan',
      assetPath:
          'assets/animations/Error 404.json',
      category: 'Error',
      primaryColor: Color(0xFFE53935),
    ),

    // ==========================================================
    // GAMING
    // ==========================================================

    LottieAnimationItem(
      name: 'Game Controller',
      description: 'Animasi game controller',
      assetPath:
          'assets/animations/Game Controller.json',
      category: 'Gaming',
      primaryColor: Color(0xFF8E24AA),
    ),

    LottieAnimationItem(
      name: 'Gaming',
      description: 'Animasi gaming',
      assetPath:
          'assets/animations/gaming.json',
      category: 'Gaming',
      primaryColor: Color(0xFF00897B),
    ),

    // ==========================================================
    // AI
    // ==========================================================

    LottieAnimationItem(
      name: 'AI Animation Flow 1',
      description: 'Alur animasi AI',
      assetPath:
          'assets/animations/ai animation Flow 1.json',
      category: 'AI',
      primaryColor: Color(0xFF3949AB),
    ),

    // ==========================================================
    // DASHBOARD
    // ==========================================================

    LottieAnimationItem(
      name: 'Dashboard',
      description: 'Animasi dashboard aplikasi',
      assetPath:
          'assets/animations/Dashboard.json',
      category: 'Dashboard',
      primaryColor: Color(0xFF5E35B1),
    ),

    // ==========================================================
    // UMUM
    // ==========================================================

    LottieAnimationItem(
      name: 'Benefits',
      description:
          'Animasi keuntungan / benefit',
      assetPath:
          'assets/animations/Benefits.json',
      category: 'Umum',
      primaryColor: Color(0xFF43A047),
    ),
  ];
}

// ============================================================
// TOP NOTIFICATION POPUP
// ============================================================

void showTopNotification(
  BuildContext context,
  String message, {
  Color color = Colors.redAccent,
}) {
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) {
      Future.delayed(
        const Duration(seconds: 3),
        () {
          if (overlayEntry.mounted) {
            overlayEntry.remove();
          }
        },
      );

      return Positioned(
        top: 50.0,
        left: 16.0,
        right: 16.0,
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration:
                const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset:
                      const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (overlayEntry.mounted) {
                      overlayEntry.remove();
                    }
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Overlay.of(context).insert(overlayEntry);
}