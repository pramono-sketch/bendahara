// lib/features/settings.dart

import 'dart:ui';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/scroll_reveal.dart';
import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';
import '../l10n/translations.dart';
import '../templates/sound_helper.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double _volume = 0.7;

  int _backupClickCount = 0;

  bool _easterEggActivated = false;

  bool _easterEggFooterEnabled = false;

  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();

    _volume = SoundHelper().getVolume();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final translations = ref.watch(translationsProvider);

    final currentLocale = ref.watch(localeProvider);

    final currentThemeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(translations.t('settings')),
        ),

        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),

          children: [
            // ============================================
            // TAMPILAN
            // ============================================
            ScrollReveal(
              delay: const Duration(milliseconds: 50),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  ThemeHelper.buildSectionHeader(
                    context,
                    translations.t('appearance'),
                    themeMode,
                  ),

                  const SizedBox(height: 8),

                  ThemeHelper.buildSectionGroup(themeMode, [
                    ListTile(
                      leading: Icon(
                        Icons.palette_outlined,
                        color: colors.primary,
                      ),

                      title: Text(translations.t('app_theme')),

                      subtitle: Text(
                        _getThemeLabel(currentThemeMode, translations),
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _showThemeDialog(context, ref),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================
            // PREFERENSI
            // ============================================
            ScrollReveal(
              delay: const Duration(milliseconds: 120),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  ThemeHelper.buildSectionHeader(
                    context,
                    translations.t('preferences'),
                    themeMode,
                  ),

                  const SizedBox(height: 8),

                  ThemeHelper.buildSectionGroup(themeMode, [
                    // -----------------------------------
                    // VOLUME
                    // -----------------------------------
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.volume_up_outlined,
                                color: colors.primary,
                                size: 22,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      translations.t('sound_volume'),

                                      style: theme.textTheme.titleMedium,
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      '${(_volume * 100).toInt()}%',

                                      style: theme.textTheme.labelLarge,
                                    ),
                                  ],
                                ),
                              ),

                              IconButton(
                                tooltip: _volume == 0
                                    ? translations.t('enable_sound')
                                    : translations.t('mute_sound'),

                                icon: Icon(
                                  _volume == 0
                                      ? Icons.volume_off_outlined
                                      : Icons.volume_up_outlined,

                                  color: colors.primary,
                                ),

                                onPressed: () {
                                  final newVolume = _volume == 0 ? 1.0 : 0.0;

                                  setState(() => _volume = newVolume);

                                  SoundHelper().setVolume(newVolume);

                                  SoundHelper().playClick();
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Slider(
                            value: _volume,

                            min: 0,

                            max: 1,

                            divisions: 10,

                            label: '${(_volume * 100).toInt()}%',

                            onChanged: (value) {
                              setState(() => _volume = value);

                              SoundHelper().setVolume(value);

                              SoundHelper().playClick();
                            },
                          ),
                        ],
                      ),
                    ),

                    Divider(
                      height: 1,

                      color: ThemeHelper.dividerColor(themeMode),
                    ),

                    // -----------------------------------
                    // NOTIFICATIONS
                    // -----------------------------------
                    SwitchListTile(
                      secondary: Icon(
                        Icons.notifications_none_outlined,
                        color: colors.primary,
                      ),

                      title: Text(translations.t('notifications')),

                      subtitle: Text(translations.t('enable_notifications')),

                      value: _notificationsEnabled,

                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              translations.t('feature_unavailable'),
                            ),

                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),

                    Divider(
                      height: 1,

                      color: ThemeHelper.dividerColor(themeMode),
                    ),

                    // -----------------------------------
                    // LANGUAGE
                    // -----------------------------------
                    ListTile(
                      leading: Icon(
                        Icons.language_outlined,
                        color: colors.primary,
                      ),

                      title: Text(translations.t('language')),

                      subtitle: Text(
                        currentLocale.languageCode == 'en'
                            ? translations.t('english')
                            : translations.t('indonesian'),
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _showLanguageDialog(context, ref),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================
            // DATA
            // ============================================
            ScrollReveal(
              delay: const Duration(milliseconds: 190),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  ThemeHelper.buildSectionHeader(
                    context,
                    translations.t('data'),
                    themeMode,
                  ),

                  const SizedBox(height: 8),

                  ThemeHelper.buildSectionGroup(themeMode, [
                    ListTile(
                      leading: Icon(
                        Icons.cloud_upload_outlined,
                        color: colors.primary,
                      ),

                      title: Text(translations.t('backup_data')),

                      subtitle: Text(translations.t('backup_subtitle')),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _handleBackupTap(context, ref),
                    ),

                    if (_easterEggActivated) ...[
                      Divider(
                        height: 1,
                        color: ThemeHelper.dividerColor(themeMode),
                      ),

                      SwitchListTile(
                        secondary: const Icon(Icons.egg_outlined),

                        title: Text(translations.t('show_easter_egg')),

                        subtitle: Text(translations.t('easter_egg_subtitle')),

                        value: _easterEggFooterEnabled,

                        onChanged: (value) {
                          setState(() => _easterEggFooterEnabled = value);
                        },
                      ),
                    ],
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ============================================
            // TENTANG
            // ============================================
            ScrollReveal(
              delay: const Duration(milliseconds: 260),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  ThemeHelper.buildSectionHeader(
                    context,
                    translations.t('about'),
                    themeMode,
                  ),

                  const SizedBox(height: 8),

                  ThemeHelper.buildSectionGroup(themeMode, [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: colors.primary),

                      title: Text(translations.t('about')),

                      subtitle: Text(translations.t('version')),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: () => _showAboutDialog(context, ref),
                    ),
                  ]),
                ],
              ),
            ),

            // ============================================
            // EASTER EGG FOOTER
            // ============================================
            if (_easterEggActivated && _easterEggFooterEnabled) ...[
              const SizedBox(height: 20),

              ScrollReveal(
                delay: const Duration(milliseconds: 330),

                child: _buildEasterEggFooter(
                  themeMode: themeMode,
                  colors: colors,
                  translations: translations,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ================= EASTER EGG FOOTER ======================
  // ==========================================================

  Widget _buildEasterEggFooter({
    required AppThemeMode themeMode,
    required ColorScheme colors,
    required Translations translations,
  }) {
    // NEOMORPHISM
    if (ThemeHelper.isNeo(themeMode)) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: neumorphismDecoration(borderRadius: 16, isPressed: false),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('🥚', style: TextStyle(fontSize: 22)),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                translations.t('easter_egg_found'),

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9B2C2C),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // GLASSMORPHISM
    if (ThemeHelper.isGlass(themeMode)) {
      return Container(
        width: double.infinity,

        decoration: glassmorphismDecoration(borderRadius: 16),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),

          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text('🥚', style: TextStyle(fontSize: 22)),

                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      translations.t('easter_egg_found'),

                      textAlign: TextAlign.center,

                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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

    // MODERN UI
    if (ThemeHelper.isModern(themeMode)) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: modernDecoration(borderRadius: 16),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('🥚', style: TextStyle(fontSize: 22)),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                translations.t('easter_egg_found'),

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.modernPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AURORA UI
    if (ThemeHelper.isAurora(themeMode)) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: auroraDecoration(borderRadius: 16),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('🥚', style: TextStyle(fontSize: 22)),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                translations.t('easter_egg_found'),

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.auroraAccent1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // CYBERPUNK
    if (ThemeHelper.isCyber(themeMode)) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: cyberpunkDecoration(borderRadius: 12),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Text('🥚', style: TextStyle(fontSize: 22)),

            const SizedBox(width: 8),

            Flexible(
              child: Text(
                translations.t('easter_egg_found'),

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyberAccent1,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // DEFAULT LIGHT / DARK
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          const Text('🥚', style: TextStyle(fontSize: 22)),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              translations.t('easter_egg_found'),

              textAlign: TextAlign.center,

              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ==================== THEME DIALOG ========================
  // ==========================================================

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);

    final translations = ref.read(translationsProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: Text(translations.t('select_theme')),

          content: SizedBox(
            width: double.maxFinite,

            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: AppThemeMode.values.map((mode) {
                  return RadioListTile<AppThemeMode>(
                    title: Row(
                      children: [
                        _buildThemeIcon(mode),

                        const SizedBox(width: 12),

                        Text(_getThemeLabel(mode, translations)),
                      ],
                    ),

                    value: mode,

                    groupValue: current,

                    contentPadding: EdgeInsets.zero,

                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      ref.read(themeModeProvider.notifier).setTheme(value);

                      Navigator.pop(ctx);
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),

              child: Text(translations.t('close')),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ================ THEME ICON PREVIEW =====================
  // ==========================================================

  Widget _buildThemeIcon(AppThemeMode mode) {
    final icon = switch (mode) {
      AppThemeMode.light => Icons.light_mode_outlined,

      AppThemeMode.dark => Icons.dark_mode_outlined,

      AppThemeMode.neumorphism => Icons.blur_on,

      AppThemeMode.glassmorphism => Icons.water_drop_outlined,

      AppThemeMode.modern => Icons.widgets_outlined,

      AppThemeMode.aurora => Icons.auto_awesome,

      AppThemeMode.cyberpunk => Icons.bolt,

      AppThemeMode.system => Icons.settings_suggest_outlined,
    };

    return Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary);
  }

  // ==========================================================
  // ====================== THEME LABEL =======================
  // ==========================================================

  String _getThemeLabel(AppThemeMode mode, Translations translations) {
    switch (mode) {
      case AppThemeMode.light:
        return translations.t('theme_light');

      case AppThemeMode.dark:
        return translations.t('theme_dark');

      case AppThemeMode.neumorphism:
        return translations.t('theme_neumorphism');

      case AppThemeMode.glassmorphism:
        return translations.t('theme_glassmorphism');

      case AppThemeMode.modern:
        return translations.t('theme_modern');

      case AppThemeMode.aurora:
        return translations.t('theme_aurora');

      case AppThemeMode.cyberpunk:
        return translations.t('theme_cyberpunk');

      case AppThemeMode.system:
        return translations.t('theme_system');
    }
  }

  // ==========================================================
  // ================= BACKUP / EASTER EGG ====================
  // ==========================================================

  void _handleBackupTap(BuildContext context, WidgetRef ref) {
    final translations = ref.read(translationsProvider);

    setState(() => _backupClickCount++);

    debugPrint('[SettingsPage] Backup tile tapped. Count: $_backupClickCount');

    if (_backupClickCount == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translations.t('easter_egg_hint')),

          duration: const Duration(seconds: 2),
        ),
      );

      debugPrint('[SettingsPage] Easter egg hint shown at count 3.');
    } else if (_backupClickCount == 5) {
      debugPrint('[SettingsPage] Easter egg dialog shown at count 5.');

      AwesomeDialog(
        context: context,

        dialogType: DialogType.info,

        animType: AnimType.bottomSlide,

        title: translations.t('easter_egg_title'),

        desc: translations.t('easter_egg_desc'),

        btnOkOnPress: () {},

        btnOkText: translations.t('ok'),
      ).show();
    } else if (_backupClickCount >= 7) {
      setState(() {
        _easterEggActivated = true;

        _easterEggFooterEnabled = true;

        _backupClickCount = 0;
      });

      debugPrint(
        '[SettingsPage] Easter egg activated permanently. Launching WhatsApp...',
      );

      _launchWhatsApp(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(translations.t('backup_not_ready')),

          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==========================================================
  // ===================== WHATSAPP ===========================
  // ==========================================================

  Future<void> _launchWhatsApp(BuildContext context) async {
    const phone = '6287833467630';

    const message =
        'Admin, saya menemukan easter egg di aplikasi Bendahara. '
        'Terima kasih atas kerja kerasnya! '
        'Semangat terus Admin, semoga sehat selalu dan sukses selalu.';

    final encodedMessage = Uri.encodeComponent(message);

    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');

    final whatsappSchemeUrl = Uri.parse(
      'whatsapp://send?phone=$phone&text=$encodedMessage',
    );

    debugPrint('[SettingsPage] WhatsApp launch requested.');

    debugPrint('[SettingsPage] Primary URL: $webUrl');

    debugPrint('[SettingsPage] Fallback URL: $whatsappSchemeUrl');

    try {
      final webLaunched = await launchUrl(
        webUrl,
        mode: LaunchMode.externalApplication,
      );

      if (webLaunched) {
        debugPrint('[SettingsPage] WhatsApp web URL launched successfully.');

        return;
      }

      debugPrint(
        '[SettingsPage] Failed to launch web URL, trying WhatsApp scheme...',
      );

      final appLaunched = await launchUrl(
        whatsappSchemeUrl,
        mode: LaunchMode.externalApplication,
      );

      if (appLaunched) {
        debugPrint('[SettingsPage] WhatsApp scheme launched successfully.');

        return;
      }

      debugPrint('[SettingsPage] Both WhatsApp launch attempts failed.');

      _showWhatsAppErrorDialog(context);
    } catch (e, stackTrace) {
      debugPrint('[SettingsPage] WhatsApp launch failed with exception: $e');

      debugPrint('[SettingsPage] Stack trace: $stackTrace');

      _showWhatsAppErrorDialog(context);
    }
  }

  // ==========================================================
  // ================= WHATSAPP ERROR =========================
  // ==========================================================

  void _showWhatsAppErrorDialog(BuildContext context) {
    final translations = ref.read(translationsProvider);

    debugPrint('[SettingsPage] Showing WhatsApp error dialog.');

    AwesomeDialog(
      context: context,

      dialogType: DialogType.warning,

      animType: AnimType.bottomSlide,

      title: translations.t('whatsapp_error_title'),

      desc: translations.t('whatsapp_error_desc'),

      btnOkOnPress: () {},

      btnOkText: translations.t('ok'),
    ).show();
  }

  // ==========================================================
  // ==================== LANGUAGE ============================
  // ==========================================================

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        final translations = ref.read(translationsProvider);

        return AlertDialog(
          title: Text(translations.t('select_language')),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              RadioListTile<Locale>(
                title: Text(translations.t('indonesian')),

                value: const Locale('id'),

                groupValue: currentLocale,

                contentPadding: EdgeInsets.zero,

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  ref.read(localeProvider.notifier).setLocale(value);

                  Navigator.pop(ctx);
                },
              ),

              RadioListTile<Locale>(
                title: Text(translations.t('english')),

                value: const Locale('en'),

                groupValue: currentLocale,

                contentPadding: EdgeInsets.zero,

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  ref.read(localeProvider.notifier).setLocale(value);

                  Navigator.pop(ctx);
                },
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),

              child: Text(translations.t('close')),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ======================= ABOUT =============================
  // ==========================================================

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final translations = ref.read(translationsProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: Text(translations.t('about')),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                translations.t('app_title'),

                style: const TextStyle(
                  fontSize: 18,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(translations.t('version')),

              const SizedBox(height: 8),

              Text(translations.t('about_description')),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),

              child: Text(translations.t('close')),
            ),
          ],
        );
      },
    );
  }
}
