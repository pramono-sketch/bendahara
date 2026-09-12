// lib/navigation/laporan.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../helpers/custom_animation.dart';
import '../helpers/sound_helper.dart';
import '../l10n/translations.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool _isLoading = true;
  bool _hasError = false;

  /// Semua transaksi (gabungan transaksi aktif + arsip bulanan)
  /// Sama persis dengan yang dibaca oleh Dashboard.
  List<Transaction> _allCombinedTransactions = [];

  // =========================================================
  // FETCH DATA: GABUNGKAN SEMUA (SAMA PERSIS DENGAN DASHBOARD)
  // =========================================================

  /// Mengambil semua transaksi (transaksi aktif + transaksi arsip bulanan)
  /// agar Laporan dan Dashboard memiliki angka yang sama persis.
  Future<List<Transaction>> _getAllCombinedTransactions() async {
    final activeTransactions = await fetchAllTransactions();
    final archivedMonths = await fetchArchivedMonths();

    final Set<String> seenIds = activeTransactions.map((t) => t.id).toSet();
    final List<Transaction> all = List.from(activeTransactions);

    // Gabungkan dengan data yang sudah diarsipkan
    for (final arch in archivedMonths) {
      for (final t in arch.transactions) {
        if (!seenIds.contains(t.id)) {
          all.add(t);
          seenIds.add(t.id);
        }
      }
    }

    // Gabungkan dengan transaksi lokal yang belum tersinkron
    for (final t in localTransactions) {
      if (!seenIds.contains(t.id)) {
        all.add(t);
        seenIds.add(t.id);
      }
    }

    return all;
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Ambil semua data gabungan
      _allCombinedTransactions = await _getAllCombinedTransactions();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // SUSUN DATA PER-BULAN UNTUK TAHUN TERTENTU
  // =========================================================

  /// Mengelompokkan _allCombinedTransactions ke dalam bulan-bulan
  /// pada tahun tertentu.
  Map<int, List<Transaction>> _getMonthsDataForYear(int year) {
    final Map<int, List<Transaction>> result = {};

    // Inisialisasi 12 bulan kosong.
    for (int m = 1; m <= 12; m++) {
      result[m] = [];
    }

    // Isi dari gabungan seluruh transaksi
    for (final t in _allCombinedTransactions) {
      if (t.date.year == year) {
        result[t.date.month]!.add(t);
      }
    }

    return result;
  }

  // =========================================================
  // DAFTAR TAHUN YANG TERSEDIA
  // =========================================================

  List<int> _getAvailableYears() {
    final Set<int> years = {};
    final now = DateTime.now();
    years.add(now.year); // Selalu tampilkan tahun berjalan.

    for (final t in _allCombinedTransactions) {
      years.add(t.date.year);
    }

    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final translations = ref.watch(translationsProvider);
    final t = translations.t;
    final colors = Theme.of(context).colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    final scaffoldBackgroundColor =
        ThemeHelper.getScaffoldBackgroundColor(themeMode, colors);

    // =========================================================
    // LOADING STATE
    // =========================================================

    if (_isLoading) {
      return ThemeHelper.buildThemedBackground(
        themeMode,
        Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: AppBar(title: Text(t('reports'))),
          body: const LottieLoading(),
        ),
      );
    }

    // =========================================================
    // ERROR STATE
    // =========================================================

    if (_hasError) {
      return ThemeHelper.buildThemedBackground(
        themeMode,
        Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: AppBar(title: Text(t('reports'))),
          body: LottieError(message: t('dashboard_loading_error')),
        ),
      );
    }

    final years = _getAvailableYears();
    final currentYear = DateTime.now().year;

    return ThemeHelper.buildThemedBackground(
      themeMode,
      DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: scaffoldBackgroundColor,

          // =====================================================
          // APP BAR
          // =====================================================

          appBar: AppBar(
            title: Text(t('reports')),
            bottom: TabBar(
              tabs: [
                Tab(text: t('monthly')),
                Tab(text: t('yearly')),
              ],
              labelColor: accentColor,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: accentColor,
            ),
          ),

          body: TabBarView(
            children: [
              // === BULANAN: 12 BULAN PADA TAHUN BERJALAN ===
              _buildMonthlyReport(context, currentYear, t, translations, accentColor),

              // === TAHUNAN: FOLDER TAHUN, DI DALAMNYA BULAN ===
              _buildYearlyReport(context, years, t, translations),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LAPORAN BULANAN — 12 BULAN PADA TAHUN BERJALAN
  // =========================================================

  Widget _buildMonthlyReport(
    BuildContext context,
    int year,
    String Function(String) t,
    Translations translations,
    Color accentColor,
  ) {
    final monthsData = _getMonthsDataForYear(year);
    final now = DateTime.now();
    final isIndonesian = translations.locale.languageCode == 'id';
    final currentMonthLabel = isIndonesian ? 'Bulan Ini' : 'Current Month';
    final noDataLabel = isIndonesian ? 'Belum ada data' : 'No data yet';

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = index + 1;
        final list = monthsData[month] ?? [];

        final totalIncome = list
            .where((tr) => tr.type == TransType.pemasukan)
            .fold<double>(0, (sum, tr) => sum + tr.amount);

        final totalExpense = list
            .where((tr) => tr.type == TransType.pengeluaran)
            .fold<double>(0, (sum, tr) => sum + tr.amount);

        final net = totalIncome - totalExpense;
        final monthName = _getMonthName(month, t);
        final label = '$monthName $year';
        final isCurrentMonth = (month == now.month && year == now.year);
        final hasData = list.isNotEmpty;

        final delayMs = (index * 50).clamp(0, 400).toInt();

        return ScrollReveal(
          delay: Duration(milliseconds: delayMs),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            color: isCurrentMonth ? accentColor.withOpacity(0.08) : null,
            shape: isCurrentMonth
                ? RoundedRectangleBorder(
                    side: BorderSide(
                      color: accentColor.withOpacity(0.4),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isCurrentMonth
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (isCurrentMonth)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        currentMonthLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: hasData
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${t('income')}: Rp ${formatCurrency(totalIncome)} • '
                        '${t('expense')}: Rp ${formatCurrency(totalExpense)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        noDataLabel,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
              trailing: hasData
                  ? Text(
                      'Rp ${formatCurrency(net)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: net >= 0 ? AppColors.success : AppColors.error,
                      ),
                    )
                  : Text(
                      '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
              onTap: hasData
                  ? () {
                      SoundHelper().playClick();
                      _showDetailDialog(context, label, list, t);
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LAPORAN TAHUNAN — FOLDER TAHUN, DI DALAMNYA BULAN
  // =========================================================

  Widget _buildYearlyReport(
    BuildContext context,
    List<int> years,
    String Function(String) t,
    Translations translations,
  ) {
    if (years.isEmpty) {
      return LottieError(message: t('no_yearly_report_data'));
    }

    final isIndonesian = translations.locale.languageCode == 'id';
    final noDataLabel = isIndonesian ? 'Belum ada data' : 'No data yet';

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final delayMs = (index * 50).clamp(0, 400).toInt();

        final monthsData = _getMonthsDataForYear(year);

        // Hitung total seluruh bulan pada tahun ini.
        final List<Transaction> yearTransactions = [];
        for (int m = 1; m <= 12; m++) {
          yearTransactions.addAll(monthsData[m] ?? []);
        }

        final totalIncome = yearTransactions
            .where((tr) => tr.type == TransType.pemasukan)
            .fold<double>(0, (sum, tr) => sum + tr.amount);

        final totalExpense = yearTransactions
            .where((tr) => tr.type == TransType.pengeluaran)
            .fold<double>(0, (sum, tr) => sum + tr.amount);

        final net = totalIncome - totalExpense;
        final hasData = yearTransactions.isNotEmpty;

        // Hitung jumlah bulan yang punya data.
        final monthsWithData = monthsData.entries
            .where((e) => e.value.isNotEmpty)
            .length;

        return ScrollReveal(
          delay: Duration(milliseconds: delayMs),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Row(
                children: [
                  Icon(Icons.folder,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${t('year_label')} $year',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4, left: 32),
                child: Text(
                  hasData
                      ? '${t('income')}: Rp ${formatCurrency(totalIncome)} • '
                          '${t('expense')}: Rp ${formatCurrency(totalExpense)}\n'
                          '${monthsWithData}/12 ${isIndonesian ? 'bulan' : 'months'}'
                      : noDataLabel,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              trailing: Text(
                hasData ? 'Rp ${formatCurrency(net)}' : '-',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hasData
                      ? (net >= 0 ? AppColors.success : AppColors.error)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                // Tampilkan setiap bulan yang ada datanya.
                for (int m = 1; m <= 12; m++)
                  if ((monthsData[m] ?? []).isNotEmpty)
                    _buildMonthSubItem(context, year, m, monthsData[m]!, t),

                // Jika tidak ada data sama sekali, tampilkan pesan.
                if (yearTransactions.isEmpty)
                  ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.only(left: 32),
                    title: Text(
                      noDataLabel,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // SUB-ITEM BULAN (DI DALAM FOLDER TAHUN)
  // =========================================================

  Widget _buildMonthSubItem(
    BuildContext context,
    int year,
    int month,
    List<Transaction> list,
    String Function(String) t,
  ) {
    final totalIncome = list
        .where((tr) => tr.type == TransType.pemasukan)
        .fold<double>(0, (sum, tr) => sum + tr.amount);

    final totalExpense = list
        .where((tr) => tr.type == TransType.pengeluaran)
        .fold<double>(0, (sum, tr) => sum + tr.amount);

    final net = totalIncome - totalExpense;
    final monthName = _getMonthName(month, t);

    final now = DateTime.now();
    final isCurrentMonth = (month == now.month && year == now.year);

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading: Icon(
        isCurrentMonth ? Icons.event_available : Icons.calendar_month,
        size: 20,
        color: isCurrentMonth
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        '$monthName $year',
        style: TextStyle(
          fontWeight: isCurrentMonth ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '${t('income')}: Rp ${formatCurrency(totalIncome)} • '
        '${t('expense')}: Rp ${formatCurrency(totalExpense)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        'Rp ${formatCurrency(net)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: net >= 0 ? AppColors.success : AppColors.error,
        ),
      ),
      onTap: () {
        SoundHelper().playClick();
        _showDetailDialog(context, '$monthName $year', list, t);
      },
    );
  }

  // =========================================================
  // DETAIL TRANSAKSI
  // =========================================================

  void _showDetailDialog(
    BuildContext context,
    String title,
    List<Transaction> list,
    String Function(String) t,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${t('transaction_detail')} - $title'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, index) {
              final transaction = list[index];

              return ListTile(
                dense: true,
                title: Text(transaction.description),
                subtitle: Text(
                  _getCategoryLabel(transaction.category, t),
                ),
                trailing: Text(
                  'Rp ${formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    color: transaction.type == TransType.pemasukan
                        ? AppColors.success
                        : AppColors.error,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick();
              Navigator.pop(ctx);
            },
            child: Text(t('close')),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // CATEGORY LABEL
  // =========================================================

  String _getCategoryLabel(
    String category,
    String Function(String) t,
  ) {
    switch (category.trim().toLowerCase()) {
      case 'pemasukan':
      case 'income':
        return t('income');
      case 'pengeluaran':
      case 'expense':
        return t('expense');
      default:
        return category;
    }
  }

  // =========================================================
  // NAMA BULAN
  // =========================================================

  String _getMonthName(
    int month,
    String Function(String) t,
  ) {
    switch (month) {
      case 1:
        return t('month_january_short');
      case 2:
        return t('month_february_short');
      case 3:
        return t('month_march_short');
      case 4:
        return t('month_april_short');
      case 5:
        return t('month_may_short');
      case 6:
        return t('month_june_short');
      case 7:
        return t('month_july_short');
      case 8:
        return t('month_august_short');
      case 9:
        return t('month_september_short');
      case 10:
        return t('month_october_short');
      case 11:
        return t('month_november_short');
      case 12:
        return t('month_december_short');
      default:
        return '';
    }
  }
}