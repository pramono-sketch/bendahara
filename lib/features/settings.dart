// features/settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dependencies/theme_provider.dart';
import '../l10n/translations.dart';
import '../templates/sound_helper.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  double _volume = 1.0;
  int _backupClickCount = 0;
  bool _easterEggActivated = false;
  bool _easterEggFooterEnabled = false;

  @override
  void initState() {
    super.initState();
    _volume = SoundHelper().getVolume();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(isDarkProvider);
    final translations = ref.watch(translationsProvider);
    final currentLocale = ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(translations.t('settings'))),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  leading: const Icon(Icons.volume_up),
                  title: Text(translations.t('sound_volume')),
                  subtitle: Text('${(_volume * 100).toInt()}%'),
                  trailing: IconButton(
                    icon: Icon(_volume == 0 ? Icons.volume_off : Icons.volume_up),
                    onPressed: () {
                      final newVol = _volume == 0 ? 1.0 : 0.0;
                      setState(() => _volume = newVol);
                      SoundHelper().setVolume(newVol);
                      SoundHelper().playClick();
                    },
                  ),
                ),
                Slider(
                  value: _volume,
                  min: 0.0,
                  max: 1.0,
                  divisions: 10,
                  label: '${(_volume * 100).toInt()}%',
                  onChanged: (value) {
                    setState(() => _volume = value);
                    SoundHelper().setVolume(value);
                    SoundHelper().playClick();
                  },
                ),
                const Divider(),

                SwitchListTile(
                  title: Text(translations.t('dark_mode')),
                  subtitle: Text(translations.t('change_theme')),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(isDarkProvider.notifier).state = val;
                  },
                ),

                SwitchListTile(
                  title: Text(translations.t('notifications')),
                  subtitle: Text(translations.t('enable_notifications')),
                  value: true,
                  onChanged: (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.t('feature_unavailable')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(translations.t('language')),
                  subtitle: Text(
                    currentLocale.languageCode == 'en'
                        ? translations.t('english')
                        : translations.t('indonesian'),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageDialog(context, ref),
                ),

                ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(translations.t('backup_data')),
                  subtitle: Text(translations.t('backup_subtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _handleBackupTap(context, ref),
                ),

                if (_easterEggActivated)
                  SwitchListTile(
                    title: const Text('Tampilkan Easter Egg'),
                    subtitle: const Text('Aktifkan / nonaktifkan footer spesial'),
                    value: _easterEggFooterEnabled,
                    onChanged: (val) {
                      setState(() {
                        _easterEggFooterEnabled = val;
                      });
                    },
                  ),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(translations.t('about')),
                  subtitle: Text(translations.t('version')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showAboutDialog(context, ref),
                ),
              ],
            ),
          ),

          if (_easterEggActivated && _easterEggFooterEnabled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey.shade200,
              child: Text(
                '🥚 Selamat! Anda menemukan telur Paskah! 🥚',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleBackupTap(BuildContext context, WidgetRef ref) {
    final translations = ref.read(translationsProvider);

    setState(() {
      _backupClickCount++;
    });

    debugPrint('[SettingsPage] Backup tile tapped. Count: $_backupClickCount');

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

      debugPrint('[SettingsPage] Easter egg activated permanently. Launching WhatsApp...');
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

  Future<void> _launchWhatsApp(BuildContext context) async {
    const phone = '6287833467630';
    const message = 'Admin, saya menemukan easter egg di aplikasi Bendahara. Terima kasih atas kerja kerasnya!Semangat terus Admin, semoga sehat selalu dan sukses selalu.';

    final encodedMessage = Uri.encodeComponent(message);

    final webUrl = Uri.parse('https://wa.me/$phone?text=$encodedMessage');
    final whatsappSchemeUrl = Uri.parse('whatsapp://send?phone=$phone&text=$encodedMessage');

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

      debugPrint('[SettingsPage] Failed to launch web URL, trying WhatsApp scheme...');
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

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ref.watch(translationsProvider).t('select_language')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<Locale>(
                title: Text(ref.watch(translationsProvider).t('indonesian')),
                value: const Locale('id'),
                groupValue: currentLocale,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(localeProvider.notifier).state = val;
                    Navigator.pop(ctx);
                  }
                },
              ),
              RadioListTile<Locale>(
                title: Text(ref.watch(translationsProvider).t('english')),
                value: const Locale('en'),
                groupValue: currentLocale,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(localeProvider.notifier).state = val;
                    Navigator.pop(ctx);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ref.watch(translationsProvider).t('close')),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final translations = ref.watch(translationsProvider);
    showDialog(
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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