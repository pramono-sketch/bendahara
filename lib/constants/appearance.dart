// lib/constants/appearance.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ============================================================
// ====================== APP COLORS ===========================
// ============================================================

class AppColors {
  // ----------------------------------------------------------
  // LIGHT / MATERIAL
  // ----------------------------------------------------------

  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);

  static const surface = Color(0xFFF5F7FA);
  static const card = Colors.white;

  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const error = Color(0xFFC62828);

  static const textPrimary = Color(0xFF1D1B20);
  static const textSecondary = Color(0xFF494551);

  static const outline = Color(0xFF7A7582);
  static const outlineVariant = Color(0xFFCBC4D2);

  static const surfaceVariant = Color(0xFFE6E0E9);
  static const surfaceContainer = Color(0xFFF2ECF4);
  static const surfaceContainerHigh = Color(0xFFECE6EE);
  static const surfaceContainerHighest = Color(0xFFE6E0E9);

  static const onSurfaceVariant = Color(0xFF494551);

  // ----------------------------------------------------------
  // LIGHT NEUMORPHISM (IMPROVED — lebih natural, less "AI")
  // ----------------------------------------------------------

  /// Base lebih hangat dengan tint ungu lembut
  static const neoBase = Color(0xFFE6E3EF);
  static const neoBaseAlt = Color(0xFFDFDBE8);
  static const neoHighlight = Color(0xFFFFFFFF);
  static const neoShadow = Color(0xFFA8A4B8);
  static const neoShadowAccent = Color(0xFF8B7DB0);

  static const neoPrimary = Color(0xFF5B3FA3);
  static const neoPrimaryLight = Color(0xFF7B5FC3);

  static const neoTextPrimary = Color(0xFF292631);
  static const neoTextSecondary = Color(0xFF67616F);

  // ----------------------------------------------------------
  // GLASSMORPHISM (IMPROVED — more mature & realistic)
  // ----------------------------------------------------------

  static const glassBg1 = Color(0xFF6A11CB); // Ungu
  static const glassBg2 = Color(0xFF2575FC); // Biru
  static const glassBg3 = Color(0xFFE55D87); // Pink

  static const glassSurface = Color(0xFFFFFFFF);
  static const glassBorder = Color(0xFFFFFFFF);
  static const glassTextPrimary = Color(0xFFFFFFFF);
  static const glassTextSecondary = Color(0xFFE8E8F0);
  static const glassAccent = Color(0xFFFFFFFF);

  // ----------------------------------------------------------
  // MODERN UI
  // ----------------------------------------------------------

  static const modernBg = Color(0xFFF8F9FE);
  static const modernSurface = Color(0xFFFFFFFF);
  static const modernPrimary = Color(0xFF6C5CE7);
  static const modernPrimaryLight = Color(0xFFA29BFE);
  static const modernAccent = Color(0xFF00CEC9);
  static const modernTextPrimary = Color(0xFF2D3436);
  static const modernTextSecondary = Color(0xFF636E72);
  static const modernDivider = Color(0xFFEDEFF2);

  // ----------------------------------------------------------
  // AURORA UI
  // ----------------------------------------------------------

  static const auroraBg = Color(0xFF0F0C29);
  static const auroraBg2 = Color(0xFF302B63);
  static const auroraBg3 = Color(0xFF24243E);

  static const auroraAccent1 = Color(0xFF00F5FF);
  static const auroraAccent2 = Color(0xFFB06AB3);
  static const auroraAccent3 = Color(0xFF4568DC);

  static const auroraSurface = Color(0xFF1A1A2E);
  static const auroraTextPrimary = Color(0xFFF0F0FF);
  static const auroraTextSecondary = Color(0xFFB8B8D0);

  // ----------------------------------------------------------
  // CYBERPUNK NEON
  // ----------------------------------------------------------

  static const cyberBg = Color(0xFF0A0A0F);
  static const cyberSurface = Color(0xFF13131F);
  static const cyberAccent1 = Color(0xFF00F0FF);
  static const cyberAccent2 = Color(0xFFFF00AA);
  static const cyberAccent3 = Color(0xFF39FF14);

  static const cyberTextPrimary = Color(0xFFFFFFFF);
  static const cyberTextSecondary = Color(0xFF8888AA);

  // ----------------------------------------------------------
  // DARK THEME
  // ----------------------------------------------------------

  static const darkSurface = Color(0xFF16181D);
  static const darkSurfaceContainer = Color(0xFF202329);
  static const darkSurfaceContainerHigh = Color(0xFF272A31);

  static const darkTextPrimary = Color(0xFFF4F3F7);
  static const darkTextSecondary = Color(0xFFA9A7B0);

  static const darkOutline = Color(0xFF484B53);
  static const darkDivider = Color(0xFF34373E);
}

// ============================================================
// ================== HELPER FUNCTIONS ========================
// ============================================================

String formatCurrency(double amount) {
  final formatter = amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );

  return formatter;
}

Color getMajorColor(String kelas) {
  if (kelas.contains('RPL')) return Colors.green;
  if (kelas.contains('TKR')) return Colors.blue;
  if (kelas.contains('TKJ')) return Colors.red;

  return AppColors.primary;
}

// ============================================================
// ====================== THEME MODE ==========================
// ============================================================

enum AppThemeMode {
  light,
  dark,
  neumorphism,
  glassmorphism,
  modern,
  aurora,
  cyberpunk,
  system,
}

// Provider untuk menyimpan kecerahan sistem
final systemBrightnessProvider =
    StateProvider<Brightness>((ref) => Brightness.light);

// ============================================================
// ====================== PROVIDERS ============================
// ============================================================

final themeModeProvider =
    StateProvider<AppThemeMode>((ref) => AppThemeMode.system);

final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final systemBrightness = ref.watch(systemBrightnessProvider);

  if (mode == AppThemeMode.system) {
    return systemBrightness == Brightness.dark
        ? _buildDarkTheme()
        : _buildLightTheme();
  }

  switch (mode) {
    case AppThemeMode.light:
      return _buildLightTheme();
    case AppThemeMode.dark:
      return _buildDarkTheme();
    case AppThemeMode.neumorphism:
      return _buildNeumorphismTheme();
    case AppThemeMode.glassmorphism:
      return _buildGlassmorphismTheme();
    case AppThemeMode.modern:
      return _buildModernTheme();
    case AppThemeMode.aurora:
      return _buildAuroraTheme();
    case AppThemeMode.cyberpunk:
      return _buildCyberpunkTheme();
    default:
      return _buildLightTheme();
  }
});

// ============================================================
// ====================== LIGHT THEME ==========================
// ============================================================

ThemeData _buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimary,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    ),
    scaffoldBackgroundColor: AppColors.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary, size: 22),
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: AppColors.primary,
      textColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.outlineVariant.withValues(alpha: 0.35),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFB9BAC0);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.primary.withValues(alpha: 0.45);
        return const Color(0xFFE0E1E5);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.outlineVariant,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
  );
}

// ============================================================
// ======================= DARK THEME =========================
// ============================================================

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF64B5F6),
      secondary: Color(0xFF90CAF9),
      surface: AppColors.darkSurface,
      error: AppColors.error,
      onPrimary: Color(0xFF0B1D2A),
      onSurface: AppColors.darkTextPrimary,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkDivider,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
    ),
    scaffoldBackgroundColor: AppColors.darkSurface,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.darkSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: AppColors.darkTextPrimary, size: 22),
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceContainer,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: const Color(0xFF64B5F6),
      textColor: AppColors.darkTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.darkDivider,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF777A82);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return const Color(0xFF64B5F6).withValues(alpha: 0.45);
        return const Color(0xFF363940);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF64B5F6),
      inactiveTrackColor: const Color(0xFF43464D),
      thumbColor: const Color(0xFF64B5F6),
      overlayColor: const Color(0xFF64B5F6).withValues(alpha: 0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: AppColors.darkTextSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceContainer,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF64B5F6), width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: const Color(0xFF0B1D2A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
  );
}

// ============================================================
// ============== NEUMORPHISM THEME (IMPROVED) ================
// ============================================================

ThemeData _buildNeumorphismTheme() {
  const Color baseColor = AppColors.neoBase;
  const Color textPrimary = AppColors.neoTextPrimary;
  const Color textSecondary = AppColors.neoTextSecondary;

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: baseColor,
    colorScheme: const ColorScheme.light(
      primary: AppColors.neoPrimary,
      secondary: AppColors.neoPrimaryLight,
      surface: baseColor,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      outline: AppColors.neoShadow,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: baseColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(color: textPrimary, size: 22),
    ),
    cardTheme: CardThemeData(
      color: baseColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: AppColors.neoPrimary,
      textColor: textPrimary,
      tileColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.neoShadow.withValues(alpha: 0.20),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFB7B3BC);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.neoPrimary.withValues(alpha: 0.42);
        return const Color(0xFFD2CFD7);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.neoPrimary,
      inactiveTrackColor: const Color(0xFFC7C4CC),
      thumbColor: AppColors.neoPrimary,
      overlayColor: AppColors.neoPrimary.withValues(alpha: 0.10),
      trackHeight: 5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: textSecondary, fontSize: 13, fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: baseColor,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            const BorderSide(color: AppColors.neoPrimary, width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: baseColor,
        foregroundColor: AppColors.neoPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
  );
}

// ============================================================
// ================= GLASSMORPHISM THEME (MATURED) =============
// ============================================================

ThemeData _buildGlassmorphismTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.transparent, // Transparan agar gradient terlihat
    colorScheme: ColorScheme.light(
      primary: Colors.white,
      secondary: AppColors.glassBg3,
      surface: Colors.white.withValues(alpha: 0.15),
      error: AppColors.error,
      onPrimary: AppColors.glassBg1,
      onSurface: AppColors.glassTextPrimary,
      outline: Colors.white.withValues(alpha: 0.4),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent, // Transparan
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.glassTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: AppColors.glassTextPrimary,
        size: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white.withValues(alpha: 0.15),
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: Colors.white.withValues(alpha: 0.85),
      textColor: AppColors.glassTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      thickness: 0.5,
      space: 0,
      color: Colors.white.withValues(alpha: 0.2),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return Colors.white.withValues(alpha: 0.5);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return Colors.white.withValues(alpha: 0.4);
        return Colors.white.withValues(alpha: 0.15);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.25),
      thumbColor: Colors.white,
      overlayColor: Colors.white.withValues(alpha: 0.15),
      trackHeight: 5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.glassTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: AppColors.glassTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.glassTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.glassTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: Color(0xB3FFFFFF), // White 70%
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: Color(0x99FFFFFF), // White 60%
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
  );
}

// ============================================================
// ==================== MODERN UI THEME ========================
// ============================================================

ThemeData _buildModernTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.modernBg,
    colorScheme: const ColorScheme.light(
      primary: AppColors.modernPrimary,
      secondary: AppColors.modernAccent,
      surface: AppColors.modernSurface,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: AppColors.modernTextPrimary,
      outline: AppColors.modernDivider,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: AppColors.modernBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.modernTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(
        color: AppColors.modernTextPrimary,
        size: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.modernSurface,
      elevation: 0,
      shadowColor: AppColors.modernPrimary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      horizontalTitleGap: 14,
      minLeadingWidth: 24,
      iconColor: AppColors.modernPrimary,
      textColor: AppColors.modernTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dividerTheme: DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.modernDivider.withValues(alpha: 0.6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFFB2BEC3);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.modernPrimary;
        return const Color(0xFFDFE6E9);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.modernPrimary,
      inactiveTrackColor: AppColors.modernDivider,
      thumbColor: AppColors.modernPrimary,
      overlayColor: AppColors.modernPrimary.withValues(alpha: 0.12),
      trackHeight: 6,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.modernTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700),
      titleMedium: TextStyle(
          color: AppColors.modernTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.modernTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.modernTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: AppColors.modernTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: AppColors.modernPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.modernSurface,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
            color: AppColors.modernPrimary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.modernPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: AppColors.modernPrimary.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        textStyle: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

// ============================================================
// ===================== AURORA UI THEME =======================
// ============================================================

ThemeData _buildAuroraTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // Transparan agar gradient terlihat
    colorScheme: ColorScheme.dark(
      primary: AppColors.auroraAccent1,
      secondary: AppColors.auroraAccent2,
      surface: AppColors.auroraSurface,
      error: AppColors.error,
      onPrimary: AppColors.auroraBg,
      onSurface: AppColors.auroraTextPrimary,
      outline: AppColors.auroraAccent1.withValues(alpha: 0.3),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent, // Transparan
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.auroraTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: IconThemeData(
        color: AppColors.auroraTextPrimary,
        size: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.auroraSurface,
      elevation: 0,
      shadowColor: AppColors.auroraAccent1.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: AppColors.auroraAccent1,
      textColor: AppColors.auroraTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(
      thickness: 0.5,
      space: 0,
      color: AppColors.auroraAccent1.withValues(alpha: 0.12),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF555570);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.auroraAccent1.withValues(alpha: 0.5);
        return const Color(0xFF2A2A40);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.auroraAccent1,
      inactiveTrackColor: const Color(0xFF2A2A40),
      thumbColor: AppColors.auroraAccent1,
      overlayColor: AppColors.auroraAccent1.withValues(alpha: 0.15),
      trackHeight: 5,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.auroraTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600),
      titleMedium: TextStyle(
          color: AppColors.auroraTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.auroraTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.auroraTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: AppColors.auroraTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: AppColors.auroraAccent1,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.auroraSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: AppColors.auroraAccent1.withValues(alpha: 0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: AppColors.auroraAccent1.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: AppColors.auroraAccent1.withValues(alpha: 0.6),
            width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.auroraAccent1,
        foregroundColor: AppColors.auroraBg,
        elevation: 0,
        shadowColor: AppColors.auroraAccent1.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      ),
    ),
  );
}

// ============================================================
// ================== CYBERPUNK NEON THEME =====================
// ============================================================

ThemeData _buildCyberpunkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Colors.transparent, // Transparan agar gradient terlihat
    colorScheme: ColorScheme.dark(
      primary: AppColors.cyberAccent1,
      secondary: AppColors.cyberAccent2,
      surface: AppColors.cyberSurface,
      error: AppColors.error,
      onPrimary: AppColors.cyberBg,
      onSurface: AppColors.cyberTextPrimary,
      outline: AppColors.cyberAccent1.withValues(alpha: 0.4),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent, // Transparan
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: AppColors.cyberAccent1,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 1,
      ),
      iconTheme: IconThemeData(
        color: AppColors.cyberAccent1,
        size: 22,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cyberSurface,
      elevation: 0,
      shadowColor: AppColors.cyberAccent1.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: AppColors.cyberAccent1,
      textColor: AppColors.cyberTextPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dividerTheme: DividerThemeData(
      thickness: 0.5,
      space: 0,
      color: AppColors.cyberAccent1.withValues(alpha: 0.15),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.cyberAccent1;
        return const Color(0xFF444460);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.cyberAccent1.withValues(alpha: 0.3);
        return const Color(0xFF1A1A28);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected))
          return AppColors.cyberAccent1;
        return AppColors.cyberAccent1.withValues(alpha: 0.2);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.cyberAccent1,
      inactiveTrackColor: const Color(0xFF1A1A28),
      thumbColor: AppColors.cyberAccent1,
      overlayColor: AppColors.cyberAccent1.withValues(alpha: 0.2),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
          color: AppColors.cyberTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700),
      titleMedium: TextStyle(
          color: AppColors.cyberTextPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(
          color: AppColors.cyberTextPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w400),
      bodyMedium: TextStyle(
          color: AppColors.cyberTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400),
      labelLarge: TextStyle(
          color: AppColors.cyberTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w500),
      labelMedium: TextStyle(
          color: AppColors.cyberAccent1,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cyberSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppColors.cyberAccent1.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide:
            BorderSide(color: AppColors.cyberAccent1.withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
            color: AppColors.cyberAccent1.withValues(alpha: 0.8),
            width: 1.5),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cyberAccent1,
        foregroundColor: AppColors.cyberBg,
        elevation: 0,
        shadowColor: AppColors.cyberAccent1.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
        textStyle: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.5),
      ),
    ),
  );
}

// ============================================================
// ============ NEO DECORATION (IMPROVED — less "AI") =========
// ============================================================

BoxDecoration neumorphismDecoration({
  bool isPressed = false,
  double borderRadius = 22,
  Color? baseColor,
}) {
  final Color base = baseColor ?? AppColors.neoBase;

  const Color highlight = AppColors.neoHighlight;
  const Color shadow = AppColors.neoShadow;
  const Color accentShadow = AppColors.neoShadowAccent;

  if (isPressed) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          base,
          Color.lerp(base, shadow, 0.12)!,
        ],
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: shadow.withValues(alpha: 0.32),
          offset: const Offset(4, 4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: highlight.withValues(alpha: 0.45),
          offset: const Offset(-4, -4),
          blurRadius: 8,
          spreadRadius: -1,
        ),
      ],
    );
  }

  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(base, highlight, 0.06)!,
        base,
        Color.lerp(base, shadow, 0.05)!,
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: shadow.withValues(alpha: 0.50),
        offset: const Offset(7, 7),
        blurRadius: 16,
        spreadRadius: -3,
      ),
      BoxShadow(
        color: highlight.withValues(alpha: 0.90),
        offset: const Offset(-7, -7),
        blurRadius: 16,
        spreadRadius: -3,
      ),
      BoxShadow(
        color: accentShadow.withValues(alpha: 0.12),
        offset: const Offset(3, 3),
        blurRadius: 6,
        spreadRadius: -1,
      ),
      BoxShadow(
        color: highlight.withValues(alpha: 0.35),
        offset: const Offset(-3, -3),
        blurRadius: 6,
        spreadRadius: -1,
      ),
    ],
  );
}

// ============================================================
// ============ GLASSMORPHISM DECORATION ======================
// ============================================================

BoxDecoration glassmorphismDecoration({
  double borderRadius = 20,
}) {
  return BoxDecoration(
    // Gradient putih halus untuk efek refleksi cahaya
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.30),
        Colors.white.withValues(alpha: 0.08),
      ],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.4),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        offset: const Offset(0, 10),
        blurRadius: 30,
        spreadRadius: -5,
      ),
    ],
  );
}

// ============================================================
// ============== MODERN UI DECORATION ========================
// ============================================================

BoxDecoration modernDecoration({
  double borderRadius = 24,
}) {
  return BoxDecoration(
    color: AppColors.modernSurface,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: [
      BoxShadow(
        color: AppColors.modernPrimary.withValues(alpha: 0.06),
        offset: const Offset(0, 4),
        blurRadius: 20,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        offset: const Offset(0, 1),
        blurRadius: 3,
        spreadRadius: 0,
      ),
    ],
  );
}

// ============================================================
// ================ AURORA UI DECORATION ======================
// ============================================================

BoxDecoration auroraDecoration({
  double borderRadius = 22,
}) {
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.auroraSurface.withValues(alpha: 0.9),
        AppColors.auroraBg3.withValues(alpha: 0.7),
      ],
    ),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.auroraAccent1.withValues(alpha: 0.15),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.auroraAccent1.withValues(alpha: 0.08),
        offset: const Offset(0, 4),
        blurRadius: 20,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: AppColors.auroraAccent2.withValues(alpha: 0.06),
        offset: const Offset(0, 0),
        blurRadius: 30,
        spreadRadius: -5,
      ),
    ],
  );
}

// ============================================================
// =============== CYBERPUNK NEON DECORATION ==================
// ============================================================

BoxDecoration cyberpunkDecoration({
  double borderRadius = 12,
}) {
  return BoxDecoration(
    color: AppColors.cyberSurface,
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: AppColors.cyberAccent1.withValues(alpha: 0.35),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.cyberAccent1.withValues(alpha: 0.15),
        offset: const Offset(0, 0),
        blurRadius: 12,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        offset: const Offset(0, 4),
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  );
}