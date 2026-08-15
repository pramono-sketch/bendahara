// navigation/laporan.dart
import 'package:flutter/material.dart';

import '../data.dart';
import '../templates/sound_helper.dart'; // 🔥 import
import '../constants/appearance.dart'; // 🔥 import warna

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    List<Transaction> allTransactions = [];
    for (var list in arsipTransaksi.values) {
      allTransactions.addAll(list);
    }
    allTransactions.addAll(dummyTransactions);

    Map<String, List<Transaction>> grouped = {};
    for (var t in allTransactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(t);
    }

    final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                SoundHelper().playClick(); // 🔥
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export $value dalam pengembangan')),
                );
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'PDF', child: Text('Export PDF')),
                const PopupMenuItem(value: 'Excel', child: Text('Export Excel')),
              ],
              icon: const Icon(Icons.download),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bulanan'),
              Tab(text: 'Tahunan'),
              Tab(text: 'Semua'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMonthlyReport(grouped, keys),
            _buildYearlyReport(grouped, keys),
            _buildAllReport(grouped, keys),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyReport(Map<String, List<Transaction>> grouped, List<String> keys) {
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final list = grouped[key]!;
        final totalIncome = list.where((t) => t.type == TransType.pemasukan)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final totalExpense = list.where((t) => t.type == TransType.pengeluaran)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final net = totalIncome - totalExpense;

        final parts = key.split('-');
        final monthName = _getMonthName(int.parse(parts[1]));
        final year = parts[0];
        final label = '$monthName $year';

        return Card(
          child: ListTile(
            title: Text(label),
            subtitle: Text(
              'Pemasukan: Rp ${formatCurrency(totalIncome)} • Pengeluaran: Rp ${formatCurrency(totalExpense)}',
            ),
            trailing: Text(
              'Rp ${formatCurrency(net)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: net >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
            onTap: () {
              SoundHelper().playClick(); // 🔥
              _showDetailDialog(context, label, list);
            },
          ),
        );
      },
    );
  }

  Widget _buildYearlyReport(Map<String, List<Transaction>> grouped, List<String> keys) {
    Map<String, List<Transaction>> yearly = {};
    for (var key in keys) {
      final year = key.split('-')[0];
      yearly.putIfAbsent(year, () => []);
      yearly[year]!.addAll(grouped[key]!);
    }
    final yearKeys = yearly.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      itemCount: yearKeys.length,
      itemBuilder: (context, index) {
        final year = yearKeys[index];
        final list = yearly[year]!;
        final totalIncome = list.where((t) => t.type == TransType.pemasukan)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final totalExpense = list.where((t) => t.type == TransType.pengeluaran)
            .fold<double>(0, (sum, t) => sum + t.amount);
        final net = totalIncome - totalExpense;

        return Card(
          child: ListTile(
            title: Text('Tahun $year'),
            subtitle: Text(
              'Pemasukan: Rp ${formatCurrency(totalIncome)} • Pengeluaran: Rp ${formatCurrency(totalExpense)}',
            ),
            trailing: Text(
              'Rp ${formatCurrency(net)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: net >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllReport(Map<String, List<Transaction>> grouped, List<String> keys) {
    List<Transaction> all = [];
    for (var list in grouped.values) {
      all.addAll(list);
    }
    final totalIncome = all.where((t) => t.type == TransType.pemasukan)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final totalExpense = all.where((t) => t.type == TransType.pengeluaran)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final net = totalIncome - totalExpense;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total Keseluruhan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _summaryRow('Total Pemasukan', formatCurrency(totalIncome), AppColors.success),
              _summaryRow('Total Pengeluaran', formatCurrency(totalExpense), AppColors.error),
              const Divider(),
              _summaryRow('Saldo Akhir', formatCurrency(net), net >= 0 ? AppColors.primary : AppColors.error),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            'Rp $value',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(BuildContext context, String title, List<Transaction> list) {
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
              final t = list[index];
              return ListTile(
                dense: true,
                title: Text(t.description),
                subtitle: Text(t.category),
                trailing: Text(
                  'Rp ${formatCurrency(t.amount)}',
                  style: TextStyle(
                    color: t.type == TransType.pemasukan ? AppColors.success : AppColors.error,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick(); // 🔥
              Navigator.pop(ctx);
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return names[month - 1];
  }
}