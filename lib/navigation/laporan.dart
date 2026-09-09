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
  List<Transaction> _allTransactions = [];

  // =========================================================
  // FETCH DATA DARI FIREBASE + MERGE DENGAN DATA LOKAL
  // =========================================================

  Future<void> _fetchTransactions() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // =======================================================
      // 1. AMBIL SEMUA TRANSAKSI DARI FIREBASE
      // =======================================================

      final firebaseTransactions = await fetchAllTransactions();

      final Set<String> seenIds =
          firebaseTransactions.map((t) => t.id).toSet();

      final List<Transaction> all = List.from(firebaseTransactions);

      // =======================================================
      // 2. TAMBAHKAN TRANSAKSI LOKAL YANG BELUM ADA DI FIREBASE
      // =======================================================

      for (final t in localTransactions) {
        if (!seenIds.contains(t.id)) {
          all.add(t);
          seenIds.add(t.id);
        }
      }

      // =======================================================
      // 3. TAMBAHKAN TRANSAKSI ARSIP YANG BELUM ADA DI FIREBASE
      // =======================================================

      for (final list in arsipTransaksi.values) {
        for (final t in list) {
          if (!seenIds.contains(t.id)) {
            all.add(t);
            seenIds.add(t.id);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allTransactions = all;
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
  // GROUP TRANSAKSI BERDASARKAN BULAN
  // =========================================================

  Map<String, List<Transaction>> _groupTransactions() {
    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in _allTransactions) {
      final key =
          '${transaction.date.year}-'
          '${transaction.date.month.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(transaction);
    }

    return grouped;
  }

  @override
  void initState() {
    super.initState();

    _fetchTransactions();
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

    final accentColor =
        ThemeHelper.getAccentColor(themeMode, colors);

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
          body: LottieError(
            message: t('dashboard_loading_error'),
          ),
        ),
      );
    }

    // =========================================================
    // GROUP & SORT TRANSAKSI
    // =========================================================

    final grouped = _groupTransactions();

    final keys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ThemeHelper.buildThemedBackground(
      themeMode,
      DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: scaffoldBackgroundColor,

          appBar: AppBar(
            title: Text(t('reports')),

            actions: [
              // =================================================
              // TOMBOL REFRESH
              // =================================================

              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  SoundHelper().playClick();
                  _fetchTransactions();
                },
              ),

              PopupMenuButton<String>(
                onSelected: (value) {
                  SoundHelper().playClick();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t('export_development').replaceFirst(
                          '{format}',
                          value,
                        ),
                      ),
                    ),
                  );
                },

                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'PDF',
                    child: Text(t('export_pdf')),
                  ),
                  PopupMenuItem(
                    value: 'Excel',
                    child: Text(t('export_excel')),
                  ),
                ],

                icon: const Icon(Icons.download),
              ),
            ],

            bottom: TabBar(
              tabs: [
                Tab(text: t('monthly')),
                Tab(text: t('yearly')),
                Tab(text: t('all_reports')),
              ],
              labelColor: accentColor,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: accentColor,
            ),
          ),

          body: TabBarView(
            children: [
              _buildMonthlyReport(context, grouped, keys, t),
              _buildYearlyReport(context, grouped, keys, t),
              _buildAllReport(context, grouped, keys, t),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LAPORAN BULANAN
  // =========================================================

  Widget _buildMonthlyReport(
    BuildContext context,
    Map<String, List<Transaction>> grouped,
    List<String> keys,
    String Function(String) t,
  ) {
    if (keys.isEmpty) {
      return LottieError(
        message: t('no_monthly_report_data'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];

        final list = grouped[key]!;

        final totalIncome = list
            .where((transaction) =>
                transaction.type == TransType.pemasukan)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final totalExpense = list
            .where((transaction) =>
                transaction.type == TransType.pengeluaran)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final net = totalIncome - totalExpense;

        final parts = key.split('-');

        final monthName = _getMonthName(int.parse(parts[1]), t);

        final year = parts[0];

        final label = '$monthName $year';

        final delayMs = (index * 50).clamp(0, 400).toInt();

        return ScrollReveal(
          delay: Duration(milliseconds: delayMs),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(label),
              subtitle: Text(
                '${t('income')}: '
                'Rp ${formatCurrency(totalIncome)} • '
                '${t('expense')}: '
                'Rp ${formatCurrency(totalExpense)}',
              ),
              trailing: Text(
                'Rp ${formatCurrency(net)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
              onTap: () {
                SoundHelper().playClick();
                _showDetailDialog(context, label, list, t);
              },
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LAPORAN TAHUNAN
  // =========================================================

  Widget _buildYearlyReport(
    BuildContext context,
    Map<String, List<Transaction>> grouped,
    List<String> keys,
    String Function(String) t,
  ) {
    final Map<String, List<Transaction>> yearly = {};

    for (final key in keys) {
      final year = key.split('-')[0];

      yearly.putIfAbsent(year, () => []);

      yearly[year]!.addAll(grouped[key]!);
    }

    final yearKeys = yearly.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    if (yearKeys.isEmpty) {
      return LottieError(
        message: t('no_yearly_report_data'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: yearKeys.length,
      itemBuilder: (context, index) {
        final year = yearKeys[index];

        final list = yearly[year]!;

        final totalIncome = list
            .where((transaction) =>
                transaction.type == TransType.pemasukan)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final totalExpense = list
            .where((transaction) =>
                transaction.type == TransType.pengeluaran)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final net = totalIncome - totalExpense;

        final delayMs = (index * 50).clamp(0, 400).toInt();

        return ScrollReveal(
          delay: Duration(milliseconds: delayMs),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${t('year_label')} $year'),
              subtitle: Text(
                '${t('income')}: '
                'Rp ${formatCurrency(totalIncome)} • '
                '${t('expense')}: '
                'Rp ${formatCurrency(totalExpense)}',
              ),
              trailing: Text(
                'Rp ${formatCurrency(net)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: net >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // LAPORAN SEMUA
  // =========================================================

  Widget _buildAllReport(
    BuildContext context,
    Map<String, List<Transaction>> grouped,
    List<String> keys,
    String Function(String) t,
  ) {
    final List<Transaction> all = [];

    for (final list in grouped.values) {
      all.addAll(list);
    }

    if (all.isEmpty) {
      return LottieError(
        message: t('no_all_report_data'),
      );
    }

    final totalIncome = all
        .where((transaction) => transaction.type == TransType.pemasukan)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final totalExpense = all
        .where((transaction) => transaction.type == TransType.pengeluaran)
        .fold<double>(0, (sum, transaction) => sum + transaction.amount);

    final net = totalIncome - totalExpense;

    return Center(
      child: ScrollReveal(
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t('total_overall'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  context,
                  t('total_income'),
                  formatCurrency(totalIncome),
                  AppColors.success,
                ),
                _summaryRow(
                  context,
                  t('total_expense'),
                  formatCurrency(totalExpense),
                  AppColors.error,
                ),
                const Divider(),
                _summaryRow(
                  context,
                  t('ending_balance'),
                  formatCurrency(net),
                  net >= 0
                      ? Theme.of(context).colorScheme.primary
                      : AppColors.error,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SUMMARY ROW
  // =========================================================

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            'Rp $value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
          ),
        ],
      ),
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