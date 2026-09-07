import 'dart:ui';

import 'package:flutter/material.dart';

import '../constants/appearance.dart';

/// Helper terpusat untuk kebutuhan tampilan berdasarkan AppThemeMode.
///
/// Berisi logic visual yang dapat digunakan ulang oleh berbagai page.
///
/// ThemeHelper menangani:
/// - Theme detection
/// - Accent color
/// - Header color
/// - Themed background
/// - Divider
/// - Section header
/// - Section group
class ThemeHelper {
  ThemeHelper._();

  // ============================================================
  // THEME DETECTION
  // ============================================================

  static bool isNeo(AppThemeMode mode) {
    return mode == AppThemeMode.neumorphism;
  }

  static bool isGlass(AppThemeMode mode) {
    return mode == AppThemeMode.glassmorphism;
  }

  static bool isModern(AppThemeMode mode) {
    return mode == AppThemeMode.modern;
  }

  static bool isAurora(AppThemeMode mode) {
    return mode == AppThemeMode.aurora;
  }

  static bool isCyber(AppThemeMode mode) {
    return mode == AppThemeMode.cyberpunk;
  }

  // ============================================================
  // ACCENT COLOR
  // ============================================================

  static Color getAccentColor(AppThemeMode mode, ColorScheme colors) {
    if (isNeo(mode)) {
      return AppColors.neoPrimary;
    }

    if (isGlass(mode)) {
      return Colors.white;
    }

    if (isModern(mode)) {
      return AppColors.modernPrimary;
    }

    if (isAurora(mode)) {
      return AppColors.auroraAccent1;
    }

    if (isCyber(mode)) {
      return AppColors.cyberAccent1;
    }

    return colors.primary;
  }

  // ============================================================
  // HEADER BACKGROUND
  // ============================================================

  static Color getHeaderBgColor(AppThemeMode mode, ColorScheme colors) {
    if (isNeo(mode)) {
      return AppColors.neoBaseAlt;
    }

    if (isGlass(mode)) {
      return AppColors.glassBg1;
    }

    if (isModern(mode)) {
      return AppColors.modernPrimary;
    }

    if (isAurora(mode)) {
      return AppColors.auroraSurface;
    }

    if (isCyber(mode)) {
      return AppColors.cyberSurface;
    }

    return colors.primary;
  }

  // ============================================================
  // HEADER TEXT COLOR
  // ============================================================

  static Color getHeaderTextColor(AppThemeMode mode, ColorScheme colors) {
    if (isNeo(mode)) {
      return AppColors.neoTextPrimary;
    }

    if (isGlass(mode)) {
      return AppColors.glassTextPrimary;
    }

    if (isModern(mode)) {
      return Colors.white;
    }

    if (isAurora(mode)) {
      return AppColors.auroraTextPrimary;
    }

    if (isCyber(mode)) {
      return AppColors.cyberAccent1;
    }

    return colors.onPrimary;
  }

  // ============================================================
  // THEMED BACKGROUND
  // ============================================================

  static Widget buildThemedBackground(AppThemeMode themeMode, Widget child) {
    if (isGlass(themeMode)) {
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
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (isAurora(themeMode)) {
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
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (isCyber(themeMode)) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.8,
            colors: [
              AppColors.cyberBg,
              AppColors.cyberSurface.withValues(alpha: 0.5),
              AppColors.cyberBg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: child,
      );
    }

    return child;
  }

  // ============================================================
  // DIVIDER COLOR
  // ============================================================

  static Color dividerColor(AppThemeMode mode) {
    if (isNeo(mode)) {
      return AppColors.neoShadow.withValues(alpha: 0.20);
    }

    if (isGlass(mode)) {
      return Colors.white.withValues(alpha: 0.2);
    }

    if (isModern(mode)) {
      return AppColors.modernDivider.withValues(alpha: 0.6);
    }

    if (isAurora(mode)) {
      return AppColors.auroraAccent1.withValues(alpha: 0.12);
    }

    if (isCyber(mode)) {
      return AppColors.cyberAccent1.withValues(alpha: 0.15);
    }

    return Colors.transparent;
  }

  // ============================================================
  // SECTION HEADER COLOR
  // ============================================================

  static Color getSectionHeaderColor(AppThemeMode mode, ColorScheme colors) {
    if (isNeo(mode)) {
      return AppColors.neoTextSecondary;
    }

    if (isGlass(mode)) {
      return Colors.white.withValues(alpha: 0.8);
    }

    if (isModern(mode)) {
      return AppColors.modernPrimary;
    }

    if (isAurora(mode)) {
      return AppColors.auroraAccent1;
    }

    if (isCyber(mode)) {
      return AppColors.cyberAccent1;
    }

    return colors.primary;
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  static Widget buildSectionHeader(
    BuildContext context,
    String title,
    AppThemeMode themeMode,
  ) {
    final colors = Theme.of(context).colorScheme;

    final labelColor = getSectionHeaderColor(themeMode, colors);

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
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

    if (isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(borderRadius: 22, isPressed: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // GLASSMORPHISM
    // ----------------------------------------------------------

    if (isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // MODERN
    // ----------------------------------------------------------

    if (isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // AURORA
    // ----------------------------------------------------------

    if (isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // CYBERPUNK
    // ----------------------------------------------------------

    if (isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
