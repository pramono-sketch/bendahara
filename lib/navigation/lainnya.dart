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
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../l10n/translations.dart';
import '../templates/sound_helper.dart';
import '../simulation/lottie_prev.dart';

class MorePage extends ConsumerStatefulWidget {
  const MorePage({super.key});

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final translations = ref.watch(translationsProvider);
    final colors = Theme.of(context).colorScheme;

    final List<Map<String, dynamic>> keuanganItems = [
      {
        'title': translations.t('bills'),
        'icon': Icons.receipt_long,
        'page': const TagihanPage(),
      },
      {
        'title': translations.t('teacher_salary'),
        'icon': Icons.attach_money,
        'page': const GajiGuruPage(),
      },
      {
        'title': translations.t('statistics'),
        'icon': Icons.bar_chart,
        'page': const StatistikPage(),
      },
    ];

    final List<Map<String, dynamic>> dataItems = [
      {
        'title': translations.t('add_student'),
        'icon': Icons.person_add,
        'page': const ManageStudentsPage(),
      },
      {
        'title': translations.t('digital_account'),
        'icon': Icons.vpn_key,
        'page': const DatabaseAkunPage(),
      },
      {
        'title': translations.t('activity_log'),
        'icon': Icons.history,
        'page': const LogAktivitasPage(),
      },
    ];

    final List<Map<String, dynamic>> lainnyaItems = [
      {
        'title': translations.t('ai_assistant'),
        'icon': Icons.auto_awesome,
        'page': const AIAssistantPage(),
      },
      {
        'title': translations.t('animation_gallery'),
        'icon': Icons.animation,
        'page': const LottieAnimationGallery(),
      },
      {
        'title': translations.t('settings'),
        'icon': Icons.settings,
        'page': const SettingsPage(),
      },
    ];

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        appBar: AppBar(
          title: Text(translations.t('more_menu')),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            10,
            16,
            32,
          ),
          children: [
            ScrollReveal(
              child: ThemeHelper.buildSectionHeader(
                context,
                translations.t('finance'),
                themeMode,
              ),
            ),

            const SizedBox(height: 8),

            ScrollReveal(
              delay: const Duration(milliseconds: 80),
              child: ThemeHelper.buildSectionGroup(
                themeMode,
                _buildMenuTiles(
                  keuanganItems,
                  colors,
                  themeMode,
                ),
              ),
            ),

            const SizedBox(height: 24),

            ScrollReveal(
              delay: const Duration(milliseconds: 140),
              child: ThemeHelper.buildSectionHeader(
                context,
                translations.t('data_management'),
                themeMode,
              ),
            ),

            const SizedBox(height: 8),

            ScrollReveal(
              delay: const Duration(milliseconds: 200),
              child: ThemeHelper.buildSectionGroup(
                themeMode,
                _buildMenuTiles(
                  dataItems,
                  colors,
                  themeMode,
                ),
              ),
            ),

            const SizedBox(height: 24),

            ScrollReveal(
              delay: const Duration(milliseconds: 260),
              child: ThemeHelper.buildSectionHeader(
                context,
                translations.t('system_more'),
                themeMode,
              ),
            ),

            const SizedBox(height: 8),

            ScrollReveal(
              delay: const Duration(milliseconds: 320),
              child: ThemeHelper.buildSectionGroup(
                themeMode,
                _buildMenuTiles(
                  lainnyaItems,
                  colors,
                  themeMode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMenuTiles(
    List<Map<String, dynamic>> items,
    ColorScheme colors,
    AppThemeMode themeMode,
  ) {
    final List<Widget> tiles = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      tiles.add(
        ListTile(
          leading: Icon(
            item['icon'] as IconData,
            color: colors.primary,
          ),
          title: Text(
            item['title'] as String,
          ),
          trailing: const Icon(
            Icons.chevron_right,
          ),
          onTap: () async {
            await SoundHelper().playClick();

            if (!mounted) {
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => item['page'] as Widget,
              ),
            );
          },
        ),
      );

      if (i < items.length - 1) {
        tiles.add(
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: ThemeHelper.dividerColor(
              themeMode,
            ),
          ),
        );
      }
    }

    return tiles;
  }
}