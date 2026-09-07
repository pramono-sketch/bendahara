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
      'easter_egg_subtitle': 'Enable / disable special footer',
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
      'easter_egg_hint': "I told you the feature isn't available yet",
      'easter_egg_title': 'Easter Egg!',
      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',
      'ok': 'OK',

      // WhatsApp
      'whatsapp_error_title': 'WhatsApp Launch Failed',
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

      // =====================================================
      // SISWA PAGE
      // =====================================================
      'active_students_data': 'Active Students Data',
      'view_archive': 'View Archive',
      'search_name_nis': 'Search name, NIS...',
      'all': 'All',
      'no_active_students': 'No active students',

      // Archive Root
      'student_archive': 'Student Archive',
      'refresh': 'Refresh',
      'try_again': 'Try Again',
      'no_archive_yet': 'No archive yet',
      'archive_will_appear':
          'Archive will appear after class promotion\nin Student Data Management menu',
      'students_archived': 'students archived',

      // Archive Majors
      'archive': 'Archive',
      'no_majors_found': 'No majors found',
      'major': 'Major',
      'students': 'students',

      // Archive Student List
      'no_archived_students': 'No archived students',
      'nis_label': 'NIS',

      // Student Detail
      'archived_student_notice':
          'This student has graduated and is archived. Data is read-only.',
      'student_info': 'Student Information',
      'name': 'Name',
      'address': 'Address',
      'phone_number': 'Phone Number',
      'gender': 'Gender',

      // Quick Payment
      'quick_payment': 'Quick Payment',
      'enter_amount': 'Enter amount',
      'pay': 'Pay',
      'quick_payment_hint':
          'Amount will be allocated to all unpaid bills. Excess will become savings balance.',

      // Payment History
      'payment_history': 'Payment History',
      'paid': 'Paid',
      'partial': 'Partial',
      'unpaid': 'Unpaid',
      'balance_label': 'Balance',
      'mark_paid': 'Mark Paid',

      // Financial Summary
      'financial_summary': 'Financial Summary',
      'total_bills': 'Total Bills',
      'total_paid': 'Total Paid',
      'remaining_bills': 'Remaining Bills',
      'savings_balance': 'Savings Balance',
      'savings_notice':
          'This balance can be used for payments in the next academic year (class promotion).',
      'unpaid_warning':
          'There are still unpaid bills. Use quick payment or pay per item.',

      // Payment Actions / Snackbars
      'enter_payment_amount': 'Enter payment amount',
      'amount_must_be_positive': 'Amount must be greater than 0',
      'savings_cannot_be_changed':
          'Savings balance cannot be changed manually',
      'payment_cannot_be_canceled':
          'Payment is already paid and cannot be canceled',
      'savings_increased': 'Savings balance increased by',
      'all_paid_surplus': 'All paid! Surplus Rp',
      'went_to_savings': 'went to savings',
      'all_payments_paid': 'All payments paid!',
      'payment_distributed': 'Payment Rp',
      'distributed': 'distributed',
      'paid_off': 'Paid off',

      // Transaction Log Descriptions
      'savings_payment': 'Savings balance -',
      'savings_payment_log': 'Savings balance payment of',
      'full_payment': 'Full payment -',
      'quick_payment_full_log': 'Quick payment full payment',
      'quick_payment_full_log_exact': 'Quick payment full payment (exact)',
      'partial_payment': 'Partial payment -',
      'quick_payment_partial_log': 'Quick partial payment of',
      'income': 'Income',
      'expense': 'Expense',
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
      'easter_egg_subtitle': 'Aktifkan / nonaktifkan footer spesial',
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
      'easter_egg_hint': 'sudah kubilang fitur belum ada',
      'easter_egg_title': 'Easter Egg!',
      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',
      'ok': 'OK',

      // WhatsApp
      'whatsapp_error_title': 'Gagal Meluncurkan WhatsApp',
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

      // =====================================================
      // SISWA PAGE
      // =====================================================
      'active_students_data': 'Data Siswa Aktif',
      'view_archive': 'Lihat Arsip',
      'search_name_nis': 'Cari nama, NIS...',
      'all': 'Semua',
      'no_active_students': 'Tidak ada siswa aktif',

      // Archive Root
      'student_archive': 'Arsip Siswa',
      'refresh': 'Refresh',
      'try_again': 'Coba Lagi',
      'no_archive_yet': 'Belum ada arsip',
      'archive_will_appear':
          'Arsip akan muncul setelah melakukan\nkenaikan kelas di menu Manajemen Data Siswa',
      'students_archived': 'siswa diarsipkan',

      // Archive Majors
      'archive': 'Arsip',
      'no_majors_found': 'Tidak ada jurusan ditemukan',
      'major': 'Jurusan',
      'students': 'siswa',

      // Archive Student List
      'no_archived_students': 'Tidak ada siswa arsip',
      'nis_label': 'NIS',

      // Student Detail
      'archived_student_notice':
          'Siswa ini sudah lulus dan diarsipkan. Data hanya bisa dilihat (read-only).',
      'student_info': 'Informasi Siswa',
      'name': 'Nama',
      'address': 'Alamat',
      'phone_number': 'No. Telepon',
      'gender': 'Jenis Kelamin',

      // Quick Payment
      'quick_payment': 'Pembayaran Cepat',
      'enter_amount': 'Masukkan nominal',
      'pay': 'Bayar',
      'quick_payment_hint':
          'Nominal akan dialokasikan ke semua tagihan yang belum lunas. Kelebihan akan menjadi saldo tabungan.',

      // Payment History
      'payment_history': 'Riwayat Pembayaran',
      'paid': 'Lunas',
      'partial': 'Sebagian',
      'unpaid': 'Belum Bayar',
      'balance_label': 'Saldo',
      'mark_paid': 'Lunas',

      // Financial Summary
      'financial_summary': 'Ringkasan Keuangan',
      'total_bills': 'Total Tagihan',
      'total_paid': 'Total Dibayar',
      'remaining_bills': 'Sisa Tagihan',
      'savings_balance': 'Saldo Tabungan',
      'savings_notice':
          'Saldo ini dapat digunakan untuk pembayaran di tahun ajaran berikutnya (naik kelas).',
      'unpaid_warning':
          'Masih ada tagihan yang belum lunas. Gunakan pembayaran cepat atau lunasi per item.',

      // Payment Actions / Snackbars
      'enter_payment_amount': 'Masukkan nominal pembayaran',
      'amount_must_be_positive': 'Nominal harus lebih dari 0',
      'savings_cannot_be_changed':
          'Saldo tabungan tidak dapat diubah secara manual',
      'payment_cannot_be_canceled':
          'Pembayaran sudah lunas dan tidak dapat dibatalkan',
      'savings_increased': 'Saldo tabungan bertambah Rp',
      'all_paid_surplus': 'Semua lunas! Surplus Rp',
      'went_to_savings': 'masuk saldo',
      'all_payments_paid': 'Semua pembayaran lunas!',
      'payment_distributed': 'Pembayaran Rp',
      'distributed': 'didistribusikan',
      'paid_off': 'Melunasi',

      // Transaction Log Descriptions
      'savings_payment': 'Saldo tabungan -',
      'savings_payment_log': 'Pembayaran saldo tabungan sebesar Rp',
      'full_payment': 'Pembayaran lunas semua -',
      'quick_payment_full_log': 'Pembayaran cepat lunas semua',
      'quick_payment_full_log_exact': 'Pembayaran cepat lunas semua (pas)',
      'partial_payment': 'Pembayaran parsial -',
      'quick_payment_partial_log': 'Pembayaran cepat parsial sebesar Rp',
      'income': 'Pemasukan',
      'expense': 'Pengeluaran',
    },
  };

  String t(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}