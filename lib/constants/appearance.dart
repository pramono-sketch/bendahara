// lib/constants/appearance.dart
import 'package:flutter/material.dart';

// ================== TEMA & KONSTANTA WARNA ==================
class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const surface = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const error = Color(0xFFC62828);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}

// ================== FUNGSI BANTU TAMPILAN ==================
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