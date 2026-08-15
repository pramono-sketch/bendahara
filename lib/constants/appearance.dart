// lib/constants/appearance.dart

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
  // LIGHT NEUMORPHISM
  // ----------------------------------------------------------

  static const neoBase = Color(0xFFE7E4EC);
  static const neoHighlight = Color(0xFFFFFFFF);
  static const neoShadow = Color(0xFFB8B4BD);

  // Ungu lembut, bukan ungu terlalu kuat.
  static const neoPrimary = Color(0xFF5B3FA3);

  static const neoTextPrimary = Color(0xFF292631);
  static const neoTextSecondary = Color(0xFF67616F);

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
  system, // tambahan: mengikuti sistem
}

// Provider untuk menyimpan kecerahan sistem (diperbarui di main.dart)
final systemBrightnessProvider = StateProvider<Brightness>((ref) => Brightness.light);

// ============================================================
// ====================== PROVIDERS ============================
// ============================================================

final themeModeProvider =
    StateProvider<AppThemeMode>((ref) => AppThemeMode.system); // default system

final themeDataProvider = Provider<ThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  final systemBrightness = ref.watch(systemBrightnessProvider);

  // Jika mode = system, gunakan brightness dari sistem
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

    // --------------------------------------------------------
    // APP BAR
    // --------------------------------------------------------

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

      iconTheme: IconThemeData(
        color: AppColors.textPrimary,
        size: 22,
      ),
    ),

    // --------------------------------------------------------
    // CARD
    // --------------------------------------------------------

    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      margin: EdgeInsets.zero,
    ),

    // --------------------------------------------------------
    // LIST TILE
    // --------------------------------------------------------

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 7,
      ),
      horizontalTitleGap: 12,
      minLeadingWidth: 22,
      iconColor: AppColors.primary,
      textColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    // --------------------------------------------------------
    // DIVIDER
    // --------------------------------------------------------

    dividerTheme: DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.outlineVariant.withValues(alpha: 0.35),
    ),

    // --------------------------------------------------------
    // SWITCH (diperbaiki)
    // --------------------------------------------------------

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white; // thumb putih saat aktif
        }
        return const Color(0xFFB9BAC0);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primary.withValues(alpha: 0.45); // transparan
        }
        return const Color(0xFFE0E1E5);
      }),
      trackOutlineColor: WidgetStateProperty.all(
        Colors.transparent,
      ),
    ),

    // --------------------------------------------------------
    // SLIDER
    // --------------------------------------------------------

    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.primary,
      inactiveTrackColor: AppColors.outlineVariant,
      thumbColor: AppColors.primary,
      overlayColor: AppColors.primary.withValues(alpha: 0.12),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 7,
      ),
    ),

    // --------------------------------------------------------
    // TEXT
    // --------------------------------------------------------

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),

    // --------------------------------------------------------
    // INPUT
    // --------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // --------------------------------------------------------
    // BUTTON
    // --------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 13,
        ),
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

    // --------------------------------------------------------
    // APP BAR
    // --------------------------------------------------------

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

      iconTheme: IconThemeData(
        color: AppColors.darkTextPrimary,
        size: 22,
      ),
    ),

    // --------------------------------------------------------
    // CARD
    // --------------------------------------------------------

    cardTheme: CardThemeData(
      color: AppColors.darkSurfaceContainer,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.18),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),

      margin: EdgeInsets.zero,
    ),

    // --------------------------------------------------------
    // LIST TILE
    // --------------------------------------------------------

    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 7,
      ),

      horizontalTitleGap: 12,
      minLeadingWidth: 22,

      iconColor: const Color(0xFF64B5F6),
      textColor: AppColors.darkTextPrimary,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),

    // --------------------------------------------------------
    // DIVIDER
    // --------------------------------------------------------

    dividerTheme: const DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.darkDivider,
    ),

    // --------------------------------------------------------
    // SWITCH (diperbaiki)
    // --------------------------------------------------------

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white; // thumb putih saat aktif
        }
        return const Color(0xFF777A82);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF64B5F6).withValues(alpha: 0.45); // transparan
        }
        return const Color(0xFF363940);
      }),
      trackOutlineColor: WidgetStateProperty.all(
        Colors.transparent,
      ),
    ),

    // --------------------------------------------------------
    // SLIDER
    // --------------------------------------------------------

    sliderTheme: SliderThemeData(
      activeTrackColor: const Color(0xFF64B5F6),
      inactiveTrackColor: const Color(0xFF43464D),
      thumbColor: const Color(0xFF64B5F6),
      overlayColor: const Color(0xFF64B5F6).withValues(alpha: 0.12),
      trackHeight: 4,

      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 7,
      ),
    ),

    // --------------------------------------------------------
    // TEXT
    // --------------------------------------------------------

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: AppColors.darkTextSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),

    // --------------------------------------------------------
    // INPUT
    // --------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurfaceContainer,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: Color(0xFF64B5F6),
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // --------------------------------------------------------
    // BUTTON
    // --------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF64B5F6),
        foregroundColor: const Color(0xFF0B1D2A),
        elevation: 0,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 13,
        ),
      ),
    ),
  );
}

// ============================================================
// ================== NEUMORPHISM THEME =======================
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
      secondary: AppColors.neoPrimary,
      surface: baseColor,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSurface: textPrimary,
      outline: AppColors.neoShadow,
    ),

    // --------------------------------------------------------
    // APP BAR
    // --------------------------------------------------------

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

      iconTheme: IconThemeData(
        color: textPrimary,
        size: 22,
      ),
    ),

    // --------------------------------------------------------
    // CARD
    // --------------------------------------------------------

    cardTheme: CardThemeData(
      color: baseColor,
      elevation: 0,
      shadowColor: Colors.transparent,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),

      margin: EdgeInsets.zero,
    ),

    // --------------------------------------------------------
    // LIST TILE
    // --------------------------------------------------------

    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 8,
      ),

      horizontalTitleGap: 12,
      minLeadingWidth: 22,

      iconColor: AppColors.neoPrimary,
      textColor: textPrimary,

      tileColor: Colors.transparent,
    ),

    // --------------------------------------------------------
    // DIVIDER
    // --------------------------------------------------------

    dividerTheme: DividerThemeData(
      thickness: 1,
      space: 0,
      color: AppColors.neoShadow.withValues(alpha: 0.25),
    ),

    // --------------------------------------------------------
    // SWITCH (diperbaiki)
    // --------------------------------------------------------

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white; // thumb putih saat aktif
        }
        return const Color(0xFFB7B3BC);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.neoPrimary.withValues(alpha: 0.42);
        }
        return const Color(0xFFD2CFD7);
      }),
      trackOutlineColor: WidgetStateProperty.all(
        Colors.transparent,
      ),
    ),

    // --------------------------------------------------------
    // SLIDER
    // --------------------------------------------------------

    sliderTheme: SliderThemeData(
      activeTrackColor: AppColors.neoPrimary,
      inactiveTrackColor: const Color(0xFFC7C4CC),
      thumbColor: AppColors.neoPrimary,
      overlayColor: AppColors.neoPrimary.withValues(alpha: 0.10),

      trackHeight: 5,

      thumbShape: const RoundSliderThumbShape(
        enabledThumbRadius: 8,
      ),
    ),

    // --------------------------------------------------------
    // TEXT
    // --------------------------------------------------------

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        color: textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    ),

    // --------------------------------------------------------
    // INPUT
    // --------------------------------------------------------

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: baseColor,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.neoPrimary,
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    ),

    // --------------------------------------------------------
    // BUTTON
    // --------------------------------------------------------

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: baseColor,
        foregroundColor: AppColors.neoPrimary,
        elevation: 0,
        shadowColor: Colors.transparent,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),

        padding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 13,
        ),
      ),
    ),
  );
}

// ============================================================
// ================= NEO DECORATION ============================
// ============================================================

BoxDecoration neumorphismDecoration({
  bool isPressed = false,
  double borderRadius = 20,
  Color? baseColor,
}) {
  final Color base = baseColor ?? AppColors.neoBase;

  const Color highlight = AppColors.neoHighlight;
  const Color shadow = AppColors.neoShadow;

  if (isPressed) {
    // Versi ditekan dibuat lebih datar.
    return BoxDecoration(
      color: base,
      borderRadius: BorderRadius.circular(borderRadius),

      boxShadow: [
        BoxShadow(
          color: shadow.withValues(alpha: 0.38),
          offset: const Offset(2, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: highlight.withValues(alpha: 0.55),
          offset: const Offset(-2, -2),
          blurRadius: 4,
        ),
      ],
    );
  }

  // Cahaya dari kiri atas.
  // Highlight -> kiri atas
  // Shadow    -> kanan bawah

  return BoxDecoration(
    color: base,
    borderRadius: BorderRadius.circular(borderRadius),

    boxShadow: [
      BoxShadow(
        color: highlight.withValues(alpha: 0.92),
        offset: const Offset(-5, -5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
      BoxShadow(
        color: shadow.withValues(alpha: 0.58),
        offset: const Offset(5, 5),
        blurRadius: 10,
        spreadRadius: 0,
      ),
    ],
  );
}