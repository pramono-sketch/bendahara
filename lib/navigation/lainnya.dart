// navigation/lainnya.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../features/settings.dart';
import '../features/tambahkan.dart';
import '../features/ai_assistant.dart';
import '../features/database_akun.dart';
import '../features/log_aktivitas.dart';
import '../features/statistik.dart';
import '../features/tagihan.dart';
import '../features/gaji_guru.dart';
import '../templates/sound_helper.dart';
import '../simulation/lottie_prev.dart'; // Import halaman Lottie Gallery

class MorePage extends ConsumerStatefulWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    // Pengelompokan Menu
    final List<Map<String, dynamic>> keuanganItems = [
      {'title': 'Tagihan', 'icon': Icons.receipt_long, 'page': const TagihanPage()},
      {'title': 'Gaji Guru', 'icon': Icons.attach_money, 'page': const GajiGuruPage()},
      {'title': 'Statistik', 'icon': Icons.bar_chart, 'page': const StatistikPage()},
    ];

    final List<Map<String, dynamic>> dataItems = [
      {'title': 'Tambah Siswa', 'icon': Icons.person_add, 'page': const ManageStudentsPage()},
      {'title': 'Akun Digital', 'icon': Icons.vpn_key, 'page': const DatabaseAkunPage()},
      {'title': 'Log Aktivitas', 'icon': Icons.history, 'page': const LogAktivitasPage()},
    ];

    final List<Map<String, dynamic>> lainnyaItems = [
      {'title': 'AI Assistant', 'icon': Icons.auto_awesome, 'page': const AIAssistantPage()},
      {'title': 'Galeri Animasi', 'icon': Icons.animation, 'page': const LottieAnimationGallery()},
      {'title': 'Pengaturan', 'icon': Icons.settings, 'page': const SettingsPage()},
    ];

    return _buildThemedBackground(
      themeMode: themeMode,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Menu Lainnya'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            // ============================================
            // KEUANGAN
            // ============================================
            _buildSectionHeader(title: 'Keuangan', themeMode: themeMode),
            const SizedBox(height: 8),
            _buildSectionGroup(
              themeMode: themeMode,
              children: _buildMenuTiles(keuanganItems, colors, themeMode),
            ),
            const SizedBox(height: 24),

            // ============================================
            // MANAJEMEN DATA
            // ============================================
            _buildSectionHeader(title: 'Manajemen Data', themeMode: themeMode),
            const SizedBox(height: 8),
            _buildSectionGroup(
              themeMode: themeMode,
              children: _buildMenuTiles(dataItems, colors, themeMode),
            ),
            const SizedBox(height: 24),

            // ============================================
            // SISTEM & LAINNYA
            // ============================================
            _buildSectionHeader(title: 'Sistem & Lainnya', themeMode: themeMode),
            const SizedBox(height: 8),
            _buildSectionGroup(
              themeMode: themeMode,
              children: _buildMenuTiles(lainnyaItems, colors, themeMode),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ================== HELPER BUILDERS =======================
  // ==========================================================

  List<Widget> _buildMenuTiles(
      List<Map<String, dynamic>> items, ColorScheme colors, AppThemeMode themeMode) {
    List<Widget> tiles = [];
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      tiles.add(
        ListTile(
          leading: Icon(item['icon'] as IconData, color: colors.primary),
          title: Text(item['title'] as String),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await SoundHelper().playClick();
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item['page'] as Widget),
              );
            }
          },
        ),
      );
      if (i < items.length - 1) {
        tiles.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: _dividerColor(themeMode),
          ),
        );
      }
    }
    return tiles;
  }

  Widget _buildThemedBackground({
    required AppThemeMode themeMode,
    required Widget child,
  }) {
    if (themeMode == AppThemeMode.glassmorphism) {
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

    if (themeMode == AppThemeMode.aurora) {
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

    if (themeMode == AppThemeMode.cyberpunk) {
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
    if (mode == AppThemeMode.neumorphism)
      return AppColors.neoShadow.withValues(alpha: 0.20);
    if (mode == AppThemeMode.glassmorphism) return Colors.white.withValues(alpha: 0.2);
    if (mode == AppThemeMode.modern)
      return AppColors.modernDivider.withValues(alpha: 0.6);
    if (mode == AppThemeMode.aurora)
      return AppColors.auroraAccent1.withValues(alpha: 0.12);
    if (mode == AppThemeMode.cyberpunk)
      return AppColors.cyberAccent1.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  Widget _buildSectionHeader({
    required String title,
    required AppThemeMode themeMode,
  }) {
    final colors = Theme.of(context).colorScheme;

    Color labelColor;
    if (themeMode == AppThemeMode.neumorphism)
      labelColor = AppColors.neoTextSecondary;
    else if (themeMode == AppThemeMode.glassmorphism)
      labelColor = Colors.white.withValues(alpha: 0.8);
    else if (themeMode == AppThemeMode.modern)
      labelColor = AppColors.modernPrimary;
    else if (themeMode == AppThemeMode.aurora)
      labelColor = AppColors.auroraAccent1;
    else if (themeMode == AppThemeMode.cyberpunk)
      labelColor = AppColors.cyberAccent1;
    else
      labelColor = colors.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
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

  Widget _buildSectionGroup({
    required AppThemeMode themeMode,
    required List<Widget> children,
  }) {
    // NEUMORPHISM
    if (themeMode == AppThemeMode.neumorphism) {
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

    // GLASSMORPHISM
    if (themeMode == AppThemeMode.glassmorphism) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
    }

    // MODERN UI
    if (themeMode == AppThemeMode.modern) {
      return Container(
        decoration: modernDecoration(borderRadius: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // AURORA UI
    if (themeMode == AppThemeMode.aurora) {
      return Container(
        decoration: auroraDecoration(borderRadius: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // CYBERPUNK NEON
    if (themeMode == AppThemeMode.cyberpunk) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    // DEFAULT (Light / Dark)
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}