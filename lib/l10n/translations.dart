// lib/l10n/translations.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider untuk locale saat ini (default: Indonesia)
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadLocale();

    return const Locale(
      'id',
    );
  }

  Future<void> _loadLocale() async {
    final prefs =
        await SharedPreferences.getInstance();

    final langCode =
        prefs.getString('locale') ??
            'id';

    state = Locale(
      langCode,
    );
  }

  Future<void> setLocale(
    Locale locale,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      'locale',
      locale.languageCode,
    );

    state = locale;
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

// Provider untuk objek terjemahan
final translationsProvider =
    Provider<Translations>((ref) {
  final locale = ref.watch(
    localeProvider,
  );

  return Translations(
    locale,
  );
});

class Translations {
  final Locale locale;

  Translations(
    this.locale,
  );

  static const Map<String, Map<String, String>>
      _localizedValues = {
    // =====================================================
    // ENGLISH
    // =====================================================

    'en': {
      // =====================================================
      // NAVIGATION
      // =====================================================

      'dashboard': 'Dashboard',
      'students_nav': 'Students',
      'reports': 'Reports',
      'more': 'More',
      'account': 'Account',
      'action': 'Action',

      // =====================================================
      // DASHBOARD
      // =====================================================

      'greeting_morning':
          'Good Morning',

      'greeting_afternoon':
          'Good Afternoon',

      'greeting_evening':
          'Good Evening',

      'greeting_night':
          'Good Evening',

      'dashboard_loading_error':
          'Failed to load data. Please check your internet connection.',

      'balance_summary':
          'BALANCE SUMMARY',

      'total_school_balance':
          'Total School Balance',

      'income_statistics_6_months':
          'Income Statistics (6 Months)',

      'student_payment_status':
          'Student Payment Status',

      'financial_insight':
          'Financial Insight',

      'students_paid':
          'Paid Students',

      'payment_completion':
          '{percent}% of active students have completed their payments.',

      // =====================================================
      // DASHBOARD AI
      // =====================================================

      'insight_paid_good':
          '✅ {percent}% of students have paid in full. Great!',

      'insight_paid_medium':
          '📊 {percent}% of students have paid. There is still work to do to collect the rest.',

      'insight_paid_low':
          '⚠️ Only {percent}% of students have paid. A stronger collection strategy is needed.',

      'insight_income_up':
          '📈 This month\'s income increased by {percent}% compared to last month.',

      'insight_income_down':
          '📉 This month\'s income decreased by {percent}% compared to last month.',

      'insight_income_stable':
          '➖ This month\'s income is stable.',

      'insight_income_new':
          '💰 There is new income this month.',

      'insight_balance_positive':
          '💚 Positive balance: Rp {amount}. Finances are healthy.',

      'insight_balance_negative':
          '🔴 Negative balance: Rp {amount}. Pay attention to expenses.',

      'insight_balance_even':
          '⚖️ Balance is even.',

      // =====================================================
      // DAYS
      // =====================================================

      'day_monday': 'Monday',
      'day_tuesday': 'Tuesday',
      'day_wednesday': 'Wednesday',
      'day_thursday': 'Thursday',
      'day_friday': 'Friday',
      'day_saturday': 'Saturday',
      'day_sunday': 'Sunday',

      // =====================================================
      // MONTHS
      // =====================================================

      'month_january':
          'January',
      'month_february':
          'February',
      'month_march':
          'March',
      'month_april':
          'April',
      'month_may':
          'May',
      'month_june':
          'June',
      'month_july':
          'July',
      'month_august':
          'August',
      'month_september':
          'September',
      'month_october':
          'October',
      'month_november':
          'November',
      'month_december':
          'December',

      // Short month names
      'month_january_short':
          'Jan',
      'month_february_short':
          'Feb',
      'month_march_short':
          'Mar',
      'month_april_short':
          'Apr',
      'month_may_short':
          'May',
      'month_june_short':
          'Jun',
      'month_july_short':
          'Jul',
      'month_august_short':
          'Aug',
      'month_september_short':
          'Sep',
      'month_october_short':
          'Oct',
      'month_november_short':
          'Nov',
      'month_december_short':
          'Dec',

      // =====================================================
      // REPORTS / LAPORAN
      // =====================================================

      'monthly':
          'Monthly',

      'yearly':
          'Yearly',

      'all_reports':
          'All',

      'export_development':
          'Export {format} is under development',

      'export_pdf':
          'Export PDF',

      'export_excel':
          'Export Excel',

      'no_monthly_report_data':
          'No monthly report data yet.',

      'no_yearly_report_data':
          'No yearly report data yet.',

      'no_all_report_data':
          'No report data yet.',

      'year_label':
          'Year',

      'total_overall':
          'Overall Total',

      'total_income':
          'Total Income',

      'total_expense':
          'Total Expense',

      'ending_balance':
          'Ending Balance',

      'transaction_detail':
          'Transaction Details',

      // =====================================================
      // SISWA
      // =====================================================

      'active_students_data':
          'Active Students Data',

      'view_archive':
          'View Archive',

      'search_name_nis':
          'Search name, NIS...',

      'all':
          'All',

      'no_active_students':
          'No active students',

      'firebase_data_error':
          'Failed to read Firebase data',

      'student_archive':
          'Student Archive',

      'refresh':
          'Refresh',

      'try_again':
          'Try Again',

      'no_archive_yet':
          'No archive yet',

      'archive_will_appear':
          'Archive will appear after class promotion\n'
          'in Student Data Management menu',

      'students_archived':
          'students archived',

      'archive':
          'Archive',

      'no_majors_found':
          'No majors found',

      'major':
          'Major',

      'students':
          'students',

      'no_archived_students':
          'No archived students',

      'nis_label':
          'NIS',

      'student_info':
          'Student Information',

      'name':
          'Name',

      'address':
          'Address',

      'phone_number':
          'Phone Number',

      'gender':
          'Gender',

      'male':
          'Male',

      'female':
          'Female',

      'balance_payment_type':
          'Balance',

      'archived_student_notice':
          'This student has graduated and is archived. Data is read-only.',

      'quick_payment':
          'Quick Payment',

      'enter_amount':
          'Enter amount',

      'pay':
          'Pay',

      'quick_payment_hint':
          'Amount will be allocated to all unpaid bills. Excess will become savings balance.',

      'payment_history':
          'Payment History',

      'paid':
          'Paid',

      'partial':
          'Partial',

      'unpaid':
          'Unpaid',

      'balance_label':
          'Balance',

      'mark_paid':
          'Mark Paid',

      'financial_summary':
          'Financial Summary',

      'total_bills':
          'Total Bills',

      'total_paid':
          'Total Paid',

      'remaining_bills':
          'Remaining Bills',

      'savings_balance':
          'Savings Balance',

      'savings_notice':
          'This balance can be used for payments in the next academic year (class promotion).',

      'unpaid_warning':
          'There are still unpaid bills. Use quick payment or pay per item.',

      'enter_payment_amount':
          'Enter payment amount',

      'amount_must_be_positive':
          'Amount must be greater than 0',

      'savings_cannot_be_changed':
          'Savings balance cannot be changed manually',

      'payment_cannot_be_canceled':
          'Payment is already paid and cannot be canceled',

      'savings_increased':
          'Savings balance increased by',

      'all_paid_surplus':
          'All paid! Surplus Rp',

      'went_to_savings':
          'went to savings',

      'all_payments_paid':
          'All payments paid!',

      'payment_distributed':
          'Payment Rp',

      'distributed':
          'distributed',

      'paid_off':
          'Paid off',

      'archive_data_error':
          'Failed to read student archive',

      'archive_major_error':
          'Failed to read archived majors',

      'archive_student_error':
          'Failed to read archived students',

      // =====================================================
      // SETTINGS
      // =====================================================

      'app_title':
          'Eduvest Finance',

      'settings':
          'Settings',

      'dark_mode':
          'Dark Mode',

      'change_theme':
          'Change theme',

      'notifications':
          'Notifications',

      'enable_notifications':
          'Enable notifications',

      'language':
          'Language',

      'about':
          'About',

      'version':
          'Version 1.0.0',

      'select_language':
          'Select Language',

      'indonesian':
          'Indonesian',

      'english':
          'English',

      'backup_data':
          'Backup Data',

      'backup_subtitle':
          'Save to cloud',

      'backup_not_ready':
          'Backup feature is coming soon',

      'about_description':
          'Eduvest Finance App\nManage school payments easily.',

      'close':
          'Close',

      'feature_unavailable':
          'Feature not available yet',

      // =====================================================
      // AKSI
      // =====================================================

      'quick_menu':
          'Quick Menu',

      'add_transaction':
          'Add Transaction',

      'calculator':
          'Calculator',

      'simulation_data':
          'Data Simulation',

      'transaction_type':
          'Type',

      'description':
          'Description',

      'amount_rupiah':
          'Amount (Rp)',

      'cancel':
          'Cancel',

      'save':
          'Save',

      'failed_add_transaction':
          'Failed to add transaction',

      // =====================================================
      // APPEARANCE
      // =====================================================

      'appearance':
          'Appearance',

      'app_theme':
          'App Theme',

      // =====================================================
      // PREFERENCES
      // =====================================================

      'preferences':
          'Preferences',

      'sound_volume':
          'Sound Volume',

      'enable_sound':
          'Enable sound',

      'mute_sound':
          'Mute sound',

      // =====================================================
      // DATA
      // =====================================================

      'data':
          'Data',

      'show_easter_egg':
          'Show Easter Egg',

      'easter_egg_subtitle':
          'Enable / disable special footer',

      'easter_egg_found':
          'Congratulations! You found the Easter Egg! 🥚',

      // =====================================================
      // THEME
      // =====================================================

      'select_theme':
          'Select Theme',

      'theme_light':
          'Light',

      'theme_dark':
          'Dark',

      'theme_neumorphism':
          'Neomorphism',

      'theme_glassmorphism':
          'Glassmorphism',

      'theme_modern':
          'Modern UI',

      'theme_aurora':
          'Aurora UI',

      'theme_cyberpunk':
          'Cyberpunk Neon',

      'theme_system':
          'System',

      // =====================================================
      // EASTER EGG
      // =====================================================

      'easter_egg_hint':
          "I told you the feature isn't available yet",

      'easter_egg_title':
          'Easter Egg!',

      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',

      'ok':
          'OK',

      // =====================================================
      // WHATSAPP
      // =====================================================

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

      'more_menu':
          'More Menu',

      'finance':
          'Finance',

      'data_management':
          'Data Management',

      'system_more':
          'System & More',

      'bills':
          'Bills',

      'teacher_salary':
          'Teacher Salary',

      'statistics':
          'Statistics',

      'add_student':
          'Add Student',

      'digital_account':
          'Digital Account',

      'activity_log':
          'Activity Log',

      'ai_assistant':
          'AI Assistant',

      'animation_gallery':
          'Animation Gallery',

      // =====================================================
      // TRANSACTION LOG
      // =====================================================

      'savings_payment':
          'Savings balance -',

      'savings_payment_log':
          'Savings balance payment of',

      'full_payment':
          'Full payment -',

      'quick_payment_full_log':
          'Quick payment full payment',

      'quick_payment_full_log_exact':
          'Quick payment full payment (exact)',

      'partial_payment':
          'Partial payment -',

      'quick_payment_partial_log':
          'Quick partial payment of',

      'income':
          'Income',

      'expense':
          'Expense',
    },

    // =====================================================
    // INDONESIAN
    // =====================================================

    'id': {
      // =====================================================
      // NAVIGATION
      // =====================================================

      'dashboard':
          'Dashboard',

      'students_nav':
          'Siswa',

      'reports':
          'Laporan',

      'more':
          'Lainnya',

      'account':
          'Akun',

      'action':
          'Aksi',

      // =====================================================
      // DASHBOARD
      // =====================================================

      'greeting_morning':
          'Selamat Pagi',

      'greeting_afternoon':
          'Selamat Siang',

      'greeting_evening':
          'Selamat Sore',

      'greeting_night':
          'Selamat Malam',

      'dashboard_loading_error':
          'Gagal memuat data. Periksa koneksi internet Anda.',

      'balance_summary':
          'RINGKASAN SALDO',

      'total_school_balance':
          'Total Saldo Sekolah',

      'income_statistics_6_months':
          'Statistik Pemasukan (6 Bulan)',

      'student_payment_status':
          'Status Pembayaran Siswa',

      'financial_insight':
          'Insight Keuangan',

      'students_paid':
          'Siswa Lunas',

      'payment_completion':
          '{percent}% dari total siswa aktif telah melunasi pembayaran.',

      // =====================================================
      // DASHBOARD AI
      // =====================================================

      'insight_paid_good':
          '✅ {percent}% siswa sudah lunas. Bagus!',

      'insight_paid_medium':
          '📊 {percent}% siswa lunas. Masih ada PR menagih sisanya.',

      'insight_paid_low':
          '⚠️ Hanya {percent}% siswa lunas. Perlu strategi penagihan lebih agresif.',

      'insight_income_up':
          '📈 Pemasukan bulan ini naik {percent}% dibanding bulan lalu.',

      'insight_income_down':
          '📉 Pemasukan bulan ini turun {percent}% dibanding bulan lalu.',

      'insight_income_stable':
          '➖ Pemasukan bulan ini stabil.',

      'insight_income_new':
          '💰 Bulan ini mulai ada pemasukan baru.',

      'insight_balance_positive':
          '💚 Saldo positif: Rp {amount}. Keuangan sehat.',

      'insight_balance_negative':
          '🔴 Saldo negatif: Rp {amount}. Perhatikan pengeluaran.',

      'insight_balance_even':
          '⚖️ Saldo impas.',

      // =====================================================
      // DAYS
      // =====================================================

      'day_monday':
          'Senin',

      'day_tuesday':
          'Selasa',

      'day_wednesday':
          'Rabu',

      'day_thursday':
          'Kamis',

      'day_friday':
          'Jumat',

      'day_saturday':
          'Sabtu',

      'day_sunday':
          'Minggu',

      // =====================================================
      // MONTHS
      // =====================================================

      'month_january':
          'Januari',

      'month_february':
          'Februari',

      'month_march':
          'Maret',

      'month_april':
          'April',

      'month_may':
          'Mei',

      'month_june':
          'Juni',

      'month_july':
          'Juli',

      'month_august':
          'Agustus',

      'month_september':
          'September',

      'month_october':
          'Oktober',

      'month_november':
          'November',

      'month_december':
          'Desember',

      // Short month names
      'month_january_short':
          'Jan',

      'month_february_short':
          'Feb',

      'month_march_short':
          'Mar',

      'month_april_short':
          'Apr',

      'month_may_short':
          'Mei',

      'month_june_short':
          'Jun',

      'month_july_short':
          'Jul',

      'month_august_short':
          'Agu',

      'month_september_short':
          'Sep',

      'month_october_short':
          'Okt',

      'month_november_short':
          'Nov',

      'month_december_short':
          'Des',

      // =====================================================
      // LAPORAN
      // =====================================================

      'monthly':
          'Bulanan',

      'yearly':
          'Tahunan',

      'all_reports':
          'Semua',

      'export_development':
          'Export {format} sedang dalam pengembangan',

      'export_pdf':
          'Export PDF',

      'export_excel':
          'Export Excel',

      'no_monthly_report_data':
          'Belum ada data laporan bulanan.',

      'no_yearly_report_data':
          'Belum ada data laporan tahunan.',

      'no_all_report_data':
          'Belum ada data laporan.',

      'year_label':
          'Tahun',

      'total_overall':
          'Total Keseluruhan',

      'total_income':
          'Total Pemasukan',

      'total_expense':
          'Total Pengeluaran',

      'ending_balance':
          'Saldo Akhir',

      'transaction_detail':
          'Detail Transaksi',

      // =====================================================
      // SISWA
      // =====================================================

      'active_students_data':
          'Data Siswa Aktif',

      'view_archive':
          'Lihat Arsip',

      'search_name_nis':
          'Cari nama, NIS...',

      'all':
          'Semua',

      'no_active_students':
          'Tidak ada siswa aktif',

      'firebase_data_error':
          'Gagal membaca data Firebase',

      'student_archive':
          'Arsip Siswa',

      'refresh':
          'Refresh',

      'try_again':
          'Coba Lagi',

      'no_archive_yet':
          'Belum ada arsip',

      'archive_will_appear':
          'Arsip akan muncul setelah melakukan\n'
          'kenaikan kelas di menu Manajemen Data Siswa',

      'students_archived':
          'siswa diarsipkan',

      'archive':
          'Arsip',

      'no_majors_found':
          'Tidak ada jurusan ditemukan',

      'major':
          'Jurusan',

      'students':
          'siswa',

      'no_archived_students':
          'Tidak ada siswa arsip',

      'nis_label':
          'NIS',

      'student_info':
          'Informasi Siswa',

      'name':
          'Nama',

      'address':
          'Alamat',

      'phone_number':
          'No. Telepon',

      'gender':
          'Jenis Kelamin',

      'male':
          'Laki-laki',

      'female':
          'Perempuan',

      'balance_payment_type':
          'Saldo',

      'archived_student_notice':
          'Siswa ini sudah lulus dan diarsipkan. Data hanya bisa dilihat (read-only).',

      'quick_payment':
          'Pembayaran Cepat',

      'enter_amount':
          'Masukkan nominal',

      'pay':
          'Bayar',

      'quick_payment_hint':
          'Nominal akan dialokasikan ke semua tagihan yang belum lunas. Kelebihan akan menjadi saldo tabungan.',

      'payment_history':
          'Riwayat Pembayaran',

      'paid':
          'Lunas',

      'partial':
          'Sebagian',

      'unpaid':
          'Belum Bayar',

      'balance_label':
          'Saldo',

      'mark_paid':
          'Lunas',

      'financial_summary':
          'Ringkasan Keuangan',

      'total_bills':
          'Total Tagihan',

      'total_paid':
          'Total Dibayar',

      'remaining_bills':
          'Sisa Tagihan',

      'savings_balance':
          'Saldo Tabungan',

      'savings_notice':
          'Saldo ini dapat digunakan untuk pembayaran di tahun ajaran berikutnya (naik kelas).',

      'unpaid_warning':
          'Masih ada tagihan yang belum lunas. Gunakan pembayaran cepat atau lunasi per item.',

      'enter_payment_amount':
          'Masukkan nominal pembayaran',

      'amount_must_be_positive':
          'Nominal harus lebih dari 0',

      'savings_cannot_be_changed':
          'Saldo tabungan tidak dapat diubah secara manual',

      'payment_cannot_be_canceled':
          'Pembayaran sudah lunas dan tidak dapat dibatalkan',

      'savings_increased':
          'Saldo tabungan bertambah Rp',

      'all_paid_surplus':
          'Semua lunas! Surplus Rp',

      'went_to_savings':
          'masuk saldo',

      'all_payments_paid':
          'Semua pembayaran lunas!',

      'payment_distributed':
          'Pembayaran Rp',

      'distributed':
          'didistribusikan',

      'paid_off':
          'Melunasi',

      'archive_data_error':
          'Gagal membaca arsip siswa',

      'archive_major_error':
          'Gagal membaca jurusan arsip',

      'archive_student_error':
          'Gagal membaca siswa arsip',

      // =====================================================
      // SETTINGS
      // =====================================================

      'app_title':
          'Eduvest Finance',

      'settings':
          'Pengaturan',

      'dark_mode':
          'Mode Gelap',

      'change_theme':
          'Ubah tema aplikasi',

      'notifications':
          'Notifikasi',

      'enable_notifications':
          'Aktifkan pemberitahuan',

      'language':
          'Bahasa',

      'about':
          'Tentang',

      'version':
          'Versi 1.0.0',

      'select_language':
          'Pilih Bahasa',

      'indonesian':
          'Indonesia',

      'english':
          'Inggris',

      'backup_data':
          'Backup Data',

      'backup_subtitle':
          'Simpan cadangan ke cloud',

      'backup_not_ready':
          'Fitur backup akan segera hadir',

      'about_description':
          'Aplikasi Eduvest Finance\n'
          'Kelola pembayaran sekolah dengan mudah.',

      'close':
          'Tutup',

      'feature_unavailable':
          'Fitur belum tersedia',

      // =====================================================
      // AKSI
      // =====================================================

      'quick_menu':
          'Menu Cepat',

      'add_transaction':
          'Tambah Transaksi',

      'calculator':
          'Kalkulator',

      'simulation_data':
          'Simulasi Data',

      'transaction_type':
          'Jenis',

      'description':
          'Deskripsi',

      'amount_rupiah':
          'Jumlah (Rp)',

      'cancel':
          'Batal',

      'save':
          'Simpan',

      'failed_add_transaction':
          'Gagal menambah transaksi',

      // =====================================================
      // APPEARANCE
      // =====================================================

      'appearance':
          'Tampilan',

      'app_theme':
          'Tema Aplikasi',

      // =====================================================
      // PREFERENCES
      // =====================================================

      'preferences':
          'Preferensi',

      'sound_volume':
          'Volume Suara',

      'enable_sound':
          'Aktifkan suara',

      'mute_sound':
          'Matikan suara',

      // =====================================================
      // DATA
      // =====================================================

      'data':
          'Data',

      'show_easter_egg':
          'Tampilkan Easter Egg',

      'easter_egg_subtitle':
          'Aktifkan / nonaktifkan footer spesial',

      'easter_egg_found':
          'Selamat! Anda menemukan telur Paskah! 🥚',

      // =====================================================
      // THEME
      // =====================================================

      'select_theme':
          'Pilih Tema',

      'theme_light':
          'Terang',

      'theme_dark':
          'Gelap',

      'theme_neumorphism':
          'Neomorphism',

      'theme_glassmorphism':
          'Glassmorphism',

      'theme_modern':
          'Modern UI',

      'theme_aurora':
          'Aurora UI',

      'theme_cyberpunk':
          'Cyberpunk Neon',

      'theme_system':
          'Sistem',

      // =====================================================
      // EASTER EGG
      // =====================================================

      'easter_egg_hint':
          'sudah kubilang fitur belum ada',

      'easter_egg_title':
          'Easter Egg!',

      'easter_egg_desc':
          'you found easter egg, admin say: kita sayang pak win',

      'ok':
          'OK',

      // =====================================================
      // WHATSAPP
      // =====================================================

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

      'more_menu':
          'Menu Lainnya',

      'finance':
          'Keuangan',

      'data_management':
          'Manajemen Data',

      'system_more':
          'Sistem & Lainnya',

      'bills':
          'Tagihan',

      'teacher_salary':
          'Gaji Guru',

      'statistics':
          'Statistik',

      'add_student':
          'Tambah Siswa',

      'digital_account':
          'Akun Digital',

      'activity_log':
          'Log Aktivitas',

      'ai_assistant':
          'AI Assistant',

      'animation_gallery':
          'Galeri Animasi',

      // =====================================================
      // TRANSACTION LOG
      // =====================================================

      'savings_payment':
          'Saldo tabungan -',

      'savings_payment_log':
          'Pembayaran saldo tabungan sebesar Rp',

      'full_payment':
          'Pembayaran lunas semua -',

      'quick_payment_full_log':
          'Pembayaran cepat lunas semua',

      'quick_payment_full_log_exact':
          'Pembayaran cepat lunas semua (pas)',

      'partial_payment':
          'Pembayaran parsial -',

      'quick_payment_partial_log':
          'Pembayaran cepat parsial sebesar Rp',

      'income':
          'Pemasukan',

      'expense':
          'Pengeluaran',
    },
  };

  String t(
    String key,
  ) {
    return _localizedValues[
            locale.languageCode]?[key] ??
        key;
  }
}