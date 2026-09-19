import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ============================================================
// ACTIVITY LOGGING
// ============================================================

/// Semua activity log aplikasi disimpan di collection ini.
///
/// Jangan menyimpan password, API key, token, atau data rahasia
/// ke dalam log.
final activityLogsCollection = FirebaseFirestore.instance.collection(
  'log_aktivitas',
);

/// Menulis activity log secara terpusat.
Future<void> recordActivityLog({
  String user = 'Admin',
  required ActivityAction action,
  required String detail,
  DateTime? timestamp,
}) async {
  final log = ActivityLog(
    user: user,
    action: action,
    detail: detail,
    timestamp: timestamp ?? DateTime.now(),
  );

  // Hindari duplikasi log lokal.
  final duplicate = localLogs.any(
    (existing) =>
        existing.user == log.user &&
        existing.action == log.action &&
        existing.detail == log.detail &&
        existing.timestamp == log.timestamp,
  );

  if (duplicate) {
    return;
  }

  localLogs.insert(0, log);

  try {
    await activityLogsCollection.add(log.toMap());
  } catch (e) {
    debugPrint('[ActivityLog] Gagal menyimpan log: $e');
  }
}

Future<void> logLogin({String user = 'Admin'}) async {
  await recordActivityLog(
    user: user,
    action: ActivityAction.login,
    detail: 'Login ke aplikasi',
  );
}

Future<void> logLogout({String user = 'Admin'}) async {
  await recordActivityLog(
    user: user,
    action: ActivityAction.logout,
    detail: 'Logout dari aplikasi',
  );
}

Future<void> logPayment({String user = 'Admin', required String detail}) async {
  await recordActivityLog(
    user: user,
    action: ActivityAction.bayar,
    detail: detail,
  );
}

// ============================================================
// MODEL AKUN DIGITAL
// ============================================================

class AkunDigital {
  final String id;
  String name;
  String? namaSiswa;
  String email;
  String penanggungJawab;
  String password;
  String keterangan;
  String category;
  String? kelas;

  AkunDigital({
    required this.id,
    required this.name,
    this.namaSiswa,
    required this.email,
    required this.penanggungJawab,
    required this.password,
    required this.keterangan,
    required this.category,
    this.kelas,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'namaSiswa': namaSiswa,
    'email': email,
    'penanggungJawab': penanggungJawab,
    'password': password,
    'keterangan': keterangan,
    'category': category,
    'kelas': kelas,
  };

  factory AkunDigital.fromJson(Map<String, dynamic> json) => AkunDigital(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    namaSiswa: json['namaSiswa']?.toString(),
    email: json['email']?.toString() ?? '',
    penanggungJawab: json['penanggungJawab']?.toString() ?? '',
    password: json['password']?.toString() ?? '',
    keterangan: json['keterangan']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    kelas: json['kelas']?.toString(),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'namaSiswa': namaSiswa,
    'email': email,
    'penanggungJawab': penanggungJawab,
    'password': password,
    'keterangan': keterangan,
    'category': category,
    'kelas': kelas,
  };

  static AkunDigital fromMap(Map<String, dynamic> map) {
    return AkunDigital(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      namaSiswa: map['namaSiswa']?.toString(),
      email: map['email']?.toString() ?? '',
      penanggungJawab: map['penanggungJawab']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      kelas: map['kelas']?.toString(),
    );
  }
}

// ============================================================
// SISTEM PEMBAYARAN
// ============================================================

enum PaymentStatus { lunas, belumBayar, sebagian }

class PaymentItem {
  String type;
  double amount;
  PaymentStatus status;
  double paidAmount;
  DateTime? lastPaymentDate;

  PaymentItem({
    required this.type,
    required this.amount,
    this.status = PaymentStatus.belumBayar,
    this.paidAmount = 0,
    this.lastPaymentDate,
  });

  static const Object _unset = Object();

  PaymentItem copyWith({
    String? type,
    double? amount,
    PaymentStatus? status,
    double? paidAmount,
    Object? lastPaymentDate = _unset,
  }) {
    final DateTime? resolvedLastPaymentDate = identical(lastPaymentDate, _unset)
        ? this.lastPaymentDate
        : lastPaymentDate as DateTime?;

    return PaymentItem(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      lastPaymentDate: resolvedLastPaymentDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'amount': amount,
    'status': status.index,
    'paidAmount': paidAmount,
    'lastPaymentDate': lastPaymentDate?.toIso8601String(),
  };

  static PaymentItem fromMap(Map<String, dynamic> map) {
    final rawStatus = map['status'];

    final int statusIndex = rawStatus is num
        ? rawStatus.toInt().clamp(0, PaymentStatus.values.length - 1).toInt()
        : 0;

    final rawAmount = map['amount'];
    final rawPaidAmount = map['paidAmount'];

    return PaymentItem(
      type: map['type']?.toString() ?? '',
      amount: rawAmount is num ? rawAmount.toDouble() : 0,
      status: PaymentStatus.values[statusIndex],
      paidAmount: rawPaidAmount is num ? rawPaidAmount.toDouble() : 0,
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.tryParse(map['lastPaymentDate'].toString())
          : null,
    );
  }
}

// ============================================================
// CACHE TEMPLATE PEMBAYARAN
// ============================================================

final Map<String, List<PaymentItem>> paymentTemplatesByGrade = {};

/// Alias kompatibilitas.
Map<String, List<PaymentItem>> get paymentTemplatesByClass =>
    paymentTemplatesByGrade;

// ============================================================
// TINGKAT DAN JURUSAN
// ============================================================

const List<String> gradeLevels = ['X', 'XI', 'XII'];

const List<String> majors = ['TKJ', 'RPL', 'TKR'];

// ============================================================
// HELPER TINGKAT PEMBAYARAN
// ============================================================

String paymentGradeFromClass(String kelas) {
  final normalized = kelas.trim().toUpperCase();

  if (normalized == 'X' || normalized.startsWith('X ')) {
    return 'X';
  }

  if (normalized == 'XI' || normalized.startsWith('XI ')) {
    return 'XI';
  }

  if (normalized == 'XII' || normalized.startsWith('XII ')) {
    return 'XII';
  }

  return normalized.split(RegExp(r'\s+')).first;
}

// ============================================================
// DAFTAR KELAS SISWA
// ============================================================

List<String> getAllClassNames() {
  return [
    for (final grade in gradeLevels)
      for (final major in majors) '$grade $major',
  ];
}

// ============================================================
// MEMBACA TEMPLATE PEMBAYARAN
// ============================================================

List<PaymentItem> getConfiguredPaymentsForClass(String kelas) {
  final grade = paymentGradeFromClass(kelas);

  final list = paymentTemplatesByGrade[grade] ?? [];

  return list
      .map(
        (p) => PaymentItem(
          type: p.type,
          amount: p.amount,
          status: PaymentStatus.belumBayar,
          paidAmount: 0,
          lastPaymentDate: null,
        ),
      )
      .toList();
}

List<PaymentItem> getDefaultPaymentsForClass(String kelas) {
  return getConfiguredPaymentsForClass(kelas);
}

// ============================================================
// STUDENT MODEL
// ============================================================

class Student {
  String id;
  String name;
  String nis;
  String kelas;
  String alamat;
  String phone;
  List<PaymentItem> payments;
  bool isActive;

  Student({
    required this.id,
    required this.name,
    required this.nis,
    required this.kelas,
    required this.alamat,
    required this.phone,
    required this.payments,
    this.isActive = true,
  });

  double get totalDue {
    return payments.fold(0, (sum, p) => sum + p.amount);
  }

  double get totalPaid {
    return payments.fold<double>(0, (sum, p) {
      if (p.status == PaymentStatus.lunas) {
        return sum + p.amount;
      }

      if (p.status == PaymentStatus.sebagian) {
        return sum + p.paidAmount;
      }

      return sum;
    });
  }

  double get remaining {
    return totalDue - totalPaid;
  }

  bool get hasOutstanding {
    return payments.any((p) => p.status != PaymentStatus.lunas);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'nis': nis,
    'kelas': kelas,
    'alamat': alamat,
    'phone': phone,
    'isActive': isActive,
    'payments': payments.map((p) => p.toMap()).toList(),
  };

  static Student fromMap(Map<String, dynamic> map) {
    final rawPayments = map['payments'];

    return Student(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      nis: map['nis']?.toString() ?? '',
      kelas: map['kelas']?.toString() ?? '',
      alamat: map['alamat']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      payments: rawPayments is List
          ? rawPayments
                .whereType<Map>()
                .map((e) => PaymentItem.fromMap(Map<String, dynamic>.from(e)))
                .toList()
          : [],
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
    );
  }
}

// ============================================================
// CREATE STUDENT DENGAN TEMPLATE PEMBAYARAN
// ============================================================

Student createStudentWithPayments({
  required String id,
  required String name,
  required String nis,
  required String kelas,
  required String alamat,
  required String phone,
}) {
  final payments = getConfiguredPaymentsForClass(kelas);

  return Student(
    id: id,
    name: name,
    nis: nis,
    kelas: kelas,
    alamat: alamat,
    phone: phone,
    payments: payments,
    isActive: true,
  );
}

// ============================================================
// [TAMBAHAN] SINKRONISASI PEMBAYARAN SISWA DENGAN KONFIGURASI
// ============================================================
//
// Fungsi ini memastikan setiap siswa memiliki item pembayaran
// yang sesuai dengan konfigurasi payment_management di Firebase.
//
// Aturan:
// 1. Jenis pembayaran baru dari konfigurasi → ditambahkan sebagai belumBayar
// 2. Jenis pembayaran yang sudah ada → status dipertahankan, amount diupdate
// 3. Item 'Saldo' atau item lain di luar konfigurasi → tetap dipertahankan
// ============================================================

List<PaymentItem> syncStudentPaymentsWithConfig(
  List<PaymentItem> studentPayments,
  List<PaymentItem> configItems,
) {
  final result = <PaymentItem>[];
  final configTypes = <String>{};

  // 1. Tambahkan semua item dari konfigurasi
  for (final config in configItems) {
    final key = config.type.trim().toLowerCase();
    configTypes.add(key);

    // Cari item pembayaran yang sudah ada di siswa
    PaymentItem? existing;
    for (final p in studentPayments) {
      if (p.type.trim().toLowerCase() == key) {
        existing = p;
        break;
      }
    }

    if (existing != null) {
      // Item sudah ada — pertahankan status pembayaran,
      // tapi gunakan amount terbaru dari konfigurasi.
      result.add(PaymentItem(
        type: config.type,
        amount: config.amount,
        status: existing.status,
        paidAmount: existing.paidAmount,
        lastPaymentDate: existing.lastPaymentDate,
      ));
    } else {
      // Item baru dari konfigurasi — tambahkan sebagai belum bayar.
      result.add(PaymentItem(
        type: config.type,
        amount: config.amount,
        status: PaymentStatus.belumBayar,
        paidAmount: 0,
        lastPaymentDate: null,
      ));
    }
  }

  // 2. Tambahkan item siswa yang TIDAK ada di konfigurasi
  //    (misalnya 'Saldo' atau jenis pembayaran yang sudah dihapus
  //    tapi siswa sudah membayar sebagian).
  for (final p in studentPayments) {
    final key = p.type.trim().toLowerCase();
    if (!configTypes.contains(key)) {
      result.add(p);
    }
  }

  return result;
}

// ============================================================
// TRANSACTION
// ============================================================

enum TransType { pemasukan, pengeluaran }

class Transaction {
  String id;
  TransType type;
  double amount;
  String description;
  DateTime date;
  String category;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    this.category = '',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.index,
    'amount': amount,
    'description': description,
    'date': Timestamp.fromDate(date),
    'category': category,
  };

  static Transaction fromMap(Map<String, dynamic> map) {
    final rawType = map['type'];

    final int typeIndex = rawType is num
        ? rawType.toInt().clamp(0, TransType.values.length - 1).toInt()
        : 0;

    final rawDate = map['date'];

    final DateTime date = rawDate is Timestamp
        ? rawDate.toDate()
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();

    final rawAmount = map['amount'];

    return Transaction(
      id: map['id']?.toString() ?? '',
      type: TransType.values[typeIndex],
      amount: rawAmount is num ? rawAmount.toDouble() : 0,
      description: map['description']?.toString() ?? '',
      date: date,
      category: map['category']?.toString() ?? '',
    );
  }
}

// ============================================================
// ACTIVITY LOG MODEL
// ============================================================

enum ActivityAction { tambah, edit, hapus, login, logout, bayar }

class ActivityLog {
  String user;
  ActivityAction action;
  String detail;
  DateTime timestamp;

  ActivityLog({
    required this.user,
    required this.action,
    required this.detail,
    required this.timestamp,
  });

  String get actionText {
    switch (action) {
      case ActivityAction.tambah:
        return 'Menambah';
      case ActivityAction.edit:
        return 'Mengedit';
      case ActivityAction.hapus:
        return 'Menghapus';
      case ActivityAction.login:
        return 'Login';
      case ActivityAction.logout:
        return 'Logout';
      case ActivityAction.bayar:
        return 'Pembayaran';
    }
  }

  IconData get actionIcon {
    switch (action) {
      case ActivityAction.tambah:
        return Icons.add_circle_outline;
      case ActivityAction.edit:
        return Icons.edit_outlined;
      case ActivityAction.hapus:
        return Icons.delete_outline;
      case ActivityAction.login:
        return Icons.login;
      case ActivityAction.logout:
        return Icons.logout;
      case ActivityAction.bayar:
        return Icons.payment;
    }
  }

  Map<String, dynamic> toMap() => {
    'user': user,
    'action': action.index,
    'detail': detail,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  static ActivityLog fromMap(Map<String, dynamic> map) {
    final rawAction = map['action'];

    final int actionIndex = rawAction is num
        ? rawAction.toInt().clamp(0, ActivityAction.values.length - 1).toInt()
        : 0;

    final rawTimestamp = map['timestamp'];

    final DateTime timestamp = rawTimestamp is Timestamp
        ? rawTimestamp.toDate()
        : DateTime.tryParse(rawTimestamp?.toString() ?? '') ?? DateTime.now();

    return ActivityLog(
      user: map['user']?.toString() ?? '',
      action: ActivityAction.values[actionIndex],
      detail: map['detail']?.toString() ?? '',
      timestamp: timestamp,
    );
  }
}

// ============================================================
// DATA TAMBAHAN SISWA
// ============================================================

Map<String, Map<String, String>> extraInfo = {};

String getExtraInfo(String id, String key) {
  if (!extraInfo.containsKey(id)) {
    final seed = int.tryParse(id.replaceAll('STD', '')) ?? 0;

    final random = Random(seed);

    final tempatLahir = [
      'Jakarta',
      'Bandung',
      'Surabaya',
      'Yogyakarta',
      'Semarang',
      'Medan',
    ][random.nextInt(6)];

    final tanggalLahir = DateTime(
      2008 + random.nextInt(4),
      random.nextInt(12) + 1,
      random.nextInt(28) + 1,
    );

    final jenisKelamin = random.nextBool() ? 'Laki-laki' : 'Perempuan';

    final orangTua = 'Orang Tua ${seed + 1}';

    final agama = [
      'Islam',
      'Kristen',
      'Katolik',
      'Hindu',
      'Buddha',
    ][random.nextInt(5)];

    extraInfo[id] = {
      'tempatLahir': tempatLahir,
      'tanggalLahir':
          '${tanggalLahir.day}/${tanggalLahir.month}/${tanggalLahir.year}',
      'jenisKelamin': jenisKelamin,
      'orangTua': orangTua,
      'agama': agama,
    };
  }

  return extraInfo[id]?[key] ?? '-';
}

void setExtraInfo(String id, String key, String value) {
  if (!extraInfo.containsKey(id)) {
    getExtraInfo(id, key);
  }

  if (extraInfo.containsKey(id)) {
    extraInfo[id]?[key] = value;

    unawaitedRecordActivity(
      action: ActivityAction.edit,
      detail: 'Mengedit informasi tambahan siswa $id: $key',
    );
  }
}

// ============================================================
// SISTEM TRANSAKSI LOKAL
// ============================================================

List<Transaction> localTransactions = [];

Map<String, List<Transaction>> arsipTransaksi = {};

void addIncomeTransaction(
  String description,
  double amount, {
  String category = 'Pemasukan',
}) {
  _addTransaction(TransType.pemasukan, description, amount, category);
}

void addExpenseTransaction(
  String description,
  double amount, {
  String category = 'Pengeluaran',
}) {
  _addTransaction(TransType.pengeluaran, description, amount, category);
}

void _addTransaction(
  TransType type,
  String description,
  double amount,
  String category,
) {
  final int nextId = localTransactions.length + 1;

  final transaction = Transaction(
    id: 'TRX${nextId.toString().padLeft(3, '0')}',
    type: type,
    description: description,
    amount: amount,
    date: DateTime.now(),
    category: category,
  );

  localTransactions.add(transaction);

  unawaitedRecordActivity(
    action: ActivityAction.tambah,
    detail: 'Menambah transaksi lokal: ${transaction.description}',
  );
}

void resetMonthlyTransactions() {
  final now = DateTime.now();

  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

  if (localTransactions.isNotEmpty) {
    arsipTransaksi.putIfAbsent(monthKey, () => []);

    final count = localTransactions.length;

    arsipTransaksi[monthKey]!.addAll(localTransactions);

    localTransactions.clear();

    unawaitedRecordActivity(
      action: ActivityAction.edit,
      detail: 'Mengarsipkan $count transaksi lokal untuk bulan $monthKey',
    );
  }
}

void generateSampleTransactions() {
  final now = DateTime.now();

  for (int i = 1; i <= 6; i++) {
    final month = now.month - i;

    final year = now.year;

    int m = month;
    int y = year;

    if (m <= 0) {
      m += 12;
      y -= 1;
    }

    final key = '$y-${m.toString().padLeft(2, '0')}';

    arsipTransaksi.putIfAbsent(key, () => []);

    final random = Random();

    final count = random.nextInt(5) + 3;

    for (int j = 0; j < count; j++) {
      final isIncome = random.nextBool();

      final amount = (random.nextDouble() * 3000000 + 500000).roundToDouble();

      final desc = isIncome
          ? ['Pembayaran SPP', 'Bantuan', 'Sumbangan', 'Pendaftaran'][random
                .nextInt(4)]
          : ['ATK', 'Listrik', 'Perbaikan', 'Honor'][random.nextInt(4)];

      arsipTransaksi[key]!.add(
        Transaction(
          id: 'TRX${j + 1}',
          type: isIncome ? TransType.pemasukan : TransType.pengeluaran,
          amount: amount,
          description: '$desc (sample)',
          date: DateTime(y, m, random.nextInt(28) + 1),
          category: isIncome ? 'Pemasukan' : 'Pengeluaran',
        ),
      );
    }
  }
}

// ============================================================
// SAMPLE STUDENTS
// ============================================================

List<Student> generateSampleStudents() {
  final List<Student> students = [];

  int idCounter = 1;
  int nisCounter = 1;

  for (final grade in gradeLevels) {
    for (final major in majors) {
      for (int i = 1; i <= 5; i++) {
        final String kelas = '$grade $major';

        final String name = 'Siswa $grade $major $i';

        final String nis = '2026${(nisCounter++).toString().padLeft(3, '0')}';

        final String id = 'STD${idCounter.toString().padLeft(3, '0')}';

        students.add(
          Student(
            id: id,
            name: name,
            nis: nis,
            kelas: kelas,
            alamat: 'Jl. Merdeka No. ${idCounter + 1}',
            phone: '08123456${(700 + idCounter).toString()}',
            payments: [],
            isActive: true,
          ),
        );

        idCounter++;
      }
    }
  }

  return students;
}

// ============================================================
// ARSIP SISWA LOKAL
// ============================================================

Map<String, Map<String, List<Student>>> arsipSiswa = {};

void archiveGraduatedStudents(
  String tahunAjaran,
  List<Student> activeStudents,
) {
  final List<Student> graduated = activeStudents
      .where((s) => s.kelas.startsWith('XII') && s.isActive)
      .toList();

  if (graduated.isEmpty) {
    return;
  }

  final Map<String, List<Student>> grouped = {};

  for (final s in graduated) {
    grouped.putIfAbsent(s.kelas, () => []).add(s);
  }

  arsipSiswa.putIfAbsent(tahunAjaran, () => {});

  for (final entry in grouped.entries) {
    arsipSiswa[tahunAjaran]!
        .putIfAbsent(entry.key, () => [])
        .addAll(entry.value);
  }

  for (final s in graduated) {
    s.isActive = false;
  }

  unawaitedRecordActivity(
    action: ActivityAction.edit,
    detail:
        'Mengarsipkan ${graduated.length} siswa kelas XII ke arsip lokal "$tahunAjaran"',
  );
}

// ============================================================
// NAIK KELAS LOKAL
// ============================================================

void processClassPromotion(List<Student> students) {
  int promotedCount = 0;

  for (final s in students) {
    if (!s.isActive) {
      continue;
    }

    if (s.kelas.startsWith('XI')) {
      s.kelas = s.kelas.replaceFirst('XI', 'XII');

      promotedCount++;
    } else if (s.kelas.startsWith('X ')) {
      s.kelas = s.kelas.replaceFirst('X ', 'XI ');

      promotedCount++;
    }
  }

  if (promotedCount > 0) {
    unawaitedRecordActivity(
      action: ActivityAction.edit,
      detail: 'Kenaikan kelas lokal untuk $promotedCount siswa',
    );
  }
}

// ============================================================
// ARSIP AKUN DIGITAL SISWA
// ============================================================

Map<String, Map<String, List<AkunDigital>>> arsipAkunSiswa = {};

void archiveGraduatedAccounts(String tahunAjaran, List<AkunDigital> accounts) {
  final List<AkunDigital> graduated = accounts
      .where(
        (a) =>
            a.category == 'siswa' &&
            a.kelas != null &&
            a.kelas!.startsWith('XII'),
      )
      .toList();

  if (graduated.isEmpty) {
    return;
  }

  final Map<String, List<AkunDigital>> grouped = {};

  for (final acc in graduated) {
    final String kelasAsal = acc.kelas!;

    grouped.putIfAbsent(kelasAsal, () => []).add(acc);
  }

  arsipAkunSiswa.putIfAbsent(tahunAjaran, () => {});

  for (final entry in grouped.entries) {
    arsipAkunSiswa[tahunAjaran]!
        .putIfAbsent(entry.key, () => [])
        .addAll(entry.value);
  }

  for (final acc in graduated) {
    acc.kelas = 'Lulus';
  }

  unawaitedRecordActivity(
    action: ActivityAction.edit,
    detail:
        'Mengarsipkan ${graduated.length} akun digital siswa kelas XII ke arsip lokal "$tahunAjaran"',
  );
}

void promoteAccounts(List<AkunDigital> accounts) {
  int promotedCount = 0;

  for (final acc in accounts) {
    if (acc.category != 'siswa' || acc.kelas == null) {
      continue;
    }

    final String kelas = acc.kelas!;

    String? jurusan;

    if (kelas.contains('RPL')) {
      jurusan = 'RPL';
    } else if (kelas.contains('TKJ')) {
      jurusan = 'TKJ';
    } else if (kelas.contains('TKR')) {
      jurusan = 'TKR';
    } else {
      continue;
    }

    if (kelas.startsWith('X ')) {
      acc.kelas = 'XI $jurusan';
      promotedCount++;
    } else if (kelas.startsWith('XI ')) {
      acc.kelas = 'XII $jurusan';
      promotedCount++;
    }
  }

  if (promotedCount > 0) {
    unawaitedRecordActivity(
      action: ActivityAction.edit,
      detail: 'Kenaikan kelas lokal untuk $promotedCount akun digital siswa',
    );
  }
}

// ============================================================
// DIGITAL ACCOUNT
// ============================================================

class DigitalAccount {
  String name;
  String email;
  String penanggungJawab;
  String keterangan;
  String passwordMasked;

  DigitalAccount({
    required this.name,
    required this.email,
    required this.penanggungJawab,
    required this.keterangan,
    this.passwordMasked = '••••••••',
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'penanggungJawab': penanggungJawab,
    'keterangan': keterangan,
    'passwordMasked': passwordMasked,
  };

  static DigitalAccount fromMap(Map<String, dynamic> map) {
    return DigitalAccount(
      name: map['name']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      penanggungJawab: map['penanggungJawab']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
      passwordMasked: map['passwordMasked']?.toString() ?? '••••••••',
    );
  }
}

// ============================================================
// LOG LOKAL
// ============================================================

List<ActivityLog> localLogs = [];

void unawaitedRecordActivity({
  String user = 'Admin',
  required ActivityAction action,
  required String detail,
}) {
  recordActivityLog(user: user, action: action, detail: detail);
}

// ============================================================
// INISIALISASI DATA LOKAL
// ============================================================

void initData() {
  paymentTemplatesByGrade.clear();

  generateSampleTransactions();

  localTransactions.clear();

  sampleStudents = generateSampleStudents();
}

// ============================================================
// SAMPLE STUDENTS GLOBAL
// ============================================================

List<Student> sampleStudents = [];