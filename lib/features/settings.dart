// lib/features/settings.dart

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/appearance.dart';
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
    final systemBrightness = ref.watch(systemBrightnessProvider);

    // Tentukan apakah mode gelap aktif (termasuk jika mengikuti sistem)
    final bool isDark = themeMode == AppThemeMode.dark ||
        (themeMode == AppThemeMode.system &&
            systemBrightness == Brightness.dark);
    final bool isNeo = themeMode == AppThemeMode.neumorphism;

    final translations = ref.watch(translationsProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          translations.t('settings'),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          32,
        ),

        children: [
          // ==================================================
          // TAMPILAN
          // ==================================================

          _buildSectionHeader(
            title: 'Tampilan',
            isNeo: isNeo,
          ),

          const SizedBox(height: 8),

          _buildSectionGroup(
            isNeo: isNeo,
            children: [
              ListTile(
                leading: Icon(
                  Icons.palette_outlined,
                  color: colors.primary,
                ),

                title: const Text(
                  'Tema Aplikasi',
                ),

                subtitle: Text(
                  _getThemeLabel(currentThemeMode),
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: () => _showThemeDialog(
                  context,
                  ref,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================================================
          // PREFERENSI
          // ==================================================

          _buildSectionHeader(
            title: 'Preferensi',
            isNeo: isNeo,
          ),

          const SizedBox(height: 8),

          _buildSectionGroup(
            isNeo: isNeo,
            children: [
              // ------------------------------------------------
              // VOLUME
              // ------------------------------------------------

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  18,
                  16,
                  18,
                  12,
                ),

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
                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [
                              Text(
                                translations.t(
                                  'sound_volume',
                                ),
                                style: theme
                                    .textTheme
                                    .titleMedium,
                              ),

                              const SizedBox(height: 2),

                              Text(
                                '${(_volume * 100).toInt()}%',
                                style: theme
                                    .textTheme
                                    .labelLarge,
                              ),
                            ],
                          ),
                        ),

                        IconButton(
                          tooltip: _volume == 0
                              ? 'Aktifkan suara'
                              : 'Matikan suara',

                          icon: Icon(
                            _volume == 0
                                ? Icons.volume_off_outlined
                                : Icons.volume_up_outlined,
                            color: colors.primary,
                          ),

                          onPressed: () {
                            final newVolume =
                                _volume == 0 ? 1.0 : 0.0;

                            setState(() {
                              _volume = newVolume;
                            });

                            SoundHelper().setVolume(
                              newVolume,
                            );

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

                      label:
                          '${(_volume * 100).toInt()}%',

                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                        });

                        SoundHelper().setVolume(
                          value,
                        );

                        SoundHelper().playClick();
                      },
                    ),
                  ],
                ),
              ),

              const Divider(
                height: 1,
              ),

              // ------------------------------------------------
              // NOTIFICATIONS
              // ------------------------------------------------

              SwitchListTile(
                secondary: Icon(
                  Icons.notifications_none_outlined,
                  color: colors.primary,
                ),

                title: Text(
                  translations.t(
                    'notifications',
                  ),
                ),

                subtitle: Text(
                  translations.t(
                    'enable_notifications',
                  ),
                ),

                value: _notificationsEnabled,

                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        translations.t(
                          'feature_unavailable',
                        ),
                      ),

                      duration:
                          const Duration(
                        seconds: 2,
                      ),
                    ),
                  );
                },
              ),

              const Divider(
                height: 1,
              ),

              // ------------------------------------------------
              // LANGUAGE
              // ------------------------------------------------

              ListTile(
                leading: Icon(
                  Icons.language_outlined,
                  color: colors.primary,
                ),

                title: Text(
                  translations.t(
                    'language',
                  ),
                ),

                subtitle: Text(
                  currentLocale.languageCode == 'en'
                      ? translations.t(
                          'english',
                        )
                      : translations.t(
                          'indonesian',
                        ),
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: () =>
                    _showLanguageDialog(
                  context,
                  ref,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ==================================================
          // DATA
          // ==================================================

          _buildSectionHeader(
            title: 'Data',
            isNeo: isNeo,
          ),

          const SizedBox(height: 8),

          _buildSectionGroup(
            isNeo: isNeo,
            children: [
              ListTile(
                leading: Icon(
                  Icons.cloud_upload_outlined,
                  color: colors.primary,
                ),

                title: Text(
                  translations.t(
                    'backup_data',
                  ),
                ),

                subtitle: Text(
                  translations.t(
                    'backup_subtitle',
                  ),
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: () =>
                    _handleBackupTap(
                  context,
                  ref,
                ),
              ),

              if (_easterEggActivated) ...[
                const Divider(
                  height: 1,
                ),

                SwitchListTile(
                  secondary: const Icon(
                    Icons.egg_outlined,
                  ),

                  title: const Text(
                    'Tampilkan Easter Egg',
                  ),

                  subtitle: const Text(
                    'Aktifkan / nonaktifkan footer spesial',
                  ),

                  value:
                      _easterEggFooterEnabled,

                  onChanged: (value) {
                    setState(() {
                      _easterEggFooterEnabled =
                          value;
                    });
                  },
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // ==================================================
          // TENTANG
          // ==================================================

          _buildSectionHeader(
            title: 'Tentang',
            isNeo: isNeo,
          ),

          const SizedBox(height: 8),

          _buildSectionGroup(
            isNeo: isNeo,
            children: [
              ListTile(
                leading: Icon(
                  Icons.info_outline,
                  color: colors.primary,
                ),

                title: Text(
                  translations.t(
                    'about',
                  ),
                ),

                subtitle: Text(
                  translations.t(
                    'version',
                  ),
                ),

                trailing: const Icon(
                  Icons.chevron_right,
                ),

                onTap: () =>
                    _showAboutDialog(
                  context,
                  ref,
                ),
              ),
            ],
          ),

          // ==================================================
          // EASTER EGG FOOTER
          // ==================================================

          if (_easterEggActivated &&
              _easterEggFooterEnabled) ...[
            const SizedBox(height: 20),

            _buildEasterEggFooter(
              isNeo: isNeo,
              colors: colors,
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================================
  // ================== SECTION HEADER ========================
  // ==========================================================

  Widget _buildSectionHeader({
    required String title,
    required bool isNeo,
  }) {
    final colors = Theme.of(context).colorScheme;

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

          color: isNeo
              ? AppColors.neoTextSecondary
              : colors.primary,
        ),
      ),
    );
  }

  // ==========================================================
  // ================== SECTION GROUP =========================
  // ==========================================================

  Widget _buildSectionGroup({
    required bool isNeo,
    required List<Widget> children,
  }) {
    if (isNeo) {
      return Container(
        decoration: neumorphismDecoration(
          borderRadius: 20,
          isPressed: false,
        ),

        child: ClipRRect(
          borderRadius:
              BorderRadius.circular(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

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
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: children,
      ),
    );
  }

  // ==========================================================
  // ================= EASTER EGG FOOTER ======================
  // ==========================================================

  Widget _buildEasterEggFooter({
    required bool isNeo,
    required ColorScheme colors,
  }) {
    if (isNeo) {
      return Container(
        width: double.infinity,

        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        decoration: neumorphismDecoration(
          borderRadius: 16,
          isPressed: false,
        ),

        child: const Row(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Text(
              '🥚',
              style: TextStyle(
                fontSize: 22,
              ),
            ),

            SizedBox(width: 8),

            Flexible(
              child: Text(
                'Selamat! Anda menemukan telur Paskah! 🥚',
                textAlign: TextAlign.center,

                style: TextStyle(
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

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),

      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius:
            BorderRadius.circular(16),
      ),

      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,

        children: [
          const Text(
            '🥚',
            style: TextStyle(
              fontSize: 22,
            ),
          ),

          const SizedBox(width: 8),

          Flexible(
            child: Text(
              'Selamat! Anda menemukan telur Paskah! 🥚',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade800,
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

  void _showThemeDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final current =
        ref.read(themeModeProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: const Text(
            'Pilih Tema',
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: AppThemeMode.values.map(
              (mode) {
                return RadioListTile<
                    AppThemeMode>(
                  title: Text(
                    _getThemeLabel(
                      mode,
                    ),
                  ),

                  value: mode,
                  groupValue: current,

                  contentPadding:
                      EdgeInsets.zero,

                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    ref
                        .read(
                          themeModeProvider
                              .notifier,
                        )
                        .state = value;

                    Navigator.pop(ctx);
                  },
                );
              },
            ).toList(),
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),

              child: const Text(
                'Tutup',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ====================== THEME LABEL =======================
  // ==========================================================

  String _getThemeLabel(
    AppThemeMode mode,
  ) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Terang';
      case AppThemeMode.dark:
        return 'Gelap';
      case AppThemeMode.neumorphism:
        return 'Neomorphism';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }

  // ==========================================================
  // ================= BACKUP / EASTER EGG ====================
  // ==========================================================

  void _handleBackupTap(
    BuildContext context,
    WidgetRef ref,
  ) {
    final translations =
        ref.read(translationsProvider);

    setState(() {
      _backupClickCount++;
    });

    debugPrint(
      '[SettingsPage] Backup tile tapped. Count: $_backupClickCount',
    );

    if (_backupClickCount == 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'sudah kubilang fitur belum ada',
          ),

          duration:
              Duration(seconds: 2),
        ),
      );

      debugPrint(
        '[SettingsPage] Easter egg hint shown at count 3.',
      );
    } else if (_backupClickCount == 5) {
      debugPrint(
        '[SettingsPage] Easter egg dialog shown at count 5.',
      );

      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.bottomSlide,

        title: 'Easter Egg!',

        desc:
            'you found easter egg, admin say: kita sayang pak win',

        btnOkOnPress: () {},

        btnOkText: 'OK',
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
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            translations.t(
              'backup_not_ready',
            ),
          ),

          duration:
              const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==========================================================
  // ===================== WHATSAPP ===========================
  // ==========================================================

  Future<void> _launchWhatsApp(
    BuildContext context,
  ) async {
    const phone = '6287833467630';

    const message =
        'Admin, saya menemukan easter egg di aplikasi Bendahara. '
        'Terima kasih atas kerja kerasnya! '
        'Semangat terus Admin, semoga sehat selalu dan sukses selalu.';

    final encodedMessage =
        Uri.encodeComponent(message);

    final webUrl = Uri.parse(
      'https://wa.me/$phone?text=$encodedMessage',
    );

    final whatsappSchemeUrl =
        Uri.parse(
      'whatsapp://send?phone=$phone&text=$encodedMessage',
    );

    debugPrint(
      '[SettingsPage] WhatsApp launch requested.',
    );

    debugPrint(
      '[SettingsPage] Primary URL: $webUrl',
    );

    debugPrint(
      '[SettingsPage] Fallback URL: $whatsappSchemeUrl',
    );

    try {
      final webLaunched = await launchUrl(
        webUrl,
        mode: LaunchMode.externalApplication,
      );

      if (webLaunched) {
        debugPrint(
          '[SettingsPage] WhatsApp web URL launched successfully.',
        );

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
        debugPrint(
          '[SettingsPage] WhatsApp scheme launched successfully.',
        );

        return;
      }

      debugPrint(
        '[SettingsPage] Both WhatsApp launch attempts failed.',
      );

      _showWhatsAppErrorDialog(
        context,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '[SettingsPage] WhatsApp launch failed with exception: $e',
      );

      debugPrint(
        '[SettingsPage] Stack trace: $stackTrace',
      );

      _showWhatsAppErrorDialog(
        context,
      );
    }
  }

  // ==========================================================
  // ================= WHATSAPP ERROR =========================
  // ==========================================================

  void _showWhatsAppErrorDialog(
    BuildContext context,
  ) {
    debugPrint(
      '[SettingsPage] Showing WhatsApp error dialog.',
    );

    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,

      title:
          'WhatsApp Launch Failed',

      desc:
          'Unable to open WhatsApp or browser link.\n'
          'Please check whether WhatsApp is installed and whether the device can open external links.\n'
          'Target number: +6287833467630',

      btnOkOnPress: () {},

      btnOkText: 'OK',
    ).show();
  }

  // ==========================================================
  // ==================== LANGUAGE ============================
  // ==========================================================

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final currentLocale =
        ref.read(localeProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        final translations =
            ref.read(
              translationsProvider,
            );

        return AlertDialog(
          title: Text(
            translations.t(
              'select_language',
            ),
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,

            children: [
              RadioListTile<Locale>(
                title: Text(
                  translations.t(
                    'indonesian',
                  ),
                ),

                value:
                    const Locale('id'),

                groupValue:
                    currentLocale,

                contentPadding:
                    EdgeInsets.zero,

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  ref
                      .read(
                        localeProvider
                            .notifier,
                      )
                      .state = value;

                  Navigator.pop(ctx);
                },
              ),

              RadioListTile<Locale>(
                title: Text(
                  translations.t(
                    'english',
                  ),
                ),

                value:
                    const Locale('en'),

                groupValue:
                    currentLocale,

                contentPadding:
                    EdgeInsets.zero,

                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  ref
                      .read(
                        localeProvider
                            .notifier,
                      )
                      .state = value;

                  Navigator.pop(ctx);
                },
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),

              child: Text(
                translations.t(
                  'close',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // ======================= ABOUT =============================
  // ==========================================================

  void _showAboutDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    final translations =
        ref.read(translationsProvider);

    showDialog<void>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: Text(
            translations.t(
              'about',
            ),
          ),

          content: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                translations.t(
                  'app_title',
                ),

                style: const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                translations.t(
                  'version',
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                translations.t(
                  'about_description',
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx),

              child: Text(
                translations.t(
                  'close',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}