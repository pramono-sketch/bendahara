// features/settings.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                // -------- Slider Volume --------
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
                      // Putar suara demo setelah mute/unmute
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
                    // 🔥 Demo suara setiap kali slider digeser
                    SoundHelper().playClick();
                  },
                ),
                const Divider(),
                // -------- Tema Gelap --------
                SwitchListTile(
                  title: Text(translations.t('dark_mode')),
                  subtitle: Text(translations.t('change_theme')),
                  value: isDark,
                  onChanged: (val) {
                    ref.read(isDarkProvider.notifier).state = val;
                  },
                ),
                // -------- Notifikasi --------
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
                // -------- Bahasa --------
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
                // -------- Backup --------
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: Text(translations.t('backup_data')),
                  subtitle: Text(translations.t('backup_subtitle')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(translations.t('backup_not_ready')),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                // -------- About --------
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
          // Footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade200,
            child: Text(
              'hello world',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
        ],
      ),
    );
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