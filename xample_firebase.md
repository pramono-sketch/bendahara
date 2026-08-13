// lib/main.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('========================================');
    debugPrint('FIREBASE INITIALIZATION SUCCESS');
    debugPrint('========================================');
  } catch (e, stackTrace) {
    debugPrint('========================================');
    debugPrint('FIREBASE INITIALIZATION FAILED');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $stackTrace');
    debugPrint('========================================');
  }

  runApp(const FirebaseDebugApp());
}

class FirebaseDebugApp extends StatelessWidget {
  const FirebaseDebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Debug',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const EduvestApp(),
    );
  }
}

class EduvestApp extends StatefulWidget {
  const EduvestApp({super.key});

  @override
  State<EduvestApp> createState() => _EduvestAppState();
}

class _EduvestAppState extends State<EduvestApp> {
  String status = 'Belum melakukan test Firestore.';

  bool isLoading = false;

  Future<void> testFirestore() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      status = 'Menghubungkan ke Firestore...';
    });

    try {
      final firestore = FirebaseFirestore.instance;

      // ==============================
      // WRITE
      // ==============================
      await firestore
          .collection('debug')
          .doc('connection_test')
          .set({
        'message': 'Firestore berhasil terhubung',
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('========================================');
      debugPrint('FIRESTORE WRITE SUCCESS');
      debugPrint('========================================');

      // ==============================
      // READ
      // ==============================
      final snapshot = await firestore
          .collection('debug')
          .doc('connection_test')
          .get();

      if (!mounted) return;

      if (snapshot.exists) {
        setState(() {
          status =
              'Firestore berhasil READ & WRITE.\n\n'
              'Data:\n${snapshot.data()}';
        });

        debugPrint('========================================');
        debugPrint('FIRESTORE TEST SUCCESS');
        debugPrint('========================================');
        debugPrint('Data: ${snapshot.data()}');
      } else {
        setState(() {
          status =
              'WRITE berhasil, tetapi data tidak ditemukan.';
        });

        debugPrint('========================================');
        debugPrint('FIRESTORE READ FAILED');
        debugPrint('========================================');
        debugPrint('Dokumen tidak ditemukan.');
      }
    } catch (e, stackTrace) {
      if (!mounted) return;

      setState(() {
        status =
            'Firestore gagal digunakan.\n\n'
            'Error:\n$e';
      });

      debugPrint('========================================');
      debugPrint('FIRESTORE TEST FAILED');
      debugPrint('========================================');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseApps = Firebase.apps;

    final bool firebaseConnected = firebaseApps.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ==============================
              // FIREBASE STATUS ICON
              // ==============================
              Icon(
                firebaseConnected
                    ? Icons.cloud_done
                    : Icons.cloud_off,
                size: 80,
                color: firebaseConnected
                    ? Colors.green
                    : Colors.red,
              ),

              const SizedBox(height: 24),

              // ==============================
              // FIREBASE STATUS
              // ==============================
              Text(
                firebaseConnected
                    ? 'Firebase berhasil terhubung'
                    : 'Firebase belum terhubung',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Jumlah Firebase App: ${firebaseApps.length}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 32),

              // ==============================
              // FIRESTORE TEST BUTTON
              // ==============================
              ElevatedButton.icon(
                onPressed: isLoading
                    ? null
                    : testFirestore,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.cloud_sync),
                label: Text(
                  isLoading
                      ? 'Testing...'
                      : 'Test Firestore',
                ),
              ),

              const SizedBox(height: 24),

              // ==============================
              // RESULT
              // ==============================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    status,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}