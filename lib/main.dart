// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'addon/navigation.dart';
import 'addon/splash_screen.dart';
import 'constants/appearance.dart';
import 'data.dart';
import 'firebase_options.dart';
import 'l10n/translations.dart';
import 'templates/sound_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================
  // MULAI STARTUP DI BACKGROUND
  // ============================================================
  //
  // Jangan await di main().
  //
  // Dengan begitu runApp() bisa langsung berjalan dan splash
  // langsung terlihat, sementara Firebase dan Firestore dimuat.
  final startupFuture = initializeApplication();

  // ============================================================
  // RUN APP LANGSUNG
  // ============================================================

  runApp(
    ProviderScope(
      child: EduvestApp(
        startupFuture: startupFuture,
      ),
    ),
  );
}

// ============================================================
// ================= INITIALIZE APPLICATION =====================
// ============================================================

Future<void> initializeApplication() async {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================================
  // SEED DATA
  // ==========================================================
  //
  // Hanya berjalan jika koleksi Firestore masih kosong.
  // Splash tetap tampil selama proses ini.

  await seedFirestoreIfEmpty();
}

// ============================================================
// ================= SEED FIRESTORE =============================
// ============================================================

/// Mengisi data awal Firestore jika koleksi masih kosong.
Future<void> seedFirestoreIfEmpty() async {
  final firestoreInstance =
      firestore.FirebaseFirestore.instance;

  // ==========================================================
  // STUDENTS
  // ==========================================================

  final studentsSnapshot = await firestoreInstance
      .collection('students')
      .limit(1)
      .get();

  if (studentsSnapshot.docs.isEmpty) {
    final students = generateDummyStudents();

    for (final student in students) {
      await firestoreInstance
          .collection('students')
          .doc(student.id)
          .set(student.toMap());
    }
  }

  // ==========================================================
  // TRANSACTIONS
  // ==========================================================

  final transSnapshot = await firestoreInstance
      .collection('transactions')
      .limit(1)
      .get();

  if (transSnapshot.docs.isEmpty) {
    initDummyTransactions();

    final allTransactions = <Transaction>[];

    arsipTransaksi.forEach(
      (key, transactions) {
        allTransactions.addAll(transactions);
      },
    );

    allTransactions.addAll(dummyTransactions);

    for (final transaction in allTransactions) {
      await firestoreInstance
          .collection('transactions')
          .doc(transaction.id)
          .set(transaction.toMap());
    }
  }

  // ==========================================================
  // DIGITAL ACCOUNTS
  // ==========================================================

  final accountSnapshot = await firestoreInstance
      .collection('digital_accounts')
      .limit(1)
      .get();

  if (accountSnapshot.docs.isEmpty) {
    for (final account in dummyAccounts) {
      await firestoreInstance
          .collection('digital_accounts')
          .add(account.toMap());
    }
  }
}

// ============================================================
// ====================== EDUVEST APP ===========================
// ============================================================

class EduvestApp extends ConsumerStatefulWidget {
  final Future<void> startupFuture;

  const EduvestApp({
    super.key,
    required this.startupFuture,
  });

  @override
  ConsumerState<EduvestApp> createState() =>
      _EduvestAppState();
}

class _EduvestAppState
    extends ConsumerState<EduvestApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    // ==========================================================
    // SOUND
    // ==========================================================

    SoundHelper().init();

    // ==========================================================
    // SYSTEM BRIGHTNESS
    // ==========================================================

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

  // ============================================================
  // UPDATE SYSTEM BRIGHTNESS
  // ============================================================

  void _updateSystemBrightness() {
    if (!mounted) return;

    final brightness = WidgetsBinding
        .instance
        .platformDispatcher
        .platformBrightness;

    ref
        .read(systemBrightnessProvider.notifier)
        .state = brightness;
  }

  // ============================================================
  // BUILD
  // ============================================================

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

      // ========================================================
      // SPLASH
      // ========================================================

      home: SimpleSplashScreen(
        nextPage: const HomePage(),
        startupFuture: widget.startupFuture,
      ),
    );
  }
}