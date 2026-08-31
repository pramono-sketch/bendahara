// lib/data.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================== MODEL AKUN DIGITAL (GURU & SISWA) ==================
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
        id: json['id'],
        name: json['name'],
        namaSiswa: json['namaSiswa'],
        email: json['email'],
        penanggungJawab: json['penanggungJawab'],
        password: json['password'],
        keterangan: json['keterangan'],
        category: json['category'],
        kelas: json['kelas'],
      );

  // ===== FIRESTORE HELPERS =====
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
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      namaSiswa: map['namaSiswa'],
      email: map['email'] ?? '',
      penanggungJawab: map['penanggungJawab'] ?? '',
      password: map['password'] ?? '',
      keterangan: map['keterangan'] ?? '',
      category: map['category'] ?? '',
      kelas: map['kelas'],
    );
  }
}

// ================== MODEL DATA LAINNYA ==================
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

  PaymentItem copyWith({
    String? type,
    double? amount,
    PaymentStatus? status,
    double? paidAmount,
    DateTime? lastPaymentDate,
  }) {
    return PaymentItem(
      type: type ?? this.type,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paidAmount: paidAmount ?? this.paidAmount,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
    );
  }

  // ===== FIRESTORE HELPERS =====
  Map<String, dynamic> toMap() => {
        'type': type,
        'amount': amount,
        'status': status.index,
        'paidAmount': paidAmount,
        'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      };

  static PaymentItem fromMap(Map<String, dynamic> map) {
    return PaymentItem(
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: PaymentStatus.values[map['status'] ?? 0],
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      lastPaymentDate: map['lastPaymentDate'] != null
          ? DateTime.parse(map['lastPaymentDate'])
          : null,
    );
  }
}

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

  double get totalDue => payments.fold(0, (sum, p) => sum + p.amount);
  double get totalPaid => payments.fold(0, (sum, p) {
        if (p.status == PaymentStatus.lunas) return sum + p.amount;
        if (p.status == PaymentStatus.sebagian) return sum + p.paidAmount;
        return sum;
      });
  double get remaining => totalDue - totalPaid;
  bool get hasOutstanding => payments.any((p) => p.status != PaymentStatus.lunas);

  // ===== FIRESTORE HELPERS =====
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
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      nis: map['nis'] ?? '',
      kelas: map['kelas'] ?? '',
      alamat: map['alamat'] ?? '',
      phone: map['phone'] ?? '',
      payments: (map['payments'] as List<dynamic>?)
              ?.map((e) => PaymentItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] ?? true,
    );
  }
}

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

  // ===== FIRESTORE HELPERS =====
  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.index,
        'amount': amount,
        'description': description,
        'date': Timestamp.fromDate(date),
        'category': category,
      };

  static Transaction fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      type: TransType.values[map['type'] ?? 0],
      amount: (map['amount'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      category: map['category'] ?? '',
    );
  }
}

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
      case ActivityAction.tambah: return 'Menambah';
      case ActivityAction.edit: return 'Mengedit';
      case ActivityAction.hapus: return 'Menghapus';
      case ActivityAction.login: return 'Login';
      case ActivityAction.logout: return 'Logout';
      case ActivityAction.bayar: return 'Pembayaran';
    }
  }

  IconData get actionIcon {
    switch (action) {
      case ActivityAction.tambah: return Icons.add_circle_outline;
      case ActivityAction.edit: return Icons.edit_outlined;
      case ActivityAction.hapus: return Icons.delete_outline;
      case ActivityAction.login: return Icons.login;
      case ActivityAction.logout: return Icons.logout;
      case ActivityAction.bayar: return Icons.payment;
    }
  }

  // ===== FIRESTORE HELPERS =====
  Map<String, dynamic> toMap() => {
        'user': user,
        'action': action.index,
        'detail': detail,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  static ActivityLog fromMap(Map<String, dynamic> map) {
    return ActivityLog(
      user: map['user'] ?? '',
      action: ActivityAction.values[map['action'] ?? 0],
      detail: map['detail'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

// ================== DATA TAMBAHAN SISWA (EXTRA INFO) ==================
Map<String, Map<String, String>> extraInfo = {};

String getExtraInfo(String id, String key) {
  if (!extraInfo.containsKey(id)) {
    final seed = int.tryParse(id.replaceAll('STD', '')) ?? 0;
    final random = Random(seed);
    final tempatLahir = ['Jakarta', 'Bandung', 'Surabaya', 'Yogyakarta', 'Semarang', 'Medan'][random.nextInt(6)];
    final tanggalLahir = DateTime(2008 + random.nextInt(4), random.nextInt(12) + 1, random.nextInt(28) + 1);
    final jenisKelamin = random.nextBool() ? 'Laki-laki' : 'Perempuan';
    final orangTua = 'Orang Tua ${seed + 1}';
    final agama = ['Islam', 'Kristen', 'Katolik', 'Hindu', 'Buddha'][random.nextInt(5)];
    extraInfo[id] = {
      'tempatLahir': tempatLahir,
      'tanggalLahir': '${tanggalLahir.day}/${tanggalLahir.month}/${tanggalLahir.year}',
      'jenisKelamin': jenisKelamin,
      'orangTua': orangTua,
      'agama': agama,
    };
  }
  return extraInfo[id]?[key] ?? '-';
}

void setExtraInfo(String id, String key, String value) {
  if (!extraInfo.containsKey(id)) getExtraInfo(id, key);
  if (extraInfo.containsKey(id)) extraInfo[id]?[key] = value;
}

// ================== SISTEM TRANSAKSI (Lokal) ==================
List<Transaction> localTransactions = [];
Map<String, List<Transaction>> arsipTransaksi = {};

void addIncomeTransaction(String description, double amount, {String category = 'Pemasukan'}) {
  _addTransaction(TransType.pemasukan, description, amount, category);
}

void addExpenseTransaction(String description, double amount, {String category = 'Pengeluaran'}) {
  _addTransaction(TransType.pengeluaran, description, amount, category);
}

void _addTransaction(TransType type, String description, double amount, String category) {
  int nextId = localTransactions.length + 1;
  localTransactions.add(Transaction(
    id: 'TRX${nextId.toString().padLeft(3, '0')}',
    type: type,
    amount: amount,
    description: description,
    date: DateTime.now(),
    category: category,
  ));
}

void resetMonthlyTransactions() {
  final now = DateTime.now();
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  if (localTransactions.isNotEmpty) {
    arsipTransaksi.putIfAbsent(monthKey, () => []);
    arsipTransaksi[monthKey]!.addAll(localTransactions);
    localTransactions.clear();
  }
}

void generateSampleTransactions() {
  final now = DateTime.now();
  for (int i = 1; i <= 6; i++) {
    final month = now.month - i;
    final year = now.year;
    int m = month;
    int y = year;
    if (m <= 0) { m += 12; y -= 1; }
    final key = '$y-${m.toString().padLeft(2, '0')}';
    arsipTransaksi.putIfAbsent(key, () => []);
    final random = Random();
    final count = random.nextInt(5) + 3;
    for (int j = 0; j < count; j++) {
      final isIncome = random.nextBool();
      final amount = (random.nextDouble() * 3000000 + 500000).roundToDouble();
      final desc = isIncome
          ? ['Pembayaran SPP', 'Bantuan', 'Sumbangan', 'Pendaftaran'][random.nextInt(4)]
          : ['ATK', 'Listrik', 'Perbaikan', 'Honor'][random.nextInt(4)];
      arsipTransaksi[key]!.add(Transaction(
        id: 'TRX${j + 1}',
        type: isIncome ? TransType.pemasukan : TransType.pengeluaran,
        amount: amount,
        description: '$desc (sample)',
        date: DateTime(y, m, random.nextInt(28) + 1),
        category: isIncome ? 'Pemasukan' : 'Pengeluaran',
      ));
    }
  }
}

// ================== DATA SISWA (TETAP) ==================
const List<String> gradeLevels = ['X', 'XI', 'XII'];
const List<String> majors = ['TKJ', 'RPL', 'TKR'];

Map<String, List<PaymentItem>> defaultPaymentsByClass = {
  'X': [
    PaymentItem(type: 'SPP', amount: 200000),
    PaymentItem(type: 'Gedung', amount: 5000000),
    PaymentItem(type: 'Seragam', amount: 750000),
    PaymentItem(type: 'Buku', amount: 300000),
    PaymentItem(type: 'Study Tour', amount: 1500000),
    PaymentItem(type: 'Lainnya', amount: 1000000),
  ],
  'XI': [
    PaymentItem(type: 'SPP', amount: 200000),
    PaymentItem(type: 'Gedung', amount: 5000000),
    PaymentItem(type: 'Seragam', amount: 750000),
    PaymentItem(type: 'Buku', amount: 300000),
    PaymentItem(type: 'Study Tour', amount: 1500000),
    PaymentItem(type: 'Lainnya', amount: 1000000),
  ],
  'XII': [
    PaymentItem(type: 'SPP', amount: 200000),
    PaymentItem(type: 'Gedung', amount: 5000000),
    PaymentItem(type: 'Seragam', amount: 750000),
    PaymentItem(type: 'Buku', amount: 300000),
    PaymentItem(type: 'Study Tour', amount: 1500000),
    PaymentItem(type: 'Lainnya', amount: 1000000),
  ],
};

List<PaymentItem> getDefaultPaymentsForClass(String kelas) {
  String grade = kelas.split(' ').first;
  if (defaultPaymentsByClass.containsKey(grade)) {
    return defaultPaymentsByClass[grade]!.map((p) => PaymentItem(
      type: p.type,
      amount: p.amount,
      status: PaymentStatus.belumBayar,
      paidAmount: 0,
    )).toList();
  } else {
    return [
      PaymentItem(type: 'SPP', amount: 200000),
      PaymentItem(type: 'Gedung', amount: 5000000),
    ];
  }
}

Student createStudentWithPayments({
  required String id,
  required String name,
  required String nis,
  required String kelas,
  required String alamat,
  required String phone,
}) {
  List<PaymentItem> payments = getDefaultPaymentsForClass(kelas);
  return Student(id: id, name: name, nis: nis, kelas: kelas, alamat: alamat, phone: phone, payments: payments, isActive: true);
}

List<Student> generateSampleStudents() {
  List<Student> students = [];
  int idCounter = 1;
  int nisCounter = 1;
  for (var grade in gradeLevels) {
    for (var major in majors) {
      for (int i = 1; i <= 5; i++) {
        final String kelas = '$grade $major';
        final String name = 'Siswa $grade $major $i';
        final String nis = '2026${(nisCounter++).toString().padLeft(3, '0')}';
        final String id = 'STD${(idCounter++).toString().padLeft(3, '0')}';
        List<PaymentItem> payments = getDefaultPaymentsForClass(kelas);
        for (int j = 0; j < payments.length; j++) {
          if (j == 1 && idCounter % 3 == 0) payments[j].status = PaymentStatus.belumBayar;
          else if (j == 2 && idCounter % 4 == 0) payments[j].status = PaymentStatus.sebagian;
          else payments[j].status = PaymentStatus.lunas;
          if (payments[j].status == PaymentStatus.lunas) {
            payments[j].paidAmount = payments[j].amount;
            payments[j].lastPaymentDate = DateTime(2026, 6, 10);
          } else if (payments[j].status == PaymentStatus.sebagian) {
            payments[j].paidAmount = 400000;
            payments[j].lastPaymentDate = DateTime(2026, 3, 20);
          }
        }
        students.add(Student(
          id: id, name: name, nis: nis, kelas: kelas,
          alamat: 'Jl. Merdeka No. $idCounter',
          phone: '08123456${(700 + idCounter).toString()}',
          payments: payments, isActive: true,
        ));
      }
    }
  }
  return students;
}

// ================== SISTEM ARSIP SISWA ==================
Map<String, Map<String, List<Student>>> arsipSiswa = {};

void archiveGraduatedStudents(String tahunAjaran, List<Student> activeStudents) {
  List<Student> graduated = activeStudents.where((s) => s.kelas.startsWith('XII') && s.isActive).toList();
  if (graduated.isEmpty) return;
  Map<String, List<Student>> grouped = {};
  for (var s in graduated) { grouped.putIfAbsent(s.kelas, () => []).add(s); }
  arsipSiswa.putIfAbsent(tahunAjaran, () => {});
  for (var entry in grouped.entries) {
    arsipSiswa[tahunAjaran]!.putIfAbsent(entry.key, () => []);
    arsipSiswa[tahunAjaran]![entry.key]!.addAll(entry.value);
  }
  for (var s in graduated) { s.isActive = false; }
}

void processClassPromotion(List<Student> students) {
  for (var s in students) {
    if (s.isActive) {
      if (s.kelas.startsWith('XI')) s.kelas = s.kelas.replaceFirst('XI', 'XII');
      else if (s.kelas.startsWith('X')) s.kelas = s.kelas.replaceFirst('X', 'XI');
    }
  }
}

// ================== ARSIP AKUN DIGITAL SISWA ==================
Map<String, Map<String, List<AkunDigital>>> arsipAkunSiswa = {};

// ================== 🔥 TAMBAHAN: GLOBAL SAMPLE STUDENTS ==================
List<Student> sampleStudents = []; // <-- DEKLARASI GLOBAL

void archiveGraduatedAccounts(String tahunAjaran, List<AkunDigital> accounts) {
  List<AkunDigital> graduated = accounts.where((a) => a.category == 'siswa' && a.kelas != null && a.kelas!.startsWith('XII')).toList();
  if (graduated.isEmpty) return;
  Map<String, List<AkunDigital>> grouped = {};
  for (var acc in graduated) { String kelasAsal = acc.kelas!; grouped.putIfAbsent(kelasAsal, () => []).add(acc); }
  arsipAkunSiswa.putIfAbsent(tahunAjaran, () => {});
  for (var entry in grouped.entries) {
    arsipAkunSiswa[tahunAjaran]!.putIfAbsent(entry.key, () => []);
    arsipAkunSiswa[tahunAjaran]![entry.key]!.addAll(entry.value);
  }
  for (var acc in graduated) { acc.kelas = 'Lulus'; }
}

void promoteAccounts(List<AkunDigital> accounts) {
  for (var acc in accounts) {
    if (acc.category != 'siswa' || acc.kelas == null) continue;
    String kelas = acc.kelas!;
    String? jurusan;
    if (kelas.contains('RPL')) jurusan = 'RPL';
    else if (kelas.contains('TKJ')) jurusan = 'TKJ';
    else if (kelas.contains('TKR')) jurusan = 'TKR';
    else continue;
    if (kelas.startsWith('X ')) acc.kelas = 'XI $jurusan';
    else if (kelas.startsWith('XI ')) acc.kelas = 'XII $jurusan';
  }
}

class DigitalAccount {
  String name; String email; String penanggungJawab; String keterangan; String passwordMasked;
  DigitalAccount({required this.name, required this.email, required this.penanggungJawab, required this.keterangan, this.passwordMasked = '••••••••'});
  Map<String, dynamic> toMap() => {'name': name, 'email': email, 'penanggungJawab': penanggungJawab, 'keterangan': keterangan, 'passwordMasked': passwordMasked};
  static DigitalAccount fromMap(Map<String, dynamic> map) {
    return DigitalAccount(name: map['name'] ?? '', email: map['email'] ?? '', penanggungJawab: map['penanggungJawab'] ?? '', keterangan: map['keterangan'] ?? '', passwordMasked: map['passwordMasked'] ?? '••••••••');
  }
}

// ================== AKUN DIGITAL & LOG ==================
List<ActivityLog> localLogs = []; // Dipindah kembali ke sini agar tidak crash

// ================== INISIALISASI DATA (Lokal) ==================
void initData() {
  generateSampleTransactions();
  localTransactions.clear();
  // 🔥 TAMBAHAN: inisialisasi sampleStudents dengan data dummy
  sampleStudents = generateSampleStudents();
}