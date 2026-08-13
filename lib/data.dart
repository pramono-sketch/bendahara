// lib/data.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ================== TEMA & KONSTANTA ==================
class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const surface = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFF57F17);
  static const error = Color(0xFFC62828);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
}

// ================== FUNGSI BANTU UMUM ==================
String formatCurrency(double amount) {
  final formatter = amount
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
  return formatter;
}

Color getMajorColor(String kelas) {
  if (kelas.contains('RPL')) return Colors.green;
  if (kelas.contains('TKR')) return Colors.blue;
  if (kelas.contains('TKJ')) return Colors.red;
  return AppColors.primary;
}

// ================== MODEL AKUN DIGITAL (GURU & SISWA) ==================
class AkunDigital {
  final String id;
  String name; // nama layanan
  String? namaSiswa; // nama siswa (khusus kategori siswa)
  String email;
  String penanggungJawab;
  String password;
  String keterangan;
  String category; // 'guru' atau 'siswa'
  String? kelas; // hanya untuk siswa

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
  bool get hasOutstanding =>
      payments.any((p) => p.status != PaymentStatus.lunas);

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
  }
}

// ================== SISTEM TRANSAKSI (Lokal) ==================
List<Transaction> dummyTransactions = [];
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
  int nextId = dummyTransactions.length + 1;
  dummyTransactions.add(
    Transaction(
      id: 'TRX${nextId.toString().padLeft(3, '0')}',
      type: type,
      amount: amount,
      description: description,
      date: DateTime.now(),
      category: category,
    ),
  );
}

void resetMonthlyTransactions() {
  final now = DateTime.now();
  final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  if (dummyTransactions.isNotEmpty) {
    arsipTransaksi.putIfAbsent(monthKey, () => []);
    arsipTransaksi[monthKey]!.addAll(dummyTransactions);
    dummyTransactions.clear();
  }
}

void initDummyTransactions() {
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
          description: '$desc (dummy)',
          date: DateTime(y, m, random.nextInt(28) + 1),
          category: isIncome ? 'Pemasukan' : 'Pengeluaran',
        ),
      );
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
    return defaultPaymentsByClass[grade]!
        .map(
          (p) => PaymentItem(
            type: p.type,
            amount: p.amount,
            status: PaymentStatus.belumBayar,
            paidAmount: 0,
          ),
        )
        .toList();
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

List<Student> generateDummyStudents() {
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
          if (j == 1 && idCounter % 3 == 0)
            payments[j].status = PaymentStatus.belumBayar;
          else if (j == 2 && idCounter % 4 == 0)
            payments[j].status = PaymentStatus.sebagian;
          else
            payments[j].status = PaymentStatus.lunas;
          if (payments[j].status == PaymentStatus.lunas) {
            payments[j].paidAmount = payments[j].amount;
            payments[j].lastPaymentDate = DateTime(2026, 6, 10);
          } else if (payments[j].status == PaymentStatus.sebagian) {
            payments[j].paidAmount = 400000;
            payments[j].lastPaymentDate = DateTime(2026, 3, 20);
          }
        }
        students.add(
          Student(
            id: id,
            name: name,
            nis: nis,
            kelas: kelas,
            alamat: 'Jl. Merdeka No. $idCounter',
            phone: '08123456${(700 + idCounter).toString()}',
            payments: payments,
            isActive: true,
          ),
        );
      }
    }
  }
  return students;
}

List<Student> dummyStudents = generateDummyStudents();

// ================== SISTEM ARSIP SISWA (untuk data siswa) ==================
Map<String, Map<String, List<Student>>> arsipSiswa = {};

void archiveGraduatedStudents(String tahunAjaran) {
  List<Student> graduated = dummyStudents
      .where((s) => s.kelas.startsWith('XII') && s.isActive)
      .toList();
  if (graduated.isEmpty) return;
  Map<String, List<Student>> grouped = {};
  for (var s in graduated) {
    grouped.putIfAbsent(s.kelas, () => []).add(s);
  }
  arsipSiswa.putIfAbsent(tahunAjaran, () => {});
  for (var entry in grouped.entries) {
    arsipSiswa[tahunAjaran]!.putIfAbsent(entry.key, () => []);
    arsipSiswa[tahunAjaran]![entry.key]!.addAll(entry.value);
  }
  for (var s in graduated) {
    s.isActive = false;
  }
}

void processClassPromotion() {
  for (var s in dummyStudents) {
    if (s.isActive) {
      if (s.kelas.startsWith('XI')) {
        s.kelas = s.kelas.replaceFirst('XI', 'XII');
      } else if (s.kelas.startsWith('X')) {
        s.kelas = s.kelas.replaceFirst('X', 'XI');
      }
    }
  }
}

// ================== ARSIP AKUN DIGITAL SISWA (khusus untuk database_akun) ==================
Map<String, Map<String, List<AkunDigital>>> arsipAkunSiswa = {};

/// Mengarsipkan akun siswa yang berstatus 'XII ...' ke dalam folder arsip,
/// dan mengubah kelasnya menjadi 'Lulus'.
void archiveGraduatedAccounts(String tahunAjaran, List<AkunDigital> accounts) {
  // Ambil akun siswa dengan kelas XII
  List<AkunDigital> graduated = accounts
      .where(
        (a) =>
            a.category == 'siswa' &&
            a.kelas != null &&
            a.kelas!.startsWith('XII'),
      )
      .toList();

  if (graduated.isEmpty) return;

  // Kelompokkan berdasarkan kelas asal (misal 'XII RPL')
  Map<String, List<AkunDigital>> grouped = {};
  for (var acc in graduated) {
    String kelasAsal = acc.kelas!;
    grouped.putIfAbsent(kelasAsal, () => []).add(acc);
  }

  // Simpan ke arsip
  arsipAkunSiswa.putIfAbsent(tahunAjaran, () => {});
  for (var entry in grouped.entries) {
    arsipAkunSiswa[tahunAjaran]!.putIfAbsent(entry.key, () => []);
    arsipAkunSiswa[tahunAjaran]![entry.key]!.addAll(entry.value);
  }

  // Tandai sebagai lulus dengan mengubah kelas menjadi 'Lulus'
  for (var acc in graduated) {
    acc.kelas = 'Lulus';
  }
}

/// Fungsi untuk menaikkan kelas akun digital siswa (X→XI, XI→XII)
void promoteAccounts(List<AkunDigital> accounts) {
  for (var acc in accounts) {
    if (acc.category != 'siswa' || acc.kelas == null) continue;

    String kelas = acc.kelas!;
    String? jurusan;
    if (kelas.contains('RPL'))
      jurusan = 'RPL';
    else if (kelas.contains('TKJ'))
      jurusan = 'TKJ';
    else if (kelas.contains('TKR'))
      jurusan = 'TKR';
    else
      continue;

    if (kelas.startsWith('X ')) {
      acc.kelas = 'XI $jurusan';
    } else if (kelas.startsWith('XI ')) {
      acc.kelas = 'XII $jurusan';
    }
    // Siswa XII sudah ditangani oleh archiveGraduatedAccounts
  }
}

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

  // ===== FIRESTORE HELPERS =====
  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'penanggungJawab': penanggungJawab,
        'keterangan': keterangan,
        'passwordMasked': passwordMasked,
      };

  static DigitalAccount fromMap(Map<String, dynamic> map) {
    return DigitalAccount(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      penanggungJawab: map['penanggungJawab'] ?? '',
      keterangan: map['keterangan'] ?? '',
      passwordMasked: map['passwordMasked'] ?? '••••••••',
    );
  }
}

// ================== AKUN DIGITAL & LOG ==================
List<DigitalAccount> dummyAccounts = [
  DigitalAccount(
    name: 'Google Workspace',
    email: 'admin@eduvest.sch.id',
    penanggungJawab: 'Kepala Sekolah',
    keterangan: 'Email dan Drive',
  ),
  DigitalAccount(
    name: 'SiPendik',
    email: 'sipendik@eduvest.sch.id',
    penanggungJawab: 'Bendahara',
    keterangan: 'Sistem Informasi Pendidikan',
  ),
  DigitalAccount(
    name: 'Zoom Meeting',
    email: 'zoom@eduvest.sch.id',
    penanggungJawab: 'Waka Kurikulum',
    keterangan: 'Akun Zoom premium',
  ),
  DigitalAccount(
    name: 'Canva for Edu',
    email: 'canva@eduvest.sch.id',
    penanggungJawab: 'Guru',
    keterangan: 'Desain grafis',
  ),
  DigitalAccount(
    name: 'Bank Sekolah',
    email: 'bank@eduvest.sch.id',
    penanggungJawab: 'Bendahara',
    keterangan: 'Rekening operasional',
  ),
  DigitalAccount(
    name: 'Sistem Absensi',
    email: 'absensi@eduvest.sch.id',
    penanggungJawab: 'TU',
    keterangan: 'Absensi digital',
  ),
  DigitalAccount(
    name: 'Perpustakaan Digital',
    email: 'pustaka@eduvest.sch.id',
    penanggungJawab: 'Kepala Perpus',
    keterangan: 'E-book dan katalog',
  ),
  DigitalAccount(
    name: 'Website Sekolah',
    email: 'webmaster@eduvest.sch.id',
    penanggungJawab: 'IT Support',
    keterangan: 'Hosting dan domain',
  ),
  DigitalAccount(
    name: 'Youtube Edu',
    email: 'youtube@eduvest.sch.id',
    penanggungJawab: 'Humas',
    keterangan: 'Channel resmi',
  ),
  DigitalAccount(
    name: 'SMS Gateway',
    email: 'sms@eduvest.sch.id',
    penanggungJawab: 'Administrasi',
    keterangan: 'Notifikasi ke orang tua',
  ),
  DigitalAccount(
    name: 'Aplikasi Rapor',
    email: 'rapor@eduvest.sch.id',
    penanggungJawab: 'Waka Kurikulum',
    keterangan: 'E-rapor',
  ),
  DigitalAccount(
    name: 'Cloud Storage',
    email: 'cloud@eduvest.sch.id',
    penanggungJawab: 'IT Support',
    keterangan: 'Backup data',
  ),
  DigitalAccount(
    name: 'WhatsApp Business',
    email: 'wa@eduvest.sch.id',
    penanggungJawab: 'Humas',
    keterangan: 'Layanan chat',
  ),
  DigitalAccount(
    name: 'Microsoft 365',
    email: 'office@eduvest.sch.id',
    penanggungJawab: 'Kepala Sekolah',
    keterangan: 'Office dan Teams',
  ),
  DigitalAccount(
    name: 'E-Learning',
    email: 'elearning@eduvest.sch.id',
    penanggungJawab: 'Guru',
    keterangan: 'Moodle',
  ),
];

List<ActivityLog> dummyLogs = [];

// ================== INISIALISASI DATA (Lokal) ==================
void initData() {
  initDummyTransactions();
  dummyTransactions.clear();
}

// ================================================================
// ================== FIRESTORE INTEGRATION ========================
// ================================================================

/// Referensi koleksi Firestore
final studentsCollection = FirebaseFirestore.instance.collection('students');
final transactionsCollection = FirebaseFirestore.instance.collection('transactions');
final logsCollection = FirebaseFirestore.instance.collection('activity_logs');
final accountsCollection = FirebaseFirestore.instance.collection('digital_accounts');

// ================== FIRESTORE CRUD FUNCTIONS ==================

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

/// Ambil akun digital
Future<List<DigitalAccount>> fetchDigitalAccounts() async {
  final snapshot = await accountsCollection.get();
  return snapshot.docs.map((doc) => DigitalAccount.fromMap(doc.data())).toList();
}

/// Mengarsipkan siswa lulus (kelas XII) – set isActive = false
Future<void> archiveGraduatedStudentsFirestore(String tahunAjaran) async {
  final snapshot = await studentsCollection
      .where('kelas', isGreaterThanOrEqualTo: 'XII')
      .where('kelas', isLessThan: 'XIII') // hanya XII
      .where('isActive', isEqualTo: true)
      .get();

  final batch = FirebaseFirestore.instance.batch();
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
  final batch = FirebaseFirestore.instance.batch();
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

// ================== SEED DATA AWAL ==================
/// Isi data dummy ke Firestore jika koleksi kosong
Future<void> seedFirestoreIfEmpty() async {
  // Seed students
  final studentSnapshot = await studentsCollection.limit(1).get();
  if (studentSnapshot.docs.isEmpty) {
    final dummyList = generateDummyStudents();
    for (var s in dummyList) {
      await studentsCollection.doc(s.id).set(s.toMap());
    }
  }

  // Seed transactions
  final transSnapshot = await transactionsCollection.limit(1).get();
  if (transSnapshot.docs.isEmpty) {
    // Gunakan data dari arsipTransaksi dan dummyTransactions lokal
    // (pastikan initDummyTransactions sudah dipanggil)
    initDummyTransactions();
    final allTransactions = <Transaction>[];
    arsipTransaksi.forEach((key, list) => allTransactions.addAll(list));
    allTransactions.addAll(dummyTransactions);
    for (var t in allTransactions) {
      await transactionsCollection.doc(t.id).set(t.toMap());
    }
    // Kosongkan lokal agar tidak tumpang tindih
    dummyTransactions.clear();
    arsipTransaksi.clear();
  }

  // Seed digital accounts
  final accSnapshot = await accountsCollection.limit(1).get();
  if (accSnapshot.docs.isEmpty) {
    for (var acc in dummyAccounts) {
      await accountsCollection.add(acc.toMap());
    }
  }
}