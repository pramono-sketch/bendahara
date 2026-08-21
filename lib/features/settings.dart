// lib/features/settings.dart

import 'dart:ui';
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

  // ========================================================
  // THEME DETECTION HELPERS
  // ========================================================

  bool _isNeo(AppThemeMode mode) => mode == AppThemeMode.neumorphism;
  bool _isGlass(AppThemeMode mode) => mode == AppThemeMode.glassmorphism;
  bool _isModern(AppThemeMode mode) => mode == AppThemeMode.modern;
  bool _isAurora(AppThemeMode mode) => mode == AppThemeMode.aurora;
  bool _isCyber(AppThemeMode mode) => mode == AppThemeMode.cyberpunk;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final translations = ref.watch(translationsProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentThemeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return _buildThemedBackground(
      themeMode: themeMode,
      child: Scaffold(
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

            _buildSectionHeader(
              title: 'Tampilan',
              themeMode: themeMode,
            ),
            const SizedBox(height: 8),

            _buildSectionGroup(
              themeMode: themeMode,
              children: [
                ListTile(
                  leading: Icon(Icons.palette_outlined, color: colors.primary),
                  title: const Text('Tema Aplikasi'),
                  subtitle: Text(_getThemeLabel(currentThemeMode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showThemeDialog(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ============================================
            // PREFERENSI
            // ============================================

            _buildSectionHeader(
              title: 'Preferensi',
              themeMode: themeMode,
            ),
            const SizedBox(height: 8),

            _buildSectionGroup(
              themeMode: themeMode,
              children: [
                // VOLUME
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_up_outlined,
                              color: colors.primary, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(translations.t('sound_volume'),
                                    style: theme.textTheme.titleMedium),
                                const SizedBox(height: 2),
                                Text('${(_volume * 100).toInt()}%',
                                    style: theme.textTheme.labelLarge),
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
                  color: _dividerColor(themeMode),
                ),

                // NOTIFICATIONS
                SwitchListTile(
                  secondary: Icon(Icons.notifications_none_outlined,
                      color: colors.primary),
                  title: Text(translations.t('notifications')),
                  subtitle: Text(translations.t('enable_notifications')),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.t('feature_unavailable')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                Divider(
                  height: 1,
                  color: _dividerColor(themeMode),
                ),

                // LANGUAGE
                ListTile(
                  leading: Icon(Icons.language_outlined,
                      color: colors.primary),
                  title: Text(translations.t('language')),
                  subtitle: Text(currentLocale.languageCode == 'en'
                      ? translations.t('english')
                      : translations.t('indonesian')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context, ref),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ============================================
            // DATA
            // ============================================

            _buildSectionHeader(
              title: 'Data',
              themeMode: themeMode,
            ),
            const SizedBox(height: 8),

            _buildSectionGroup(
              themeMode: themeMode,
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_upload_outlined,
                      color: colors.primary),
                  title: Text(translations.t('backup_data')),
                  subtitle: Text(translations.t('backup_subtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleBackupTap(context, ref),
                ),
                if (_easterEggActivated) ...[
                  Divider(
                    height: 1,
                    color: _dividerColor(themeMode),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.egg_outlined),
                    title: const Text('Tampilkan Easter Egg'),
                    subtitle: const Text(
                        'Aktifkan / nonaktifkan footer spesial'),
                    value: _easterEggFooterEnabled,
                    onChanged: (value) {
                      setState(() => _easterEggFooterEnabled = value);
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // ============================================
            // TENTANG
            // ============================================

            _buildSectionHeader(
              title: 'Tentang',
              themeMode: themeMode,
            ),
            const SizedBox(height: 8),

            _buildSectionGroup(
              themeMode: themeMode,
              children: [
                ListTile(
                  leading:
                      Icon(Icons.info_outline, color: colors.primary),
                  title: Text(translations.t('about')),
                  subtitle: Text(translations.t('version')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context, ref),
                ),
              ],
            ),

            // EASTER EGG FOOTER
            if (_easterEggActivated && _easterEggFooterEnabled) ...[
              const SizedBox(height: 20),
              _buildEasterEggFooter(
                themeMode: themeMode,
                colors: colors,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // ============== THEMED BACKGROUND =========================
  // ==========================================================

  Widget _buildThemedBackground({
    required AppThemeMode themeMode,
    required Widget child,
  }) {
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

  // ==========================================================
  // ============== DIVIDER COLOR HELPER ======================
  // ==========================================================

  Color _dividerColor(AppThemeMode mode) {
    if (_isNeo(mode))
      return AppColors.neoShadow.withValues(alpha: 0.20);
    if (_isGlass(mode)) return Colors.white.withValues(alpha: 0.2);
    if (_isModern(mode))
      return AppColors.modernDivider.withValues(alpha: 0.6);
    if (_isAurora(mode))
      return AppColors.auroraAccent1.withValues(alpha: 0.12);
    if (_isCyber(mode))
      return AppColors.cyberAccent1.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  // ==========================================================
  // ================== SECTION HEADER ========================
  // ==========================================================

  Widget _buildSectionHeader({
    required String title,
    required AppThemeMode themeMode,
  }) {
    final colors = Theme.of(context).colorScheme;

    Color labelColor;
    if (_isNeo(themeMode))
      labelColor = AppColors.neoTextSecondary;
    else if (_isGlass(themeMode))
      labelColor = Colors.white.withValues(alpha: 0.8);
    else if (_isModern(themeMode))
      labelColor = AppColors.modernPrimary;
    else if (_isAurora(themeMode))
      labelColor = AppColors.auroraAccent1;
    else if (_isCyber(themeMode))
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

  // ==========================================================
  // ================== SECTION GROUP =========================
  // ==========================================================

  Widget _buildSectionGroup({
    required AppThemeMode themeMode,
    required List<Widget> children,
  }) {
    // NEUMORPHISM
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

    // GLASSMORPHISM
    if (_isGlass(themeMode)) {
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
    if (_isModern(themeMode)) {
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
    if (_isAurora(themeMode)) {
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
    if (_isCyber(themeMode)) {
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

  // ==========================================================
  // ================= EASTER EGG FOOTER ======================
  // ==========================================================

  Widget _buildEasterEggFooter({
    required AppThemeMode themeMode,
    required ColorScheme colors,
  }) {
    // NEOMORPHISM
    if (_isNeo(themeMode)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: neumorphismDecoration(borderRadius: 16, isPressed: false),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥚', style: TextStyle(fontSize: 22)),
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

    // GLASSMORPHISM
    if (_isGlass(themeMode)) {
      return Container(
        width: double.infinity,
        decoration: glassmorphismDecoration(borderRadius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🥚', style: TextStyle(fontSize: 22)),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Selamat! Anda menemukan telur Paskah! 🥚',
                      textAlign: TextAlign.center,
                      style: TextStyle(
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
    if (_isModern(themeMode)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: modernDecoration(borderRadius: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Selamat! Anda menemukan telur Paskah! 🥚',
                textAlign: TextAlign.center,
                style: TextStyle(
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
    if (_isAurora(themeMode)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: auroraDecoration(borderRadius: 16),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Selamat! Anda menemukan telur Paskah! 🥚',
                textAlign: TextAlign.center,
                style: TextStyle(
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
    if (_isCyber(themeMode)) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: cyberpunkDecoration(borderRadius: 12),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🥚', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Selamat! Anda menemukan telur Paskah! 🥚',
                textAlign: TextAlign.center,
                style: TextStyle(
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

    // DEFAULT (Light / Dark)
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🥚', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Selamat! Anda menemukan telur Paskah! 🥚',
              textAlign: TextAlign.center,
              style: TextStyle(
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

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Pilih Tema'),
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
                        Text(_getThemeLabel(mode)),
                      ],
                    ),
                    value: mode,
                    groupValue: current,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      if (value == null) return;
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
              child: const Text('Tutup'),
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

  String _getThemeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Terang';
      case AppThemeMode.dark:
        return 'Gelap';
      case AppThemeMode.neumorphism:
        return 'Neomorphism';
      case AppThemeMode.glassmorphism:
        return 'Glassmorphism';
      case AppThemeMode.modern:
        return 'Modern UI';
      case AppThemeMode.aurora:
        return 'Aurora UI';
      case AppThemeMode.cyberpunk:
        return 'Cyberpunk Neon';
      case AppThemeMode.system:
        return 'Sistem';
    }
  }

  // ==========================================================
  // ================= BACKUP / EASTER EGG ====================
  // ==========================================================

  void _handleBackupTap(BuildContext context, WidgetRef ref) {
    final translations = ref.read(translationsProvider);

    setState(() => _backupClickCount++);

    debugPrint(
        '[SettingsPage] Backup tile tapped. Count: $_backupClickCount');

    if (_backupClickCount == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('sudah kubilang fitur belum ada'),
          duration: Duration(seconds: 2),
        ),
      );
      debugPrint('[SettingsPage] Easter egg hint shown at count 3.');
    } else if (_backupClickCount == 5) {
      debugPrint('[SettingsPage] Easter egg dialog shown at count 5.');
      AwesomeDialog(
        context: context,
        dialogType: DialogType.info,
        animType: AnimType.bottomSlide,
        title: 'Easter Egg!',
        desc: 'you found easter egg, admin say: kita sayang pak win',
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
          '[SettingsPage] Easter egg activated permanently. Launching WhatsApp...');
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
    const message = 'Admin, saya menemukan easter egg di aplikasi Bendahara. '
        'Terima kasih atas kerja kerasnya! '
        'Semangat terus Admin, semoga sehat selalu dan sukses selalu.';

    final encodedMessage = Uri.encodeComponent(message);
    final webUrl =
        Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    final whatsappSchemeUrl =
        Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');

    debugPrint('[SettingsPage] WhatsApp launch requested.');
    debugPrint('[SettingsPage] Primary URL: $webUrl');
    debugPrint('[SettingsPage] Fallback URL: $whatsappSchemeUrl');

    try {
      final webLaunched = await launchUrl(webUrl,
          mode: LaunchMode.externalApplication);
      if (webLaunched) {
        debugPrint(
            '[SettingsPage] WhatsApp web URL launched successfully.');
        return;
      }

      debugPrint(
          '[SettingsPage] Failed to launch web URL, trying WhatsApp scheme...');
      final appLaunched = await launchUrl(whatsappSchemeUrl,
          mode: LaunchMode.externalApplication);
      if (appLaunched) {
        debugPrint(
            '[SettingsPage] WhatsApp scheme launched successfully.');
        return;
      }

      debugPrint(
          '[SettingsPage] Both WhatsApp launch attempts failed.');
      _showWhatsAppErrorDialog(context);
    } catch (e, stackTrace) {
      debugPrint(
          '[SettingsPage] WhatsApp launch failed with exception: $e');
      debugPrint('[SettingsPage] Stack trace: $stackTrace');
      _showWhatsAppErrorDialog(context);
    }
  }

  // ==========================================================
  // ================= WHATSAPP ERROR =========================
  // ==========================================================

  void _showWhatsAppErrorDialog(BuildContext context) {
    debugPrint('[SettingsPage] Showing WhatsApp error dialog.');
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.bottomSlide,
      title: 'WhatsApp Launch Failed',
      desc: 'Unable to open WhatsApp or browser link.\n'
          'Please check whether WhatsApp is installed and whether the device can open external links.\n'
          'Target number: +6287833467630',
      btnOkOnPress: () {},
      btnOkText: 'OK',
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
                  if (value == null) return;
                  ref.read(localeProvider.notifier).state = value;
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<Locale>(
                title: Text(translations.t('english')),
                value: const Locale('en'),
                groupValue: currentLocale,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(localeProvider.notifier).state = value;
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
              Text(translations.t('app_title'),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
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