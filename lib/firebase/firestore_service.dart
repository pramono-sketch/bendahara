// lib/firebase/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../data.dart';
import '../simulation/FAB_helper.dart';

// ============================================================
// KOLEKSI REFERENSI
// ============================================================

final studentsCollection = firestore.FirebaseFirestore.instance.collection(
  'students',
);

final transactionsCollection = firestore.FirebaseFirestore.instance.collection(
  'transactions',
);

final logsCollection = firestore.FirebaseFirestore.instance.collection(
  'activity_logs',
);

final accountsCollection = firestore.FirebaseFirestore.instance.collection(
  'digital_accounts',
);

// Koleksi akun pengguna aplikasi.
final userAccountsCollection = firestore.FirebaseFirestore.instance.collection(
  'manajemen account',
);

// ============================================================
// KOLEKSI ARSIP
// ============================================================

final archiveStudentsCollection = firestore.FirebaseFirestore.instance
    .collection('archive_students');

// ============================================================
// KOLEKSI GURU & KARYAWAN
// ============================================================

final teachersCollection = firestore.FirebaseFirestore.instance.collection(
  'teachers',
);

// ============================================================
// ACCOUNT MANAGEMENT
// ============================================================

/// Ambil akun aplikasi berdasarkan UID Firebase Authentication.
///
/// Collection:
/// manajemen account
///
/// Document ID:
/// UID Firebase
Future<firestore.DocumentSnapshot<Map<String, dynamic>>> fetchUserAccount(
  String uid,
) async {
  return await userAccountsCollection.doc(uid).get();
}

/// Mengecek apakah UID sudah memiliki akun di Firestore.
Future<bool> isUserAccountRegistered(String uid) async {
  final snapshot = await userAccountsCollection.doc(uid).get();

  return snapshot.exists;
}

/// Simpan / update akun aplikasi.
///
/// UID Firebase digunakan sebagai document ID agar satu
/// akun Firebase hanya memiliki satu profile aplikasi.
Future<void> saveUserAccount({
  required String uid,
  required String nama,
  required String? email,
  required String? photoUrl,
  required String role,
  required String nomorTelepon,
  required bool nomorTerverifikasi,
  required String provider,
}) async {
  await userAccountsCollection.doc(uid).set({
    'uid': uid,
    'nama': nama,
    'email': email,
    'photoUrl': photoUrl,
    'role': role,
    'nomorTelepon': nomorTelepon,
    'nomorTerverifikasi': nomorTerverifikasi,
    'provider': provider,
    'updatedAt': firestore.FieldValue.serverTimestamp(),
  }, firestore.SetOptions(merge: true));
}

/// Membuat akun baru.
///
/// Fungsi ini menggunakan createdAt hanya saat document baru.
Future<void> createUserAccount({
  required String uid,
  required String nama,
  required String? email,
  required String? photoUrl,
  required String role,
  required String nomorTelepon,
  required bool nomorTerverifikasi,
  required String provider,
}) async {
  await userAccountsCollection.doc(uid).set({
    'uid': uid,
    'nama': nama,
    'email': email,
    'photoUrl': photoUrl,
    'role': role,
    'nomorTelepon': nomorTelepon,
    'nomorTerverifikasi': nomorTerverifikasi,
    'provider': provider,
    'createdAt': firestore.FieldValue.serverTimestamp(),
    'updatedAt': firestore.FieldValue.serverTimestamp(),
  }, firestore.SetOptions(merge: false));
}

/// Hapus akun aplikasi dari collection manajemen account.
///
/// Tidak menghapus akun dari Firebase Authentication.
Future<void> deleteUserAccount(String uid) async {
  await userAccountsCollection.doc(uid).delete();
}

// ============================================================
// TEACHER MODEL & CRUD
// ============================================================

class Teacher {
  final String id;
  final String nama;
  final String role; // 'guru' atau 'karyawan'

  Teacher({required this.id, required this.nama, required this.role});

  Map<String, dynamic> toMap() => {'id': id, 'nama': nama, 'role': role};

  factory Teacher.fromMap(Map<String, dynamic> map) => Teacher(
    id: map['id'] ?? '',
    nama: map['nama'] ?? '',
    role: map['role'] ?? 'guru',
  );
}

Future<void> saveTeacher(Teacher teacher) async {
  await teachersCollection.doc(teacher.id).set(teacher.toMap());
}

Future<void> deleteTeacher(String id) async {
  await teachersCollection.doc(id).delete();
}

Future<List<Teacher>> fetchTeachers() async {
  final snapshot = await teachersCollection.get();

  return snapshot.docs.map((doc) => Teacher.fromMap(doc.data())).toList();
}

// ============================================================
// STUDENT CRUD
// ============================================================

/// Ambil semua siswa aktif dari Firestore.
Future<List<Student>> fetchActiveStudents() async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Ambil semua siswa termasuk tidak aktif.
Future<List<Student>> fetchAllStudents() async {
  final snapshot = await studentsCollection.get();

  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Simpan atau perbarui siswa.
Future<void> saveStudent(Student student) async {
  await studentsCollection.doc(student.id).set(student.toMap());
}

/// Hapus siswa.
Future<void> deleteStudent(String id) async {
  await studentsCollection.doc(id).delete();
}

// ============================================================
// FUNGSI ARSIP
// ============================================================

/// Mengarsipkan siswa kelas XII.
///
/// Siswa dipindahkan dari:
/// students
///
/// ke:
/// archive_students
Future<void> archiveGraduatedStudentsFirestore(String tahunArsip) async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  final batch = firestore.FirebaseFirestore.instance.batch();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    final String kelas = data['kelas'] ?? '';

    if (kelas.startsWith('XII ')) {
      final parts = kelas.split(' ');

      final String jurusan = parts.length >= 2 ? parts[1] : '';

      final archiveData = Map<String, dynamic>.from(data);

      archiveData['tahunArsip'] = tahunArsip;

      archiveData['jurusan'] = jurusan;

      archiveData['isActive'] = false;

      archiveData['archivedAt'] = firestore.FieldValue.serverTimestamp();

      batch.set(archiveStudentsCollection.doc(doc.id), archiveData);

      batch.delete(doc.reference);
    }
  }

  await batch.commit();
}

/// Ambil daftar folder arsip.
Future<List<Map<String, dynamic>>> fetchArchiveFolders() async {
  final snapshot = await archiveStudentsCollection.get();

  final Map<String, int> counts = {};

  for (var doc in snapshot.docs) {
    final String tahun = doc.data()['tahunArsip'] as String? ?? 'Unknown';

    counts[tahun] = (counts[tahun] ?? 0) + 1;
  }

  final result = counts.entries
      .map((entry) => {'name': entry.key, 'count': entry.value})
      .toList();

  result.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));

  return result;
}

/// Ambil daftar jurusan pada tahun arsip tertentu.
Future<List<Map<String, dynamic>>> fetchMajorsInArchive(
  String tahunArsip,
) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .get();

  final Map<String, int> counts = {};

  for (var doc in snapshot.docs) {
    final String jurusan = doc.data()['jurusan'] as String? ?? 'Unknown';

    if (jurusan.isNotEmpty) {
      counts[jurusan] = (counts[jurusan] ?? 0) + 1;
    }
  }

  final result = counts.entries
      .map((entry) => {'name': entry.key, 'count': entry.value})
      .toList();

  result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

  return result;
}

/// Ambil siswa arsip berdasarkan tahun dan jurusan.
Future<List<Student>> fetchArchivedStudents(
  String tahunArsip,
  String jurusan,
) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .where('jurusan', isEqualTo: jurusan)
      .get();

  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Simpan perubahan siswa arsip.
Future<void> saveArchivedStudent(
  Student student,
  String tahunArsip,
  String jurusan,
) async {
  final data = student.toMap();

  data['tahunArsip'] = tahunArsip;

  data['jurusan'] = jurusan;

  data['isActive'] = false;

  await archiveStudentsCollection.doc(student.id).set(data);
}

// ============================================================
// END ARSIP
// ============================================================

// ============================================================
// NAIK KELAS
// ============================================================

/// Menaikkan kelas siswa aktif.
///
/// X  -> XI
/// XI -> XII
Future<void> promoteStudentsFirestore() async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  final batch = firestore.FirebaseFirestore.instance.batch();

  for (var doc in snapshot.docs) {
    final data = doc.data();

    final String kelas = data['kelas'] ?? '';

    if (kelas.startsWith('X ')) {
      batch.update(doc.reference, {'kelas': kelas.replaceFirst('X ', 'XI ')});
    } else if (kelas.startsWith('XI ')) {
      batch.update(doc.reference, {'kelas': kelas.replaceFirst('XI ', 'XII ')});
    }
  }

  await batch.commit();
}

// ============================================================
// TRANSACTION CRUD
// ============================================================

/// Ambil transaksi terbaru.
Future<List<Transaction>> fetchTransactions({int limit = 50}) async {
  final snapshot = await transactionsCollection
      .orderBy('date', descending: true)
      .limit(limit)
      .get();

  return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
}

/// Ambil semua transaksi.
Future<List<Transaction>> fetchAllTransactions() async {
  final snapshot = await transactionsCollection.get();

  return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
}

/// Tambah transaksi.
Future<void> addTransaction(Transaction transaction) async {
  await transactionsCollection.doc(transaction.id).set(transaction.toMap());
}

// ============================================================
// ACTIVITY LOG CRUD
// ============================================================

/// Tambah log aktivitas.
Future<void> addActivityLog(ActivityLog log) async {
  await logsCollection.add(log.toMap());
}

/// Ambil log terbaru.
Future<List<ActivityLog>> fetchRecentLogs({int limit = 20}) async {
  final snapshot = await logsCollection
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .get();

  return snapshot.docs.map((doc) => ActivityLog.fromMap(doc.data())).toList();
}

// ============================================================
// DIGITAL ACCOUNT CRUD
// ============================================================

/// Ambil akun digital.
Future<List<DigitalAccount>> fetchDigitalAccounts() async {
  final snapshot = await accountsCollection.get();

  return snapshot.docs
      .map((doc) => DigitalAccount.fromMap(doc.data()))
      .toList();
}

// ============================================================
// SEED DATA
// ============================================================

/// Isi data sample ke Firestore jika koleksi kosong.
Future<void> seedFirestoreIfEmpty() async {
  // ==========================================================
  // STUDENTS
  // ==========================================================

  final studentSnapshot = await studentsCollection.limit(1).get();

  if (studentSnapshot.docs.isEmpty) {
    final sampleList = generateSampleStudents();

    for (var student in sampleList) {
      await studentsCollection.doc(student.id).set(student.toMap());
    }
  }

  // ==========================================================
  // TRANSACTIONS
  // ==========================================================

  final transactionSnapshot = await transactionsCollection.limit(1).get();

  if (transactionSnapshot.docs.isEmpty) {
    generateSampleTransactions();

    final allTransactions = <Transaction>[];

    arsipTransaksi.forEach((key, list) {
      allTransactions.addAll(list);
    });

    allTransactions.addAll(localTransactions);

    for (var transaction in allTransactions) {
      await transactionsCollection.doc(transaction.id).set(transaction.toMap());
    }

    localTransactions.clear();

    arsipTransaksi.clear();
  }

  // ==========================================================
  // DIGITAL ACCOUNTS
  // ==========================================================

  final accountSnapshot = await accountsCollection.limit(1).get();

  if (accountSnapshot.docs.isEmpty) {
    for (var account in defaultAccounts) {
      await accountsCollection.add(account.toMap());
    }
  }
}
