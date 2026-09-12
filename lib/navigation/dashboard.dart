// lib/navigation/dashboard.dart

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
import '../l10n/translations.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
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
  // FUNGSI FETCH DATA GABUNGAN (AKTIF + ARSIP BULANAN)
  // =========================================================

  /// Mengambil semua transaksi (transaksi aktif + transaksi arsip bulanan)
  /// agar Total Kas Sekolah dan grafik tetap menampilkan seluruh history.
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

  Future<Map<int, double>> _getMonthlyIncome() async {
    final transactions = await _getAllCombinedTransactions();

    Map<int, double> monthly = {};

    for (var t in transactions) {
      if (t.type == TransType.pemasukan) {
        final month = t.date.month;
        final year = t.date.year;
        // hanya hitung tahun berjalan untuk chart dashboard
        if (year == DateTime.now().year) {
          monthly[month] = (monthly[month] ?? 0) + t.amount;
        }
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

    final transactions = await _getAllCombinedTransactions();

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

    final transactions = await _getAllCombinedTransactions();

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
    final transactions = await _getAllCombinedTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<double> _getTotalExpenseAllTime() async {
    final transactions = await _getAllCombinedTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pengeluaran) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<String> _generateAIInsight() async {
    final translations = ref.read(translationsProvider);

    final totalIncome = _totalIncome;
    final totalExpense = _totalExpense;
    final balance = totalIncome - totalExpense;

    final now = DateTime.now();

    int lastMonth = now.month - 1;
    int lastYear = now.year;

    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear--;
    }

    final transactions = await _getAllCombinedTransactions();

    double lastMonthIncome = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan &&
          t.date.month == lastMonth &&
          t.date.year == lastYear) {
        lastMonthIncome += t.amount;
      }
    }

    final activeStudents = _activeStudents;

    final paidStudents =
        activeStudents.where((s) => !s.hasOutstanding).length;

    final totalStudents = activeStudents.length;

    final persentaseLunas =
        totalStudents > 0 ? (paidStudents / totalStudents * 100) : 0;

    final percentText = persentaseLunas.toStringAsFixed(0);

    List<String> insights = [];

    if (persentaseLunas >= 80) {
      insights.add(
        translations.t('insight_paid_good').replaceFirst('{percent}', percentText),
      );
    } else if (persentaseLunas >= 50) {
      insights.add(
        translations.t('insight_paid_medium').replaceFirst('{percent}', percentText),
      );
    } else {
      insights.add(
        translations.t('insight_paid_low').replaceFirst('{percent}', percentText),
      );
    }

    if (lastMonthIncome > 0 && totalIncome > 0) {
      final selisih = totalIncome - lastMonthIncome;
      final persenChange = (selisih / lastMonthIncome) * 100;

      if (persenChange > 0) {
        insights.add(
          translations
              .t('insight_income_up')
              .replaceFirst('{percent}', persenChange.toStringAsFixed(1)),
        );
      } else if (persenChange < 0) {
        insights.add(
          translations
              .t('insight_income_down')
              .replaceFirst('{percent}', persenChange.abs().toStringAsFixed(1)),
        );
      } else {
        insights.add(translations.t('insight_income_stable'));
      }
    } else if (totalIncome > 0 && lastMonthIncome == 0) {
      insights.add(translations.t('insight_income_new'));
    }

    if (balance > 0) {
      insights.add(
        translations
            .t('insight_balance_positive')
            .replaceFirst('{amount}', formatCurrency(balance)),
      );
    } else if (balance < 0) {
      insights.add(
        translations
            .t('insight_balance_negative')
            .replaceFirst('{amount}', formatCurrency(balance)),
      );
    } else {
      insights.add(translations.t('insight_balance_even'));
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
      _activeStudents = await fetchActiveStudents();

      _totalIncome = await _getCurrentMonthIncome();
      _totalExpense = await _getCurrentMonthExpense();

      _totalIncomeAll = await _getTotalIncomeAllTime();
      _totalExpenseAll = await _getTotalExpenseAllTime();

      _monthlyIncome = await _getMonthlyIncome();

      _aiInsight = await _generateAIInsight();
    } catch (e) {
      _hasError = true;

      if (mounted) {
        final translations = ref.read(translationsProvider);

        showTopNotification(
          context,
          translations.t('dashboard_loading_error'),
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

  String _getGreeting(Translations translations) {
    final hour = DateTime.now().hour;

    if (hour < 11) {
      return translations.t('greeting_morning');
    }

    if (hour < 15) {
      return translations.t('greeting_afternoon');
    }

    if (hour < 18) {
      return translations.t('greeting_evening');
    }

    return translations.t('greeting_night');
  }

  String _getCurrentDate(Translations translations) {
    final now = DateTime.now();

    final days = [
      translations.t('day_monday'),
      translations.t('day_tuesday'),
      translations.t('day_wednesday'),
      translations.t('day_thursday'),
      translations.t('day_friday'),
      translations.t('day_saturday'),
      translations.t('day_sunday'),
    ];

    final months = [
      translations.t('month_january'),
      translations.t('month_february'),
      translations.t('month_march'),
      translations.t('month_april'),
      translations.t('month_may'),
      translations.t('month_june'),
      translations.t('month_july'),
      translations.t('month_august'),
      translations.t('month_september'),
      translations.t('month_october'),
      translations.t('month_november'),
      translations.t('month_december'),
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
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final translations = ref.watch(translationsProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final headerBgColor = ThemeHelper.getHeaderBgColor(themeMode, colors);
    final headerTextColor = ThemeHelper.getHeaderTextColor(themeMode, colors);
    final scaffoldBackgroundColor =
        ThemeHelper.getScaffoldBackgroundColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        extendBodyBehindAppBar: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: headerTextColor,
        ),

        body: _isLoading
            ? const LottieLoading()
            : _hasError
                ? LottieError(message: translations.t('dashboard_loading_error'))
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: NotificationListener<
                        OverscrollIndicatorNotification>(
                      onNotification: (notification) {
                        notification.disallowIndicator();
                        return false;
                      },
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 32),
                        children: [
                          // =====================================================
                          // HEADER + HERO CARD
                          // =====================================================

                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 260,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: headerBgColor,
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(36),
                                      bottomRight: Radius.circular(36),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: MediaQuery.of(context).padding.top +
                                    kToolbarHeight +
                                    10,
                                left: 20,
                                right: 20,
                                child: ScrollReveal(
                                  delay: const Duration(milliseconds: 50),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        translations.t('app_title'),
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: headerTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '${_getGreeting(translations)}, Admin 👋',
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: headerTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getCurrentDate(translations),
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color:
                                              headerTextColor.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ScrollReveal(
                                delay: const Duration(milliseconds: 120),
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    top: 200,
                                    left: 16,
                                    right: 16,
                                    bottom: 16,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          translations.t('balance_summary'),
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color:
                                                headerTextColor.withOpacity(0.9),
                                          ),
                                        ),
                                      ),
                                      ThemeHelper.buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding: const EdgeInsets.all(20),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  translations
                                                      .t('total_school_balance'),
                                                  style:
                                                      theme.textTheme.bodyMedium,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Rp ${formatCurrency(_totalIncomeAll - _totalExpenseAll)}',
                                                  style: theme
                                                      .textTheme.headlineMedium
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colors.primary,
                                                  ),
                                                ),
                                                const SizedBox(height: 20),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: _buildBalanceItem(
                                                        translations.t('income'),
                                                        _totalIncome,
                                                        AppColors.success,
                                                        Icons.arrow_upward,
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 1,
                                                      height: 40,
                                                      color: ThemeHelper
                                                          .dividerColor(
                                                              themeMode),
                                                    ),
                                                    const SizedBox(width: 16),
                                                    Expanded(
                                                      child: _buildBalanceItem(
                                                        translations
                                                            .t('expense'),
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
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ScrollReveal(
                                  delay: const Duration(milliseconds: 100),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper.buildSectionHeader(
                                        context,
                                        translations
                                            .t('income_statistics_6_months'),
                                        themeMode,
                                      ),
                                      const SizedBox(height: 8),
                                      ThemeHelper.buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding:
                                                const EdgeInsets.fromLTRB(
                                                    8, 20, 16, 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  height: 200,
                                                  child: _buildBarChart(
                                                    _getLast6MonthsLabels(
                                                        translations),
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
                                const SizedBox(height: 24),
                                ScrollReveal(
                                  delay: const Duration(milliseconds: 150),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper.buildSectionHeader(
                                        context,
                                        translations.t('student_payment_status'),
                                        themeMode,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildStudentPaymentCard(
                                          themeMode, translations),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ScrollReveal(
                                  delay: const Duration(milliseconds: 200),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ThemeHelper.buildSectionHeader(
                                        context,
                                        translations.t('financial_insight'),
                                        themeMode,
                                      ),
                                      const SizedBox(height: 8),
                                      ThemeHelper.buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const SizedBox(
                                                  width: 40,
                                                  height: 40,
                                                  child: LottieAiAnimation(
                                                      size: 40),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _aiInsight,
                                                    style: theme
                                                        .textTheme.bodyMedium
                                                        ?.copyWith(height: 1.4),
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
      String title, double amount, Color color, IconData icon) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(title, style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Rp ${formatCurrency(amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // STUDENT PAYMENT
  // =========================================================

  Widget _buildStudentPaymentCard(
      AppThemeMode themeMode, Translations translations) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final paidStudents =
        _activeStudents.where((s) => !s.hasOutstanding).length;
    final totalStudents = _activeStudents.length;

    final persentaseLunas =
        totalStudents > 0 ? (paidStudents / totalStudents * 100) : 0;

    final percentageText = persentaseLunas.toStringAsFixed(0);

    return ThemeHelper.buildSectionGroup(
      themeMode,
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translations.t('students_paid'),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$paidStudents / $totalStudents ${translations.t('students')}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: totalStudents > 0
                            ? paidStudents / totalStudents
                            : 0,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: AppColors.success,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translations
                          .t('payment_completion')
                          .replaceFirst('{percent}', percentageText),
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const LottieBenefits(size: 64),
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

  List<String> _getLast6MonthsLabels(Translations translations) {
    const monthKeys = [
      'month_january',
      'month_february',
      'month_march',
      'month_april',
      'month_may',
      'month_june',
      'month_july',
      'month_august',
      'month_september',
      'month_october',
      'month_november',
      'month_december',
    ];

    final now = DateTime.now();
    List<String> labels = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;

      if (month <= 0) {
        month += 12;
      }

      final monthName = translations.t(monthKeys[month - 1]);

      labels.add(_getShortMonthName(monthName, translations));
    }

    return labels;
  }

  // =========================================================
  // SHORT MONTH NAME
  // =========================================================

  String _getShortMonthName(String monthName, Translations translations) {
    final languageCode = translations.locale.languageCode;

    if (languageCode == 'en') {
      switch (monthName) {
        case 'January':
          return 'Jan';
        case 'February':
          return 'Feb';
        case 'March':
          return 'Mar';
        case 'April':
          return 'Apr';
        case 'May':
          return 'May';
        case 'June':
          return 'Jun';
        case 'July':
          return 'Jul';
        case 'August':
          return 'Aug';
        case 'September':
          return 'Sep';
        case 'October':
          return 'Oct';
        case 'November':
          return 'Nov';
        case 'December':
          return 'Dec';
      }
    }

    switch (monthName) {
      case 'Januari':
        return 'Jan';
      case 'Februari':
        return 'Feb';
      case 'Maret':
        return 'Mar';
      case 'April':
        return 'Apr';
      case 'Mei':
        return 'Mei';
      case 'Juni':
        return 'Jun';
      case 'Juli':
        return 'Jul';
      case 'Agustus':
        return 'Agu';
      case 'September':
        return 'Sep';
      case 'Oktober':
        return 'Okt';
      case 'November':
        return 'Nov';
      case 'Desember':
        return 'Des';
      default:
        return monthName;
    }
  }

  // =========================================================
  // MONTH VALUES
  // =========================================================

  List<double> _getLast6MonthsValues() {
    final now = DateTime.now();
    List<double> values = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;

      if (month <= 0) {
        month += 12;
      }

      values.add(_monthlyIncome[month] ?? 0);
    }

    return values;
  }

  // =========================================================
  // BAR CHART
  // =========================================================

  Widget _buildBarChart(
      List<String> labels, List<double> values, AppThemeMode themeMode) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final maxVal = values.reduce((a, b) => a > b ? a : b);

    final double maxY = maxVal > 0 ? maxVal : 1;

    final List<BarChartGroupData> barGroups = List.generate(
      labels.length,
      (index) {
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: values[index],
              color: colors.primary,
              width: 14,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        );
      },
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY * 1.2,
        minY: 0,
        groupsSpace: 16,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
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
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      labels[index],
                      style: theme.textTheme.labelMedium,
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
              reservedSize: 40,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == 0) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    '${(value / 1000).toInt()}k',
                    style: theme.textTheme.labelMedium,
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => colors.primary,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                'Rp ${formatCurrency(rod.toY)}',
                TextStyle(
                  color: colors.onPrimary,
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