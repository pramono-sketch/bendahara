import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_gate.dart'; // Import AuthGate
import 'addon/splash_screen.dart';
import 'constants/appearance.dart';
import 'firebase_options.dart';
import 'l10n/translations.dart';
import 'helpers/sound_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: EduvestApp(),
    ),
  );
}

// ============================================================
// ================= INITIALIZE APPLICATION =====================
// ============================================================

Future<void> initializeApplication() async {
  // 1. HANYA INISIALISASI FIREBASE
  // Tidak ada lagi seed data otomatis, gunakan data real di Firestore
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

// ============================================================
// ====================== EDUVEST APP ===========================
// ============================================================

class EduvestApp extends ConsumerStatefulWidget {
  const EduvestApp({super.key});

  @override
  ConsumerState<EduvestApp> createState() => _EduvestAppState();
}

class _EduvestAppState extends ConsumerState<EduvestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SoundHelper().init();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateSystemBrightness();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SoundHelper().dispose();
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    _updateSystemBrightness();
  }

  void _updateSystemBrightness() {
    if (!mounted) return;
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    ref.read(systemBrightnessProvider.notifier).state = brightness;
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
      supportedLocales: const [
        Locale('id'),
        Locale('en'),
      ],
      // Ubah nextPage dari HomePage() menjadi AuthGate()
      home: SimpleSplashScreen(
        nextPage: const AuthGate(),
        startupTask: initializeApplication,
      ),
    );
  }
}