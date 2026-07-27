// navigation/dashboard.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data.dart';
import '../addon/aksi.dart';
import '../templates/sound_helper.dart'; // 🔥 import

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // =========================================================
  // HELPER DATA: Pemasukan per bulan dari arsip + transaksi aktif
  // =========================================================
  Map<int, double> _getMonthlyIncome() {
    Map<int, double> monthly = {};

    for (var entry in arsipTransaksi.entries) {
      final parts = entry.key.split('-');
      if (parts.length == 2) {
        final month = int.parse(parts[1]);
        for (var t in entry.value) {
          if (t.type == TransType.pemasukan) {
            monthly[month] = (monthly[month] ?? 0) + t.amount;
          }
        }
      }
    }

    for (var t in dummyTransactions) {
      if (t.type == TransType.pemasukan) {
        final month = t.date.month;
        monthly[month] = (monthly[month] ?? 0) + t.amount;
      }
    }

    for (int i = 1; i <= 12; i++) {
      monthly.putIfAbsent(i, () => 0);
    }

    return monthly;
  }

  double _getCurrentMonthIncome() {
    final now = DateTime.now();
    final month = now.month;
    double total = 0;

    for (var t in dummyTransactions) {
      if (t.type == TransType.pemasukan && t.date.month == month) {
        total += t.amount;
      }
    }

    return total;
  }

  double _getCurrentMonthExpense() {
    final now = DateTime.now();
    final month = now.month;
    double total = 0;

    for (var t in dummyTransactions) {
      if (t.type == TransType.pengeluaran && t.date.month == month) {
        total += t.amount;
      }
    }

    return total;
  }

  double _getTotalIncomeAllTime() {
    double total = 0;

    for (var list in arsipTransaksi.values) {
      for (var t in list) {
        if (t.type == TransType.pemasukan) total += t.amount;
      }
    }

    for (var t in dummyTransactions) {
      if (t.type == TransType.pemasukan) total += t.amount;
    }

    return total;
  }

  double _getTotalExpenseAllTime() {
    double total = 0;

    for (var list in arsipTransaksi.values) {
      for (var t in list) {
        if (t.type == TransType.pengeluaran) total += t.amount;
      }
    }

    for (var t in dummyTransactions) {
      if (t.type == TransType.pengeluaran) total += t.amount;
    }

    return total;
  }

  String _generateAIInsight() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    final totalIncome = _getCurrentMonthIncome();
    final totalExpense = _getCurrentMonthExpense();
    final balance = totalIncome - totalExpense;

    int lastMonth = currentMonth - 1;
    int lastYear = currentYear;
    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear -= 1;
    }

    final lastMonthKey = '$lastYear-${lastMonth.toString().padLeft(2, '0')}';
    double lastMonthIncome = 0;

    if (arsipTransaksi.containsKey(lastMonthKey)) {
      for (var t in arsipTransaksi[lastMonthKey]!) {
        if (t.type == TransType.pemasukan) {
          lastMonthIncome += t.amount;
        }
      }
    }

    final activeStudents = dummyStudents.where((s) => s.isActive).toList();
    final paidStudents = activeStudents.where((s) => !s.hasOutstanding).length;
    final totalStudents = activeStudents.length;
    final persentaseLunas = totalStudents > 0
        ? (paidStudents / totalStudents * 100)
        : 0;

    List<String> insights = [];

    if (persentaseLunas >= 80) {
      insights.add('✅ ${persentaseLunas.toStringAsFixed(0)}% siswa sudah lunas. Bagus!');
    } else if (persentaseLunas >= 50) {
      insights.add('📊 ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. Masih ada PR menagih sisanya.');
    } else {
      insights.add('⚠️ Hanya ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. Perlu strategi penagihan lebih agresif.');
    }

    if (lastMonthIncome > 0 && totalIncome > 0) {
      final selisih = totalIncome - lastMonthIncome;
      final persenChange = (selisih / lastMonthIncome * 100);

      if (persenChange > 0) {
        insights.add('📈 Pemasukan bulan ini naik ${persenChange.toStringAsFixed(1)}% dibanding bulan lalu.');
      } else if (persenChange < 0) {
        insights.add('📉 Pemasukan bulan ini turun ${persenChange.abs().toStringAsFixed(1)}% dibanding bulan lalu.');
      } else {
        insights.add('➖ Pemasukan bulan ini stabil dibanding bulan lalu.');
      }
    } else if (totalIncome > 0 && lastMonthIncome == 0) {
      insights.add('💰 Bulan ini mulai ada pemasukan baru.');
    }

    if (balance > 0) {
      insights.add('💚 Saldo positif: Rp ${formatCurrency(balance)}. Keuangan sehat.');
    } else if (balance < 0) {
      insights.add('🔴 Saldo negatif: Rp ${formatCurrency(balance)}. Perhatikan pengeluaran.');
    } else {
      insights.add('⚖️ Saldo impas.');
    }

    return insights.join(' • ');
  }

  @override
  void initState() {
    super.initState();
    AksiHelper.setRefreshCallback(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    AksiHelper.setRefreshCallback(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalIncome = _getCurrentMonthIncome();
    final totalExpense = _getCurrentMonthExpense();
    final balance = totalIncome - totalExpense;

    final totalIncomeAll = _getTotalIncomeAllTime();
    final totalExpenseAll = _getTotalExpenseAllTime();
    final balanceAll = totalIncomeAll - totalExpenseAll;

    final activeStudents = dummyStudents.where((s) => s.isActive).toList();
    final paidStudents = activeStudents.where((s) => !s.hasOutstanding).length;
    final totalStudents = activeStudents.length;

    Map<int, double> monthlyIncome = _getMonthlyIncome();
    List<String> monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    final now = DateTime.now();
    final List<String> last6Months = [];
    final List<double> last6Values = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      if (month <= 0) month += 12;
      last6Months.add(monthLabels[month - 1]);
      last6Values.add(monthlyIncome[month] ?? 0);
    }

    final aiInsight = _generateAIInsight();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eduvest Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset transaksi bulan ini (testing)',
            onPressed: () {
              SoundHelper().playClick(); // 🔥
              _showResetDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Sekolah',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp: ${formatCurrency(balance)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? AppColors.primary : AppColors.error,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pemasukan',
                    'Rp: ${formatCurrency(totalIncome)}',
                    Icons.arrow_downward,
                    AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pengeluaran',
                    'Rp: ${formatCurrency(totalExpense)}',
                    Icons.arrow_upward,
                    AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Saldo Sekolah',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rp: ${formatCurrency(balanceAll)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: balanceAll >= 0 ? AppColors.primary : AppColors.error,
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Pembayaran',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 140,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildBarChart(last6Months, last6Values),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Siswa Lunas: $paidStudents / $totalStudents',
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: totalStudents > 0
                                      ? paidStudents / totalStudents
                                      : 0,
                                  backgroundColor: Colors.grey.shade200,
                                  color: AppColors.success,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: AppColors.primary.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        aiInsight,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Transaksi Bulan Ini'),
        content: const Text(
          'Semua transaksi pemasukan dan pengeluaran bulan ini akan dipindahkan ke arsip laporan. Saldo akan kembali ke 0. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick(); // 🔥
              Navigator.pop(ctx);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              SoundHelper().playClick(); // 🔥
              resetMonthlyTransactions();
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaksi bulan ini telah direset!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<String> labels, List<double> values) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final double maxY = maxVal > 0 ? maxVal : 1;

    List<BarChartGroupData> barGroups = List.generate(labels.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: values[index],
            color: AppColors.primary,
            width: 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      labels[index],
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${(value / 1000).toInt()}k',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Rp ${formatCurrency(rod.toY)}',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}