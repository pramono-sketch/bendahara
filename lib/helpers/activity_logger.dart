// helpers/activity_logger.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// ACTIVITY LOGGER
// ============================================================
// Service untuk mencatat log aktivitas pengguna ke Firebase Firestore.
// Mencakup berbagai aktivitas seperti login, logout, edit profil,
// ganti password, dan lainnya.
// ============================================================

class ActivityLogger {
  // ----------------------------------------------------------
  // KONSTANTA
  // ----------------------------------------------------------

  static const String _collection = 'log_aktivitas';

  // Kategori aktivitas
  static const String kategoriAuth = 'autentikasi';
  static const String kategoriProfil = 'profil';
  static const String kategoriKeamanan = 'keamanan';
  static const String kategoriNavigasi = 'navigasi';
  static const String kategoriSistem = 'sistem';

  // ----------------------------------------------------------
  // LOG UTAMA
  // ----------------------------------------------------------

  /// Mencatat aktivitas ke Firestore
  static Future<void> log({
    required String aktivitas,
    required String kategori,
    String? deskripsi,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;

      final now = DateTime.now();

      await FirebaseFirestore.instance
          .collection(_collection)
          .doc()
          .set({
        'uid': user?.uid ?? 'unknown',
        'email': user?.email ?? '',
        'nama': user?.displayName ?? '',
        'aktivitas': aktivitas,
        'kategori': kategori,
        'deskripsi': deskripsi ?? '',
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'timestampLocal': now.toIso8601String(),
        'platform': defaultTargetPlatform.name,
        'terhapus': false,
      });
    } catch (e) {
      debugPrint('Gagal mencatat aktivitas: $e');
    }
  }

  // ----------------------------------------------------------
  // AUTENTIKASI
  // ----------------------------------------------------------

  static Future<void> logLogin({
    String method = 'google',
  }) async {
    await log(
      aktivitas: 'Login',
      kategori: kategoriAuth,
      deskripsi: 'Pengguna berhasil masuk ke aplikasi',
      metadata: {'method': method},
    );
  }

  static Future<void> logLogout() async {
    await log(
      aktivitas: 'Logout',
      kategori: kategoriAuth,
      deskripsi: 'Pengguna keluar dari aplikasi',
    );
  }

  static Future<void> logLoginGagal({
    required String alasan,
  }) async {
    await log(
      aktivitas: 'Login Gagal',
      kategori: kategoriAuth,
      deskripsi: alasan,
      metadata: {'error': alasan},
    );
  }

  // ----------------------------------------------------------
  // PROFIL
  // ----------------------------------------------------------

  static Future<void> logLihatProfil() async {
    await log(
      aktivitas: 'Lihat Profil',
      kategori: kategoriProfil,
      deskripsi: 'Membuka halaman profil',
    );
  }

  static Future<void> logEditProfil() async {
    await log(
      aktivitas: 'Buka Edit Profil',
      kategori: kategoriProfil,
      deskripsi: 'Membuka dialog edit profil',
    );
  }

  static Future<void> logProfilDiperbarui({
    String? nama,
    String? nis,
    String? phone,
    String? address,
  }) async {
    await log(
      aktivitas: 'Profil Diperbarui',
      kategori: kategoriProfil,
      deskripsi: 'Data profil berhasil diperbarui',
      metadata: {
        if (nama != null) 'nama': nama,
        if (nis != null) 'nis': nis,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
      },
    );
  }

  static Future<void> logFotoProfil({
    required String source,
  }) async {
    await log(
      aktivitas: 'Ubah Foto Profil',
      kategori: kategoriProfil,
      deskripsi: 'Foto profil berhasil diperbarui',
      metadata: {'source': source},
    );
  }

  static Future<void> logFotoGagal({
    required String alasan,
  }) async {
    await log(
      aktivitas: 'Gagal Ubah Foto',
      kategori: kategoriProfil,
      deskripsi: alasan,
      metadata: {'error': alasan},
    );
  }

  static Future<void> logAvatarHati({
    required bool aktif,
  }) async {
    await log(
      aktivitas: aktif
          ? 'Aktifkan Avatar Hati'
          : 'Nonaktifkan Avatar Hati',
      kategori: kategoriProfil,
      deskripsi: aktif
          ? 'Easter egg avatar hati diaktifkan'
          : 'Easter egg avatar hati dinonaktifkan',
      metadata: {'heartShape': aktif},
    );
  }

  static Future<void> logBukaPemilihGambar() async {
    await log(
      aktivitas: 'Buka Pemilih Gambar',
      kategori: kategoriProfil,
      deskripsi: 'Membuka dialog pemilih gambar profil',
    );
  }

  // ----------------------------------------------------------
  // KEAMANAN
  // ----------------------------------------------------------

  static Future<void> logBukaKeamanan() async {
    await log(
      aktivitas: 'Buka Keamanan Akun',
      kategori: kategoriKeamanan,
      deskripsi: 'Membuka dialog keamanan akun',
    );
  }

  static Future<void> logPasswordDiperbarui() async {
    await log(
      aktivitas: 'Password Diperbarui',
      kategori: kategoriKeamanan,
      deskripsi: 'Password akun berhasil diubah',
    );
  }

  static Future<void> logPasswordGagal({
    required String alasan,
  }) async {
    await log(
      aktivitas: 'Gagal Ubah Password',
      kategori: kategoriKeamanan,
      deskripsi: alasan,
      metadata: {'error': alasan},
    );
  }

  // ----------------------------------------------------------
  // NAVIGASI
  // ----------------------------------------------------------

  static Future<void> logNavigasi({
    required String halaman,
  }) async {
    await log(
      aktivitas: 'Navigasi',
      kategori: kategoriNavigasi,
      deskripsi: 'Membuka halaman $halaman',
      metadata: {'halaman': halaman},
    );
  }

  // ----------------------------------------------------------
  // SISTEM
  // ----------------------------------------------------------

  static Future<void> logError({
    required String proses,
    required String error,
  }) async {
    await log(
      aktivitas: 'Error Sistem',
      kategori: kategoriSistem,
      deskripsi: 'Terjadi error pada proses $proses',
      metadata: {
        'proses': proses,
        'error': error,
      },
    );
  }
}