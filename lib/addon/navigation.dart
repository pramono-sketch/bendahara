// addon/navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';
import '../navigation/dashboard.dart';
import '../navigation/siswa.dart';
import '../navigation/laporan.dart';
import '../navigation/lainnya.dart';
import '../navigation/akun.dart';
import 'aksi.dart';
import '../helpers/sound_helper.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    StudentsPage(),
    ReportsPage(),
    MorePage(),
    AkunPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _pages[_currentIndex],
        ),

        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            SoundHelper().playClick(); // 🔥 suara bottom nav
            setState(() => _currentIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Siswa',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined),
              selectedIcon: Icon(Icons.assessment),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Lainnya',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_circle_outlined),
              selectedIcon: Icon(Icons.account_circle),
              label: 'Akun',
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            SoundHelper().playClick(); // 🔥 suara FAB
            AksiHelper.showFABMenu(
              context,
              () => setState(() {}),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Aksi'),
        ),
      ),
    );
  }
}