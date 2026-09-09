// lib/auth/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../firebase/firestore_service.dart';
import '../helpers/custom_animation.dart';
import 'auth_page.dart';
import '../addon/navigation.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Cek apakah data user benar-benar terdaftar di Firestore
      final registered = await isUserAccountRegistered(user.uid);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = registered;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoggedIn = false;
        });
      }
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: const Center(child: LottieLoading(size: 150)),
      );
    }

    if (_isLoggedIn) {
      // Jika sudah login, langsung tampilkan HomePage
      return const HomePage();
    }

    // Jika belum login, tampilkan AuthPage
    return AuthPage(
      onAuthSuccess: _navigateToHome,
    );
  }
}