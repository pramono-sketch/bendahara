// lib/l10n/translations.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider untuk locale saat ini (default: Indonesia)
final localeProvider = StateProvider<Locale>(
  (ref) => const Locale('id'),
);

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
      'about_description':
          'Eduvest Finance App\nManage school payments easily.',
      'close': 'Close',
      'feature_unavailable': 'Feature not available yet',

      // Appearance
      'appearance': 'Appearance',
      'app_theme': 'App Theme',

      // Preferences
      'preferences': 'Preferences',
      'sound_volume': 'Sound Volume',
      'enable_sound': 'Enable sound',
      'mute_sound': 'Mute sound',

      // Data
      'data': 'Data',
      'show_easter_egg': 'Show Easter Egg',
      'easter_egg_subtitle':
          'Enable / disable special footer',
      'easter_egg_found':
          'Congratulations! You found the Easter Egg! 🥚',

      // Theme
      'select_theme': 'Select Theme',
      'theme_light': 'Light',
      'theme_dark': 'Dark',
      'theme_neumorphism': 'Neomorphism',
      'theme_glassmorphism': 'Glassmorphism',
      'theme_modern': 'Modern UI',
      'theme_aurora': 'Aurora UI',
      'theme_cyberpunk': 'Cyberpunk Neon',
      'theme_system': 'System',

      // Easter Egg
      'easter_egg_hint':
          "I told you the feature isn't available yet",
      'easter_egg_title': 'Easter Egg!',
      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',
      'ok': 'OK',

      // WhatsApp
      'whatsapp_error_title':
          'WhatsApp Launch Failed',
      'whatsapp_error_desc':
          'Unable to open WhatsApp or browser link.\n'
          'Please check whether WhatsApp is installed and whether '
          'the device can open external links.\n'
          'Target number: +6287833467630',

      // =====================================================
      // MENU LAINNYA
      // =====================================================
      'more_menu': 'More Menu',

      // Sections
      'finance': 'Finance',
      'data_management': 'Data Management',
      'system_more': 'System & More',

      // Finance
      'bills': 'Bills',
      'teacher_salary': 'Teacher Salary',
      'statistics': 'Statistics',

      // Data Management
      'add_student': 'Add Student',
      'digital_account': 'Digital Account',
      'activity_log': 'Activity Log',

      // System & More
      'ai_assistant': 'AI Assistant',
      'animation_gallery': 'Animation Gallery',
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
      'backup_not_ready':
          'Fitur backup akan segera hadir',
      'about_description':
          'Aplikasi Eduvest Finance\nKelola pembayaran sekolah dengan mudah.',
      'close': 'Tutup',
      'feature_unavailable': 'Fitur belum tersedia',

      // Appearance
      'appearance': 'Tampilan',
      'app_theme': 'Tema Aplikasi',

      // Preferences
      'preferences': 'Preferensi',
      'sound_volume': 'Volume Suara',
      'enable_sound': 'Aktifkan suara',
      'mute_sound': 'Matikan suara',

      // Data
      'data': 'Data',
      'show_easter_egg': 'Tampilkan Easter Egg',
      'easter_egg_subtitle':
          'Aktifkan / nonaktifkan footer spesial',
      'easter_egg_found':
          'Selamat! Anda menemukan telur Paskah! 🥚',

      // Theme
      'select_theme': 'Pilih Tema',
      'theme_light': 'Terang',
      'theme_dark': 'Gelap',
      'theme_neumorphism': 'Neomorphism',
      'theme_glassmorphism': 'Glassmorphism',
      'theme_modern': 'Modern UI',
      'theme_aurora': 'Aurora UI',
      'theme_cyberpunk': 'Cyberpunk Neon',
      'theme_system': 'Sistem',

      // Easter Egg
      'easter_egg_hint':
          'sudah kubilang fitur belum ada',
      'easter_egg_title': 'Easter Egg!',
      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',
      'ok': 'OK',

      // WhatsApp
      'whatsapp_error_title':
          'Gagal Meluncurkan WhatsApp',
      'whatsapp_error_desc':
          'Tidak dapat membuka WhatsApp atau link browser.\n'
          'Pastikan WhatsApp terpasang dan perangkat dapat membuka '
          'link eksternal.\n'
          'Nomor tujuan: +6287833467630',

      // =====================================================
      // MENU LAINNYA
      // =====================================================
      'more_menu': 'Menu Lainnya',

      // Sections
      'finance': 'Keuangan',
      'data_management': 'Manajemen Data',
      'system_more': 'Sistem & Lainnya',

      // Finance
      'bills': 'Tagihan',
      'teacher_salary': 'Gaji Guru',
      'statistics': 'Statistik',

      // Data Management
      'add_student': 'Tambah Siswa',
      'digital_account': 'Akun Digital',
      'activity_log': 'Log Aktivitas',

      // System & More
      'ai_assistant': 'AI Assistant',
      'animation_gallery': 'Galeri Animasi',
    },
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}