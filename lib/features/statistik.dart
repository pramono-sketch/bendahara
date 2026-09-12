// lib/features/statistik.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/theme_helper.dart';
import '../helpers/scroll_reveal.dart'; // Import ScrollReveal

class StatistikPage extends ConsumerStatefulWidget {
  const StatistikPage({super.key});

  @override
  ConsumerState<StatistikPage> createState() => _StatistikPageState();
}

class _StatistikPageState extends ConsumerState<StatistikPage> {
  // ===== DATA FROM FIREBASE =====
  List<Student> _students = [];
  List<Transaction> _activeTransactions = [];
  List<ArchivedMonth> _archivedMonths = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDataFromFirebase();
  }

  // =============================================================
  // LOAD ALL DATA FROM FIREBASE
  // =============================================================
  Future<void> _loadDataFromFirebase() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Load students dari Firebase
      _students = await fetchAllStudents();

      // 2. Load active transactions dari Firebase
      _activeTransactions = await fetchAllTransactions();

      // 3. Load archived months dari Firebase
      _archivedMonths = await fetchArchivedMonths();

      // 4. Merge dengan data lokal yang belum tersinkron
      final Set<String> seenIds =
          _activeTransactions.map((t) => t.id).toSet();
      for (var t in localTransactions) {
        if (!seenIds.contains(t.id)) {
          _activeTransactions.add(t);
          seenIds.add(t.id);
        }
      }

      // 5. Fallback: jika Firebase kosong, gunakan sampleStudents
      if (_students.isEmpty) {
        _students = sampleStudents;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Fallback ke data lokal jika Firebase gagal
      _students = sampleStudents;
      _activeTransactions = List.from(localTransactions);
      _archivedMonths = [];

      setState(() {
        _isLoading = false;
        _errorMessage = 'Menggunakan data lokal (Firebase: $e)';
      });
    }
  }

  // =============================================================
  // 1. DATA PEMASUKAN PER BULAN (dari Firebase + lokal)
  // =============================================================
  Map<int, double> _getMonthlyIncome() {
    Map<int, double> monthly = {};
    final now = DateTime.now();

    // Dari arsip Firebase
    for (var arch in _archivedMonths) {
      if (arch.year == now.year) {
        monthly[arch.month] = (monthly[arch.month] ?? 0) + arch.totalIncome;
      }
    }

    // Dari transaksi aktif Firebase
    for (var t in _activeTransactions) {
      if (t.type == TransType.pemasukan && t.date.year == now.year) {
        monthly[t.date.month] = (monthly[t.date.month] ?? 0) + t.amount;
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
    final now = DateTime.now();

    for (var arch in _archivedMonths) {
      if (arch.year == now.year) {
        monthly[arch.month] = (monthly[arch.month] ?? 0) + arch.totalExpense;
      }
    }

    for (var t in _activeTransactions) {
      if (t.type == TransType.pengeluaran && t.date.year == now.year) {
        monthly[t.date.month] = (monthly[t.date.month] ?? 0) + t.amount;
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
    double total = _activeTransactions
        .where((t) => t.type == TransType.pemasukan)
        .fold(0.0, (sum, t) => sum + t.amount);

    for (var arch in _archivedMonths) {
      total += arch.totalIncome;
    }
    return total;
  }

  double _getTotalExpenseAllTime() {
    double total = _activeTransactions
        .where((t) => t.type == TransType.pengeluaran)
        .fold(0.0, (sum, t) => sum + t.amount);

    for (var arch in _archivedMonths) {
      total += arch.totalExpense;
    }
    return total;
  }

  // =============================================================
  // 4. DATA PEMBAYARAN SISWA PER KELAS (dari Firebase students)
  // =============================================================
  Map<String, Map<String, dynamic>> _getPaymentStatsByClass() {
    Map<String, Map<String, dynamic>> result = {};

    for (var s in _students.where((s) => s.isActive)) {
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

    // Bulan ini (dari transaksi aktif Firebase)
    double incomeThisMonth = 0;
    double expenseThisMonth = 0;
    for (var t in _activeTransactions) {
      if (t.date.month == currentMonth && t.date.year == currentYear) {
        if (t.type == TransType.pemasukan)
          incomeThisMonth += t.amount;
        else
          expenseThisMonth += t.amount;
      }
    }

    // Bulan lalu (dari arsip Firebase)
    int lastMonth = currentMonth - 1;
    int lastYear = currentYear;
    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear -= 1;
    }

    double incomeLastMonth = 0;
    double expenseLastMonth = 0;

    final arch = _archivedMonths.firstWhere(
      (a) => a.year == lastYear && a.month == lastMonth,
      orElse: () => ArchivedMonth(
        monthKey: '',
        year: lastYear,
        month: lastMonth,
        transactions: [],
        totalIncome: 0,
        totalExpense: 0,
      ),
    );

    incomeLastMonth = arch.totalIncome;
    expenseLastMonth = arch.totalExpense;

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
  // 6. TOP 5 SISWA DENGAN TUNGGAKAN TERBESAR (dari Firebase students)
  // =============================================================
  List<Map<String, dynamic>> _getTopOutstandingStudents() {
    List<Map<String, dynamic>> result = [];

    for (var s in _students.where((s) => s.isActive && s.hasOutstanding)) {
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

    result.sort((a, b) =>
        (b['outstanding'] as double).compareTo(a['outstanding'] as double));
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

      final arch = _archivedMonths.firstWhere(
        (a) => a.year == year && a.month == month,
        orElse: () => ArchivedMonth(
          monthKey: '',
          year: year,
          month: month,
          transactions: [],
          totalIncome: 0,
          totalExpense: 0,
        ),
      );

      income += arch.totalIncome;
      expense += arch.totalExpense;

      // Tambahkan transaksi aktif jika bulan ini
      if (month == now.month && year == now.year) {
        for (var t in _activeTransactions) {
          if (t.type == TransType.pemasukan)
            income += t.amount;
          else
            expense += t.amount;
        }
      }
      cumulative += (income - expense);
      balances.add(cumulative);
    }
    return balances;
  }

  // =============================================================
  // 8. PERSENTASE JENIS PEMBAYARAN (dari Firebase students)
  // =============================================================
  Map<String, double> _getPaymentTypeDistribution() {
    Map<String, double> distribution = {};

    for (var s in _students.where((s) => s.isActive)) {
      for (var p in s.payments) {
        if (p.status == PaymentStatus.lunas) {
          distribution[p.type] = (distribution[p.type] ?? 0) + p.amount;
        }
      }
    }

    return distribution;
  }

  // =============================================================
  // FORMAT CURRENCY
  // =============================================================
  String _formatCurrency(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // =============================================================
  // BUILD UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    // ===== LOADING STATE =====
    if (_isLoading) {
      return ThemeHelper.buildThemedBackground(
        themeMode,
        Scaffold(
          backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
          appBar: AppBar(
            title: const Text('Statistik Keuangan'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: ThemeHelper.getHeaderTextColor(themeMode, colors),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: accentColor),
                const SizedBox(height: 16),
                Text(
                  'Memuat data dari Firebase...',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
      if (month <= 0) {
        month += 12;
      }
      last6MonthLabels.add(monthLabels[month - 1]);
      double inc = monthlyIncome[month] ?? 0;
      double exp = monthlyExpense[month] ?? 0;
      last6Income.add(inc);
      last6Expense.add(exp);
    }

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          title: const Text('Statistik Keuangan'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: ThemeHelper.getHeaderTextColor(themeMode, colors),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDataFromFirebase,
              tooltip: 'Refresh Data',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== INFO STATUS DATA & INFO JUMLAH DATA =====
              ScrollReveal(
                delay: const Duration(milliseconds: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.error.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: colors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(fontSize: 12, color: colors.error),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.cloud_done, color: accentColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data: ${_students.length} siswa • ${_activeTransactions.length} transaksi aktif • '
                              '${_archivedMonths.fold(0, (sum, arch) => sum + arch.transactions.length)} arsip',
                              style: TextStyle(fontSize: 12, color: accentColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // -------------------------------------------------
              // 1. RINGKASAN TOTAL SALDO
              // -------------------------------------------------
              ScrollReveal(
                delay: const Duration(milliseconds: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeHelper.buildSectionHeader(context, 'Ringkasan Total Saldo', themeMode),
                    const SizedBox(height: 8),
                    ThemeHelper.buildSectionGroup(themeMode, [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem(
                              'Total Pemasukan',
                              'Rp ${_formatCurrency(totalIncome)}',
                              AppColors.success,
                              colors,
                            ),
                            _buildSummaryItem(
                              'Total Pengeluaran',
                              'Rp ${_formatCurrency(totalExpense)}',
                              AppColors.error,
                              colors,
                            ),
                            _buildSummaryItem(
                              'Total Saldo',
                              'Rp ${_formatCurrency(totalBalance)}',
                              totalBalance >= 0 ? accentColor : AppColors.error,
                              colors,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 2. PERBANDINGAN BULAN INI VS BULAN LALU
              // -------------------------------------------------
              ScrollReveal(
                delay: const Duration(milliseconds: 150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeHelper.buildSectionHeader(context, 'Perbandingan Bulan Ini vs Bulan Lalu', themeMode),
                    const SizedBox(height: 8),
                    ThemeHelper.buildSectionGroup(themeMode, [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildComparisonItem(
                              'Pemasukan',
                              comparison['incomeThisMonth'],
                              comparison['incomeLastMonth'],
                              AppColors.success,
                              colors,
                            ),
                            _buildComparisonItem(
                              'Pengeluaran',
                              comparison['expenseThisMonth'],
                              comparison['expenseLastMonth'],
                              AppColors.error,
                              colors,
                            ),
                            _buildComparisonItem(
                              'Saldo',
                              comparison['balanceThisMonth'],
                              comparison['balanceLastMonth'],
                              accentColor,
                              colors,
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 3. GRAFIK PEMASUKAN & PENGELUARAN 6 BULAN TERAKHIR
              // -------------------------------------------------
              ScrollReveal(
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeHelper.buildSectionHeader(context, 'Tren Pemasukan & Pengeluaran 6 Bulan Terakhir', themeMode),
                    const SizedBox(height: 8),
                    ThemeHelper.buildSectionGroup(themeMode, [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 200,
                          child: _buildIncomeExpenseChart(
                              last6MonthLabels, last6Income, last6Expense, themeMode, colors),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 4. SALDO KUMULATIF 6 BULAN TERAKHIR
              // -------------------------------------------------
              ScrollReveal(
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeHelper.buildSectionHeader(context, 'Saldo Kumulatif 6 Bulan Terakhir', themeMode),
                    const SizedBox(height: 8),
                    ThemeHelper.buildSectionGroup(themeMode, [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 150,
                          child: _buildBalanceChart(last6MonthLabels, last6Balances, themeMode, colors),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 5. STATISTIK PEMBAYARAN PER KELAS
              // -------------------------------------------------
              ScrollReveal(
                delay: const Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ThemeHelper.buildSectionHeader(context, 'Statistik Pembayaran per Kelas', themeMode),
                    const SizedBox(height: 8),
                    ThemeHelper.buildSectionGroup(themeMode, [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (paymentStats.isEmpty)
                               Padding(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    'Belum ada data siswa',
                                    style: TextStyle(color: colors.onSurfaceVariant),
                                  ),
                                ),
                              )
                            else
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
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              entry.key,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: colors.onSurface),
                                            ),
                                          ),
                                          Text(
                                            '$lunas / $total siswa lunas (${persen.toStringAsFixed(1)}%)',
                                            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: total > 0 ? lunas / total : 0,
                                        backgroundColor: colors.surfaceContainerHighest,
                                        color: persen >= 80
                                            ? AppColors.success
                                            : persen >= 50
                                                ? Colors.orange
                                                : AppColors.error,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Tagihan: Rp ${_formatCurrency(totalDue)}',
                                              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Terkumpul: Rp ${_formatCurrency(totalPaid)}',
                                              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        height: 12,
                                        color: ThemeHelper.dividerColor(themeMode),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 6. TOP 5 SISWA DENGAN TUNGGAKAN TERBESAR
              // -------------------------------------------------
              if (topOutstanding.isNotEmpty)
                ScrollReveal(
                  delay: const Duration(milliseconds: 350),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemeHelper.buildSectionHeader(context, 'Top 5 Siswa dengan Tunggakan Terbesar', themeMode),
                      const SizedBox(height: 8),
                      ThemeHelper.buildSectionGroup(themeMode, [
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  title: Text(data['name'] as String, style: TextStyle(color: colors.onSurface)),
                                  subtitle: Text(
                                      '${data['kelas']} • Total Tagihan: Rp ${_formatCurrency(data['totalDue'])}',
                                      style: TextStyle(color: colors.onSurfaceVariant)),
                                  trailing: Text(
                                    'Rp ${_formatCurrency(data['outstanding'])}',
                                    style: const TextStyle(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  dense: true,
                                );
                              }),
                            ],
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              const SizedBox(height: 16),

              // -------------------------------------------------
              // 7. DISTRIBUSI JENIS PEMBAYARAN (Pie Chart)
              // -------------------------------------------------
              if (paymentTypes.isNotEmpty)
                ScrollReveal(
                  delay: const Duration(milliseconds: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ThemeHelper.buildSectionHeader(context, 'Distribusi Jenis Pembayaran (Lunas)', themeMode),
                      const SizedBox(height: 8),
                      ThemeHelper.buildSectionGroup(themeMode, [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            height: 200,
                            child: _buildPieChart(paymentTypes, colors, themeMode),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // WIDGET PEMBANTU
  // =============================================================

  Widget _buildSummaryItem(String label, String value, Color color, ColorScheme colors) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
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

  Widget _buildComparisonItem(
      String label, double current, double previous, Color color, ColorScheme colors) {
    final diff = current - previous;
    final diffPercent = previous != 0 ? (diff / previous * 100) : 0;
    final isUp = diff >= 0;

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${_formatCurrency(current)}',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          diff == 0
              ? '= 0%'
              : '${isUp ? '▲' : '▼'} ${diffPercent.abs().toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 11,
            color: isUp ? AppColors.success : AppColors.error,
          ),
        ),
        Text(
          '(bln lalu: Rp ${_formatCurrency(previous)})',
          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  // =============================================================
  // GRAFIK: PEMASUKAN & PENGELUARAN (Bar Chart)
  // =============================================================
  Widget _buildIncomeExpenseChart(
      List<String> labels, List<double> incomes, List<double> expenses, AppThemeMode themeMode, ColorScheme colors) {
    final maxVal = [
      ...incomes,
      ...expenses,
    ].fold(0.0, (a, b) => a > b ? a : b);

    final double maxY = maxVal > 0 ? maxVal * 1.3 : 1;

    List<BarChartGroupData> barGroups = List.generate(labels.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: incomes[index],
            color: AppColors.success,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: expenses[index],
            color: AppColors.error,
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
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: ThemeHelper.dividerColor(themeMode),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
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
                    child: Text(labels[index],
                        style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
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
                  style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final isIncome = rodIndex == 0;
              final value = rod.toY;
              return BarTooltipItem(
                '${isIncome ? 'Pemasukan' : 'Pengeluaran'}: Rp ${_formatCurrency(value)}',
                TextStyle(
                  color: isIncome ? AppColors.success : AppColors.error,
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
  Widget _buildBalanceChart(List<String> labels, List<double> balances, AppThemeMode themeMode, ColorScheme colors) {
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    if (balances.isEmpty) {
      return Center(child: Text('Tidak ada data', style: TextStyle(color: colors.onSurfaceVariant)));
    }

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
            color: accentColor,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: accentColor.withOpacity(0.2),
            ),
          ),
        ],
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: ThemeHelper.dividerColor(themeMode),
              strokeWidth: 1,
              dashArray: [5, 5],
            );
          },
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
                    child: Text(labels[index],
                        style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant)),
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
                  style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  'Saldo: Rp ${_formatCurrency(spot.y)}',
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
  // GRAFIK: PIE CHART
  // =============================================================
  Widget _buildPieChart(Map<String, double> data, ColorScheme colors, AppThemeMode themeMode) {
    final total = data.values.fold(0.0, (sum, v) => sum + v);
    if (total == 0) return Center(child: Text('Tidak ada data', style: TextStyle(color: colors.onSurfaceVariant)));

    final colorsList = [
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
        'color': colorsList[colorIndex % colorsList.length],
      });
      colorIndex++;
    });

    slices.sort((a, b) =>
        (b['value'] as double).compareTo(a['value'] as double));

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomPaint(
            size: const Size(140, 140),
            painter: _PieChartPainter(slices, ThemeHelper.dividerColor(themeMode)),
          ),
        ),
        const SizedBox(width: 16),
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
                        style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
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
  final Color borderColor;

  _PieChartPainter(this.slices, this.borderColor);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final total =
        slices.fold(0.0, (sum, s) => sum + (s['value'] as double));

    double startAngle = -90 * 3.14159 / 180;

    for (var slice in slices) {
      final value = slice['value'] as double;
      final sweepAngle = (value / total) * 2 * 3.14159;
      final color = slice['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      canvas.drawArc(rect, startAngle, sweepAngle, true, paint);

      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}