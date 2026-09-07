// lib/helpers/theme_helper.dart

import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/appearance.dart';

/// Helper untuk kebutuhan tampilan berdasarkan AppThemeMode.
///
/// File ini sengaja dipisahkan dari appearance.dart.
///
/// appearance.dart:
/// - Menyimpan AppColors
/// - Menyimpan AppThemeMode
/// - Menyimpan ThemeData
///
/// ThemeHelper:
/// - Menentukan warna header berdasarkan tema
/// - Menentukan warna teks header
/// - Membuat background bertema
/// - Membuat warna divider
/// - Membuat section header
/// - Membuat section group/card
///
/// Dengan struktur ini, page lain dapat menggunakan helper yang sama
/// tanpa menyalin fungsi theme helper ke masing-masing page.
class ThemeHelper {
  ThemeHelper._();

  // ============================================================
  // THEME CHECK
  // ============================================================

  static bool _isNeo(AppThemeMode mode) {
    return mode == AppThemeMode.neumorphism;
  }

  static bool _isGlass(AppThemeMode mode) {
    return mode == AppThemeMode.glassmorphism;
  }

  static bool _isModern(AppThemeMode mode) {
    return mode == AppThemeMode.modern;
  }

  static bool _isAurora(AppThemeMode mode) {
    return mode == AppThemeMode.aurora;
  }

  static bool _isCyber(AppThemeMode mode) {
    return mode == AppThemeMode.cyberpunk;
  }

  // ============================================================
  // HEADER BACKGROUND
  // ============================================================

  static Color getHeaderBgColor(
    AppThemeMode mode,
    ColorScheme colors,
  ) {
    if (_isNeo(mode)) {
      return AppColors.neoBaseAlt;
    }

    if (_isGlass(mode)) {
      return AppColors.glassBg1;
    }

    if (_isModern(mode)) {
      return AppColors.modernPrimary;
    }

    if (_isAurora(mode)) {
      return AppColors.auroraSurface;
    }

    if (_isCyber(mode)) {
      return AppColors.cyberSurface;
    }

    return colors.primary;
  }

  // ============================================================
  // HEADER TEXT COLOR
  // ============================================================

  static Color getHeaderTextColor(
    AppThemeMode mode,
    ColorScheme colors,
  ) {
    if (_isNeo(mode)) {
      return AppColors.neoTextPrimary;
    }

    if (_isGlass(mode)) {
      return AppColors.glassTextPrimary;
    }

    if (_isModern(mode)) {
      return Colors.white;
    }

    if (_isAurora(mode)) {
      return AppColors.auroraTextPrimary;
    }

    if (_isCyber(mode)) {
      return AppColors.cyberAccent1;
    }

    return colors.onPrimary;
  }

  // ============================================================
  // THEMED BACKGROUND
  // ============================================================

  static Widget buildThemedBackground(
    AppThemeMode themeMode,
    Widget child,
  ) {
    // ----------------------------------------------------------
    // GLASSMORPHISM
    // ----------------------------------------------------------

    if (_isGlass(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassBg1,
              AppColors.glassBg2,
              AppColors.glassBg3,
            ],
            stops: [
              0.0,
              0.5,
              1.0,
            ],
          ),
        ),
        child: child,
      );
    }

    // ----------------------------------------------------------
    // AURORA
    // ----------------------------------------------------------

    if (_isAurora(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.auroraBg,
              AppColors.auroraBg2,
              AppColors.auroraBg3,
            ],
            stops: [
              0.0,
              0.5,
              1.0,
            ],
          ),
        ),
        child: child,
      );
    }

    // ----------------------------------------------------------
    // CYBERPUNK
    // ----------------------------------------------------------

    if (_isCyber(themeMode)) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.8,
            colors: [
              AppColors.cyberBg,
              AppColors.cyberSurface.withValues(
                alpha: 0.5,
              ),
              AppColors.cyberBg,
            ],
            stops: const [
              0.0,
              0.4,
              1.0,
            ],
          ),
        ),
        child: child,
      );
    }

    // ----------------------------------------------------------
    // LIGHT / DARK / NEUMORPHISM / MODERN
    // ----------------------------------------------------------

    return child;
  }

  // ============================================================
  // DIVIDER COLOR
  // ============================================================

  static Color dividerColor(
    AppThemeMode mode,
  ) {
    if (_isNeo(mode)) {
      return AppColors.neoShadow.withValues(
        alpha: 0.20,
      );
    }

    if (_isGlass(mode)) {
      return Colors.white.withValues(
        alpha: 0.2,
      );
    }

    if (_isModern(mode)) {
      return AppColors.modernDivider.withValues(
        alpha: 0.6,
      );
    }

    if (_isAurora(mode)) {
      return AppColors.auroraAccent1.withValues(
        alpha: 0.12,
      );
    }

    if (_isCyber(mode)) {
      return AppColors.cyberAccent1.withValues(
        alpha: 0.15,
      );
    }

    return Colors.transparent;
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  static Widget buildSectionHeader(
    BuildContext context,
    String title,
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    Color labelColor;

    if (_isNeo(themeMode)) {
      labelColor =
          AppColors.neoTextSecondary;
    } else if (_isGlass(themeMode)) {
      labelColor =
          Colors.white.withValues(
        alpha: 0.8,
      );
    } else if (_isModern(themeMode)) {
      labelColor =
          AppColors.modernPrimary;
    } else if (_isAurora(themeMode)) {
      labelColor =
          AppColors.auroraAccent1;
    } else if (_isCyber(themeMode)) {
      labelColor =
          AppColors.cyberAccent1;
    } else {
      labelColor = colors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        top: 2,
        bottom: 2,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: labelColor,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION GROUP
  // ============================================================

  static Widget buildSectionGroup(
    AppThemeMode themeMode,
    List<Widget> children,
  ) {
    // ----------------------------------------------------------
    // NEUMORPHISM
    // ----------------------------------------------------------

    if (_isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(
          borderRadius: 22,
          isPressed: false,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // GLASSMORPHISM
    // ----------------------------------------------------------

    if (_isGlass(themeMode)) {
      return Container(
        decoration:
            glassmorphismDecoration(
          borderRadius: 20,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // MODERN
    // ----------------------------------------------------------

    if (_isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(
          borderRadius: 24,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // AURORA
    // ----------------------------------------------------------

    if (_isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(
          borderRadius: 22,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // CYBERPUNK
    // ----------------------------------------------------------

    if (_isCyber(themeMode)) {
      return Container(
        decoration:
            cyberpunkDecoration(
          borderRadius: 12,
        ),
        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // DEFAULT MATERIAL
    // ----------------------------------------------------------

    return Card(
      elevation: 1,
      clipBehavior:
          Clip.antiAlias,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}