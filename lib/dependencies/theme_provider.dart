// dependencies/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:riverpod/riverpod.dart';

import '../constants/appearance.dart'; // 🔥 import warna

// State untuk menyimpan status mode gelap (true = gelap)
final isDarkProvider = StateProvider<bool>((ref) => false);

// Provider yang menghasilkan ThemeData berdasarkan isDarkProvider
final themeDataProvider = Provider<ThemeData>((ref) {
  final isDark = ref.watch(isDarkProvider);

  return ThemeData(
    useMaterial3: true,
    colorSchemeSeed: AppColors.primary, // warna dasar dari data.dart
    brightness: isDark ? Brightness.dark : Brightness.light,

    // Salin pengaturan dari main.dart sebelumnya
    cardTheme: CardThemeData(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
  );
});