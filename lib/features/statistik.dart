// features/statistik.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data.dart';

class StatistikPage extends StatelessWidget {
  const StatistikPage({super.key});

  // =============================================================
  // 1. DATA PEMASUKAN PER BULAN (dari arsip + transaksi aktif)
  // =============================================================
  Map<int, double> _getMonthlyIncome() {
    Map<int, double> monthly = {};

    // Dari arsip
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

    // Dari transaksi aktif
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

  // =============================================================
  // 2. DATA PENGELUARAN PER BULAN
  // =============================================================
  Map<int, double> _getMonthlyExpense() {
    Map<int, double> monthly = {};

    for (var entry in arsipTransaksi.entries) {
      final parts = entry.key.split('-');
      if (parts.length == 2) {
        final month = int.parse(parts[1]);
        for (var t in entry.value) {
          if (t.type == TransType.pengeluaran) {
            monthly[month] = (monthly[month] ?? 0) + t.amount;
          }
        }
      }
    }

    for (var t in dummyTransactions) {
      if (t.type == TransType.pengeluaran) {
        final month = t.date.month;
        monthly[month] = (monthly[month] ?? 0) + t.amount;
      }
    }

    for (int i = 1; i <= 12; i++) {
      monthly.putIfAbsent(i, () => 0);
    }
    return monthly;
  }

  // =============================================================
  // 3. TOTAL PEMASUKAN & PENGELUARAN ALL TIME
  // =============================================================
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

  // =============================================================
  // 4. DATA PEMBAYARAN SISWA PER KELAS
  // =============================================================
  Map<String, Map<String, dynamic>> _getPaymentStatsByClass() {
    Map<String, Map<String, dynamic>> result = {};

    for (var s in dummyStudents.where((s) => s.isActive)) {
      final kelas = s.kelas;
      if (!result.containsKey(kelas)) {
        result[kelas] = {
          'total': 0,
          'lunas': 0,
          'totalDue': 0.0,
          'totalPaid': 0.0,
        };
      }

      result[kelas]!['total'] = result[kelas]!['total'] + 1;
      if (!s.hasOutstanding) {
        result[kelas]!['lunas'] = result[kelas]!['lunas'] + 1;
      }
      result[kelas]!['totalDue'] = result[kelas]!['totalDue'] + s.totalDue;
      result[kelas]!['totalPaid'] = result[kelas]!['totalPaid'] + s.totalPaid;
    }

    // Hitung persentase
    for (var key in result.keys) {
      final total = result[key]!['total'] as int;
      final lunas = result[key]!['lunas'] as int;
      result[key]!['persentase'] = total > 0 ? (lunas / total * 100) : 0.0;
    }

    return result;
  }

  // =============================================================
  // 5. STATISTIK BULAN INI VS BULAN LALU
  // =============================================================
  Map<String, dynamic> _getMonthComparison() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Bulan ini
    double incomeThisMonth = 0;
    double expenseThisMonth = 0;
    for (var t in dummyTransactions) {
      if (t.date.month == currentMonth && t.date.year == currentYear) {
        if (t.type == TransType.pemasukan) incomeThisMonth += t.amount;
        else expenseThisMonth += t.amount;
      }
    }

    // Bulan lalu (dari arsip)
    int lastMonth = currentMonth - 1;
    int lastYear = currentYear;
    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear -= 1;
    }
    final lastMonthKey = '$lastYear-${lastMonth.toString().padLeft(2, '0')}';
    double incomeLastMonth = 0;
    double expenseLastMonth = 0;

    if (arsipTransaksi.containsKey(lastMonthKey)) {
      for (var t in arsipTransaksi[lastMonthKey]!) {
        if (t.type == TransType.pemasukan) incomeLastMonth += t.amount;
        else expenseLastMonth += t.amount;
      }
    }

    return {
      'incomeThisMonth': incomeThisMonth,
      'expenseThisMonth': expenseThisMonth,
      'incomeLastMonth': incomeLastMonth,
      'expenseLastMonth': expenseLastMonth,
      'balanceThisMonth': incomeThisMonth - expenseThisMonth,
      'balanceLastMonth': incomeLastMonth - expenseLastMonth,
    };
  }

  // =============================================================
  // 6. TOP 5 SISWA DENGAN TUNGGAKAN TERBESAR
  // =============================================================
  List<Map<String, dynamic>> _getTopOutstandingStudents() {
    List<Map<String, dynamic>> result = [];

    for (var s in dummyStudents.where((s) => s.isActive && s.hasOutstanding)) {
      final outstanding = s.remaining;
      result.add({
        'name': s.name,
        'kelas': s.kelas,
        'outstanding': outstanding,
        'totalDue': s.totalDue,
        'totalPaid': s.totalPaid,
        'paymentCount': s.payments.length,
      });
    }

    result.sort((a, b) => (b['outstanding'] as double).compareTo(a['outstanding'] as double));
    return result.take(5).toList();
  }

  // =============================================================
  // 7. TREN PEMBAYARAN 6 BULAN TERAKHIR (saldo kumulatif)
  // =============================================================
  List<double> _getLast6MonthsBalance() {
    final now = DateTime.now();
    List<double> balances = [];
    double cumulative = 0;

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      int year = now.year;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }

      double income = 0, expense = 0;
      final key = '$year-${month.toString().padLeft(2, '0')}';
      if (arsipTransaksi.containsKey(key)) {
        for (var t in arsipTransaksi[key]!) {
          if (t.type == TransType.pemasukan) income += t.amount;
          else expense += t.amount;
        }
      }
      // Tambahkan transaksi aktif jika bulan ini
      if (month == now.month && year == now.year) {
        for (var t in dummyTransactions) {
          if (t.type == TransType.pemasukan) income += t.amount;
          else expense += t.amount;
        }
      }
      cumulative += (income - expense);
      balances.add(cumulative);
    }
    return balances;
  }

  // =============================================================
  // 8. PERSENTASE JENIS PEMBAYARAN (untuk pie chart nantinya)
  // =============================================================
  Map<String, double> _getPaymentTypeDistribution() {
    Map<String, double> distribution = {};

    for (var s in dummyStudents.where((s) => s.isActive)) {
      for (var p in s.payments) {
        if (p.status == PaymentStatus.lunas) {
          distribution[p.type] = (distribution[p.type] ?? 0) + p.amount;
        }
      }
    }

    return distribution;
  }

  // =============================================================
  // BUILD UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final monthlyIncome = _getMonthlyIncome();
    final monthlyExpense = _getMonthlyExpense();

    final totalIncome = _getTotalIncomeAllTime();
    final totalExpense = _getTotalExpenseAllTime();
    final totalBalance = totalIncome - totalExpense;

    final paymentStats = _getPaymentStatsByClass();
    final comparison = _getMonthComparison();
    final topOutstanding = _getTopOutstandingStudents();
    final last6Balances = _getLast6MonthsBalance();
    final paymentTypes = _getPaymentTypeDistribution();

    // Label bulan
    List<String> monthLabels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    // Data grafik 6 bulan terakhir untuk income
    final now = DateTime.now();
    List<String> last6MonthLabels = [];
    List<double> last6Income = [];
    List<double> last6Expense = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;
      int year = now.year;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }
      last6MonthLabels.add(monthLabels[month - 1]);
      // Ambil income dan expense
      double inc = monthlyIncome[month] ?? 0;
      double exp = monthlyExpense[month] ?? 0;
      // Jika bulan ini, ambil dari dummyTransactions juga
      if (month == now.month && year == now.year) {
        // sudah tercakup di monthlyIncome
      }
      last6Income.add(inc);
      last6Expense.add(exp);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Keuangan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // -------------------------------------------------
            // 1. RINGKASAN TOTAL SALDO
            // -------------------------------------------------
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Pemasukan',
                          'Rp ${formatCurrency(totalIncome)}',
                          Colors.green,
                        ),
                        _buildSummaryItem(
                          'Total Pengeluaran',
                          'Rp ${formatCurrency(totalExpense)}',
                          Colors.red,
                        ),
                        _buildSummaryItem(
                          'Total Saldo',
                          'Rp ${formatCurrency(totalBalance)}',
                          totalBalance >= 0 ? AppColors.primary : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 2. PERBANDINGAN BULAN INI VS BULAN LALU
            // -------------------------------------------------
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Perbandingan Bulan Ini vs Bulan Lalu',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildComparisonItem(
                          'Pemasukan',
                          comparison['incomeThisMonth'],
                          comparison['incomeLastMonth'],
                          Colors.green,
                        ),
                        _buildComparisonItem(
                          'Pengeluaran',
                          comparison['expenseThisMonth'],
                          comparison['expenseLastMonth'],
                          Colors.red,
                        ),
                        _buildComparisonItem(
                          'Saldo',
                          comparison['balanceThisMonth'],
                          comparison['balanceLastMonth'],
                          AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 3. GRAFIK PEMASUKAN & PENGELUARAN 6 BULAN TERAKHIR
            // -------------------------------------------------
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Pemasukan & Pengeluaran 6 Bulan Terakhir',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: _buildIncomeExpenseChart(last6MonthLabels, last6Income, last6Expense),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 4. SALDO KUMULATIF 6 BULAN TERAKHIR
            // -------------------------------------------------
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Kumulatif 6 Bulan Terakhir',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 150,
                      child: _buildBalanceChart(last6MonthLabels, last6Balances),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 5. STATISTIK PEMBAYARAN PER KELAS (DIPERBAIKI)
            // -------------------------------------------------
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistik Pembayaran per Kelas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ...paymentStats.entries.map((entry) {
                      final data = entry.value;
                      final total = data['total'] as int;
                      final lunas = data['lunas'] as int;
                      final persen = data['persentase'] as double;
                      final totalDue = data['totalDue'] as double;
                      final totalPaid = data['totalPaid'] as double;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Baris kelas dan persentase
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  '$lunas / $total siswa lunas (${persen.toStringAsFixed(1)}%)',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: total > 0 ? lunas / total : 0,
                              backgroundColor: Colors.grey.shade200,
                              color: persen >= 80 ? Colors.green : persen >= 50 ? Colors.orange : Colors.red,
                            ),
                            const SizedBox(height: 4),
                            // Baris total tagihan dan terkumpul (dengan Expanded agar tidak overflow)
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Tagihan: Rp ${formatCurrency(totalDue)}',
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Terkumpul: Rp ${formatCurrency(totalPaid)}',
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 6. TOP 5 SISWA DENGAN TUNGGAKAN TERBESAR
            // -------------------------------------------------
            if (topOutstanding.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Top 5 Siswa dengan Tunggakan Terbesar',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      ...topOutstanding.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.error.withOpacity(0.2),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                          title: Text(data['name'] as String),
                          subtitle: Text('${data['kelas']} • Total Tagihan: Rp ${formatCurrency(data['totalDue'])}'),
                          trailing: Text(
                            'Rp ${formatCurrency(data['outstanding'])}',
                            style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                          ),
                          dense: true,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // -------------------------------------------------
            // 7. DISTRIBUSI JENIS PEMBAYARAN (Pie Chart sederhana)
            // -------------------------------------------------
            if (paymentTypes.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribusi Jenis Pembayaran (Lunas)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _buildPieChart(paymentTypes),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // WIDGET PEMBANTU
  // =============================================================

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildComparisonItem(String label, double current, double previous, Color color) {
    final diff = current - previous;
    final diffPercent = previous != 0 ? (diff / previous * 100) : 0;
    final isUp = diff >= 0;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${formatCurrency(current)}',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          diff == 0
              ? '= 0%'
              : '${isUp ? '▲' : '▼'} ${diffPercent.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: isUp ? Colors.green : Colors.red,
          ),
        ),
        Text(
          '(bln lalu: Rp ${formatCurrency(previous)})',
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // =============================================================
  // GRAFIK: PEMASUKAN & PENGELUARAN (Bar Chart dengan fl_chart)
  // =============================================================
  Widget _buildIncomeExpenseChart(List<String> labels, List<double> incomes, List<double> expenses) {
    final maxVal = [
      ...incomes,
      ...expenses,
    ].reduce((a, b) => a > b ? a : b);

    final double maxY = maxVal > 0 ? maxVal * 1.3 : 1;

    List<BarChartGroupData> barGroups = List.generate(labels.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: incomes[index],
            color: Colors.green,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expenses[index],
            color: Colors.red,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
        barsSpace: 4,
      );
    });

    return BarChart(
      BarChartData(
        maxY: maxY,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 5,
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
                    child: Text(labels[index], style: const TextStyle(fontSize: 10)),
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
              final isIncome = rodIndex == 0;
              final value = rod.toY;
              return BarTooltipItem(
                '${isIncome ? 'Pemasukan' : 'Pengeluaran'}: Rp ${formatCurrency(value)}',
                TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
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

  // =============================================================
  // GRAFIK: SALDO KUMULATIF (Line Chart)
  // =============================================================
  Widget _buildBalanceChart(List<String> labels, List<double> balances) {
    final maxVal = balances.reduce((a, b) => a > b ? a : b);
    final minVal = balances.reduce((a, b) => a < b ? a : b);
    final double maxY = maxVal > 0 ? maxVal * 1.2 : 100;
    final double minY = minVal < 0 ? minVal * 1.2 : 0;

    List<FlSpot> spots = List.generate(balances.length, (index) {
      return FlSpot(index.toDouble(), balances[index]);
    });

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
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
                    child: Text(labels[index], style: const TextStyle(fontSize: 10)),
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
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Saldo: Rp ${formatCurrency(spot.y)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  // =============================================================
  // GRAFIK: PIE CHART SEDERHANA (menggunakan Container + CustomPaint)
  // =============================================================
  Widget _buildPieChart(Map<String, double> data) {
    final total = data.values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return const Center(child: Text('Tidak ada data'));

    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.brown,
    ];

    List<Map<String, dynamic>> slices = [];
    int colorIndex = 0;
    data.forEach((key, value) {
      slices.add({
        'label': key,
        'value': value,
        'percentage': (value / total * 100),
        'color': colors[colorIndex % colors.length],
      });
      colorIndex++;
    });

    // Urutkan dari yang terbesar
    slices.sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    return Row(
      children: [
        // Pie chart sederhana dengan CustomPaint
        Expanded(
          flex: 1,
          child: CustomPaint(
            size: const Size(140, 140),
            painter: _PieChartPainter(slices),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.map((slice) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: slice['color'] as Color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${slice['label']} (${(slice['percentage'] as double).toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// PIE CHART PAINTER
// =============================================================
class _PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> slices;

  _PieChartPainter(this.slices);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total = slices.fold(0.0, (sum, s) => sum + (s['value'] as double));

    double startAngle = -90 * 3.14159 / 180; // mulai dari atas

    for (var slice in slices) {
      final value = slice['value'] as double;
      final sweepAngle = (value / total) * 2 * 3.14159;
      final color = slice['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      // Gambar garis tepi putih tipis
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}