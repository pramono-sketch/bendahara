// lib/l10n/translations.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk locale saat ini (default: Indonesia)
final localeProvider = StateProvider<Locale>((ref) => const Locale('id'));

// Provider untuk objek terjemahan
final translationsProvider = Provider<Translations>((ref) {
  final locale = ref.watch(localeProvider);
  return Translations(locale);
});

class Translations {
  final Locale locale;
  Translations(this.locale);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Eduvest Finance',
      'settings': 'Settings',
      'dark_mode': 'Dark Mode',
      'change_theme': 'Change theme',
      'notifications': 'Notifications',
      'enable_notifications': 'Enable notifications',
      'language': 'Language',
      'about': 'About',
      'version': 'Version 1.0.0',
      'select_language': 'Select Language',
      'indonesian': 'Indonesian',
      'english': 'English',
      'backup_data': 'Backup Data',
      'backup_subtitle': 'Save to cloud',
      'backup_not_ready': 'Backup feature is coming soon',
      'about_description': 'Eduvest Finance App\nManage school payments easily.',
      'close': 'Close',
      'feature_unavailable': 'Feature not available yet',
    },
    'id': {
      'app_title': 'Eduvest Finance',
      'settings': 'Pengaturan',
      'dark_mode': 'Mode Gelap',
      'change_theme': 'Ubah tema aplikasi',
      'notifications': 'Notifikasi',
      'enable_notifications': 'Aktifkan pemberitahuan',
      'language': 'Bahasa',
      'about': 'Tentang',
      'version': 'Versi 1.0.0',
      'select_language': 'Pilih Bahasa',
      'indonesian': 'Indonesia',
      'english': 'Inggris',
      'backup_data': 'Backup Data',
      'backup_subtitle': 'Simpan cadangan ke cloud',
      'backup_not_ready': 'Fitur backup akan segera hadir',
      'about_description': 'Aplikasi Eduvest Finance\nKelola pembayaran sekolah dengan mudah.',
      'close': 'Tutup',
      'feature_unavailable': 'Fitur belum tersedia',
    }
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}