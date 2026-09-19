import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:flutter/foundation.dart';
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

// Disamakan dengan halaman log_aktivitas.dart.
final logsCollection = firestore.FirebaseFirestore.instance.collection(
  'log_aktivitas',
);

final accountsCollection = firestore.FirebaseFirestore.instance.collection(
  'digital_accounts',
);

final userAccountsCollection = firestore.FirebaseFirestore.instance.collection(
  'manajemen account',
);

// ============================================================
// KOLEKSI ARSIP
// ============================================================

final archiveStudentsCollection = firestore.FirebaseFirestore.instance
    .collection('archive_students');

final archiveTransactionsCollection = firestore.FirebaseFirestore.instance
    .collection('archived_transactions');

// ============================================================
// KOLEKSI GURU & KARYAWAN
// ============================================================

final teachersCollection = firestore.FirebaseFirestore.instance.collection(
  'teachers',
);

// ============================================================
// MODEL ARSIP BULANAN
// ============================================================

class ArchivedMonth {
  final String monthKey;
  final int year;
  final int month;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;
  final DateTime? archivedAt;

  ArchivedMonth({
    required this.monthKey,
    required this.year,
    required this.month,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
    this.archivedAt,
  });

  double get net => totalIncome - totalExpense;
}

// ============================================================
// ACCOUNT MANAGEMENT
// ============================================================

Future<firestore.DocumentSnapshot<Map<String, dynamic>>> fetchUserAccount(
  String uid,
) async {
  return await userAccountsCollection.doc(uid).get();
}

Future<bool> isUserAccountRegistered(String uid) async {
  final snapshot = await userAccountsCollection.doc(uid).get();
  return snapshot.exists;
}

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
  final exists = await isUserAccountRegistered(uid);

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

  await recordActivityLog(
    action: exists ? ActivityAction.edit : ActivityAction.tambah,
    detail: exists
        ? 'Memperbarui akun pengguna: $nama'
        : 'Membuat akun pengguna: $nama',
  );
}

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

  await recordActivityLog(
    action: ActivityAction.tambah,
    detail: 'Membuat akun pengguna: $nama',
  );
}

Future<void> deleteUserAccount(String uid) async {
  final snapshot = await userAccountsCollection.doc(uid).get();
  final name = snapshot.data()?['nama']?.toString() ?? uid;

  await userAccountsCollection.doc(uid).delete();

  await recordActivityLog(
    action: ActivityAction.hapus,
    detail: 'Menghapus akun pengguna: $name',
  );
}

// ============================================================
// TEACHER MODEL & CRUD
// ============================================================

class Teacher {
  final String id;
  final String nama;
  final String role;

  Teacher({
    required this.id,
    required this.nama,
    required this.role,
  });

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
  final exists = await teachersCollection.doc(teacher.id).get();

  await teachersCollection.doc(teacher.id).set(teacher.toMap());

  await recordActivityLog(
    action: exists.exists
        ? ActivityAction.edit
        : ActivityAction.tambah,
    detail: exists.exists
        ? 'Mengedit data guru: ${teacher.nama}'
        : 'Menambah data guru: ${teacher.nama}',
  );
}

Future<void> deleteTeacher(String id) async {
  final snapshot = await teachersCollection.doc(id).get();
  final nama = snapshot.data()?['nama']?.toString() ?? id;

  await teachersCollection.doc(id).delete();

  await recordActivityLog(
    action: ActivityAction.hapus,
    detail: 'Menghapus data guru: $nama',
  );
}

Future<List<Teacher>> fetchTeachers() async {
  final snapshot = await teachersCollection.get();
  return snapshot.docs.map((doc) => Teacher.fromMap(doc.data())).toList();
}

// ============================================================
// STUDENT CRUD
// ============================================================

Future<List<Student>> fetchActiveStudents() async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  return snapshot.docs
      .map((doc) => Student.fromMap(doc.data()))
      .toList();
}

Future<List<Student>> fetchAllStudents() async {
  final snapshot = await studentsCollection.get();
  return snapshot.docs
      .map((doc) => Student.fromMap(doc.data()))
      .toList();
}

Future<void> saveStudent(Student student) async {
  final exists = await studentsCollection.doc(student.id).get();

  await studentsCollection.doc(student.id).set(student.toMap());

  await recordActivityLog(
    action: exists.exists
        ? ActivityAction.edit
        : ActivityAction.tambah,
    detail: exists.exists
        ? 'Mengedit data siswa: ${student.name} | ${student.kelas}'
        : 'Menambah siswa: ${student.name} | ${student.kelas}',
  );
}

Future<void> deleteStudent(String id) async {
  final snapshot = await studentsCollection.doc(id).get();
  final data = snapshot.data();
  final name = data?['name']?.toString() ?? id;

  await studentsCollection.doc(id).delete();

  await recordActivityLog(
    action: ActivityAction.hapus,
    detail: 'Menghapus siswa: $name',
  );
}

// ============================================================
// FUNGSI ARSIP SISWA
// ============================================================

Future<void> archiveGraduatedStudentsFirestore(String tahunArsip) async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  final batch = firestore.FirebaseFirestore.instance.batch();
  int archivedCount = 0;

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
      archivedCount++;
    }
  }

  await batch.commit();

  if (archivedCount > 0) {
    await recordActivityLog(
      action: ActivityAction.edit,
      detail:
          'Mengarsipkan $archivedCount siswa kelas XII ke arsip "$tahunArsip"',
    );
  }
}

Future<List<Map<String, dynamic>>> fetchArchiveFolders() async {
  final snapshot = await archiveStudentsCollection.get();

  final Map<String, int> counts = {};
  for (var doc in snapshot.docs) {
    final String tahun =
        doc.data()['tahunArsip'] as String? ?? 'Unknown';
    counts[tahun] = (counts[tahun] ?? 0) + 1;
  }

  final result = counts.entries
      .map((entry) => {'name': entry.key, 'count': entry.value})
      .toList();

  result.sort(
    (a, b) => (b['name'] as String).compareTo(a['name'] as String),
  );

  return result;
}

Future<List<Map<String, dynamic>>> fetchMajorsInArchive(
  String tahunArsip,
) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .get();

  final Map<String, int> counts = {};
  for (var doc in snapshot.docs) {
    final String jurusan =
        doc.data()['jurusan'] as String? ?? 'Unknown';
    if (jurusan.isNotEmpty) {
      counts[jurusan] = (counts[jurusan] ?? 0) + 1;
    }
  }

  final result = counts.entries
      .map((entry) => {'name': entry.key, 'count': entry.value})
      .toList();

  result.sort(
    (a, b) => (a['name'] as String).compareTo(b['name'] as String),
  );

  return result;
}

Future<List<Student>> fetchArchivedStudents(
  String tahunArsip,
  String jurusan,
) async {
  final snapshot = await archiveStudentsCollection
      .where('tahunArsip', isEqualTo: tahunArsip)
      .where('jurusan', isEqualTo: jurusan)
      .get();

  return snapshot.docs
      .map((doc) => Student.fromMap(doc.data()))
      .toList();
}

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

  await recordActivityLog(
    action: ActivityAction.tambah,
    detail:
        'Menyimpan siswa ${student.name} ke arsip "$tahunArsip" ($jurusan)',
  );
}

// ============================================================
// NAIK KELAS
// ============================================================

Future<void> promoteStudentsFirestore() async {
  final snapshot = await studentsCollection
      .where('isActive', isEqualTo: true)
      .get();

  final batch = firestore.FirebaseFirestore.instance.batch();
  int promotedCount = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final String kelas = data['kelas'] ?? '';

    if (kelas.startsWith('X ')) {
      batch.update(
        doc.reference,
        {'kelas': kelas.replaceFirst('X ', 'XI ')},
      );
      promotedCount++;
    } else if (kelas.startsWith('XI ')) {
      batch.update(
        doc.reference,
        {'kelas': kelas.replaceFirst('XI ', 'XII ')},
      );
      promotedCount++;
    }
  }

  await batch.commit();

  if (promotedCount > 0) {
    await recordActivityLog(
      action: ActivityAction.edit,
      detail: 'Kenaikan kelas diterapkan pada $promotedCount siswa aktif',
    );
  }
}

// ============================================================
// TRANSACTION CRUD
// ============================================================

Future<List<Transaction>> fetchTransactions({int limit = 50}) async {
  final snapshot = await transactionsCollection
      .orderBy('date', descending: true)
      .limit(limit)
      .get();

  return snapshot.docs
      .map((doc) => Transaction.fromMap(doc.data()))
      .toList();
}

Future<List<Transaction>> fetchAllTransactions() async {
  final snapshot = await transactionsCollection.get();
  return snapshot.docs
      .map((doc) => Transaction.fromMap(doc.data()))
      .toList();
}

Future<void> addTransaction(Transaction transaction) async {
  final exists = await transactionsCollection.doc(transaction.id).get();

  await transactionsCollection
      .doc(transaction.id)
      .set(transaction.toMap());

  await recordActivityLog(
    action: exists.exists
        ? ActivityAction.edit
        : ActivityAction.tambah,
    detail: exists.exists
        ? 'Mengedit transaksi: ${transaction.description} | ${_formatRupiah(transaction.amount)}'
        : 'Menambah transaksi: ${transaction.description} | ${_formatRupiah(transaction.amount)}',
    timestamp: transaction.date,
  );
}

Future<void> deleteTransaction(String id) async {
  final snapshot = await transactionsCollection.doc(id).get();
  final data = snapshot.data();
  final description = data?['description']?.toString() ?? id;

  await transactionsCollection.doc(id).delete();

  await recordActivityLog(
    action: ActivityAction.hapus,
    detail: 'Menghapus transaksi: $description',
  );
}

// ============================================================
// ARSIP TRANSAKSI BULANAN
// ============================================================

Future<void> archiveCurrentMonthTransactions(
  List<Transaction> transactions,
  int year,
  int month,
) async {
  final monthKey = '$year-${month.toString().padLeft(2, '0')}';

  final totalIncome = transactions
      .where((t) => t.type == TransType.pemasukan)
      .fold<double>(0, (sum, t) => sum + t.amount);

  final totalExpense = transactions
      .where((t) => t.type == TransType.pengeluaran)
      .fold<double>(0, (sum, t) => sum + t.amount);

  await archiveTransactionsCollection.doc(monthKey).set({
    'monthKey': monthKey,
    'year': year,
    'month': month,
    'transactions': transactions.map((t) => t.toMap()).toList(),
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'transactionCount': transactions.length,
    'archivedAt': firestore.FieldValue.serverTimestamp(),
  });

  await recordActivityLog(
    action: ActivityAction.edit,
    detail:
        'Mengarsipkan ${transactions.length} transaksi bulan $monthKey',
  );
}

Future<List<ArchivedMonth>> fetchArchivedMonths() async {
  final snapshot = await archiveTransactionsCollection.get();

  final result = snapshot.docs.map((doc) {
    final data = doc.data();

    final transactions = (data['transactions'] as List<dynamic>?)
            ?.map(
              (t) => Transaction.fromMap(
                t as Map<String, dynamic>,
              ),
            )
            .toList() ??
        [];

    return ArchivedMonth(
      monthKey: data['monthKey'] ?? '',
      year: (data['year'] ?? 0) as int,
      month: (data['month'] ?? 0) as int,
      transactions: transactions,
      totalIncome: (data['totalIncome'] ?? 0).toDouble(),
      totalExpense: (data['totalExpense'] ?? 0).toDouble(),
      archivedAt: data['archivedAt'] != null &&
              data['archivedAt'] is firestore.Timestamp
          ? (data['archivedAt'] as firestore.Timestamp).toDate()
          : null,
    );
  }).toList();

  result.sort((a, b) {
    if (a.year != b.year) return b.year.compareTo(a.year);
    return b.month.compareTo(a.month);
  });

  return result;
}

Future<ArchivedMonth?> fetchArchivedMonth(String monthKey) async {
  final doc = await archiveTransactionsCollection.doc(monthKey).get();
  if (!doc.exists) return null;

  final data = doc.data()!;

  final transactions = (data['transactions'] as List<dynamic>?)
          ?.map(
            (t) => Transaction.fromMap(
              t as Map<String, dynamic>,
            ),
          )
          .toList() ??
      [];

  return ArchivedMonth(
    monthKey: data['monthKey'] ?? monthKey,
    year: (data['year'] ?? 0) as int,
    month: (data['month'] ?? 0) as int,
    transactions: transactions,
    totalIncome: (data['totalIncome'] ?? 0).toDouble(),
    totalExpense: (data['totalExpense'] ?? 0).toDouble(),
    archivedAt: data['archivedAt'] != null &&
            data['archivedAt'] is firestore.Timestamp
        ? (data['archivedAt'] as firestore.Timestamp).toDate()
        : null,
  );
}

Future<bool> archiveCurrentMonthData() async {
  try {
    final now = DateTime.now();

    final allTransactions = await fetchAllTransactions();

    final currentMonthTransactions = allTransactions
        .where(
          (t) =>
              t.date.month == now.month &&
              t.date.year == now.year,
        )
        .toList();

    final Set<String> seenIds =
        currentMonthTransactions.map((t) => t.id).toSet();

    for (final t in localTransactions) {
      if (t.date.month == now.month &&
          t.date.year == now.year &&
          !seenIds.contains(t.id)) {
        currentMonthTransactions.add(t);
        seenIds.add(t.id);
      }
    }

    if (currentMonthTransactions.isEmpty) return false;

    await archiveCurrentMonthTransactions(
      currentMonthTransactions,
      now.year,
      now.month,
    );

    final monthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';

    arsipTransaksi.putIfAbsent(monthKey, () => []);

    final existingIds =
        arsipTransaksi[monthKey]!.map((t) => t.id).toSet();

    for (final t in currentMonthTransactions) {
      if (!existingIds.contains(t.id)) {
        arsipTransaksi[monthKey]!.add(t);
      }
    }

    return true;
  } catch (e) {
    debugPrint('[Archive] Gagal mengarsipkan transaksi: $e');
    return false;
  }
}

// ============================================================
// ACTIVITY LOG CRUD
// ============================================================

Future<void> addActivityLog(ActivityLog log) async {
  await recordActivityLog(
    user: log.user,
    action: log.action,
    detail: log.detail,
    timestamp: log.timestamp,
  );
}

Future<List<ActivityLog>> fetchRecentLogs({int limit = 20}) async {
  final snapshot = await logsCollection
      .orderBy('timestamp', descending: true)
      .limit(limit)
      .get();

  return snapshot.docs
      .map((doc) => ActivityLog.fromMap(doc.data()))
      .toList();
}

// ============================================================
// DIGITAL ACCOUNT CRUD
// ============================================================

Future<List<DigitalAccount>> fetchDigitalAccounts() async {
  final snapshot = await accountsCollection.get();
  return snapshot.docs
      .map((doc) => DigitalAccount.fromMap(doc.data()))
      .toList();
}

// ============================================================
// SEED DATA
// ============================================================

Future<void> seedFirestoreIfEmpty() async {
  // STUDENTS
  final studentSnapshot = await studentsCollection.limit(1).get();
  if (studentSnapshot.docs.isEmpty) {
    final sampleList = generateSampleStudents();
    for (var student in sampleList) {
      await studentsCollection.doc(student.id).set(student.toMap());
    }
  }

  // TRANSACTIONS
  final transactionSnapshot = await transactionsCollection.limit(1).get();
  if (transactionSnapshot.docs.isEmpty) {
    generateSampleTransactions();

    final allTransactions = <Transaction>[];
    arsipTransaksi.forEach((key, list) {
      allTransactions.addAll(list);
    });
    allTransactions.addAll(localTransactions);

    for (var transaction in allTransactions) {
      await transactionsCollection
          .doc(transaction.id)
          .set(transaction.toMap());
    }

    localTransactions.clear();
    arsipTransaksi.clear();
  }

  // DIGITAL ACCOUNTS
  final accountSnapshot = await accountsCollection.limit(1).get();
  if (accountSnapshot.docs.isEmpty) {
    for (var account in defaultAccounts) {
      await accountsCollection.add(account.toMap());
    }
  }
}

String _formatRupiah(double value) {
  final rounded = value.round().toString();
  final reversed = rounded.split('').reversed.toList();
  final parts = <String>[];

  for (int i = 0; i < reversed.length; i += 3) {
    final end =
        (i + 3 < reversed.length) ? i + 3 : reversed.length;
    parts.add(reversed.sublist(i, end).reversed.join());
  }

  return 'Rp ${parts.reversed.join('.')}';
}
