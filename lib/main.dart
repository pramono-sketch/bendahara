// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'addon/splash_screen.dart';
import 'addon/navigation.dart';
import 'templates/sound_helper.dart';
import 'dependencies/theme_provider.dart';
import 'l10n/translations.dart';
import 'firebase_options.dart';
import 'data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // (Opsional) Seed data awal jika Firestore kosong
  await seedFirestoreIfEmpty();

  runApp(
    const ProviderScope(
      child: EduvestApp(),
    ),
  );
}

/// Fungsi untuk mengisi data awal (dummy) ke Firestore jika koleksi kosong
Future<void> seedFirestoreIfEmpty() async {
  // Perbaiki di sini: gunakan firestore.FirebaseFirestore
  final firestoreInstance = firestore.FirebaseFirestore.instance;

  // Cek koleksi students
  final studentsSnapshot = await firestoreInstance.collection('students').limit(1).get();
  if (studentsSnapshot.docs.isEmpty) {
    // Generate dummy students dari data.dart
    final dummyStudents = generateDummyStudents();
    for (var student in dummyStudents) {
      await firestoreInstance.collection('students').doc(student.id).set(student.toMap());
    }
  }

  // Cek koleksi transactions
  final transSnapshot = await firestoreInstance.collection('transactions').limit(1).get();
  if (transSnapshot.docs.isEmpty) {
    // Inisialisasi dummy transactions (dari data.dart)
    initDummyTransactions();
    // Kita simpan semua transaksi dari arsipTransaksi dan dummyTransactions ke Firestore
    final allTransactions = <Transaction>[];
    arsipTransaksi.forEach((key, list) => allTransactions.addAll(list));
    allTransactions.addAll(dummyTransactions);
    for (var t in allTransactions) {
      await firestoreInstance.collection('transactions').doc(t.id).set(t.toMap());
    }
  }

  // Cek koleksi digital_accounts
  final accSnapshot = await firestoreInstance.collection('digital_accounts').limit(1).get();
  if (accSnapshot.docs.isEmpty) {
    for (var acc in dummyAccounts) {
      await firestoreInstance.collection('digital_accounts').add(acc.toMap());
    }
  }
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
    SoundHelper().init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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