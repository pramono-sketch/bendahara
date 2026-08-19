// firebase/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../data.dart';

// ================== KOLEKSI REFERENSI ==================
final studentsCollection = firestore.FirebaseFirestore.instance.collection('students');
final transactionsCollection = firestore.FirebaseFirestore.instance.collection('transactions');
final logsCollection = firestore.FirebaseFirestore.instance.collection('activity_logs');
final accountsCollection = firestore.FirebaseFirestore.instance.collection('digital_accounts');

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

/// Mengarsipkan siswa lulus (kelas XII) – set isActive = false
Future<void> archiveGraduatedStudentsFirestore(String tahunAjaran) async {
  final snapshot = await studentsCollection
      .where('kelas', isGreaterThanOrEqualTo: 'XII')
      .where('kelas', isLessThan: 'XIII')
      .where('isActive', isEqualTo: true)
      .get();

  final batch = firestore.FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    final data = doc.data();
    data['isActive'] = false;
    data['tahunArsip'] = tahunAjaran;
    batch.update(doc.reference, data);
  }
  await batch.commit();
}

/// Menaikkan kelas siswa aktif (X→XI, XI→XII)
Future<void> promoteStudentsFirestore() async {
  final snapshot =
      await studentsCollection.where('isActive', isEqualTo: true).get();
  final batch = firestore.FirebaseFirestore.instance.batch();
  for (var doc in snapshot.docs) {
    final data = doc.data();
    String kelas = data['kelas'] ?? '';
    if (kelas.startsWith('X ')) {
      data['kelas'] = kelas.replaceFirst('X ', 'XI ');
    } else if (kelas.startsWith('XI ')) {
      data['kelas'] = kelas.replaceFirst('XI ', 'XII ');
    }
    batch.update(doc.reference, data);
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