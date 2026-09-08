// navigation/dashboard.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../addon/aksi.dart';
import '../helpers/theme_helper.dart';
import '../helpers/custom_animation.dart';
import '../helpers/scroll_reveal.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() =>
      _DashboardPageState();
}

class _DashboardPageState
    extends ConsumerState<DashboardPage> {
  bool _isLoading = true;
  bool _hasError = false;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _totalIncomeAll = 0;
  double _totalExpenseAll = 0;

  Map<int, double> _monthlyIncome = {};
  String _aiInsight = '';
  List<Student> _activeStudents = [];

  // =========================================================
  // FUNGSI FETCH DATA
  // =========================================================

  Future<Map<int, double>> _getMonthlyIncome() async {
    final transactions =
        await fetchAllTransactions();

    Map<int, double> monthly = {};

    for (var t in transactions) {
      if (t.type == TransType.pemasukan) {
        final month = t.date.month;

        monthly[month] =
            (monthly[month] ?? 0) + t.amount;
      }
    }

    for (int i = 1; i <= 12; i++) {
      monthly.putIfAbsent(i, () => 0);
    }

    return monthly;
  }

  Future<double> _getCurrentMonthIncome() async {
    final now = DateTime.now();
    final month = now.month;

    final transactions =
        await fetchAllTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan &&
          t.date.month == month &&
          t.date.year == now.year) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<double> _getCurrentMonthExpense() async {
    final now = DateTime.now();
    final month = now.month;

    final transactions =
        await fetchAllTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pengeluaran &&
          t.date.month == month &&
          t.date.year == now.year) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<double> _getTotalIncomeAllTime() async {
    final transactions =
        await fetchAllTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<double> _getTotalExpenseAllTime() async {
    final transactions =
        await fetchAllTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pengeluaran) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<String> _generateAIInsight() async {
    final totalIncome = _totalIncome;
    final totalExpense = _totalExpense;
    final balance =
        totalIncome - totalExpense;

    final now = DateTime.now();

    int lastMonth =
        now.month - 1;

    int lastYear =
        now.year;

    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear--;
    }

    final transactions =
        await fetchAllTransactions();

    double lastMonthIncome = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan &&
          t.date.month == lastMonth &&
          t.date.year == lastYear) {
        lastMonthIncome += t.amount;
      }
    }

    final activeStudents =
        _activeStudents;

    final paidStudents =
        activeStudents
            .where(
              (s) => !s.hasOutstanding,
            )
            .length;

    final totalStudents =
        activeStudents.length;

    final persentaseLunas =
        totalStudents > 0
            ? (paidStudents /
                    totalStudents *
                    100)
            : 0;

    List<String> insights = [];

    if (persentaseLunas >= 80) {
      insights.add(
        '✅ ${persentaseLunas.toStringAsFixed(0)}% siswa sudah lunas. Bagus!',
      );
    } else if (persentaseLunas >= 50) {
      insights.add(
        '📊 ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. '
        'Masih ada PR menagih sisanya.',
      );
    } else {
      insights.add(
        '⚠️ Hanya ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. '
        'Perlu strategi penagihan lebih agresif.',
      );
    }

    if (lastMonthIncome > 0 &&
        totalIncome > 0) {
      final selisih =
          totalIncome -
              lastMonthIncome;

      final persenChange =
          selisih /
              lastMonthIncome *
              100;

      if (persenChange > 0) {
        insights.add(
          '📈 Pemasukan bulan ini naik '
          '${persenChange.toStringAsFixed(1)}% dibanding bulan lalu.',
        );
      } else if (persenChange < 0) {
        insights.add(
          '📉 Pemasukan bulan ini turun '
          '${persenChange.abs().toStringAsFixed(1)}% dibanding bulan lalu.',
        );
      } else {
        insights.add(
          '➖ Pemasukan bulan ini stabil.',
        );
      }
    } else if (totalIncome > 0 &&
        lastMonthIncome == 0) {
      insights.add(
        '💰 Bulan ini mulai ada pemasukan baru.',
      );
    }

    if (balance > 0) {
      insights.add(
        '💚 Saldo positif: Rp ${formatCurrency(balance)}. Keuangan sehat.',
      );
    } else if (balance < 0) {
      insights.add(
        '🔴 Saldo negatif: Rp ${formatCurrency(balance)}. Perhatikan pengeluaran.',
      );
    } else {
      insights.add(
        '⚖️ Saldo impas.',
      );
    }

    return insights.join(' • ');
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      _activeStudents =
          await fetchActiveStudents();

      _totalIncome =
          await _getCurrentMonthIncome();

      _totalExpense =
          await _getCurrentMonthExpense();

      _totalIncomeAll =
          await _getTotalIncomeAllTime();

      _totalExpenseAll =
          await _getTotalExpenseAllTime();

      _monthlyIncome =
          await _getMonthlyIncome();

      _aiInsight =
          await _generateAIInsight();
    } catch (e) {
      _hasError = true;

      if (mounted) {
        showTopNotification(
          context,
          'Tidak ada koneksi internet. Coba lagi.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchData();

    AksiHelper.setRefreshCallback(() {
      if (mounted) {
        _fetchData();
      }
    });
  }

  @override
  void dispose() {
    AksiHelper.setRefreshCallback(null);

    super.dispose();
  }

  // =========================================================
  // DATE / GREETING
  // =========================================================

  String _getGreeting() {
    final hour =
        DateTime.now().hour;

    if (hour < 11) {
      return 'Selamat Pagi';
    }

    if (hour < 15) {
      return 'Selamat Siang';
    }

    if (hour < 18) {
      return 'Selamat Sore';
    }

    return 'Selamat Malam';
  }

  String _getCurrentDate() {
    final now = DateTime.now();

    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    return '${days[now.weekday - 1]}, '
        '${now.day} '
        '${months[now.month - 1]} '
        '${now.year}';
  }

  // =========================================================
  // BUILD UI
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode =
        ref.watch(themeModeProvider);

    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final headerBgColor =
        ThemeHelper.getHeaderBgColor(
      themeMode,
      colors,
    );

    final headerTextColor =
        ThemeHelper.getHeaderTextColor(
      themeMode,
      colors,
    );

    final scaffoldBackgroundColor =
        ThemeHelper.getScaffoldBackgroundColor(
      themeMode,
      colors,
    );

    return ThemeHelper
        .buildThemedBackground(
      themeMode,
      Scaffold(
        // =====================================================
        // PERBAIKAN NEUMORPHISM
        // =====================================================

        backgroundColor:
            scaffoldBackgroundColor,

        extendBodyBehindAppBar:
            true,

        appBar: AppBar(
          backgroundColor:
              Colors.transparent,
          elevation: 0,
          foregroundColor:
              headerTextColor,
        ),

        body: _isLoading
            ? const LottieLoading()
            : _hasError
                ? const LottieError(
                    message:
                        'Gagal memuat data. Periksa koneksi internet Anda.',
                  )
                : RefreshIndicator(
                    onRefresh:
                        _fetchData,
                    child:
                        NotificationListener<
                            OverscrollIndicatorNotification>(
                      onNotification:
                          (notification) {
                        notification
                            .disallowIndicator();

                        return false;
                      },
                      child:
                          ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.only(
                          bottom: 32,
                        ),
                        children: [
                          // =====================================================
                          // HEADER + HERO CARD
                          // =====================================================

                          Stack(
                            clipBehavior:
                                Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 260,
                                child:
                                    Container(
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        headerBgColor,
                                    borderRadius:
                                        const BorderRadius.only(
                                      bottomLeft:
                                          Radius.circular(
                                        36,
                                      ),
                                      bottomRight:
                                          Radius.circular(
                                        36,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              Positioned(
                                top: MediaQuery.of(
                                          context,
                                        )
                                            .padding
                                            .top +
                                    kToolbarHeight +
                                    10,
                                left: 20,
                                right: 20,
                                child:
                                    ScrollReveal(
                                  delay:
                                      const Duration(
                                    milliseconds:
                                        50,
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Eduvest Finance',
                                        style: theme
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              headerTextColor,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        '${_getGreeting()}, Admin 👋',
                                        style: theme
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                          fontWeight:
                                              FontWeight.bold,
                                          color:
                                              headerTextColor,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 4,
                                      ),
                                      Text(
                                        _getCurrentDate(),
                                        style: theme
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color:
                                              headerTextColor.withOpacity(
                                            0.8,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              ScrollReveal(
                                delay:
                                    const Duration(
                                  milliseconds:
                                      120,
                                ),
                                child:
                                    Padding(
                                  padding:
                                      const EdgeInsets.only(
                                    top: 200,
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                        ),
                                        child:
                                            Text(
                                          'RINGKASAN SALDO',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                11.5,
                                            fontWeight:
                                                FontWeight.w700,
                                            letterSpacing:
                                                1.0,
                                            color:
                                                headerTextColor.withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ),

                                      ThemeHelper
                                          .buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding:
                                                const EdgeInsets.all(
                                              20,
                                            ),
                                            child:
                                                Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total Saldo Sekolah',
                                                  style:
                                                      theme.textTheme.bodyMedium,
                                                ),

                                                const SizedBox(
                                                  height: 8,
                                                ),

                                                Text(
                                                  'Rp ${formatCurrency(_totalIncomeAll - _totalExpenseAll)}',
                                                  style: theme
                                                      .textTheme
                                                      .headlineMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        colors.primary,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  height: 20,
                                                ),

                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          _buildBalanceItem(
                                                        'Pemasukan',
                                                        _totalIncome,
                                                        AppColors.success,
                                                        Icons.arrow_upward,
                                                      ),
                                                    ),

                                                    Container(
                                                      width:
                                                          1,
                                                      height:
                                                          40,
                                                      color:
                                                          ThemeHelper.dividerColor(
                                                        themeMode,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      width:
                                                          16,
                                                    ),

                                                    Expanded(
                                                      child:
                                                          _buildBalanceItem(
                                                        'Pengeluaran',
                                                        _totalExpense,
                                                        AppColors.error,
                                                        Icons.arrow_downward,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal:
                                  16.0,
                            ),
                            child:
                                Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                ScrollReveal(
                                  delay:
                                      const Duration(
                                    milliseconds:
                                        100,
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper
                                          .buildSectionHeader(
                                        context,
                                        'Statistik Pemasukan (6 Bulan)',
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
                                                const EdgeInsets.fromLTRB(
                                              8,
                                              20,
                                              16,
                                              8,
                                            ),
                                            child:
                                                Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height:
                                                      200,
                                                  child:
                                                      _buildBarChart(
                                                    _getLast6MonthsLabels(),
                                                    _getLast6MonthsValues(),
                                                    themeMode,
                                                  ),
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
                                  height:
                                      24,
                                ),

                                ScrollReveal(
                                  delay:
                                      const Duration(
                                    milliseconds:
                                        150,
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper
                                          .buildSectionHeader(
                                        context,
                                        'Status Pembayaran Siswa',
                                        themeMode,
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      _buildStudentPaymentCard(
                                        themeMode,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height:
                                      24,
                                ),

                                ScrollReveal(
                                  delay:
                                      const Duration(
                                    milliseconds:
                                        200,
                                  ),
                                  child:
                                      Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper
                                          .buildSectionHeader(
                                        context,
                                        'Insight Keuangan',
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
                                            child:
                                                Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  width:
                                                      40,
                                                  height:
                                                      40,
                                                  child:
                                                      LottieAiAnimation(
                                                    size:
                                                        40,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  width:
                                                      12,
                                                ),

                                                Expanded(
                                                  child:
                                                      Text(
                                                    _aiInsight,
                                                    style:
                                                        theme.textTheme.bodyMedium?.copyWith(
                                                      height:
                                                          1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
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
      ),
    );
  }

  // =========================================================
  // BALANCE ITEM
  // =========================================================

  Widget _buildBalanceItem(
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    final theme =
        Theme.of(context);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(
              width: 4,
            ),
            Text(
              title,
              style:
                  theme.textTheme.labelLarge,
            ),
          ],
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          'Rp ${formatCurrency(amount)}',
          style: theme
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STUDENT PAYMENT
  // =========================================================

  Widget _buildStudentPaymentCard(
    AppThemeMode themeMode,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final paidStudents =
        _activeStudents
            .where(
              (s) => !s.hasOutstanding,
            )
            .length;

    final totalStudents =
        _activeStudents.length;

    final persentaseLunas =
        totalStudents > 0
            ? (paidStudents /
                    totalStudents *
                    100)
            : 0;

    return ThemeHelper
        .buildSectionGroup(
      themeMode,
      [
        Padding(
          padding:
              const EdgeInsets.all(
            16,
          ),
          child:
              Row(
            children: [
              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siswa Lunas',
                      style: theme
                          .textTheme
                          .bodyMedium,
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      '$paidStudents / $totalStudents Siswa',
                      style: theme
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    ClipRRect(
                      borderRadius:
                          BorderRadius
                              .circular(
                        8,
                      ),
                      child:
                          LinearProgressIndicator(
                        value: totalStudents >
                                0
                            ? paidStudents /
                                totalStudents
                            : 0,
                        backgroundColor:
                            colors
                                .surfaceContainerHighest,
                        color:
                            AppColors.success,
                        minHeight:
                            8,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      '${persentaseLunas.toStringAsFixed(0)}% dari total siswa aktif telah melunasi pembayaran.',
                      style: theme
                          .textTheme
                          .labelMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Container(
                width: 80,
                height: 80,
                padding:
                    const EdgeInsets.all(
                  8,
                ),
                decoration:
                    BoxDecoration(
                  color: AppColors
                      .success
                      .withOpacity(
                    0.1,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const LottieBenefits(
                  size:
                      64,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MONTH LABELS
  // =========================================================

  List<String>
      _getLast6MonthsLabels() {
    const monthLabels = [
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

    final now =
        DateTime.now();

    List<String> labels = [];

    for (int i = 5;
        i >= 0;
        i--) {
      int month =
          now.month - i;

      if (month <= 0) {
        month += 12;
      }

      labels.add(
        monthLabels[
            month - 1],
      );
    }

    return labels;
  }

  // =========================================================
  // MONTH VALUES
  // =========================================================

  List<double>
      _getLast6MonthsValues() {
    final now =
        DateTime.now();

    List<double> values = [];

    for (int i = 5;
        i >= 0;
        i--) {
      int month =
          now.month - i;

      if (month <= 0) {
        month += 12;
      }

      values.add(
        _monthlyIncome[
                month] ??
            0,
      );
    }

    return values;
  }

  // =========================================================
  // BAR CHART
  // =========================================================

  Widget _buildBarChart(
    List<String> labels,
    List<double> values,
    AppThemeMode themeMode,
  ) {
    final theme =
        Theme.of(context);

    final colors =
        theme.colorScheme;

    final maxVal =
        values.reduce(
      (a, b) =>
          a > b ? a : b,
    );

    final double maxY =
        maxVal > 0
            ? maxVal
            : 1;

    final List<
            BarChartGroupData>
        barGroups =
        List.generate(
      labels.length,
      (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY:
                  values[index],
              color:
                  colors.primary,
              width:
                  14,
              borderRadius:
                  const BorderRadius.vertical(
                top:
                    Radius.circular(
                  6,
                ),
              ),
            ),
          ],
        );
      },
    );

    return BarChart(
      BarChartData(
        alignment:
            BarChartAlignment
                .spaceAround,

        maxY:
            maxY * 1.2,

        minY:
            0,

        groupsSpace:
            16,

        barGroups:
            barGroups,

        gridData:
            FlGridData(
          show:
              true,

          drawVerticalLine:
              false,

          horizontalInterval:
              maxY / 4,

          getDrawingHorizontalLine:
              (value) {
            return FlLine(
              color:
                  ThemeHelper
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
          show:
              true,

          bottomTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles:
                  true,

              reservedSize:
                  28,

              getTitlesWidget:
                  (value, meta) {
                final index =
                    value.toInt();

                if (index >=
                        0 &&
                    index <
                        labels.length) {
                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      top:
                          8.0,
                    ),
                    child:
                        Text(
                      labels[
                          index],
                      style:
                          theme.textTheme.labelMedium,
                    ),
                  );
                }

                return const SizedBox
                    .shrink();
              },
            ),
          ),

          leftTitles:
              AxisTitles(
            sideTitles:
                SideTitles(
              showTitles:
                  true,

              reservedSize:
                  40,

              interval:
                  maxY / 4,

              getTitlesWidget:
                  (value, meta) {
                if (value ==
                    0) {
                  return const SizedBox
                      .shrink();
                }

                return Padding(
                  padding:
                      const EdgeInsets
                          .only(
                    right:
                        4.0,
                  ),
                  child:
                      Text(
                    '${(value / 1000).toInt()}k',
                    style:
                        theme.textTheme.labelMedium,
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
          show:
              false,
        ),

        barTouchData:
            BarTouchData(
          enabled:
              true,

          touchTooltipData:
              BarTouchTooltipData(
            getTooltipColor:
                (_) =>
                    colors.primary,

            getTooltipItem:
                (
              group,
              groupIndex,
              rod,
              rodIndex,
            ) {
              return BarTooltipItem(
                'Rp ${formatCurrency(rod.toY)}',
                TextStyle(
                  color:
                      colors.onPrimary,
                  fontWeight:
                      FontWeight.bold,
                  fontSize:
                      12,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}