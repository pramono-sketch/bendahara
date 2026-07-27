// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'addon/splash_screen.dart';
import 'addon/navigation.dart';
import 'templates/sound_helper.dart'; // 🔥 Import SoundHelper
import 'dependencies/theme_provider.dart';
import 'l10n/translations.dart';

void main() {
  runApp(
    const ProviderScope(
      child: EduvestApp(),
    ),
  );
}

class EduvestApp extends ConsumerStatefulWidget {
  const EduvestApp({super.key});

  @override
  ConsumerState<EduvestApp> createState() => _EduvestAppState();
}

class _EduvestAppState extends ConsumerState<EduvestApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 🔥 Inisialisasi SoundHelper saat app mulai
    SoundHelper().init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // 🔥 Bersihkan resource saat app ditutup
    SoundHelper().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeDataProvider);
    final locale = ref.watch(localeProvider);
    final translations = ref.watch(translationsProvider);

    return MaterialApp(
      title: translations.t('app_title'),
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
      home: const SimpleSplashScreen(
        nextPage: HomePage(),
      ),
    );
  }
}