// firebase/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../data.dart';
import '../simulation/FAB_helper.dart';

// ================== KOLEKSI REFERENSI ==================
final studentsCollection =
    firestore.FirebaseFirestore.instance.collection('students');
final transactionsCollection =
    firestore.FirebaseFirestore.instance.collection('transactions');
final logsCollection =
    firestore.FirebaseFirestore.instance.collection('activity_logs');
final accountsCollection =
    firestore.FirebaseFirestore.instance.collection('digital_accounts');

// FIX: Collection terpisah khusus untuk siswa yang sudah diarsipkan (lulus)
final archiveStudentsCollection =
    firestore.FirebaseFirestore.instance.collection('archive_students');

// FIX: Collection khusus untuk data Guru & Karyawan
final teachersCollection =
    firestore.FirebaseFirestore.instance.collection('teachers');

// ================== TEACHER MODEL & CRUD ==================
class Teacher {
  final String id;
  final String nama;
  final String role; // 'guru' atau 'karyawan'

  Teacher({required this.id, required this.nama, required this.role});

  Map<String, dynamic> toMap() => {
        'id': id,
        'nama': nama,
        'role': role,
      };

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

// ================== STUDENT CRUD ==================

/// Ambil semua siswa aktif dari Firestore
Future<List<Student>> fetchActiveStudents() async {
  final snapshot =
      await studentsCollection.where('isActive', isEqualTo: true).get();
  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Ambil semua siswa (termasuk tidak aktif)
Future<List<Student>> fetchAllStudents() async {
  final snapshot = await studentsCollection.get();
  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Simpan atau perbarui siswa
Future<void> saveStudent(Student student) async {
  await studentsCollection.doc(student.id).set(student.toMap());
}

/// Hapus siswa (jika diperlukan)
Future<void> deleteStudent(String id) async {
  await studentsCollection.doc(id).delete();
}

// ============================================================
// ================== FUNGSI ARSIP (BARU) ====================
// ============================================================

/// Mengarsipkan siswa lulus (kelas XII) — PINDAH ke collection archive_students
/// Siswa dihapus dari collection 'students' dan dipindahkan ke 'archive_students'
/// dengan field tambahan: tahunArsip, jurusan, isActive=false
Future<void> archiveGraduatedStudentsFirestore(String tahunArsip) async {
  final snapshot =
      await studentsCollection.where('isActive', isEqualTo: true).get();

  final batch = firestore.FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    final data = doc.data();
    String kelas = data['kelas'] ?? '';

    if (kelas.startsWith('XII ')) {
      final parts = kelas.split(' ');
      String jurusan = parts.length >= 2 ? parts[1] : '';

      final archiveData = Map<String, dynamic>.from(data);
      archiveData['tahunArsip'] = tahunArsip; // FIX: Gunakan tahunArsip
      archiveData['jurusan'] = jurusan;
      archiveData['isActive'] = false;
      archiveData['archivedAt'] = firestore.FieldValue.serverTimestamp();

      batch.set(archiveStudentsCollection.doc(doc.id), archiveData);
      batch.delete(doc.reference);
    }
  }
  await batch.commit();
}

/// Ambil daftar folder arsip (tahun ajaran) dari collection archive_students
/// Returns list of {name, count}
Future<List<Map<String, dynamic>>> fetchArchiveFolders() async {
  final snapshot = await archiveStudentsCollection.get();

  final Map<String, int> counts = {};
  for (var doc in snapshot.docs) {
    final tahun = doc.data()['tahunArsip'] as String? ?? 'Unknown';
    counts[tahun] = (counts[tahun] ?? 0) + 1;
  }

  final result = counts.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
  result.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
  return result;
}

/// Ambil daftar jurusan dalam tahun arsip tertentu
/// Returns list of {name, count}
Future<List<Map<String, dynamic>>> fetchMajorsInArchive(String tahunArsip) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .get();

  final Map<String, int> counts = {};
  for (var doc in snapshot.docs) {
    final jurusan = doc.data()['jurusan'] as String? ?? 'Unknown';
    if (jurusan.isNotEmpty) {
      counts[jurusan] = (counts[jurusan] ?? 0) + 1;
    }
  }

  final result = counts.entries.map((e) => {'name': e.key, 'count': e.value}).toList();
  result.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
  return result;
}

/// Ambil daftar siswa arsip berdasarkan tahun arsip dan jurusan
Future<List<Student>> fetchArchivedStudents(String tahunArsip, String jurusan) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .where('jurusan', isEqualTo: jurusan)
      .get();

  return snapshot.docs.map((doc) => Student.fromMap(doc.data())).toList();
}

/// Simpan perubahan data siswa arsip (jika diperlukan)
Future<void> saveArchivedStudent(Student student, String tahunArsip, String jurusan) async {
  final data = student.toMap();
  data['tahunArsip'] = tahunArsip;
  data['jurusan'] = jurusan;
  data['isActive'] = false;
  await archiveStudentsCollection.doc(student.id).set(data);
}

// ============================================================
// ================== END FUNGSI ARSIP =======================
// ============================================================

/// Menaikkan kelas siswa aktif (X→XI, XI→XII)
Future<void> promoteStudentsFirestore() async {
  final snapshot =
      await studentsCollection.where('isActive', isEqualTo: true).get();
  final batch = firestore.FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    final data = doc.data();
    String kelas = data['kelas'] ?? '';

    if (kelas.startsWith('X ')) {
      batch.update(doc.reference, {'kelas': kelas.replaceFirst('X ', 'XI ')});
    } else if (kelas.startsWith('XI ')) {
      batch.update(doc.reference, {'kelas': kelas.replaceFirst('XI ', 'XII ')});
    }
  }
  await batch.commit();
}

// ================== TRANSACTION CRUD ==================

/// Ambil transaksi terbaru
Future<List<Transaction>> fetchTransactions({int limit = 50}) async {
  final snapshot = await transactionsCollection
      .orderBy('date', descending: true)
      .limit(limit)
      .get();
  return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
}

/// Ambil semua transaksi
Future<List<Transaction>> fetchAllTransactions() async {
  final snapshot = await transactionsCollection.get();
  return snapshot.docs.map((doc) => Transaction.fromMap(doc.data())).toList();
}

/// Tambah transaksi baru
Future<void> addTransaction(Transaction transaction) async {
  await transactionsCollection.doc(transaction.id).set(transaction.toMap());
}

// ================== ACTIVITY LOG CRUD ==================

/// Tambah log aktivitas
Future<void> addActivityLog(ActivityLog log) async {
  await logsCollection.add(log.toMap());
}

/// Ambil log terbaru
Future<List<ActivityLog>> fetchRecentLogs({int limit = 20}) async {
  final snapshot = await logsCollection
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .get();
  return snapshot.docs.map((doc) => ActivityLog.fromMap(doc.data())).toList();
}

// ================== DIGITAL ACCOUNT CRUD ==================

/// Ambil akun digital
Future<List<DigitalAccount>> fetchDigitalAccounts() async {
  final snapshot = await accountsCollection.get();
  return snapshot.docs.map((doc) => DigitalAccount.fromMap(doc.data())).toList();
}

// ================== SEED DATA ==================

/// Isi data sample ke Firestore jika koleksi kosong
Future<void> seedFirestoreIfEmpty() async {
  // Seed students
  final studentSnapshot = await studentsCollection.limit(1).get();
  if (studentSnapshot.docs.isEmpty) {
    final sampleList = generateSampleStudents();
    for (var s in sampleList) {
      await studentsCollection.doc(s.id).set(s.toMap());
    }
  }

  // Seed transactions
  final transSnapshot = await transactionsCollection.limit(1).get();
  if (transSnapshot.docs.isEmpty) {
    generateSampleTransactions();
    final allTransactions = <Transaction>[];
    arsipTransaksi.forEach((key, list) => allTransactions.addAll(list));
    allTransactions.addAll(localTransactions);
    for (var t in allTransactions) {
      await transactionsCollection.doc(t.id).set(t.toMap());
    }
    localTransactions.clear();
    arsipTransaksi.clear();
  }

  // Seed digital accounts
  final accSnapshot = await accountsCollection.limit(1).get();
  if (accSnapshot.docs.isEmpty) {
    for (var acc in defaultAccounts) {
      await accountsCollection.add(acc.toMap());
    }
  }
}