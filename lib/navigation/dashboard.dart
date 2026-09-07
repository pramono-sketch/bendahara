// navigation/dashboard.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../addon/aksi.dart';
import '../templates/custom_animation.dart';

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
  // FUNGSI FETCH DATA
  // =========================================================

  Future<Map<int, double>> _getMonthlyIncome() async {
    final transactions = await fetchAllTransactions();

    Map<int, double> monthly = {};

    for (var t in transactions) {
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

  Future<double> _getCurrentMonthIncome() async {
    final now = DateTime.now();
    final month = now.month;

    final transactions = await fetchAllTransactions();

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

    final transactions = await fetchAllTransactions();

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
    final transactions = await fetchAllTransactions();

    double total = 0;

    for (var t in transactions) {
      if (t.type == TransType.pemasukan) {
        total += t.amount;
      }
    }

    return total;
  }

  Future<double> _getTotalExpenseAllTime() async {
    final transactions = await fetchAllTransactions();

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
    final balance = totalIncome - totalExpense;

    final now = DateTime.now();

    int lastMonth = now.month - 1;
    int lastYear = now.year;

    if (lastMonth == 0) {
      lastMonth = 12;
      lastYear--;
    }

    final transactions = await fetchAllTransactions();

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

    final persentaseLunas = totalStudents > 0
        ? (paidStudents / totalStudents * 100)
        : 0;

    List<String> insights = [];

    if (persentaseLunas >= 80) {
      insights.add(
        '✅ ${persentaseLunas.toStringAsFixed(0)}% siswa sudah lunas. Bagus!',
      );
    } else if (persentaseLunas >= 50) {
      insights.add(
        '📊 ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. Masih ada PR menagih sisanya.',
      );
    } else {
      insights.add(
        '⚠️ Hanya ${persentaseLunas.toStringAsFixed(0)}% siswa lunas. Perlu strategi penagihan lebih agresif.',
      );
    }

    if (lastMonthIncome > 0 && totalIncome > 0) {
      final selisih = totalIncome - lastMonthIncome;
      final persenChange = (selisih / lastMonthIncome * 100);

      if (persenChange > 0) {
        insights.add(
          '📈 Pemasukan bulan ini naik ${persenChange.toStringAsFixed(1)}% dibanding bulan lalu.',
        );
      } else if (persenChange < 0) {
        insights.add(
          '📉 Pemasukan bulan ini turun ${persenChange.abs().toStringAsFixed(1)}% dibanding bulan lalu.',
        );
      } else {
        insights.add('➖ Pemasukan bulan ini stabil.');
      }
    } else if (totalIncome > 0 && lastMonthIncome == 0) {
      insights.add('💰 Bulan ini mulai ada pemasukan baru.');
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
      insights.add('⚖️ Saldo impas.');
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

  String _getGreeting() {
    var hour = DateTime.now().hour;

    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';

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
      'Desember'
    ];

    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];

    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  // =========================================================
  // THEME HELPERS
  // =========================================================

  bool _isNeo(AppThemeMode mode) =>
      mode == AppThemeMode.neumorphism;

  bool _isGlass(AppThemeMode mode) =>
      mode == AppThemeMode.glassmorphism;

  bool _isModern(AppThemeMode mode) =>
      mode == AppThemeMode.modern;

  bool _isAurora(AppThemeMode mode) =>
      mode == AppThemeMode.aurora;

  bool _isCyber(AppThemeMode mode) =>
      mode == AppThemeMode.cyberpunk;

  Color _getHeaderBgColor(
    AppThemeMode mode,
    ColorScheme colors,
  ) {
    if (_isNeo(mode)) return AppColors.neoBaseAlt;
    if (_isGlass(mode)) return AppColors.glassBg1;
    if (_isModern(mode)) return AppColors.modernPrimary;
    if (_isAurora(mode)) return AppColors.auroraSurface;
    if (_isCyber(mode)) return AppColors.cyberSurface;

    return colors.primary;
  }

  Color _getHeaderTextColor(
    AppThemeMode mode,
    ColorScheme colors,
  ) {
    if (_isNeo(mode)) return AppColors.neoTextPrimary;
    if (_isGlass(mode)) return AppColors.glassTextPrimary;
    if (_isModern(mode)) return Colors.white;
    if (_isAurora(mode)) return AppColors.auroraTextPrimary;
    if (_isCyber(mode)) return AppColors.cyberAccent1;

    return colors.onPrimary;
  }

  Widget _buildThemedBackground(
    AppThemeMode themeMode,
    Widget child,
  ) {
    if (_isGlass(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassBg1,
              AppColors.glassBg2,
              AppColors.glassBg3,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (_isAurora(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.auroraBg,
              AppColors.auroraBg2,
              AppColors.auroraBg3,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (_isCyber(themeMode)) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.8,
            colors: [
              AppColors.cyberBg,
              AppColors.cyberSurface.withValues(alpha: 0.5),
              AppColors.cyberBg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: child,
      );
    }

    return child;
  }

  Color _dividerColor(AppThemeMode mode) {
    if (_isNeo(mode)) {
      return AppColors.neoShadow.withValues(alpha: 0.20);
    }

    if (_isGlass(mode)) {
      return Colors.white.withValues(alpha: 0.2);
    }

    if (_isModern(mode)) {
      return AppColors.modernDivider.withValues(alpha: 0.6);
    }

    if (_isAurora(mode)) {
      return AppColors.auroraAccent1.withValues(alpha: 0.12);
    }

    if (_isCyber(mode)) {
      return AppColors.cyberAccent1.withValues(alpha: 0.15);
    }

    return Colors.transparent;
  }

  Widget _buildSectionHeader(
    String title,
    AppThemeMode themeMode,
  ) {
    final colors = Theme.of(context).colorScheme;

    Color labelColor;

    if (_isNeo(themeMode)) {
      labelColor = AppColors.neoTextSecondary;
    } else if (_isGlass(themeMode)) {
      labelColor = Colors.white.withValues(alpha: 0.8);
    } else if (_isModern(themeMode)) {
      labelColor = AppColors.modernPrimary;
    } else if (_isAurora(themeMode)) {
      labelColor = AppColors.auroraAccent1;
    } else if (_isCyber(themeMode)) {
      labelColor = AppColors.cyberAccent1;
    } else {
      labelColor = colors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        top: 2,
        bottom: 2,
      ),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: labelColor,
        ),
      ),
    );
  }

  Widget _buildSectionGroup(
    AppThemeMode themeMode,
    List<Widget> children,
  ) {
    if (_isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(
          borderRadius: 22,
          isPressed: false,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(
          borderRadius: 20,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
    }

    if (_isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(
          borderRadius: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(
          borderRadius: 22,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(
          borderRadius: 12,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // =========================================================
  // BUILD UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final headerBgColor =
        _getHeaderBgColor(themeMode, colors);

    final headerTextColor =
        _getHeaderTextColor(themeMode, colors);

    return _buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: headerTextColor,
        ),

        body: _isLoading
            ? const LottieLoading()
            : _hasError
                ? LottieError(
                    message:
                        'Gagal memuat data. Periksa koneksi internet Anda.',
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,

                    child: NotificationListener<
                        OverscrollIndicatorNotification>(
                      onNotification: (notification) {
                        notification.disallowIndicator();
                        return false;
                      },

                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),

                        padding: const EdgeInsets.only(
                          bottom: 32,
                        ),

                        children: [
                          // =====================================================
                          // HEADER + HERO CARD
                          // =====================================================

                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Background header
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 260,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: headerBgColor,
                                    borderRadius:
                                        const BorderRadius.only(
                                      bottomLeft:
                                          Radius.circular(36),
                                      bottomRight:
                                          Radius.circular(36),
                                    ),
                                  ),
                                ),
                              ),

                              // =================================================
                              // HEADER TEXT
                              // =================================================

                              Positioned(
                                top: MediaQuery.of(context)
                                        .padding
                                        .top +
                                    kToolbarHeight +
                                    10,
                                left: 20,
                                right: 20,
                                child: ScrollReveal(
                                  delay: const Duration(
                                    milliseconds: 50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Eduvest Finance',
                                        style: theme
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: headerTextColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
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
                                      const SizedBox(height: 4),
                                      Text(
                                        _getCurrentDate(),
                                        style: theme
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                          color: headerTextColor
                                              .withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // =================================================
                              // HERO CARD
                              // =================================================

                              ScrollReveal(
                                delay: const Duration(
                                  milliseconds: 120,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(
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
                                        padding:
                                            const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          'RINGKASAN SALDO',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight:
                                                FontWeight.w700,
                                            letterSpacing: 1.0,
                                            color:
                                                headerTextColor
                                                    .withOpacity(
                                              0.9,
                                            ),
                                          ),
                                        ),
                                      ),

                                      _buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .all(20),

                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  'Total Saldo Sekolah',
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium,
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
                                                        FontWeight
                                                            .bold,
                                                    color: colors
                                                        .primary,
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
                                                        AppColors
                                                            .success,
                                                        Icons
                                                            .arrow_upward,
                                                      ),
                                                    ),

                                                    Container(
                                                      width: 1,
                                                      height: 40,
                                                      color:
                                                          _dividerColor(
                                                        themeMode,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                      width: 16,
                                                    ),

                                                    Expanded(
                                                      child:
                                                          _buildBalanceItem(
                                                        'Pengeluaran',
                                                        _totalExpense,
                                                        AppColors
                                                            .error,
                                                        Icons
                                                            .arrow_downward,
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

                          // =====================================================
                          // KONTEN LAIN
                          // =====================================================

                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                // =================================================
                                // CHART
                                // =================================================

                                ScrollReveal(
                                  delay: const Duration(
                                    milliseconds: 100,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
                                        'Statistik Pemasukan (6 Bulan)',
                                        themeMode,
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      _buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .fromLTRB(
                                              8,
                                              20,
                                              16,
                                              8,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                SizedBox(
                                                  height: 200,
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

                                const SizedBox(height: 24),

                                // =================================================
                                // STATUS SISWA
                                // =================================================

                                ScrollReveal(
                                  delay: const Duration(
                                    milliseconds: 150,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
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

                                const SizedBox(height: 24),

                                // =================================================
                                // AI INSIGHT
                                // =================================================

                                ScrollReveal(
                                  delay: const Duration(
                                    milliseconds: 200,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSectionHeader(
                                        'Insight Keuangan',
                                        themeMode,
                                      ),

                                      const SizedBox(
                                        height: 8,
                                      ),

                                      _buildSectionGroup(
                                        themeMode,
                                        [
                                          Padding(
                                            padding:
                                                const EdgeInsets
                                                    .all(16),

                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,

                                              children: [
                                                SizedBox(
                                                  width: 40,
                                                  height: 40,

                                                  child:
                                                      Lottie.asset(
                                                    'assets/animations/ai animation Flow 1.json',

                                                    fit:
                                                        BoxFit.contain,

                                                    repeat: true,
                                                  ),
                                                ),

                                                const SizedBox(
                                                    width: 12),

                                                Expanded(
                                                  child: Text(
                                                    _aiInsight,

                                                    style: theme
                                                        .textTheme
                                                        .bodyMedium
                                                        ?.copyWith(
                                                      height: 1.4,
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: theme.textTheme.labelLarge,
            ),
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
    AppThemeMode themeMode,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final paidStudents =
        _activeStudents.where((s) => !s.hasOutstanding).length;

    final totalStudents =
        _activeStudents.length;

    final persentaseLunas = totalStudents > 0
        ? (paidStudents / totalStudents * 100)
        : 0;

    return _buildSectionGroup(
      themeMode,
      [
        Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Siswa Lunas',
                      style:
                          theme.textTheme.bodyMedium,
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$paidStudents / $totalStudents Siswa',

                      style: theme
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(8),

                      child:
                          LinearProgressIndicator(
                        value: totalStudents > 0
                            ? paidStudents /
                                totalStudents
                            : 0,

                        backgroundColor:
                            colors
                                .surfaceContainerHighest,

                        color:
                            AppColors.success,

                        minHeight: 8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '${persentaseLunas.toStringAsFixed(0)}% dari total siswa aktif telah melunasi pembayaran.',

                      style: theme
                          .textTheme
                          .labelMedium,
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Container(
                width: 80,
                height: 80,
                padding:
                    const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: AppColors.success
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),

                child: Lottie.asset(
                  'assets/animations/Benefits.json',
                  fit: BoxFit.contain,
                  repeat: true,
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

  List<String> _getLast6MonthsLabels() {
    List<String> monthLabels = [
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
      'Des'
    ];

    final now = DateTime.now();

    List<String> labels = [];

    for (int i = 5; i >= 0; i--) {
      int month = now.month - i;

      if (month <= 0) {
        month += 12;
      }

      labels.add(
        monthLabels[month - 1],
      );
    }

    return labels;
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

      values.add(
        _monthlyIncome[month] ?? 0,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final maxVal = values.reduce(
      (a, b) => a > b ? a : b,
    );

    final double maxY =
        maxVal > 0 ? maxVal : 1;

    List<BarChartGroupData> barGroups =
        List.generate(
      labels.length,
      (index) {
        return BarChartGroupData(
          x: index,

          barRods: [
            BarChartRodData(
              toY: values[index],
              color: colors.primary,
              width: 14,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
          ],
        );
      },
    );

    return BarChart(
      BarChartData(
        alignment:
            BarChartAlignment.spaceAround,

        maxY: maxY * 1.2,

        minY: 0,

        groupsSpace: 16,

        barGroups: barGroups,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,

          horizontalInterval:
              maxY / 4,

          getDrawingHorizontalLine:
              (value) {
            return FlLine(
              color:
                  _dividerColor(themeMode),
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

              getTitlesWidget:
                  (value, meta) {
                int index =
                    value.toInt();

                if (index >= 0 &&
                    index < labels.length) {
                  return Padding(
                    padding:
                        const EdgeInsets
                            .only(top: 8.0),

                    child: Text(
                      labels[index],
                      style: theme
                          .textTheme
                          .labelMedium,
                    ),
                  );
                }

                return const SizedBox
                    .shrink();
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,

              interval: maxY / 4,

              getTitlesWidget:
                  (value, meta) {
                if (value == 0) {
                  return const SizedBox
                      .shrink();
                }

                return Padding(
                  padding:
                      const EdgeInsets
                          .only(right: 4.0),

                  child: Text(
                    '${(value / 1000).toInt()}k',
                    style: theme
                        .textTheme
                        .labelMedium,
                  ),
                );
              },
            ),
          ),

          topTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),

          rightTitles:
              const AxisTitles(
            sideTitles:
                SideTitles(
              showTitles: false,
            ),
          ),
        ),

        borderData:
            FlBorderData(
          show: false,
        ),

        barTouchData:
            BarTouchData(
          enabled: true,

          touchTooltipData:
              BarTouchTooltipData(
            getTooltipColor:
                (_) => colors.primary,

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

// =========================================================
// SCROLL REVEAL
// PURE FLUTTER
// =========================================================
//
// Perbaikan utama:
// - Tidak memakai NotificationListener di dalam widget.
// - Sekarang langsung mendengarkan ScrollPosition dari ListView.
// - Widget yang berada di bawah tetap bisa mendeteksi saat masuk layar.
// - Saat aplikasi pertama dibuka, widget yang sudah terlihat langsung animasi.
// - Saat scroll, widget berikutnya muncul dengan fade + slide + scale.
// =========================================================

class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<ScrollReveal> createState() =>
      _ScrollRevealState();
}

class _ScrollRevealState
    extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _opacity;
  late Animation<Offset> _offset;
  late Animation<double> _scale;

  final GlobalKey _key = GlobalKey();

  ScrollPosition? _scrollPosition;

  bool _hasAnimated = false;
  bool _isScheduled = false;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,

      duration:
          const Duration(milliseconds: 650),
    );

    // Fade
    _opacity =
        Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Slide dari bawah ke posisi asli
    _offset =
        Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Sedikit membesar
    _scale =
        Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _attachScrollListener();
  }

  // =========================================================
  // HUBUNGKAN KE SCROLL LISTVIEW
  // =========================================================

  void _attachScrollListener() {
    try {
      final position =
          Scrollable.of(context).position;

      if (_scrollPosition == position) {
        return;
      }

      _scrollPosition
          ?.removeListener(_onScroll);

      _scrollPosition = position;

      _scrollPosition
          ?.addListener(_onScroll);

      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        _checkVisibility();
      });
    } catch (_) {
      // Scrollable belum tersedia.
      // Akan dicoba lagi melalui build lifecycle.
    }
  }

  // =========================================================
  // SAAT SCROLL
  // =========================================================

  void _onScroll() {
    _checkVisibility();
  }

  // =========================================================
  // CEK APAKAH WIDGET SUDAH MASUK LAYAR
  // =========================================================

  void _checkVisibility() {
    if (!mounted ||
        _hasAnimated ||
        _isScheduled) {
      return;
    }

    final ctx = _key.currentContext;

    if (ctx == null) {
      return;
    }

    final renderObject =
        ctx.findRenderObject();

    if (renderObject is! RenderBox ||
        !renderObject.attached) {
      return;
    }

    final position =
        renderObject.localToGlobal(
      Offset.zero,
    );

    final size =
        renderObject.size;

    final screenHeight =
        MediaQuery.of(context)
            .size
            .height;

    final top = position.dy;

    final bottom =
        position.dy + size.height;

    // Widget dianggap terlihat jika:
    // - bagian bawahnya sudah masuk viewport
    // - belum seluruhnya keluar ke atas
    //
    // Trigger sedikit sebelum benar-benar masuk
    // supaya animasinya terasa lebih natural.

    final bool isVisible =
        bottom > 70 &&
        top < screenHeight * 0.92;

    if (!isVisible) {
      return;
    }

    _hasAnimated = true;
    _isScheduled = true;

    Future.delayed(
      widget.delay,
      () {
        if (!mounted) return;

        _controller.forward();
      },
    );
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _scrollPosition
        ?.removeListener(_onScroll);

    _controller.dispose();

    super.dispose();
  }

  // =========================================================
  // BUILD ANIMASI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,

      child: FadeTransition(
        opacity: _opacity,

        child: SlideTransition(
          position: _offset,

          child: ScaleTransition(
            scale: _scale,

            child: widget.child,
          ),
        ),
      ),
    );
  }
}