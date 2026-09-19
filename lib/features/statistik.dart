// lib/features/statistik.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/theme_helper.dart';
import '../helpers/scroll_reveal.dart';

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
  // HELPER: AMBIL DATA SATU BULAN
  // =============================================================
  Map<String, double> _getMonthIncomeExpense(int year, int month) {
    double income = 0;
    double expense = 0;

    // Data arsip
    for (var arch in _archivedMonths) {
      if (arch.year == year && arch.month == month) {
        income += arch.totalIncome;
        expense += arch.totalExpense;
      }
    }

    // Data transaksi aktif
    for (var t in _activeTransactions) {
      if (t.date.year == year && t.date.month == month) {
        if (t.type == TransType.pemasukan) {
          income += t.amount;
        } else if (t.type == TransType.pengeluaran) {
          expense += t.amount;
        }
      }
    }

    return {
      'income': income,
      'expense': expense,
    };
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
  // 4. DATA PEMBAYARAN SISWA PER KELAS
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

      result[kelas]!['total'] =
          result[kelas]!['total'] + 1;

      if (!s.hasOutstanding) {
        result[kelas]!['lunas'] =
            result[kelas]!['lunas'] + 1;
      }

      result[kelas]!['totalDue'] =
          result[kelas]!['totalDue'] + s.totalDue;

      result[kelas]!['totalPaid'] =
          result[kelas]!['totalPaid'] + s.totalPaid;
    }

    // Hitung persentase
    for (var key in result.keys) {
      final total = result[key]!['total'] as int;
      final lunas = result[key]!['lunas'] as int;

      result[key]!['persentase'] =
          total > 0 ? (lunas / total * 100) : 0.0;
    }

    return result;
  }

  // =============================================================
  // 5. STATISTIK BULAN INI VS BULAN LALU
  // =============================================================
  Map<String, dynamic> _getMonthComparison() {
    final now = DateTime.now();

    final currentMonthData =
        _getMonthIncomeExpense(now.year, now.month);

    double incomeThisMonth =
        currentMonthData['income'] ?? 0;

    double expenseThisMonth =
        currentMonthData['expense'] ?? 0;

    // Bulan lalu
    int lastMonth = now.month - 1;
    int lastYear = now.year;

    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear -= 1;
    }

    final lastMonthData =
        _getMonthIncomeExpense(lastYear, lastMonth);

    final incomeLastMonth =
        lastMonthData['income'] ?? 0;

    final expenseLastMonth =
        lastMonthData['expense'] ?? 0;

    return {
      'incomeThisMonth': incomeThisMonth,
      'expenseThisMonth': expenseThisMonth,
      'incomeLastMonth': incomeLastMonth,
      'expenseLastMonth': expenseLastMonth,
      'balanceThisMonth':
          incomeThisMonth - expenseThisMonth,
      'balanceLastMonth':
          incomeLastMonth - expenseLastMonth,
    };
  }

  // =============================================================
  // 6. TOP 5 SISWA DENGAN TUNGGAKAN TERBESAR
  // =============================================================
  List<Map<String, dynamic>> _getTopOutstandingStudents() {
    List<Map<String, dynamic>> result = [];

    for (var s in _students.where(
      (s) => s.isActive && s.hasOutstanding,
    )) {
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

    result.sort(
      (a, b) => (b['outstanding'] as double)
          .compareTo(a['outstanding'] as double),
    );

    return result.take(5).toList();
  }

  // =============================================================
  // 7. TREN SALDO KUMULATIF 6 BULAN TERAKHIR
  // =============================================================
  List<double> _getLast6MonthsBalance() {
    final now = DateTime.now();

    List<double> balances = [];
    double cumulative = 0;

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(
        now.year,
        now.month - i,
        1,
      );

      final year = targetDate.year;
      final month = targetDate.month;

      final data = _getMonthIncomeExpense(
        year,
        month,
      );

      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;

      cumulative += income - expense;
      balances.add(cumulative);
    }

    return balances;
  }

  // =============================================================
  // 8. PERSENTASE JENIS PEMBAYARAN
  // =============================================================
  Map<String, double> _getPaymentTypeDistribution() {
    Map<String, double> distribution = {};

    for (var s in _students.where((s) => s.isActive)) {
      for (var p in s.payments) {
        if (p.status == PaymentStatus.lunas) {
          distribution[p.type] =
              (distribution[p.type] ?? 0) + p.amount;
        }
      }
    }

    return distribution;
  }

  // =============================================================
  // FORMAT CURRENCY FULL
  // =============================================================
  String _formatCurrency(double amount) {
    return amount
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  // =============================================================
  // FORMAT CURRENCY RINGKAS UNTUK GRAFIK
  // =============================================================
  String _formatCompactCurrency(double amount) {
    final absAmount = amount.abs();

    String result;

    if (absAmount >= 1000000000) {
      result = _formatCompactNumber(
        amount / 1000000000,
        'M',
      );
    } else if (absAmount >= 1000000) {
      result = _formatCompactNumber(
        amount / 1000000,
        'jt',
      );
    } else if (absAmount >= 1000) {
      result = _formatCompactNumber(
        amount / 1000,
        'rb',
      );
    } else {
      result = amount.toInt().toString();
    }

    return result;
  }

  // =============================================================
  // HELPER FORMAT ANGKA KOMPAK
  // =============================================================
  String _formatCompactNumber(
    double value,
    String suffix,
  ) {
    final absValue = value.abs();

    String number;

    if (absValue >= 100) {
      number = value.toStringAsFixed(0);
    } else if (absValue >= 10) {
      number = value.toStringAsFixed(1);
    } else {
      number = value.toStringAsFixed(1);
    }

    // Hapus .0
    if (number.endsWith('.0')) {
      number = number.substring(
        0,
        number.length - 2,
      );
    }

    // Ganti titik desimal menjadi koma
    number = number.replaceAll('.', ',');

    return '$number $suffix';
  }

  // =============================================================
  // NICE INTERVAL UNTUK SUMBU Y
  // =============================================================
  double _niceInterval(
    double range,
    int targetSteps,
  ) {
    if (range <= 0) {
      return 1;
    }

    final rawInterval =
        range / targetSteps;

    final exponent = math.pow(
      10,
      (math.log(rawInterval) / math.ln10).floor(),
    ).toDouble();

    final fraction =
        rawInterval / exponent;

    double niceFraction;

    if (fraction <= 1) {
      niceFraction = 1;
    } else if (fraction <= 2) {
      niceFraction = 2;
    } else if (fraction <= 5) {
      niceFraction = 5;
    } else {
      niceFraction = 10;
    }

    return niceFraction * exponent;
  }

  // =============================================================
  // BUILD UI
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors =
        Theme.of(context).colorScheme;

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    // ===== LOADING STATE =====
    if (_isLoading) {
      return ThemeHelper.buildThemedBackground(
        themeMode,
        Scaffold(
          backgroundColor:
              ThemeHelper.getScaffoldBackgroundColor(
            themeMode,
            colors,
          ),
          appBar: AppBar(
            title:
                const Text('Statistik Keuangan'),
            backgroundColor:
                Colors.transparent,
            elevation: 0,
            foregroundColor:
                ThemeHelper.getHeaderTextColor(
              themeMode,
              colors,
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: accentColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Memuat data dari Firebase...',
                  style: TextStyle(
                    color:
                        colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }


    final totalIncome =
        _getTotalIncomeAllTime();

    final totalExpense =
        _getTotalExpenseAllTime();

    final totalBalance =
        totalIncome - totalExpense;

    final paymentStats =
        _getPaymentStatsByClass();

    final comparison =
        _getMonthComparison();

    final topOutstanding =
        _getTopOutstandingStudents();

    final last6Balances =
        _getLast6MonthsBalance();

    final paymentTypes =
        _getPaymentTypeDistribution();

    // Label bulan
    const List<String> monthLabels = [
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

    // Data grafik 6 bulan terakhir
    final now = DateTime.now();

    List<String> last6MonthLabels = [];
    List<double> last6Income = [];
    List<double> last6Expense = [];

    for (int i = 5; i >= 0; i--) {
      final targetDate = DateTime(
        now.year,
        now.month - i,
        1,
      );

      final year =
          targetDate.year;

      final month =
          targetDate.month;

      final monthData =
          _getMonthIncomeExpense(
        year,
        month,
      );

      last6MonthLabels.add(
        monthLabels[month - 1],
      );

      last6Income.add(
        monthData['income'] ?? 0,
      );

      last6Expense.add(
        monthData['expense'] ?? 0,
      );
    }

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor:
            ThemeHelper.getScaffoldBackgroundColor(
          themeMode,
          colors,
        ),
        appBar: AppBar(
          title:
              const Text('Statistik Keuangan'),
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          foregroundColor:
              ThemeHelper.getHeaderTextColor(
            themeMode,
            colors,
          ),
          actions: [
            IconButton(
              icon:
                  const Icon(Icons.refresh),
              onPressed:
                  _loadDataFromFirebase,
              tooltip:
                  'Refresh Data',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // =================================================
              // INFO STATUS DATA
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 50,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        margin:
                            const EdgeInsets.only(
                          bottom: 12,
                        ),
                        padding:
                            const EdgeInsets.all(
                          12,
                        ),
                        decoration:
                            BoxDecoration(
                          color: colors
                              .errorContainer
                              .withOpacity(0.3),
                          borderRadius:
                              BorderRadius.circular(
                            8,
                          ),
                          border:
                              Border.all(
                            color: colors
                                .error
                                .withOpacity(
                              0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons
                                  .warning_amber,
                              color:
                                  colors.error,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style:
                                    TextStyle(
                                  fontSize:
                                      12,
                                  color:
                                      colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Container(
                      margin:
                          const EdgeInsets.only(
                        bottom: 12,
                      ),
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration:
                          BoxDecoration(
                        color: accentColor
                            .withOpacity(
                          0.1,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_done,
                            color:
                                accentColor,
                            size: 18,
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child: Text(
                              'Data: ${_students.length} siswa • '
                              '${_activeTransactions.length} transaksi aktif • '
                              '${_archivedMonths.fold(
                                0,
                                (sum, arch) =>
                                    sum +
                                    arch.transactions.length,
                              )} arsip',
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                                color:
                                    accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // =================================================
              // 1. RINGKASAN TOTAL SALDO
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 100,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ThemeHelper
                        .buildSectionHeader(
                      context,
                      'Ringkasan Total Saldo',
                      themeMode,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ThemeHelper
                        .buildSectionGroup(
                      themeMode,
                      [
                        Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceAround,
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
                                totalBalance >= 0
                                    ? accentColor
                                    : AppColors.error,
                                colors,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 2. PERBANDINGAN BULAN INI VS BULAN LALU
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 150,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ThemeHelper
                        .buildSectionHeader(
                      context,
                      'Perbandingan Bulan Ini vs Bulan Lalu',
                      themeMode,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ThemeHelper
                        .buildSectionGroup(
                      themeMode,
                      [
                        Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceAround,
                            children: [
                              _buildComparisonItem(
                                'Pemasukan',
                                comparison[
                                    'incomeThisMonth'],
                                comparison[
                                    'incomeLastMonth'],
                                AppColors.success,
                                colors,
                              ),
                              _buildComparisonItem(
                                'Pengeluaran',
                                comparison[
                                    'expenseThisMonth'],
                                comparison[
                                    'expenseLastMonth'],
                                AppColors.error,
                                colors,
                              ),
                              _buildComparisonItem(
                                'Saldo',
                                comparison[
                                    'balanceThisMonth'],
                                comparison[
                                    'balanceLastMonth'],
                                accentColor,
                                colors,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 3. TREN PEMASUKAN & PENGELUARAN 6 BULAN
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 200,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ThemeHelper
                        .buildSectionHeader(
                      context,
                      'Tren Pemasukan & Pengeluaran 6 Bulan Terakhir',
                      themeMode,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ThemeHelper
                        .buildSectionGroup(
                      themeMode,
                      [
                        Padding(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          child: SizedBox(
                            height: 220,
                            width: double.infinity,
                            child:
                                _buildIncomeExpenseChart(
                              last6MonthLabels,
                              last6Income,
                              last6Expense,
                              themeMode,
                              colors,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 4. SALDO KUMULATIF 6 BULAN
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 250,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ThemeHelper
                        .buildSectionHeader(
                      context,
                      'Saldo Kumulatif 6 Bulan Terakhir',
                      themeMode,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ThemeHelper
                        .buildSectionGroup(
                      themeMode,
                      [
                        Padding(
                          padding:
                              const EdgeInsets.all(
                            12,
                          ),
                          child: SizedBox(
                            height: 190,
                            width: double.infinity,
                            child:
                                _buildBalanceChart(
                              last6MonthLabels,
                              last6Balances,
                              themeMode,
                              colors,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 5. STATISTIK PEMBAYARAN PER KELAS
              // =================================================
              ScrollReveal(
                delay:
                    const Duration(
                  milliseconds: 300,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ThemeHelper
                        .buildSectionHeader(
                      context,
                      'Statistik Pembayaran per Kelas',
                      themeMode,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    ThemeHelper
                        .buildSectionGroup(
                      themeMode,
                      [
                        Padding(
                          padding:
                              const EdgeInsets.all(
                            16,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              if (paymentStats
                                  .isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 20,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Belum ada data siswa',
                                      style:
                                          TextStyle(
                                        color: colors
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ...paymentStats
                                    .entries
                                    .map(
                                  (entry) {
                                    final data =
                                        entry.value;

                                    final total =
                                        data[
                                                'total']
                                            as int;

                                    final lunas =
                                        data[
                                                'lunas']
                                            as int;

                                    final persen =
                                        data[
                                                'persentase']
                                            as double;

                                    final totalDue =
                                        data[
                                                'totalDue']
                                            as double;

                                    final totalPaid =
                                        data[
                                                'totalPaid']
                                            as double;

                                    return Padding(
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        vertical: 6,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    Text(
                                                  entry
                                                      .key,
                                                  style:
                                                      TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        colors.onSurface,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                '$lunas / $total siswa lunas (${persen.toStringAsFixed(1)}%)',
                                                style:
                                                    TextStyle(
                                                  fontSize:
                                                      12,
                                                  color:
                                                      colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          LinearProgressIndicator(
                                            value: total >
                                                    0
                                                ? lunas /
                                                    total
                                                : 0,
                                            backgroundColor:
                                                colors
                                                    .surfaceContainerHighest,
                                            color: persen >=
                                                    80
                                                ? AppColors
                                                    .success
                                                : persen >=
                                                        50
                                                    ? Colors
                                                        .orange
                                                    : AppColors
                                                        .error,
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child:
                                                    Text(
                                                  'Tagihan: Rp ${_formatCurrency(totalDue)}',
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        11,
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(
                                                width:
                                                    8,
                                              ),
                                              Expanded(
                                                child:
                                                    Text(
                                                  'Terkumpul: Rp ${_formatCurrency(totalPaid)}',
                                                  style:
                                                      TextStyle(
                                                    fontSize:
                                                        11,
                                                    color:
                                                        colors.onSurfaceVariant,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  textAlign:
                                                      TextAlign.end,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Divider(
                                            height:
                                                12,
                                            color: ThemeHelper
                                                .dividerColor(
                                              themeMode,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 6. TOP 5 SISWA
              // =================================================
              if (topOutstanding
                  .isNotEmpty)
                ScrollReveal(
                  delay:
                      const Duration(
                    milliseconds: 350,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ThemeHelper
                          .buildSectionHeader(
                        context,
                        'Top 5 Siswa dengan Tunggakan Terbesar',
                        themeMode,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ThemeHelper
                          .buildSectionGroup(
                        themeMode,
                        [
                          Padding(
                            padding:
                                const EdgeInsets.all(
                              8,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                ...topOutstanding
                                    .asMap()
                                    .entries
                                    .map(
                                  (entry) {
                                    final index =
                                        entry.key;

                                    final data =
                                        entry.value;

                                    return ListTile(
                                      leading:
                                          CircleAvatar(
                                        backgroundColor:
                                            AppColors.error
                                                .withOpacity(
                                          0.2,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style:
                                              const TextStyle(
                                            color:
                                                AppColors.error,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        data[
                                            'name'] as String,
                                        style:
                                            TextStyle(
                                          color:
                                              colors.onSurface,
                                        ),
                                      ),
                                      subtitle:
                                          Text(
                                        '${data['kelas']} • Total Tagihan: Rp ${_formatCurrency(data['totalDue'])}',
                                        style:
                                            TextStyle(
                                          color:
                                              colors.onSurfaceVariant,
                                        ),
                                      ),
                                      trailing:
                                          Text(
                                        'Rp ${_formatCurrency(data['outstanding'])}',
                                        style:
                                            const TextStyle(
                                          color:
                                              AppColors.error,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                      dense:
                                          true,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // 7. PIE CHART
              // =================================================
              if (paymentTypes
                  .isNotEmpty)
                ScrollReveal(
                  delay:
                      const Duration(
                    milliseconds: 400,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      ThemeHelper
                          .buildSectionHeader(
                        context,
                        'Distribusi Jenis Pembayaran (Lunas)',
                        themeMode,
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      ThemeHelper
                          .buildSectionGroup(
                        themeMode,
                        [
                          Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: SizedBox(
                              height: 200,
                              child:
                                  _buildPieChart(
                                paymentTypes,
                                colors,
                                themeMode,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // WIDGET SUMMARY
  // =============================================================
  Widget _buildSummaryItem(
    String label,
    String value,
    Color color,
    ColorScheme colors,
  ) {
    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // WIDGET COMPARISON
  // =============================================================
  Widget _buildComparisonItem(
    String label,
    double current,
    double previous,
    Color color,
    ColorScheme colors,
  ) {
    final diff =
        current - previous;

    final diffPercent =
        previous != 0
            ? (diff / previous * 100)
            : 0;

    final isUp = diff >= 0;

    return Flexible(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color:
                  colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Rp ${_formatCurrency(current)}',
              style: TextStyle(
                fontWeight:
                    FontWeight.bold,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            diff == 0
                ? '= 0%'
                : '${isUp ? '▲' : '▼'} ${diffPercent.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: isUp
                  ? AppColors.success
                  : AppColors.error,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '(bln lalu: Rp ${_formatCurrency(previous)})',
              style: TextStyle(
                fontSize: 10,
                color:
                    colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // GRAFIK PEMASUKAN & PENGELUARAN
  // RESPONSIVE UNTUK HP
  // =============================================================
  Widget _buildIncomeExpenseChart(
    List<String> labels,
    List<double> incomes,
    List<double> expenses,
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    final maxVal = [
      ...incomes,
      ...expenses,
    ].fold(
      0.0,
      (a, b) => a > b ? a : b,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth;

        final isSmallPhone =
            width < 360;

        final targetSteps =
            isSmallPhone ? 4 : 5;

        final paddedMax =
            maxVal > 0
                ? maxVal * 1.20
                : 1000.0;

        final interval =
            _niceInterval(
          paddedMax,
          targetSteps,
        );

        final maxY =
            math.max(
              interval,
              (paddedMax / interval)
                      .ceil() *
                  interval,
            );

        // Responsif terhadap HP
        final barWidth =
            isSmallPhone ? 7.0 : 9.0;

        final barsSpace =
            isSmallPhone ? 2.0 : 3.0;

        final reservedSize =
            isSmallPhone ? 48.0 : 56.0;

        final bottomReservedSize =
            isSmallPhone ? 26.0 : 30.0;

        final horizontalInterval =
            interval;

        List<BarChartGroupData>
            barGroups =
            List.generate(
          labels.length,
          (index) {
            return BarChartGroupData(
              x: index,
              barsSpace:
                  barsSpace,
              barRods: [
                BarChartRodData(
                  toY: incomes[index],
                  color:
                      AppColors.success,
                  width:
                      barWidth,
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      4,
                    ),
                  ),
                ),
                BarChartRodData(
                  toY: expenses[index],
                  color:
                      AppColors.error,
                  width:
                      barWidth,
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      4,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        return BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            barGroups:
                barGroups,

            // Supaya 6 bulan tetap rapi di layar kecil
            alignment:
                BarChartAlignment.spaceAround,

            gridData:
                FlGridData(
              show: true,
              drawVerticalLine:
                  false,
              horizontalInterval:
                  horizontalInterval,
              getDrawingHorizontalLine:
                  (value) {
                return FlLine(
                  color: ThemeHelper
                      .dividerColor(
                    themeMode,
                  ),
                  strokeWidth: 1,
                  dashArray: [
                    5,
                    5,
                  ],
                );
              },
            ),

            titlesData:
                FlTitlesData(
              show: true,

              // =========================
              // LABEL BULAN
              // =========================
              bottomTitles:
                  AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      true,
                  reservedSize:
                      bottomReservedSize,
                  interval: 1,
                  getTitlesWidget:
                      (value,
                          meta) {
                    final index =
                        value.toInt();

                    if (index >= 0 &&
                        index <
                            labels
                                .length) {
                      return Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 4,
                        ),
                        child:
                            Text(
                          labels[
                              index],
                          style:
                              TextStyle(
                            fontSize:
                                isSmallPhone
                                    ? 9
                                    : 10,
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return const SizedBox
                        .shrink();
                  },
                ),
              ),

              // =========================
              // SUMBU Y RESPONSIVE
              // =========================
              leftTitles:
                  AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      true,

                  // Diperbesar agar
                  // "1,5 jt" tidak terpotong
                  reservedSize:
                      reservedSize,

                  interval:
                      horizontalInterval,

                  getTitlesWidget:
                      (value,
                          meta) {
                    if (value == 0) {
                      return const SizedBox
                          .shrink();
                    }

                    return Text(
                      _formatCompactCurrency(
                        value,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow
                              .clip,
                      style:
                          TextStyle(
                        fontSize:
                            isSmallPhone
                                ? 8.5
                                : 9.5,
                        color:
                            colors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),

              topTitles:
                  const AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      false,
                ),
              ),

              rightTitles:
                  const AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      false,
                ),
              ),
            ),

            borderData:
                FlBorderData(
              show: false,
            ),

            // =========================
            // TOOLTIP
            // =========================
            barTouchData:
                BarTouchData(
              enabled: true,
              touchTooltipData:
                  BarTouchTooltipData(
                fitInsideHorizontally:
                    true,
                fitInsideVertically:
                    true,
                getTooltipItem:
                    (
                  group,
                  groupIndex,
                  rod,
                  rodIndex,
                ) {
                  final isIncome =
                      rodIndex ==
                          0;

                  final value =
                      rod.toY;

                  return BarTooltipItem(
                    '${isIncome ? 'Pemasukan' : 'Pengeluaran'}\n'
                    'Rp ${_formatCurrency(value)}',
                    TextStyle(
                      color:
                          isIncome
                              ? AppColors
                                  .success
                              : AppColors
                                  .error,
                      fontWeight:
                          FontWeight
                              .bold,
                      fontSize: 11,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // GRAFIK SALDO KUMULATIF
  // RESPONSIVE UNTUK HP
  // =============================================================
  Widget _buildBalanceChart(
    List<String> labels,
    List<double> balances,
    AppThemeMode themeMode,
    ColorScheme colors,
  ) {
    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    if (balances.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(
            color:
                colors.onSurfaceVariant,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            constraints.maxWidth;

        final isSmallPhone =
            width < 360;

        final maxVal =
            balances.reduce(
          (a, b) => a > b ? a : b,
        );

        final minVal =
            balances.reduce(
          (a, b) => a < b ? a : b,
        );

        final range =
            maxVal - minVal;

        double minY;
        double maxY;

        // ===========================
        // SEMUA NILAI POSITIF
        // ===========================
        if (minVal >= 0) {
          minY = 0;

          final paddedMax =
              maxVal > 0
                  ? maxVal * 1.15
                  : 1000.0;

          final interval =
              _niceInterval(
            paddedMax,
            isSmallPhone ? 4 : 5,
          );

          maxY =
              (paddedMax / interval)
                      .ceil() *
                  interval;

          if (maxY <= 0) {
            maxY = interval;
          }
        }

        // ===========================
        // SEMUA NILAI NEGATIF
        // ===========================
        else if (maxVal <= 0) {
          maxY = 0;

          final paddedMin =
              minVal * 1.15;

          final interval =
              _niceInterval(
            paddedMin.abs(),
            isSmallPhone ? 4 : 5,
          );

          minY =
              (paddedMin / interval)
                      .floor() *
                  interval;
        }

        // ===========================
        // ADA POSITIF & NEGATIF
        // ===========================
        else {
          final paddedRange =
              range * 1.20;

          final interval =
              _niceInterval(
            paddedRange,
            isSmallPhone ? 4 : 5,
          );

          minY =
              ((minVal -
                          range *
                              0.10) /
                      interval)
                  .floor() *
              interval;

          maxY =
              ((maxVal +
                          range *
                              0.10) /
                      interval)
                  .ceil() *
              interval;
        }

        // ===========================
        // INTERVAL FINAL
        // ===========================
        final finalRange =
            maxY - minY;

        final interval =
            _niceInterval(
          finalRange,
          isSmallPhone ? 4 : 5,
        );

        final reservedSize =
            isSmallPhone ? 48.0 : 56.0;

        final bottomReservedSize =
            isSmallPhone ? 26.0 : 30.0;

        final spots =
            List<FlSpot>.generate(
          balances.length,
          (index) {
            return FlSpot(
              index.toDouble(),
              balances[index],
            );
          },
        );

        return LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: accentColor,
                barWidth:
                    isSmallPhone
                        ? 2.5
                        : 3,
                dotData:
                    FlDotData(
                  show: true,
                  getDotPainter:
                      (
                    spot,
                    percent,
                    barData,
                    index,
                  ) {
                    return FlDotCirclePainter(
                      radius:
                          isSmallPhone
                              ? 3
                              : 4,
                      color:
                          accentColor,
                      strokeWidth: 1,
                      strokeColor:
                          colors.surface,
                    );
                  },
                ),
                belowBarData:
                    BarAreaData(
                  show: true,
                  color: accentColor
                      .withOpacity(
                    0.15,
                  ),
                ),
              ),
            ],

            gridData:
                FlGridData(
              show: true,
              drawVerticalLine:
                  false,
              horizontalInterval:
                  interval,
              getDrawingHorizontalLine:
                  (value) {
                return FlLine(
                  color: ThemeHelper
                      .dividerColor(
                    themeMode,
                  ),
                  strokeWidth:
                      1,
                  dashArray: [
                    5,
                    5,
                  ],
                );
              },
            ),

            titlesData:
                FlTitlesData(
              show: true,

              // =========================
              // LABEL BULAN
              // =========================
              bottomTitles:
                  AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      true,
                  interval: 1,
                  reservedSize:
                      bottomReservedSize,
                  getTitlesWidget:
                      (
                    value,
                    meta,
                  ) {
                    final index =
                        value.toInt();

                    if (index >= 0 &&
                        index <
                            labels
                                .length) {
                      return Padding(
                        padding:
                            const EdgeInsets
                                .only(
                          top: 4,
                        ),
                        child:
                            Text(
                          labels[
                              index],
                          style:
                              TextStyle(
                            fontSize:
                                isSmallPhone
                                    ? 9
                                    : 10,
                            color:
                                colors.onSurfaceVariant,
                          ),
                        ),
                      );
                    }

                    return const SizedBox
                        .shrink();
                  },
                ),
              ),

              // =========================
              // SUMBU Y RESPONSIVE
              // =========================
              leftTitles:
                  AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      true,
                  reservedSize:
                      reservedSize,
                  interval:
                      interval,
                  getTitlesWidget:
                      (
                    value,
                    meta,
                  ) {
                    // Tetap boleh menampilkan 0
                    // pada grafik saldo
                    return Text(
                      _formatCompactCurrency(
                        value,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.clip,
                      style:
                          TextStyle(
                        fontSize:
                            isSmallPhone
                                ? 8.5
                                : 9.5,
                        color:
                            colors.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),

              topTitles:
                  const AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      false,
                ),
              ),

              rightTitles:
                  const AxisTitles(
                sideTitles:
                    SideTitles(
                  showTitles:
                      false,
                ),
              ),
            ),

            borderData:
                FlBorderData(
              show: false,
            ),

            // =========================
            // TOOLTIP
            // =========================
            lineTouchData:
                LineTouchData(
              enabled: true,
              touchTooltipData:
                  LineTouchTooltipData(
                fitInsideHorizontally:
                    true,
                fitInsideVertically:
                    true,
                getTooltipItems:
                    (
                  touchedSpots,
                ) {
                  return touchedSpots
                      .map(
                    (spot) {
                      return LineTooltipItem(
                        'Saldo\nRp ${_formatCurrency(spot.y)}',
                        TextStyle(
                          color:
                              Colors.white,
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize:
                              11,
                        ),
                      );
                    },
                  ).toList();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // PIE CHART
  // =============================================================
  Widget _buildPieChart(
    Map<String, double> data,
    ColorScheme colors,
    AppThemeMode themeMode,
  ) {
    final total =
        data.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    if (total == 0) {
      return Center(
        child: Text(
          'Tidak ada data',
          style: TextStyle(
            color:
                colors.onSurfaceVariant,
          ),
        ),
      );
    }

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

    List<Map<String, dynamic>>
        slices = [];

    int colorIndex = 0;

    data.forEach(
      (key, value) {
        slices.add({
          'label': key,
          'value': value,
          'percentage':
              (value / total * 100),
          'color': colorsList[
              colorIndex %
                  colorsList.length],
        });

        colorIndex++;
      },
    );

    slices.sort(
      (a, b) =>
          (b['value'] as double)
              .compareTo(
        a['value'] as double,
      ),
    );

    return Row(
      children: [
        Expanded(
          flex: 1,
          child: CustomPaint(
            size:
                const Size(
              140,
              140,
            ),
            painter:
                _PieChartPainter(
              slices,
              ThemeHelper
                  .dividerColor(
                themeMode,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 16,
        ),
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children:
                slices.map(
              (slice) {
                return Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color:
                            slice[
                                'color'] as Color,
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      Expanded(
                        child: Text(
                          '${slice['label']} (${(slice['percentage'] as double).toStringAsFixed(1)}%)',
                          style:
                              TextStyle(
                            fontSize:
                                11,
                            color:
                                colors.onSurfaceVariant,
                          ),
                          overflow:
                              TextOverflow
                                  .ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }
}

// =============================================================
// PIE CHART PAINTER
// =============================================================
class _PieChartPainter
    extends CustomPainter {
  final List<Map<String, dynamic>>
      slices;

  final Color borderColor;

  _PieChartPainter(
    this.slices,
    this.borderColor,
  );

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final rect =
        Offset.zero & size;

    final total =
        slices.fold(
      0.0,
      (sum, s) =>
          sum + (s['value'] as double),
    );

    double startAngle =
        -90 * 3.14159 / 180;

    for (var slice in slices) {
      final value =
          slice['value'] as double;

      final sweepAngle =
          (value / total) *
              2 *
              3.14159;

      final color =
          slice['color'] as Color;

      final paint = Paint()
        ..color = color
        ..style =
            PaintingStyle.fill;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      final borderPaint =
          Paint()
            ..color =
                borderColor
            ..style =
                PaintingStyle.stroke
            ..strokeWidth = 1.5;

      canvas.drawArc(
        rect,
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle +=
          sweepAngle;
    }
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) =>
      true;
}