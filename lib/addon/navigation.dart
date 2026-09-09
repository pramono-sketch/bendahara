// lib/addon/navigation.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';
import '../navigation/dashboard.dart';
import '../navigation/siswa.dart';
import '../navigation/laporan.dart';
import '../navigation/lainnya.dart';
import '../navigation/akun.dart';
import '../helpers/sound_helper.dart';
import '../l10n/translations.dart';
import 'aksi.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  // Digunakan untuk menentukan arah animasi perpindahan page.
  int _previousIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    StudentsPage(),
    ReportsPage(),
    MorePage(),
    AkunPage(),
  ];

  // ==================================================
  // ARAH ANIMASI HALAMAN
  // ==================================================

  int get _navigationDirection {
    if (_currentIndex > _previousIndex) {
      return 1;
    }

    if (_currentIndex < _previousIndex) {
      return -1;
    }

    return 1;
  }

  // ==================================================
  // GANTI PAGE
  // ==================================================

  void _changePage(int index) {
    if (index == _currentIndex) {
      SoundHelper().playClick();
      return;
    }

    SoundHelper().playClick();

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      themeModeProvider,
    );

    final translations = ref.watch(
      translationsProvider,
    );

    return ThemeHelper.buildThemedBackground(
      themeMode,

      Scaffold(
        backgroundColor: Colors.transparent,

        // ==================================================
        // BODY
        // ==================================================

        body: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 380,
          ),

          reverseDuration: const Duration(
            milliseconds: 320,
          ),

          switchInCurve: Curves.easeOutCubic,

          switchOutCurve: Curves.easeInCubic,

          transitionBuilder: (
            child,
            animation,
          ) {
            final int direction =
                _navigationDirection;

            final Tween<Offset> slideTween =
                Tween<Offset>(
              begin: Offset(
                direction.toDouble(),
                0,
              ),

              end: Offset.zero,
            );

            return SlideTransition(
              position: animation.drive(
                slideTween.chain(
                  CurveTween(
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),

              child: FadeTransition(
                opacity: animation.drive(
                  CurveTween(
                    curve: Curves.easeOut,
                  ),
                ),

                child: child,
              ),
            );
          },

          child: KeyedSubtree(
            key: ValueKey(_currentIndex),

            child: _pages[_currentIndex],
          ),
        ),

        // ==================================================
        // BOTTOM NAVIGATION
        // ==================================================

        bottomNavigationBar:
            _ModernBottomNavigation(
          currentIndex: _currentIndex,

          onDestinationSelected:
              _changePage,

          destinations: [
            // ----------------------------------------------
            // INDEX 0 = DASHBOARD / HOME
            // ----------------------------------------------

            _ModernNavItem(
              icon: Icons.home_outlined,

              selectedIcon:
                  Icons.home_rounded,

              label: translations.t(
                'dashboard',
              ),
            ),

            // ----------------------------------------------
            // INDEX 1 = SISWA
            // ----------------------------------------------

            _ModernNavItem(
              icon:
                  Icons.people_outline_rounded,

              selectedIcon:
                  Icons.people_rounded,

              label: translations.t(
                'students_nav',
              ),
            ),

            // ----------------------------------------------
            // INDEX 2 = LAPORAN
            // ----------------------------------------------

            _ModernNavItem(
              icon:
                  Icons.assessment_outlined,

              selectedIcon:
                  Icons.assessment_rounded,

              label: translations.t(
                'reports',
              ),
            ),

            // ----------------------------------------------
            // INDEX 3 = LAINNYA
            // ----------------------------------------------

            _ModernNavItem(
              icon:
                  Icons.more_horiz_outlined,

              selectedIcon:
                  Icons.more_horiz_rounded,

              label: translations.t(
                'more',
              ),
            ),

            // ----------------------------------------------
            // INDEX 4 = AKUN
            // ----------------------------------------------

            _ModernNavItem(
              icon:
                  Icons.person_outline_rounded,

              selectedIcon:
                  Icons.person_rounded,

              label: translations.t(
                'account',
              ),
            ),
          ],
        ),

        // ==================================================
        // FLOATING ACTION BUTTON
        // ==================================================

        floatingActionButton:
            FloatingActionButton.extended(
          onPressed: () {
            SoundHelper().playClick();

            AksiHelper.showFABMenu(
              context,
              () => setState(() {}),
            );
          },

          icon: const Icon(
            Icons.add,
          ),

          label: Text(
            translations.t(
              'action',
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DATA ITEM
// ============================================================================

class _ModernNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

// ============================================================================
// MODERN BOTTOM NAVIGATION
// ============================================================================

class _ModernBottomNavigation
    extends StatefulWidget {
  final int currentIndex;

  final ValueChanged<int>
      onDestinationSelected;

  final List<_ModernNavItem> destinations;

  const _ModernBottomNavigation({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  State<_ModernBottomNavigation>
      createState() =>
          _ModernBottomNavigationState();
}

// ============================================================================
// STATE
// ============================================================================

class _ModernBottomNavigationState
    extends State<_ModernBottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  double _fromIndex = 0;
  double _toIndex = 0;

  @override
  void initState() {
    super.initState();

    _fromIndex =
        widget.currentIndex.toDouble();

    _toIndex =
        widget.currentIndex.toDouble();

    _controller = AnimationController(
      vsync: this,

      duration: const Duration(
        milliseconds: 360,
      ),

      value: 1,
    );
  }

  @override
  void didUpdateWidget(
    covariant _ModernBottomNavigation oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (oldWidget.currentIndex !=
        widget.currentIndex) {
      final double currentPosition =
          lerpDouble(
                _fromIndex,
                _toIndex,
                Curves.easeInOutCubic.transform(
                  _controller.value,
                ),
              ) ??
              _toIndex;

      _fromIndex = currentPosition;

      _toIndex =
          widget.currentIndex.toDouble();

      _controller
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ==================================================
  // ITEM INDEX BERDASARKAN POSISI VISUAL
  // ==================================================

  //
  // Kiri:
  //   Siswa   = index 1
  //   Laporan = index 2
  //
  // Tengah:
  //   Home    = index 0
  //
  // Kanan:
  //   Lainnya = index 3
  //   Akun    = index 4
  //

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final bool isDark =
        theme.brightness ==
            Brightness.dark;

    // ==================================================
    // WARNA MENGIKUTI TEMA
    // ==================================================

    final Color backgroundColor =
        colorScheme.surface;

    final Color activeColor =
        colorScheme.primary;

    final Color onActiveColor =
        colorScheme.onPrimary;

    final Color inactiveColor =
        colorScheme.onSurfaceVariant;

    final Color borderColor =
        colorScheme.outline.withValues(
      alpha: isDark ? 0.18 : 0.10,
    );

    final Color bottomLineColor =
        activeColor.withValues(
      alpha: isDark ? 0.65 : 0.42,
    );

    return SafeArea(
      top: false,

      minimum: const EdgeInsets.only(
        bottom: 3,
      ),

      child: SizedBox(
        height: 72,

        child: LayoutBuilder(
          builder: (
            context,
            constraints,
          ) {
            return Stack(
              clipBehavior:
                  Clip.none,

              children: [
                // ==================================================
                // BACKGROUND BOTTOM NAVIGATION
                // ==================================================

                Positioned.fill(
                  child: CustomPaint(
                    painter:
                        _BottomNavigationBackgroundPainter(
                      backgroundColor:
                          backgroundColor,

                      borderColor:
                          borderColor,

                      bottomLineColor:
                          bottomLineColor,

                      isDark:
                          isDark,
                    ),
                  ),
                ),

                // ==================================================
                // SIDE NAVIGATION
                // ==================================================

                Positioned.fill(
                  child: Row(
                    children: [
                      // ==================================================
                      // LEFT SIDE
                      // ==================================================

                      Expanded(
                        child: _SideNavigationItem(
                          item:
                              widget.destinations[1],

                          pageIndex: 1,

                          isSelected:
                              widget.currentIndex ==
                                  1,

                          activeColor:
                              activeColor,

                          inactiveColor:
                              inactiveColor,

                          onTap: () {
                            widget
                                .onDestinationSelected(
                              1,
                            );
                          },
                        ),
                      ),

                      Expanded(
                        child: _SideNavigationItem(
                          item:
                              widget.destinations[2],

                          pageIndex: 2,

                          isSelected:
                              widget.currentIndex ==
                                  2,

                          activeColor:
                              activeColor,

                          inactiveColor:
                              inactiveColor,

                          onTap: () {
                            widget
                                .onDestinationSelected(
                              2,
                            );
                          },
                        ),
                      ),

                      // ==================================================
                      // TENGAH — DIKOSONGKAN UNTUK HOME
                      // ==================================================

                      const Expanded(
                        child: SizedBox(),
                      ),

                      // ==================================================
                      // RIGHT SIDE
                      // ==================================================

                      Expanded(
                        child: _SideNavigationItem(
                          item:
                              widget.destinations[3],

                          pageIndex: 3,

                          isSelected:
                              widget.currentIndex ==
                                  3,

                          activeColor:
                              activeColor,

                          inactiveColor:
                              inactiveColor,

                          onTap: () {
                            widget
                                .onDestinationSelected(
                              3,
                            );
                          },
                        ),
                      ),

                      Expanded(
                        child: _SideNavigationItem(
                          item:
                              widget.destinations[4],

                          pageIndex: 4,

                          isSelected:
                              widget.currentIndex ==
                                  4,

                          activeColor:
                              activeColor,

                          inactiveColor:
                              inactiveColor,

                          onTap: () {
                            widget
                                .onDestinationSelected(
                              4,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CENTER HOME BUTTON
                // ==================================================

                Positioned(
                  left:
                      constraints.maxWidth / 2 -
                          28,

                  top: -18,

                  child:
                      _CenterHomeButton(
                    item:
                        widget.destinations[0],

                    isSelected:
                        widget.currentIndex ==
                            0,

                    activeColor:
                        activeColor,

                    onActiveColor:
                        onActiveColor,

                    onTap: () {
                      widget
                          .onDestinationSelected(
                        0,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// SIDE NAVIGATION ITEM
// ============================================================================

class _SideNavigationItem
    extends StatelessWidget {
  final _ModernNavItem item;

  final int pageIndex;

  final bool isSelected;

  final Color activeColor;

  final Color inactiveColor;

  final VoidCallback onTap;

  const _SideNavigationItem({
    required this.item,
    required this.pageIndex,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color =
        isSelected
            ? activeColor
            : inactiveColor;

    return Semantics(
      button: true,

      selected: isSelected,

      label: item.label,

      child: Material(
        color:
            Colors.transparent,

        child: InkWell(
          onTap: onTap,

          splashColor:
              activeColor.withValues(
            alpha: 0.08,
          ),

          highlightColor:
              activeColor.withValues(
            alpha: 0.04,
          ),

          child: SizedBox(
            height: 72,

            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,

              children: [
                // ==================================================
                // ICON
                // ==================================================

                AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),

                  transitionBuilder:
                      (
                    child,
                    animation,
                  ) {
                    return FadeTransition(
                      opacity:
                          animation,

                      child:
                          ScaleTransition(
                        scale:
                            animation,

                        child:
                            child,
                      ),
                    );
                  },

                  child: Icon(
                    isSelected
                        ? item.selectedIcon
                        : item.icon,

                    key: ValueKey(
                      isSelected,
                    ),

                    size: 21,

                    color: color,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                // ==================================================
                // LABEL
                // ==================================================

                AnimatedDefaultTextStyle(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),

                  style: TextStyle(
                    color: color,

                    fontSize: 10,

                    fontWeight:
                        isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,

                    height: 1,

                    letterSpacing: 0,
                  ),

                  child: Text(
                    item.label,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    textAlign:
                        TextAlign.center,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                // ==================================================
                // ACTIVE LINE
                // ==================================================

                AnimatedContainer(
                  duration:
                      const Duration(
                    milliseconds: 220,
                  ),

                  curve:
                      Curves.easeOutCubic,

                  width:
                      isSelected ? 18 : 0,

                  height: 2,

                  decoration:
                      BoxDecoration(
                    color:
                        activeColor,

                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// CENTER HOME BUTTON
// ============================================================================

class _CenterHomeButton
    extends StatelessWidget {
  final _ModernNavItem item;

  final bool isSelected;

  final Color activeColor;

  final Color onActiveColor;

  final VoidCallback onTap;

  const _CenterHomeButton({
    required this.item,
    required this.isSelected,
    required this.activeColor,
    required this.onActiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,

      selected: isSelected,

      label: item.label,

      child: Material(
        color:
            Colors.transparent,

        child: InkWell(
          onTap: onTap,

          customBorder:
              const CircleBorder(),

          splashColor:
              Colors.white.withValues(
            alpha: 0.16,
          ),

          highlightColor:
              Colors.white.withValues(
            alpha: 0.08,
          ),

          child: AnimatedScale(
            scale:
                isSelected
                    ? 1.0
                    : 0.94,

            duration:
                const Duration(
              milliseconds: 260,
            ),

            curve:
                Curves.easeOutBack,

            child: AnimatedContainer(
              duration:
                  const Duration(
                milliseconds: 280,
              ),

              curve:
                  Curves.easeOutCubic,

              width: 56,

              height: 56,

              decoration:
                  BoxDecoration(
                shape:
                    BoxShape.circle,

                color:
                    activeColor,

                border:
                    Border.all(
                  color:
                      Theme.of(
                    context,
                  )
                          .colorScheme
                          .surface
                          .withValues(
                    alpha: 0.95,
                  ),

                  width: 3,
                ),

                boxShadow: [
                  BoxShadow(
                    color:
                        activeColor
                            .withValues(
                      alpha:
                          isSelected
                              ? 0.38
                              : 0.22,
                    ),

                    blurRadius:
                        isSelected
                            ? 18
                            : 12,

                    spreadRadius:
                        isSelected
                            ? 1
                            : 0,

                    offset:
                        const Offset(
                      0,
                      5,
                    ),
                  ),
                ],
              ),

              child: Center(
                child:
                    AnimatedSwitcher(
                  duration:
                      const Duration(
                    milliseconds: 180,
                  ),

                  transitionBuilder:
                      (
                    child,
                    animation,
                  ) {
                    return FadeTransition(
                      opacity:
                          animation,

                      child:
                          ScaleTransition(
                        scale:
                            animation,

                        child:
                            child,
                      ),
                    );
                  },

                  child: Icon(
                    item.selectedIcon,

                    key: ValueKey(
                      isSelected,
                    ),

                    size: 27,

                    color:
                        onActiveColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// BACKGROUND BOTTOM NAVIGATION PAINTER
// ============================================================================

class _BottomNavigationBackgroundPainter
    extends CustomPainter {
  final Color backgroundColor;

  final Color borderColor;

  final Color bottomLineColor;

  final bool isDark;

  const _BottomNavigationBackgroundPainter({
    required this.backgroundColor,
    required this.borderColor,
    required this.bottomLineColor,
    required this.isDark,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    // ==================================================
    // POSISI NOTCH TENGAH
    // ==================================================

    final double centerX =
        size.width / 2;

    // Lebar cekungan.
    final double notchWidth =
        76;

    // Seberapa dalam cekungan masuk
    // ke background navigation.
    final double notchDepth =
        18;

    final double notchStart =
        centerX -
            notchWidth / 2;

    final double notchEnd =
        centerX +
            notchWidth / 2;

    // ==================================================
    // BACKGROUND PATH
    // ==================================================

    final Path path =
        Path();

    path.moveTo(
      0,
      0,
    );

    // --------------------------------------------------
    // KIRI KE NOTCH
    // --------------------------------------------------

    path.lineTo(
      notchStart,
      0,
    );

    // --------------------------------------------------
    // TURUN KE NOTCH
    // --------------------------------------------------

    path.cubicTo(
      notchStart + 9,
      0,

      notchStart + 9,
      notchDepth,

      centerX,
      notchDepth,
    );

    // --------------------------------------------------
    // NAIK DARI NOTCH
    // --------------------------------------------------

    path.cubicTo(
      notchEnd - 9,
      notchDepth,

      notchEnd - 9,
      0,

      notchEnd,
      0,
    );

    // --------------------------------------------------
    // KE UJUNG KANAN
    // --------------------------------------------------

    path.lineTo(
      size.width,
      0,
    );

    // --------------------------------------------------
    // TURUN KE BAWAH
    // --------------------------------------------------

    path.lineTo(
      size.width,
      size.height,
    );

    path.lineTo(
      0,
      size.height,
    );

    path.close();

    // ==================================================
    // SHADOW
    // ==================================================

    final Paint shadowPaint =
        Paint()
          ..color =
              Colors.black.withValues(
            alpha:
                isDark
                    ? 0.18
                    : 0.06,
          )
          ..style =
              PaintingStyle.fill
          ..maskFilter =
              const MaskFilter.blur(
            BlurStyle.normal,
            7,
          );

    final Path shadowPath =
        path.shift(
      const Offset(
        0,
        1,
      ),
    );

    canvas.drawPath(
      shadowPath,
      shadowPaint,
    );

    // ==================================================
    // BACKGROUND
    // ==================================================

    final Paint backgroundPaint =
        Paint()
          ..color =
              backgroundColor
          ..style =
              PaintingStyle.fill;

    canvas.drawPath(
      path,
      backgroundPaint,
    );

    // ==================================================
    // BORDER
    // ==================================================

    final Paint borderPaint =
        Paint()
          ..color =
              borderColor
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1;

    canvas.drawPath(
      path,
      borderPaint,
    );

    // ==================================================
    // GARIS BAGIAN BAWAH
    // ==================================================

    final Paint bottomLinePaint =
        Paint()
          ..color =
              bottomLineColor
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap =
              StrokeCap.round;

    canvas.drawLine(
      Offset(
        12,
        size.height - 1,
      ),

      Offset(
        size.width - 12,
        size.height - 1,
      ),

      bottomLinePaint,
    );

    // ==================================================
    // GARIS HALUS DI SISI NOTCH
    // ==================================================

    final Paint notchPaint =
        Paint()
          ..color =
              borderColor
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1;

    final Path notchLine =
        Path();

    notchLine.moveTo(
      notchStart,
      0,
    );

    notchLine.cubicTo(
      notchStart + 9,
      0,

      notchStart + 9,
      notchDepth,

      centerX,
      notchDepth,
    );

    notchLine.cubicTo(
      notchEnd - 9,
      notchDepth,

      notchEnd - 9,
      0,

      notchEnd,
      0,
    );

    canvas.drawPath(
      notchLine,
      notchPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _BottomNavigationBackgroundPainter
        oldDelegate,
  ) {
    return oldDelegate.backgroundColor !=
            backgroundColor ||
        oldDelegate.borderColor !=
            borderColor ||
        oldDelegate.bottomLineColor !=
            bottomLineColor ||
        oldDelegate.isDark !=
            isDark;
  }
}