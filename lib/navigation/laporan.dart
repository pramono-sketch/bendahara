// navigation/laporan.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../templates/custom_animation.dart';
import '../templates/sound_helper.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final colors = Theme.of(context).colorScheme;

    // =========================================================
    // GABUNGKAN SEMUA TRANSAKSI
    // =========================================================

    final List<Transaction> allTransactions = [];

    for (final list in arsipTransaksi.values) {
      allTransactions.addAll(list);
    }

    allTransactions.addAll(localTransactions);

    // =========================================================
    // GROUP TRANSAKSI BERDASARKAN BULAN
    // =========================================================

    final Map<String, List<Transaction>> grouped = {};

    for (final transaction in allTransactions) {
      final key =
          '${transaction.date.year}-'
          '${transaction.date.month.toString().padLeft(2, '0')}';

      grouped.putIfAbsent(key, () => []);

      grouped[key]!.add(transaction);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Colors.transparent,

          appBar: AppBar(
            title: const Text('Laporan'),

            actions: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  SoundHelper().playClick();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export $value dalam pengembangan')),
                  );
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                  const PopupMenuItem(
                    value: 'Excel',
                    child: Text('Export Excel'),
                  ),
                ],
                icon: const Icon(Icons.download),
              ),
            ],

            bottom: TabBar(
              tabs: const [
                Tab(text: 'Bulanan'),
                Tab(text: 'Tahunan'),
                Tab(text: 'Semua'),
              ],
              labelColor: accentColor,
              unselectedLabelColor: colors.onSurfaceVariant,
              indicatorColor: accentColor,
            ),
          ),

          body: TabBarView(
            children: [
              _buildMonthlyReport(context, grouped, keys),
              _buildYearlyReport(context, grouped, keys),
              _buildAllReport(context, grouped, keys),
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
  ) {
    // =======================================================
    // DATA KOSONG
    // =======================================================

    if (keys.isEmpty) {
      return const LottieError(message: 'Belum ada data laporan.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),

      itemCount: keys.length,

      itemBuilder: (context, index) {
        final key = keys[index];

        final list = grouped[key]!;

        final totalIncome = list
            .where((transaction) => transaction.type == TransType.pemasukan)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final totalExpense = list
            .where((transaction) => transaction.type == TransType.pengeluaran)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final net = totalIncome - totalExpense;

        final parts = key.split('-');

        final monthName = _getMonthName(int.parse(parts[1]));

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
                'Pemasukan: Rp ${formatCurrency(totalIncome)} • '
                'Pengeluaran: Rp ${formatCurrency(totalExpense)}',
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

                _showDetailDialog(context, label, list);
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
  ) {
    final Map<String, List<Transaction>> yearly = {};

    for (final key in keys) {
      final year = key.split('-')[0];

      yearly.putIfAbsent(year, () => []);

      yearly[year]!.addAll(grouped[key]!);
    }

    final yearKeys = yearly.keys.toList()..sort((a, b) => b.compareTo(a));

    // =======================================================
    // DATA KOSONG
    // =======================================================

    if (yearKeys.isEmpty) {
      return const LottieError(message: 'Belum ada data laporan tahunan.');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),

      itemCount: yearKeys.length,

      itemBuilder: (context, index) {
        final year = yearKeys[index];

        final list = yearly[year]!;

        final totalIncome = list
            .where((transaction) => transaction.type == TransType.pemasukan)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final totalExpense = list
            .where((transaction) => transaction.type == TransType.pengeluaran)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);

        final net = totalIncome - totalExpense;

        final delayMs = (index * 50).clamp(0, 400).toInt();

        return ScrollReveal(
          delay: Duration(milliseconds: delayMs),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('Tahun $year'),
              subtitle: Text(
                'Pemasukan: Rp ${formatCurrency(totalIncome)} • '
                'Pengeluaran: Rp ${formatCurrency(totalExpense)}',
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
  ) {
    final List<Transaction> all = [];

    for (final list in grouped.values) {
      all.addAll(list);
    }

    // =======================================================
    // DATA KOSONG
    // =======================================================

    if (all.isEmpty) {
      return const LottieError(message: 'Belum ada data laporan.');
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
                  'Total Keseluruhan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                _summaryRow(
                  context,
                  'Total Pemasukan',
                  formatCurrency(totalIncome),
                  AppColors.success,
                ),

                _summaryRow(
                  context,
                  'Total Pengeluaran',
                  formatCurrency(totalExpense),
                  AppColors.error,
                ),

                const Divider(),

                _summaryRow(
                  context,
                  'Saldo Akhir',
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
            style: TextStyle(fontSize: 16, color: colors.onSurfaceVariant),
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
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Detail Transaksi - $title'),
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

                subtitle: Text(transaction.category),

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
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // NAMA BULAN
  // =========================================================

  String _getMonthName(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return names[month - 1];
  }
}
