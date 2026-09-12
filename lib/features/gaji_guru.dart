// lib/features/gaji_guru.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../helpers/sound_helper.dart';
import '../helpers/scroll_reveal.dart';
import '../service/export_gaji_guru.dart';
import '../simulation/cheat_guru.dart';
import '../firebase/firestore_service.dart';
import '../constants/appearance.dart';
import '../helpers/theme_helper.dart';

// ================== KOMPONEN GAJI ==================
class KomponenGaji {
  String nama;
  double jumlah;
  bool isTunjangan;
  String kategori;

  KomponenGaji({
    required this.nama,
    required this.jumlah,
    this.isTunjangan = true,
    this.kategori = 'Umum',
  });

  KomponenGaji copyWith({
    String? nama,
    double? jumlah,
    bool? isTunjangan,
    String? kategori,
  }) {
    return KomponenGaji(
      nama: nama ?? this.nama,
      jumlah: jumlah ?? this.jumlah,
      isTunjangan: isTunjangan ?? this.isTunjangan,
      kategori: kategori ?? this.kategori,
    );
  }

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'jumlah': jumlah,
    'isTunjangan': isTunjangan,
    'kategori': kategori,
  };

  factory KomponenGaji.fromJson(Map<String, dynamic> json) => KomponenGaji(
    nama: json['nama'],
    jumlah: json['jumlah'],
    isTunjangan: json['isTunjangan'],
    kategori: json['kategori'],
  );
}

// ================== MANAJEMEN GAJI GURU ==================
class GajiGuru {
  String id;
  String namaGuru;
  List<KomponenGaji> komponen;
  int bulan;
  int tahun;
  bool isPaid;
  DateTime? tanggalBayar;
  String? metodeBayar;
  String? catatan;
  bool isArchived;
  String role;
  String? keterangan;

  GajiGuru({
    required this.id,
    required this.namaGuru,
    required this.komponen,
    required this.bulan,
    required this.tahun,
    this.isPaid = false,
    this.tanggalBayar,
    this.metodeBayar,
    this.catatan,
    this.isArchived = false,
    this.role = 'guru',
    this.keterangan,
  });

  double get totalGaji {
    double total = 0;
    for (var k in komponen) {
      total += k.isTunjangan ? k.jumlah : -k.jumlah;
    }
    return total;
  }

  GajiGuru copyWith({
    String? id,
    String? namaGuru,
    List<KomponenGaji>? komponen,
    int? bulan,
    int? tahun,
    bool? isPaid,
    DateTime? tanggalBayar,
    String? metodeBayar,
    String? catatan,
    bool? isArchived,
    String? role,
    String? keterangan,
  }) {
    return GajiGuru(
      id: id ?? this.id,
      namaGuru: namaGuru ?? this.namaGuru,
      komponen: komponen ?? this.komponen.map((k) => k.copyWith()).toList(),
      bulan: bulan ?? this.bulan,
      tahun: tahun ?? this.tahun,
      isPaid: isPaid ?? this.isPaid,
      tanggalBayar: tanggalBayar ?? this.tanggalBayar,
      metodeBayar: metodeBayar ?? this.metodeBayar,
      catatan: catatan ?? this.catatan,
      isArchived: isArchived ?? this.isArchived,
      role: role ?? this.role,
      keterangan: keterangan ?? this.keterangan,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'namaGuru': namaGuru,
    'komponen': komponen.map((k) => k.toJson()).toList(),
    'bulan': bulan,
    'tahun': tahun,
    'isPaid': isPaid,
    'tanggalBayar': tanggalBayar?.toIso8601String(),
    'metodeBayar': metodeBayar,
    'catatan': catatan,
    'isArchived': isArchived,
    'role': role,
    'keterangan': keterangan,
  };

  factory GajiGuru.fromJson(Map<String, dynamic> json) => GajiGuru(
    id: json['id'],
    namaGuru: json['namaGuru'],
    komponen: (json['komponen'] as List).map((e) => KomponenGaji.fromJson(e)).toList(),
    bulan: json['bulan'],
    tahun: json['tahun'],
    isPaid: json['isPaid'],
    tanggalBayar: json['tanggalBayar'] != null ? DateTime.parse(json['tanggalBayar']) : null,
    metodeBayar: json['metodeBayar'],
    catatan: json['catatan'],
    isArchived: json['isArchived'],
    role: json['role'] ?? 'guru',
    keterangan: json['keterangan'],
  );
}

// ================== FUNGSI FORMAT ANGKA ==================
String formatCurrency(double value) {
  if (value.isInfinite || value.isNaN) return '0';
  if (value > 1e15) return '> 1.000.000.000.000.000';
  if (value < -1e15) return '< -1.000.000.000.000.000';
  String str = value.toStringAsFixed(2);
  List<String> parts = str.split('.');
  String intPart = parts[0];
  String decPart = parts.length > 1 ? '.${parts[1]}' : '';
  RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
  String formatted = intPart.replaceAllMapped(reg, (Match match) => '${match[1]}.');
  return formatted + decPart;
}

String getBulanNama(int bulan) {
  const nama = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
  return nama[bulan - 1];
}

// ================== HALAMAN UTAMA ==================
class GajiGuruPage extends ConsumerStatefulWidget {
  const GajiGuruPage({super.key});

  @override
  ConsumerState<GajiGuruPage> createState() => _GajiGuruPageState();
}

class _GajiGuruPageState extends ConsumerState<GajiGuruPage> with SingleTickerProviderStateMixin {
  // ===== State Data =====
  List<Teacher> teacherList = [];
  List<GajiGuru> gajiGuruList = [];
  int currentBulan = DateTime.now().month;
  int currentTahun = DateTime.now().year;

  // ===== UI State =====
  int? filterBulan;
  int? filterTahun;
  String? filterStatus;
  String searchQuery = '';
  bool _selectionMode = false;
  Set<String> selectedIds = {};

  // ===== Loading State =====
  bool _isLoading = false;

  // ===== Controllers =====
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    filterBulan = currentBulan;
    filterTahun = currentTahun;

    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });

    _loadTeachers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== FUNGSI FIREBASE ====================
  Future<void> _loadTeachers() async {
    setState(() => _isLoading = true);
    try {
      final fetched = await fetchTeachers();
      setState(() {
        teacherList = fetched;
      });
    } catch (e) {
      debugPrint("Error loading teachers: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== FUNGSI SEED DEFAULT TEACHERS (VIA MODE DEVELOPER) ====================
  Future<void> seedDefaultTeachers() async {
    setState(() => _isLoading = true);
    try {
      final existing = await fetchTeachers();
      final existingNames = existing.map((t) => t.nama).toSet();

      int addedCount = 0;
      for (int i = 0; i < defaultTeachers.length; i++) {
        if (!existingNames.contains(defaultTeachers[i])) {
          final t = Teacher(
            id: 'TCH_SEED_${DateTime.now().millisecondsSinceEpoch}_$i',
            nama: defaultTeachers[i],
            role: 'guru',
          );
          await saveTeacher(t);
          addedCount++;
        }
      }
      await _loadTeachers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(addedCount > 0
                ? '$addedCount data guru baru ditambahkan ke Firebase!'
                : 'Semua data guru default sudah ada di Firebase.'),
            backgroundColor: addedCount > 0 ? Colors.indigo : Colors.grey,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error seeding default teachers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== FUNGSI HAPUS SEMUA GURU (BARU) ====================
  Future<void> deleteAllTeachers() async {
    setState(() => _isLoading = true);
    try {
      for (var teacher in teacherList) {
        await deleteTeacher(teacher.id);
      }
      setState(() {
        teacherList.clear();
        gajiGuruList.clear(); // Bersihkan juga data gaji lokalnya
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua data guru beserta gajinya telah dihapus dari Firebase!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error deleting all teachers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== FUNGSI MANIPULASI DATA ==================
  GajiGuru _getOrCreateGajiRecord(String namaGuru, String role, int bulan, int tahun) {
    var existing = gajiGuruList.firstWhere(
      (g) => g.namaGuru == namaGuru && g.bulan == bulan && g.tahun == tahun,
      orElse: () => GajiGuru(id: '', namaGuru: '', komponen: [], bulan: bulan, tahun: tahun, role: role),
    );
    if (existing.namaGuru.isNotEmpty) {
      return existing;
    }

    var id = 'GJ${gajiGuruList.length + 1}'.padLeft(5, '0');
    var baru = GajiGuru(
      id: id,
      namaGuru: namaGuru,
      komponen: [],
      bulan: bulan,
      tahun: tahun,
      isPaid: false,
      role: role,
    );
    setState(() {
      gajiGuruList.add(baru);
    });
    return baru;
  }

  void _updateGaji(GajiGuru oldGaji, GajiGuru newGaji) {
    final index = gajiGuruList.indexOf(oldGaji);
    if (index != -1) {
      setState(() {
        gajiGuruList[index] = newGaji;
      });
    }
  }

  void _deleteGaji(GajiGuru gaji) {
    setState(() {
      gajiGuruList.remove(gaji);
    });
  }

  void _markAsPaid(GajiGuru gaji) {
    final index = gajiGuruList.indexOf(gaji);
    if (index == -1) return;
    setState(() {
      gajiGuruList[index] = gaji.copyWith(
        isPaid: true,
        tanggalBayar: DateTime.now(),
        catatan: 'Dibayar lunas pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
    });
  }

  // ==================== FUNGSI UNTUK CHEAT ====================
  void simulateMonthChange() {
    setState(() {
      currentBulan += 1;
      if (currentBulan > 12) {
        currentBulan = 1;
        currentTahun += 1;
      }
      filterBulan = currentBulan;
      filterTahun = currentTahun;
    });
  }

  void generateCurrentMonthData() {
    setState(() {
      gajiGuruList.removeWhere((g) => g.bulan == currentBulan && g.tahun == currentTahun);
      for (var teacher in teacherList) {
        List<KomponenGaji> komp = [
          KomponenGaji(nama: 'Gaji Pokok', jumlah: 2500000.0, isTunjangan: true, kategori: 'Umum'),
          KomponenGaji(nama: 'Kehadiran', jumlah: 500000.0, isTunjangan: true, kategori: 'Kehadiran'),
          KomponenGaji(nama: 'Absen', jumlah: 50000.0, isTunjangan: false, kategori: 'Absen'),
          KomponenGaji(nama: 'Jabatan', jumlah: 300000.0, isTunjangan: true, kategori: 'Jabatan Tambahan'),
        ];
        gajiGuruList.add(
          GajiGuru(
            id: 'GJ${gajiGuruList.length + 1}'.padLeft(5, '0'),
            namaGuru: teacher.nama,
            komponen: komp,
            bulan: currentBulan,
            tahun: currentTahun,
            isPaid: false,
            role: teacher.role,
          ),
        );
      }
    });
  }

  void generateRandomData() {
    setState(() {
      gajiGuruList.clear();
      final now = DateTime.now();
      int startBulan = currentBulan;
      int startTahun = currentTahun;
      for (int i = 0; i < 6; i++) {
        int bulan = startBulan - i;
        int tahun = startTahun;
        if (bulan <= 0) {
          bulan += 12;
          tahun -= 1;
        }
        for (var teacher in teacherList) {
          List<KomponenGaji> komp = [];
          int count = 2 + (i % 3);
          for (int j = 0; j < count; j++) {
            bool tunjangan = true;
            String kategori;
            String namaKomponen;
            if (j == 0) { kategori = 'Umum'; namaKomponen = 'Gaji Pokok'; }
            else if (j == 1) { kategori = 'Kehadiran'; namaKomponen = 'Kehadiran'; tunjangan = true; }
            else if (j == 2) { kategori = 'Absen'; namaKomponen = 'Absen'; tunjangan = false; }
            else { kategori = 'Jabatan Tambahan'; namaKomponen = 'Jabatan'; tunjangan = true; }

            double jumlah = (50 + (i * 10) + (j * 20) + (teacher.nama.length % 30)) * 1000.0;
            komp.add(KomponenGaji(nama: namaKomponen, jumlah: jumlah, isTunjangan: tunjangan, kategori: kategori));
          }
          gajiGuruList.add(
            GajiGuru(
              id: 'GJ${gajiGuruList.length + 1}'.padLeft(5, '0'),
              namaGuru: teacher.nama,
              komponen: komp,
              bulan: bulan,
              tahun: tahun,
              isPaid: i > 2,
              tanggalBayar: i > 2 ? DateTime(now.year, now.month - i, 15) : null,
              catatan: i > 2 ? 'Lunas otomatis' : 'Belum dibayar',
              role: teacher.role,
            ),
          );
        }
      }
    });
  }

  void clearAllData() {
    setState(() {
      gajiGuruList.clear();
    });
  }

  void autoLunas() {
    setState(() {
      for (var gaji in gajiGuruList) {
        if (!gaji.isPaid) {
          gaji.isPaid = true;
          gaji.tanggalBayar = DateTime.now();
          gaji.catatan = 'Auto lunas pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';
        }
      }
    });
  }

  // ==================== FUNGSI FILTER & STATISTIK ====================
  List<Map<String, dynamic>> get _guruListWithSalary {
    var activeGuru = teacherList.toList();

    var filteredGuru = activeGuru.where((teacher) {
      if (searchQuery.isNotEmpty && !teacher.nama.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      if (filterStatus != null && filterBulan != null && filterTahun != null) {
        var record = gajiGuruList.firstWhere(
          (g) => g.namaGuru == teacher.nama && g.bulan == filterBulan! && g.tahun == filterTahun!,
          orElse: () => GajiGuru(id: '', namaGuru: '', komponen: [], bulan: filterBulan!, tahun: filterTahun!, role: teacher.role),
        );
        if (record.namaGuru.isEmpty) {
          if (filterStatus == 'Lunas') return false;
        } else {
          if (filterStatus == 'Lunas' && !record.isPaid) return false;
          if (filterStatus == 'Belum' && record.isPaid) return false;
        }
      }
      return true;
    }).toList();

    List<Map<String, dynamic>> result = [];
    for (var teacher in filteredGuru) {
      if (filterBulan != null && filterTahun != null) {
        var record = gajiGuruList.firstWhere(
          (g) => g.namaGuru == teacher.nama && g.bulan == filterBulan! && g.tahun == filterTahun!,
          orElse: () => GajiGuru(id: '', namaGuru: '', komponen: [], bulan: filterBulan!, tahun: filterTahun!, role: teacher.role),
        );
        if (record.namaGuru.isNotEmpty) {
          result.add({'nama': teacher.nama, 'role': teacher.role, 'record': record});
        } else {
          result.add({'nama': teacher.nama, 'role': teacher.role, 'record': null});
        }
      } else {
        result.add({'nama': teacher.nama, 'role': teacher.role, 'record': null});
      }
    }
    return result;
  }

  Map<String, dynamic> get _statistics {
    final bulanIni = gajiGuruList.where(
      (g) => g.bulan == currentBulan && g.tahun == currentTahun && teacherList.any((t) => t.nama == g.namaGuru),
    );
    final totalBulanIni = bulanIni.fold(0.0, (s, g) => s + g.totalGaji);
    final paidBulanIni = bulanIni.where((g) => g.isPaid).fold(0.0, (s, g) => s + g.totalGaji);
    final belumBulanIni = totalBulanIni - paidBulanIni;
    final countGuruBulanIni = bulanIni.map((g) => g.namaGuru).toSet().length;
    final paidGuruBulanIni = bulanIni.where((g) => g.isPaid).map((g) => g.namaGuru).toSet().length;

    int bulanLalu = currentBulan - 1;
    int tahunLalu = currentTahun;
    if (bulanLalu <= 0) {
      bulanLalu = 12;
      tahunLalu -= 1;
    }
    final dataBulanLalu = gajiGuruList.where(
      (g) => g.bulan == bulanLalu && g.tahun == tahunLalu && teacherList.any((t) => t.nama == g.namaGuru),
    );
    final totalBulanLalu = dataBulanLalu.fold(0.0, (s, g) => s + g.totalGaji);

    final totalAll = gajiGuruList.where((g) => teacherList.any((t) => t.nama == g.namaGuru)).fold(0.0, (s, g) => s + g.totalGaji);
    final totalPaid = gajiGuruList.where((g) => g.isPaid && teacherList.any((t) => t.nama == g.namaGuru)).fold(0.0, (s, g) => s + g.totalGaji);

    return {
      'totalBulanIni': totalBulanIni,
      'paidBulanIni': paidBulanIni,
      'belumBulanIni': belumBulanIni,
      'totalBulanLalu': totalBulanLalu,
      'countGuruBulanIni': countGuruBulanIni,
      'paidGuruBulanIni': paidGuruBulanIni,
      'totalAll': totalAll,
      'totalPaid': totalPaid,
    };
  }

  List<Map<String, dynamic>> get _chartData {
    List<Map<String, dynamic>> result = [];
    for (int i = 5; i >= 0; i--) {
      final month = currentBulan - i;
      final year = currentTahun;
      int m = month;
      int y = year;
      if (m <= 0) {
        m += 12;
        y -= 1;
      }
      final data = gajiGuruList.where(
        (g) => g.bulan == m && g.tahun == y && teacherList.any((t) => t.nama == g.namaGuru),
      );
      final total = data.fold(0.0, (s, g) => s + g.totalGaji);
      final paid = data.where((g) => g.isPaid).fold(0.0, (s, g) => s + g.totalGaji);
      result.add({
        'label': getBulanNama(m).substring(0, 3),
        'total': total,
        'paid': paid,
        'month': m,
        'year': y,
      });
    }
    return result;
  }

  // ==================== DIALOG MANAJEMEN GURU ====================
  void _showManageTeachersDialog() {
    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    final TextEditingController _newTeacherController = TextEditingController();
    String selectedRole = 'guru';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          int countGuru = teacherList.where((t) => t.role == 'guru').length;
          int countKaryawan = teacherList.where((t) => t.role == 'karyawan').length;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
              decoration: BoxDecoration(
                color: isGlass ? AppColors.glassBg1.withValues(alpha: 0.9) : colors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ===== HEADER GRADIENT =====
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF3949AB), Color(0xFF5C6BC0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Manajemen Pegawai',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildHeaderCounter('Guru', countGuru, Colors.lightBlueAccent),
                                    const SizedBox(width: 12),
                                    _buildHeaderCounter('Karyawan', countKaryawan, Colors.orangeAccent),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // ===== FORM TAMBAH DATA =====
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _newTeacherController,
                            decoration: InputDecoration(
                              hintText: 'Nama Pegawai...',
                              hintStyle: TextStyle(color: colors.onSurfaceVariant.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: colors.surfaceContainerHighest,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Text('Kategori: ', style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurfaceVariant)),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Guru'),
                                selected: selectedRole == 'guru',
                                onSelected: (selected) {
                                  if (selected) {
                                    setStateDialog(() {
                                      selectedRole = 'guru';
                                    });
                                  }
                                },
                                selectedColor: Colors.blue.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: selectedRole == 'guru' ? Colors.blue : colors.onSurfaceVariant,
                                  fontWeight: selectedRole == 'guru' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Karyawan'),
                                selected: selectedRole == 'karyawan',
                                onSelected: (selected) {
                                  if (selected) {
                                    setStateDialog(() {
                                      selectedRole = 'karyawan';
                                    });
                                  }
                                },
                                selectedColor: Colors.orange.withValues(alpha: 0.2),
                                labelStyle: TextStyle(
                                  color: selectedRole == 'karyawan' ? Colors.orange : colors.onSurfaceVariant,
                                  fontWeight: selectedRole == 'karyawan' ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final nama = _newTeacherController.text.trim();
                                if (nama.isNotEmpty) {
                                  final newTeacher = Teacher(
                                    id: 'TCH${DateTime.now().millisecondsSinceEpoch}',
                                    nama: nama,
                                    role: selectedRole,
                                  );
                                  await saveTeacher(newTeacher);
                                  _newTeacherController.clear();
                                  await _loadTeachers();
                                  setStateDialog(() {});
                                  setState(() {});
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nama tidak boleh kosong!')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3949AB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Pegawai', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ===== DAFTAR LIST GURU =====
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : teacherList.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.people_outline, size: 64, color: colors.outline),
                                      const SizedBox(height: 12),
                                      Text('Daftar masih kosong', style: TextStyle(color: colors.onSurfaceVariant)),
                                      const SizedBox(height: 8),
                                      Text('Gunakan Mode Developer (FAB) untuk tambah data default',
                                          style: TextStyle(color: colors.outline, fontSize: 12),
                                          textAlign: TextAlign.center),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  itemCount: teacherList.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 4),
                                  itemBuilder: (context, index) {
                                    final teacher = teacherList[index];
                                    bool isGuru = teacher.role == 'guru';
                                    Color roleColor = isGuru ? Colors.blue : Colors.orange;

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: colors.outlineVariant),
                                        boxShadow: [
                                          BoxShadow(
                                            color: colors.shadow.withValues(alpha: 0.02),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 4),
                                        leading: CircleAvatar(
                                          backgroundColor: roleColor.withValues(alpha: 0.1),
                                          child: Icon(
                                            isGuru ? Icons.school : Icons.badge,
                                            color: roleColor,
                                            size: 22,
                                          ),
                                        ),
                                        title: Text(
                                          teacher.nama,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colors.onSurface),
                                        ),
                                        subtitle: Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: roleColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isGuru ? 'Guru' : 'Karyawan',
                                            style: TextStyle(
                                              color: roleColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 22),
                                          onPressed: () {
                                            showDialog(
                                              context: ctx,
                                              builder: (confirmCtx) => AlertDialog(
                                                backgroundColor: isGlass ? AppColors.glassBg1 : null,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                title: Text('Konfirmasi Hapus', style: TextStyle(color: isGlass ? Colors.white : null)),
                                                content: Text('Yakin ingin menghapus "${teacher.nama}" dari daftar?', style: TextStyle(color: isGlass ? Colors.white : null)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(confirmCtx),
                                                    child: const Text('Batal'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      await deleteTeacher(teacher.id);
                                                      Navigator.pop(confirmCtx);
                                                      await _loadTeachers();
                                                      setStateDialog(() {});
                                                      setState(() {});
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),

                    // ===== FOOTER TOMBOL TUTUP =====
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(top: BorderSide(color: colors.outlineVariant, width: 1)),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.surfaceContainerHighest,
                            foregroundColor: colors.onSurface,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCounter(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
        ),
      ],
    );
  }

  // ==================== EDIT GAJI ====================
  void _showEditDialog(GajiGuru gaji) {
    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    String selectedGuru = gaji.namaGuru;
    List<KomponenGaji> komponen = gaji.komponen.map((k) => k.copyWith()).toList();
    int bulan = gaji.bulan;
    int tahun = gaji.tahun;
    String role = gaji.role;
    String? keterangan = gaji.keterangan;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          void tambahKomponen(String nama, double jumlah, bool isTunjangan, String kategori) {
            setStateDialog(() {
              komponen.add(KomponenGaji(nama: nama, jumlah: jumlah, isTunjangan: isTunjangan, kategori: kategori));
            });
          }

          void hapusKomponen(int idx) {
            setStateDialog(() {
              komponen.removeAt(idx);
            });
          }

          void copyFromPrevious() {
            int prevBulan = bulan - 1;
            int prevTahun = tahun;
            if (prevBulan <= 0) {
              prevBulan = 12;
              prevTahun -= 1;
            }
            var prevData = gajiGuruList.firstWhere(
              (g) => g.namaGuru == selectedGuru && g.bulan == prevBulan && g.tahun == prevTahun,
              orElse: () => GajiGuru(id: '', namaGuru: '', komponen: [], bulan: prevBulan, tahun: prevTahun, role: role),
            );
            if (prevData.namaGuru.isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Tidak ada data gaji bulan sebelumnya')),
              );
              return;
            }
            setStateDialog(() {
              komponen = prevData.komponen.map((k) => k.copyWith()).toList();
              role = prevData.role;
              keterangan = prevData.keterangan;
            });
          }

          void showTambahKomponenDialog() {
            String nama = '';
            double jumlah = 0;
            bool isTunjangan = true;
            String kategori = 'Umum';

            List<String> kategoriOptions;
            if (role == 'karyawan') {
              kategoriOptions = ['Umum', 'Absen', 'Kehadiran'];
            } else {
              kategoriOptions = ['Umum', 'Absen', 'Kehadiran', 'Total Jam Mengajar', 'Jabatan Tambahan'];
            }

            showDialog(
              context: ctx,
              builder: (dialogCtx) => StatefulBuilder(
                builder: (dialogCtx, setStateDialog2) {
                  return AlertDialog(
                    backgroundColor: isGlass ? AppColors.glassBg1 : null,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Tambah Komponen Gaji', style: TextStyle(color: isGlass ? Colors.white : null)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (kategori == 'Umum')
                          TextField(
                            decoration: const InputDecoration(labelText: 'Nama Komponen'),
                            onChanged: (val) => nama = val,
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Nama: $kategori', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        TextField(
                          decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            double parsed = double.tryParse(val) ?? 0;
                            if (parsed > 1e15) parsed = 1e15;
                            jumlah = parsed;
                          },
                        ),
                        DropdownButtonFormField<String>(
                          value: kategori,
                          items: kategoriOptions.map((k) {
                            return DropdownMenuItem(value: k, child: Text(k));
                          }).toList(),
                          onChanged: (val) {
                            setStateDialog2(() {
                              kategori = val!;
                              if (kategori != 'Umum') nama = kategori;
                              else nama = '';
                              if (kategori == 'Absen') isTunjangan = false;
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Kategori'),
                        ),
                        DropdownButtonFormField<bool>(
                          value: isTunjangan,
                          items: kategori == 'Absen'
                              ? const [DropdownMenuItem(value: false, child: Text('Potongan (-)'))]
                              : const [
                                  DropdownMenuItem(value: true, child: Text('Tunjangan (+)')),
                                  DropdownMenuItem(value: false, child: Text('Potongan (-)')),
                                ],
                          onChanged: kategori == 'Absen' ? null : (val) => setStateDialog2(() => isTunjangan = val ?? true),
                          decoration: const InputDecoration(labelText: 'Jenis'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (kategori == 'Umum' && nama.isEmpty) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(content: Text('Nama komponen harus diisi')),
                            );
                            return;
                          }
                          if (jumlah <= 0) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(content: Text('Jumlah harus lebih dari 0')),
                            );
                            return;
                          }
                          if (kategori != 'Umum') nama = kategori;
                          tambahKomponen(nama, jumlah, isTunjangan, kategori);
                          Navigator.pop(dialogCtx);
                        },
                        child: const Text('Tambah'),
                      ),
                    ],
                  );
                },
              ),
            );
          }

          final total = komponen.fold(0.0, (sum, k) => sum + (k.isTunjangan ? k.jumlah : -k.jumlah));

          return AlertDialog(
            backgroundColor: isGlass ? AppColors.glassBg1 : null,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Edit Gaji', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : null)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text('Guru: ', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
                          Expanded(
                            child: Text(selectedGuru, style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                              color: colors.surfaceContainerHighest,
                            ),
                            child: Text(getBulanNama(bulan), style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                              color: colors.surfaceContainerHighest,
                            ),
                            child: Text(tahun.toString(), style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Jabatan / Role'),
                      items: const [
                        DropdownMenuItem(value: 'guru', child: Text('Guru')),
                        DropdownMenuItem(value: 'karyawan', child: Text('Karyawan')),
                      ],
                      onChanged: (val) {
                        setStateDialog(() {
                          role = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Keterangan (untuk ekspor)'),
                      initialValue: keterangan ?? '',
                      onChanged: (val) => keterangan = val,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: copyFromPrevious,
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin dari bulan sebelumnya'),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text('Komponen', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface))),
                                Expanded(flex: 1, child: Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface), textAlign: TextAlign.right)),
                                const SizedBox(width: 8),
                                Expanded(flex: 1, child: Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface))),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          if (komponen.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Belum ada komponen gaji. Tambahkan komponen dengan tombol di bawah.',
                                style: TextStyle(color: colors.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                            )
                          else
                            ...komponen.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final k = entry.value;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(k.nama, style: TextStyle(fontSize: 13, color: colors.onSurface), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Expanded(flex: 1, child: Text(formatCurrency(k.jumlah), style: TextStyle(fontSize: 13, color: colors.onSurface), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: k.isTunjangan ? Colors.green.shade100 : Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          k.kategori,
                                          style: TextStyle(fontSize: 10, color: k.isTunjangan ? Colors.green.shade800 : Colors.red.shade800),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red, size: 18),
                                      onPressed: () => hapusKomponen(idx),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
                                Text(
                                  'Rp ${formatCurrency(total)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: total >= 0 ? Colors.green : Colors.red),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton.icon(
                                onPressed: showTambahKomponenDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Tambah Komponen'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  SoundHelper().playClick();
                  Navigator.pop(ctx);
                },
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  SoundHelper().playClick();
                  if (selectedGuru.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pilih nama guru')));
                    return;
                  }
                  if (komponen.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Tambahkan minimal satu komponen gaji')));
                    return;
                  }
                  if (total <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Total gaji harus positif')));
                    return;
                  }

                  final newGaji = gaji.copyWith(
                    namaGuru: selectedGuru,
                    komponen: komponen.map((k) => k.copyWith()).toList(),
                    bulan: bulan,
                    tahun: tahun,
                    role: role,
                    keterangan: keterangan,
                  );
                  _updateGaji(gaji, newGaji);
                  Navigator.pop(ctx);
                  setState(() {});
                },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SLIP GAJI ====================
  void _showSlipGaji(GajiGuru gaji) {
    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isGlass ? AppColors.glassBg1 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Slip Gaji ${gaji.namaGuru}', style: TextStyle(color: isGlass ? Colors.white : null)),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID', gaji.id, colors: colors, isGlass: isGlass),
              _detailRow('Nama Guru', gaji.namaGuru, colors: colors, isGlass: isGlass),
              _detailRow('Periode', '${getBulanNama(gaji.bulan)} ${gaji.tahun}', colors: colors, isGlass: isGlass),
              _detailRow('Role', gaji.role == 'guru' ? 'Guru' : 'Karyawan', colors: colors, isGlass: isGlass),
              if (gaji.keterangan != null && gaji.keterangan!.isNotEmpty)
                _detailRow('Keterangan', gaji.keterangan!, colors: colors, isGlass: isGlass),
              Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
              if (gaji.komponen.isNotEmpty) ...[
                Text('Komposisi Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
                const SizedBox(height: 8),
                SizedBox(height: 120, child: _buildPieChart(gaji.komponen)),
                Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
              ],
              Text('Komponen Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
              if (gaji.komponen.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Tidak ada komponen gaji', style: TextStyle(color: isGlass ? Colors.white70 : colors.onSurfaceVariant)),
                )
              else
                ...gaji.komponen.map(
                  (k) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})', overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                        Expanded(flex: 1, child: Text('Rp ${formatCurrency(k.jumlah)}', textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                      ],
                    ),
                  ),
                ),
              Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
              _detailRow('Total', 'Rp ${formatCurrency(gaji.totalGaji)}', bold: true, colors: colors, isGlass: isGlass),
              _detailRow('Status', gaji.isPaid ? 'Lunas' : 'Belum', colors: colors, isGlass: isGlass),
              if (gaji.isPaid && gaji.tanggalBayar != null)
                _detailRow('Tanggal Bayar', '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}', colors: colors, isGlass: isGlass),
              if (gaji.metodeBayar != null) _detailRow('Metode', gaji.metodeBayar!, colors: colors, isGlass: isGlass),
              if (gaji.catatan != null && gaji.catatan!.isNotEmpty) _detailRow('Catatan', gaji.catatan!, colors: colors, isGlass: isGlass),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick();
              Navigator.pop(ctx);
            },
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<KomponenGaji> komponen) {
    Map<String, double> grouped = {};
    for (var k in komponen) {
      grouped[k.kategori] = (grouped[k.kategori] ?? 0) + k.jumlah;
    }
    List<MapEntry<String, double>> entries = grouped.entries.toList();
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          int idx = entry.key;
          var e = entry.value;
          return PieChartSectionData(
            value: e.value,
            title: '${e.key}\n${(e.value / komponen.fold(0.0, (sum, k) => sum + k.jumlah) * 100).toStringAsFixed(1)}%',
            color: colors[idx % colors.length],
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool bold = false, required ColorScheme colors, required bool isGlass}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                color: bold ? (isGlass ? Colors.white : colors.onSurface) : (isGlass ? Colors.white70 : colors.onSurfaceVariant),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: isGlass ? Colors.white : colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DIALOG KONFIRMASI ====================
  void _confirmMarkAsPaid(GajiGuru gaji) {
    final themeMode = ref.read(themeModeProvider);
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isGlass ? AppColors.glassBg1 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Pembayaran', style: TextStyle(color: isGlass ? Colors.white : null)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tandai gaji ${gaji.namaGuru} sebagai lunas?', style: TextStyle(color: isGlass ? Colors.white : null)),
            const SizedBox(height: 8),
            Text('Total: Rp ${formatCurrency(gaji.totalGaji)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick();
              Navigator.pop(ctx);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              SoundHelper().playClick();
              _markAsPaid(gaji);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGaji(GajiGuru gaji) {
    final themeMode = ref.read(themeModeProvider);
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isGlass ? AppColors.glassBg1 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Data', style: TextStyle(color: isGlass ? Colors.white : null)),
        content: Text('Yakin hapus gaji ${gaji.namaGuru} periode ${getBulanNama(gaji.bulan)} ${gaji.tahun}?', style: TextStyle(color: isGlass ? Colors.white : null)),
        actions: [
          TextButton(
            onPressed: () {
              SoundHelper().playClick();
              Navigator.pop(ctx);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              SoundHelper().playClick();
              _deleteGaji(gaji);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          title: const Text('Manajemen Gaji Guru'),
          actions: [
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                SoundHelper().playClick();
                _showManageTeachersDialog();
              },
              tooltip: 'Manajemen Guru',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Dashboard'),
              Tab(text: 'Daftar Gaji'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboard(),
                  _buildListTab(),
                  _buildRiwayatTab(),
                ],
              ),
        floatingActionButton: FABcheat(
          context: context,
          onRefreshUI: () => setState(() {}),
          onSimulateMonthChange: simulateMonthChange,
          onGenerateCurrentMonthData: generateCurrentMonthData,
          onGenerateRandomData: generateRandomData,
          onAutoLunas: autoLunas,
          onClearAllData: clearAllData,
          onSeedDefaultTeachers: seedDefaultTeachers,
          onDeleteAllTeachers: deleteAllTeachers, // <--- Parameter Baru
          currentBulan: currentBulan,
          currentTahun: currentTahun,
        ),
      ),
    );
  }

  // ==================== DASHBOARD ====================
  Widget _buildDashboard() {
    final themeMode = ref.watch(themeModeProvider);
    final stats = _statistics;
    final bulanIniRecords = gajiGuruList
        .where(
          (g) => g.bulan == currentBulan && g.tahun == currentTahun && teacherList.any((t) => t.nama == g.namaGuru),
        )
        .toList();

    final totalBulanIni = stats['totalBulanIni'] as double;
    final paidBulanIni = stats['paidBulanIni'] as double;
    final countGuru = stats['countGuruBulanIni'] as int;
    final paidGuru = stats['paidGuruBulanIni'] as int;

    double rataRata = countGuru > 0 ? totalBulanIni / countGuru : 0;
    double tertinggi = 0;
    double terendah = double.infinity;
    List<Map<String, dynamic>> topGaji = [];
    for (var g in bulanIniRecords) {
      double total = g.totalGaji;
      if (total > tertinggi) tertinggi = total;
      if (total < terendah) terendah = total;
      topGaji.add({'nama': g.namaGuru, 'total': total, 'record': g});
    }
    if (terendah == double.infinity) terendah = 0;
    topGaji.sort((a, b) => b['total'].compareTo(a['total']));
    topGaji = topGaji.take(5).toList();

    final arsipBelumBayar = gajiGuruList.where(
      (g) => !(g.bulan == currentBulan && g.tahun == currentTahun) && !g.isPaid && teacherList.any((t) => t.nama == g.namaGuru),
    );
    final totalArsipBelum = arsipBelumBayar.fold(0.0, (sum, g) => sum + g.totalGaji);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // DIBUNGKUS DENGAN SCROLL REVEAL & DELAY TINGKAT
          ScrollReveal(
            delay: const Duration(milliseconds: 50),
            child: _buildDashboardCards(stats, themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 100),
            child: _buildChart(themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 150),
            child: _buildStatusCard(paidGuru, countGuru, paidBulanIni, totalBulanIni, themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 200),
            child: _buildStatistikCard(rataRata, tertinggi, terendah, themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 250),
            child: _buildTopGajiCard(topGaji, themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 300),
            child: _buildComparisonCard(totalBulanIni, stats['totalBulanLalu'] as double, themeMode),
          ),
          const SizedBox(height: 16),
          ScrollReveal(
            delay: const Duration(milliseconds: 350),
            child: _buildQuickFilter(themeMode),
          ),
          const SizedBox(height: 16),
          if (totalArsipBelum > 0)
            ScrollReveal(
              delay: const Duration(milliseconds: 400),
              child: _buildUnpaidArchiveCard(totalArsipBelum, arsipBelumBayar.toList(), themeMode),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(Map<String, dynamic> stats, AppThemeMode themeMode) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          title: 'Gaji Bulan Ini',
          value: 'Rp ${formatCurrency(stats['totalBulanIni'])}',
          icon: Icons.calendar_month,
          color: Colors.blue,
          subtitle: '${stats['countGuruBulanIni']} guru',
          themeMode: themeMode,
        ),
        _StatCard(
          title: 'Sudah Dibayar',
          value: 'Rp ${formatCurrency(stats['paidBulanIni'])}',
          icon: Icons.check_circle,
          color: Colors.green,
          subtitle: '${stats['paidGuruBulanIni']} guru',
          themeMode: themeMode,
        ),
        _StatCard(
          title: 'Belum Dibayar',
          value: 'Rp ${formatCurrency(stats['belumBulanIni'])}',
          icon: Icons.pending,
          color: Colors.red,
          subtitle: '${stats['countGuruBulanIni'] - stats['paidGuruBulanIni']} guru',
          themeMode: themeMode,
        ),
        _StatCard(
          title: 'Bulan Lalu',
          value: 'Rp ${formatCurrency(stats['totalBulanLalu'])}',
          icon: Icons.history,
          color: Colors.orange,
          subtitle: 'Periode sebelumnya',
          themeMode: themeMode,
        ),
      ],
    );
  }

  Widget _buildChart(AppThemeMode themeMode) {
    final data = _chartData;
    final maxTotal = data.fold(0.0, (max, item) => item['total'] > max ? item['total'] : max);
    if (maxTotal == 0) {
      return _buildThemedContainer(
        themeMode,
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Belum ada data gaji')),
        ),
      );
    }
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Perbandingan Gaji per Bulan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                _legendItem(Colors.blue, 'Total'),
                const SizedBox(width: 16),
                _legendItem(Colors.green, 'Dibayar'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxTotal * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            return Text(data[index]['label'], style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          return Text(formatCurrency(value), style: const TextStyle(fontSize: 9));
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item['total'],
                          color: Colors.blue.withValues(alpha: 0.6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: item['paid'],
                          color: Colors.green.withValues(alpha: 0.8),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusCard(int paidGuru, int countGuru, double paidBulanIni, double totalBulanIni, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status Gaji Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$paidGuru / $countGuru guru lunas', style: TextStyle(fontSize: 14, color: colors.onSurface)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: countGuru > 0 ? paidGuru / countGuru : 0,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: Colors.green,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${countGuru > 0 ? (paidGuru / countGuru * 100).toStringAsFixed(0) : 0}% guru lunas',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rp ${formatCurrency(paidBulanIni)} / Rp ${formatCurrency(totalBulanIni)}', style: TextStyle(fontSize: 14, color: colors.onSurface)),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: totalBulanIni > 0 ? paidBulanIni / totalBulanIni : 0,
                        backgroundColor: colors.surfaceContainerHighest,
                        color: Colors.blue,
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalBulanIni > 0 ? (paidBulanIni / totalBulanIni * 100).toStringAsFixed(0) : 0}% nominal dibayar',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikCard(double rataRata, double tertinggi, double terendah, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statistik Gaji Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text('Rata-rata', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      Container(
                        constraints: const BoxConstraints(maxWidth: double.infinity),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Rp ${formatCurrency(rataRata)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Tertinggi', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      Container(
                        constraints: const BoxConstraints(maxWidth: double.infinity),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Rp ${formatCurrency(tertinggi)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Terendah', style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant)),
                      Container(
                        constraints: const BoxConstraints(maxWidth: double.infinity),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Rp ${formatCurrency(terendah)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopGajiCard(List<Map<String, dynamic>> topGaji, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top 5 Gaji Tertinggi Bulan Ini', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 8),
            if (topGaji.isEmpty)
              Center(child: Text('Belum ada data', style: TextStyle(color: colors.onSurfaceVariant)))
            else
              ...topGaji.asMap().entries.map((entry) {
                int rank = entry.key + 1;
                var item = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text('#$rank', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
                  title: Text(item['nama'], overflow: TextOverflow.ellipsis, maxLines: 2, style: TextStyle(color: colors.onSurface)),
                  trailing: Text('Rp ${formatCurrency(item['total'])}', style: TextStyle(fontWeight: FontWeight.w500, color: colors.onSurface)),
                );
              }),
          ],
        ),
      ),
    );
  }

  // PERBAIKAN WARNA PERBANDINGAN BULAN INI VS BULAN LALU (MENGGUNAKAN COLORSCHEME)
  Widget _buildComparisonCard(double totalBulanIni, double totalBulanLalu, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    final Color bulanIniBg = colors.primaryContainer.withValues(alpha: isDark ? 0.3 : 0.5);
    final Color bulanIniText = colors.onPrimaryContainer;
    
    final Color bulanLaluBg = colors.surfaceContainerHighest;
    final Color bulanLaluText = colors.onSurfaceVariant;
    
    final bool isPositive = totalBulanIni >= totalBulanLalu;
    final Color trendBg = (isPositive ? Colors.green : Colors.red).withValues(alpha: isDark ? 0.2 : 0.1);
    final Color trendColor = isPositive ? Colors.green : Colors.red;
    final Color trendTextColor = isPositive ? (isDark ? Colors.greenAccent : Colors.green.shade800) : (isDark ? Colors.redAccent : Colors.red.shade800);

    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Perbandingan Bulan Ini vs Bulan Lalu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bulanIniBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bulan Ini', style: TextStyle(fontSize: 12, color: bulanIniText)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Rp ${formatCurrency(totalBulanIni)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: bulanIniText)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: bulanLaluBg, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bulan Lalu', style: TextStyle(fontSize: 12, color: bulanLaluText)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Rp ${formatCurrency(totalBulanLalu)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: trendColor,
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${isPositive ? '+' : ''}Rp ${formatCurrency(totalBulanIni - totalBulanLalu)} (${totalBulanLalu > 0 ? ((totalBulanIni - totalBulanLalu) / totalBulanLalu * 100).toStringAsFixed(1) : 0}%)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: trendTextColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnpaidArchiveCard(double totalArsipBelum, List<GajiGuru> arsipBelumBayar, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.archive, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Arsip Belum Bayar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Total gaji belum lunas dari bulan-bulan sebelumnya:', style: TextStyle(color: colors.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Rp ${formatCurrency(totalArsipBelum)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArchiveUnpaidPage(records: arsipBelumBayar, onMarkPaid: _confirmMarkAsPaid),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Lihat Arsip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter Cepat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colors.onSurface)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: filterStatus == null && filterBulan == null && filterTahun == null,
                  onSelected: (_) => setState(() {
                    filterStatus = null;
                    filterBulan = null;
                    filterTahun = null;
                  }),
                ),
                FilterChip(
                  label: const Text('Lunas'),
                  selected: filterStatus == 'Lunas',
                  onSelected: (_) => setState(() => filterStatus = 'Lunas'),
                ),
                FilterChip(
                  label: const Text('Belum'),
                  selected: filterStatus == 'Belum',
                  onSelected: (_) => setState(() => filterStatus = 'Belum'),
                ),
                DropdownButton<int>(
                  value: filterBulan,
                  hint: const Text('Bulan'),
                  items: List.generate(12, (i) => i + 1).map((b) {
                    return DropdownMenuItem(value: b, child: Text(getBulanNama(b)));
                  }).toList(),
                  onChanged: (val) => setState(() => filterBulan = val),
                ),
                DropdownButton<int>(
                  value: filterTahun,
                  hint: const Text('Tahun'),
                  items: List.generate(5, (i) => currentTahun - i).map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.toString()));
                  }).toList(),
                  onChanged: (val) => setState(() => filterTahun = val),
                ),
                if (filterStatus != null || filterBulan != null || filterTahun != null)
                  TextButton(
                    onPressed: () => setState(() {
                      filterStatus = null;
                      filterBulan = currentBulan;
                      filterTahun = currentTahun;
                    }),
                    child: const Text('Reset'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB DAFTAR GAJI ====================
  Widget _buildListTab() {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final guruData = _guruListWithSalary;
    int selectedCount = selectedIds.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama guru...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_selectionMode ? Icons.close : Icons.checklist, color: _selectionMode ? Colors.red : Colors.blue),
                onPressed: () {
                  setState(() {
                    _selectionMode = !_selectionMode;
                    if (!_selectionMode) selectedIds.clear();
                  });
                },
                tooltip: _selectionMode ? 'Keluar mode pilih' : 'Mode Pilih',
              ),
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: ThemeHelper.isGlass(themeMode) ? AppColors.glassBg1 : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Pilih Periode', style: TextStyle(color: ThemeHelper.isGlass(themeMode) ? Colors.white : null)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            value: filterBulan,
                            hint: const Text('Bulan'),
                            items: List.generate(12, (i) => i + 1).map((b) {
                              return DropdownMenuItem(value: b, child: Text(getBulanNama(b)));
                            }).toList(),
                            onChanged: (val) => setState(() => filterBulan = val),
                          ),
                          DropdownButtonFormField<int>(
                            value: filterTahun,
                            hint: const Text('Tahun'),
                            items: List.generate(5, (i) => currentTahun - i).map((t) {
                              return DropdownMenuItem(value: t, child: Text(t.toString()));
                            }).toList(),
                            onChanged: (val) => setState(() => filterTahun = val),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() {});
                          },
                          child: const Text('Terapkan'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_selectionMode && selectedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.blue.shade50,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                Text('$selectedCount terpilih', style: const TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _bulkMarkPaid,
                  icon: const Icon(Icons.payment, color: Colors.green, size: 18),
                  label: const Text('Lunas', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: _bulkDelete,
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: const Text('Hapus', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      selectedIds.clear();
                    });
                  },
                  tooltip: 'Batal pilih',
                ),
              ],
            ),
          ),
        Expanded(
          child: guruData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: colors.outline),
                      const SizedBox(height: 16),
                      Text('Tidak ada guru yang cocok', style: TextStyle(color: colors.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: guruData.length,
                  itemBuilder: (context, index) {
                    final item = guruData[index];
                    final nama = item['nama'] as String;
                    final role = item['role'] as String;
                    final record = item['record'] as GajiGuru?;
                    return _buildCompactGajiCard(nama, role, record, index, themeMode);
                  },
                ),
        ),
      ],
    );
  }

  void _bulkMarkPaid() {
    final themeMode = ref.read(themeModeProvider);
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isGlass ? AppColors.glassBg1 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Bulk', style: TextStyle(color: isGlass ? Colors.white : null)),
        content: Text('Tandai ${selectedIds.length} gaji sebagai lunas?', style: TextStyle(color: isGlass ? Colors.white : null)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var id in selectedIds) {
                  final index = gajiGuruList.indexWhere((g) => g.id == id);
                  if (index != -1) {
                    gajiGuruList[index] = gajiGuruList[index].copyWith(
                      isPaid: true,
                      tanggalBayar: DateTime.now(),
                      catatan: 'Dibayar lunas (bulk) pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    );
                  }
                }
                selectedIds.clear();
                _selectionMode = false;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya, Lunas Semua'),
          ),
        ],
      ),
    );
  }

  void _bulkDelete() {
    final themeMode = ref.read(themeModeProvider);
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isGlass ? AppColors.glassBg1 : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Konfirmasi Bulk', style: TextStyle(color: isGlass ? Colors.white : null)),
        content: Text('Hapus ${selectedIds.length} data gaji?', style: TextStyle(color: isGlass ? Colors.white : null)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                gajiGuruList.removeWhere((g) => selectedIds.contains(g.id));
                selectedIds.clear();
                _selectionMode = false;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Hapus Semua'),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactGajiCard(String namaGuru, String role, GajiGuru? record, int index, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    
    if (record == null) {
      return _buildThemedContainer(
        themeMode,
        radius: 12,
        child: ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                child: const Icon(Icons.person, color: Colors.grey),
              ),
              if (role == 'karyawan') ...[
                const SizedBox(width: 4),
                const Icon(Icons.badge, color: Colors.orange, size: 14),
              ]
            ],
          ),
          title: Text(namaGuru, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface)),
          subtitle: Text('Belum ada data gaji untuk periode ini', style: TextStyle(color: colors.onSurfaceVariant)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue, size: 24),
                onPressed: () {
                  if (filterBulan != null && filterTahun != null) {
                    var baru = _getOrCreateGajiRecord(namaGuru, role, filterBulan!, filterTahun!);
                    setState(() {});
                    _showEditDialog(baru);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pilih periode terlebih dahulu')),
                    );
                  }
                },
                tooltip: 'Tambah Gaji',
              ),
            ],
          ),
        ),
      );
    }

    final total = record.totalGaji;
    final isSelected = selectedIds.contains(record.id);

    return _buildThemedContainer(
      themeMode,
      radius: 12,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectionMode)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? Colors.blue : colors.outline, width: 2),
                  color: isSelected ? Colors.blue : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
              )
            else
              CircleAvatar(
                backgroundColor: record.isPaid ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                radius: 16,
                child: Icon(
                  record.isPaid ? Icons.check_circle : Icons.pending,
                  color: record.isPaid ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
            const SizedBox(width: 4),
            if (record.role == 'karyawan') const Icon(Icons.badge, color: Colors.orange, size: 14),
          ],
        ),
        title: Text(
          namaGuru,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.onSurface),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          record.komponen.isEmpty ? 'Belum ada komponen' : 'Rp ${formatCurrency(total)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: record.komponen.isEmpty ? FontWeight.normal : FontWeight.w500,
            color: record.komponen.isEmpty ? colors.onSurfaceVariant : colors.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!record.isPaid && record.komponen.isNotEmpty && !_selectionMode)
              IconButton(
                icon: const Icon(Icons.payment, color: Colors.green, size: 20),
                onPressed: () {
                  SoundHelper().playClick();
                  _confirmMarkAsPaid(record);
                },
                tooltip: 'Bayar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (!_selectionMode)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  SoundHelper().playClick();
                  _showEditDialog(record);
                },
                tooltip: 'Edit',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            IconButton(
              icon: const Icon(Icons.visibility, size: 20),
              onPressed: () {
                SoundHelper().playClick();
                _showSlipGaji(record);
              },
              tooltip: 'Detail',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            if (!_selectionMode)
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                onPressed: () {
                  SoundHelper().playClick();
                  _confirmDeleteGaji(record);
                },
                tooltip: 'Hapus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (_selectionMode)
              IconButton(
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.blue : Colors.grey,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isSelected) {
                      selectedIds.remove(record.id);
                    } else {
                      selectedIds.add(record.id);
                    }
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        isThreeLine: false,
        dense: true,
        onTap: _selectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    selectedIds.remove(record.id);
                  } else {
                    selectedIds.add(record.id);
                  }
                });
              }
            : null,
      ),
    );
  }

  // ==================== TAB RIWAYAT ====================
  Widget _buildRiwayatTab() {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    Map<int, List<GajiGuru>> groupedByYear = {};
    for (var g in gajiGuruList) {
      groupedByYear.putIfAbsent(g.tahun, () => []).add(g);
    }

    var tahunKeys = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    if (tahunKeys.isEmpty) {
      return Center(child: Text('Belum ada data gaji yang diarsipkan', style: TextStyle(color: colors.onSurfaceVariant)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: tahunKeys.length,
      itemBuilder: (context, index) {
        int tahun = tahunKeys[index];
        var items = groupedByYear[tahun]!;
        int totalGuru = items.map((g) => g.namaGuru).toSet().length;
        double totalNominal = items.fold(0.0, (sum, g) => sum + g.totalGaji);
        int totalLunas = items.where((g) => g.isPaid).length;

        return _buildThemedContainer(
          themeMode,
          radius: 12,
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.amber),
            title: Text('$tahun', style: TextStyle(fontWeight: FontWeight.bold, color: colors.onSurface)),
            subtitle: Text('$totalGuru guru • Rp ${formatCurrency(totalNominal)} • $totalLunas lunas', style: TextStyle(color: colors.onSurfaceVariant)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              SoundHelper().playClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RiwayatBulanPage(tahun: tahun, data: items),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ================== HALAMAN RIWAYAT PER BULAN ==================
class RiwayatBulanPage extends ConsumerWidget {
  final int tahun;
  final List<GajiGuru> data;

  const RiwayatBulanPage({super.key, required this.tahun, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    Map<int, List<GajiGuru>> groupedByMonth = {};
    for (var g in data) {
      groupedByMonth.putIfAbsent(g.bulan, () => []).add(g);
    }
    var bulanKeys = groupedByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          title: Text('Arsip $tahun'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              onSelected: (value) async {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menyiapkan file...')),
                  );
                  if (value == 'word') {
                    await DownloadService.exportYearToWord(tahun, data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File berhasil disimpan di folder Download!'), backgroundColor: Colors.green),
                    );
                  } else if (value == 'excel') {
                    await DownloadService.exportYearToExcel(tahun, data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File berhasil disimpan di folder Download!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal download: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'word',
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Word (.doc)'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'excel',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Excel (.xls)'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: bulanKeys.isEmpty
            ? Center(child: Text('Tidak ada data bulan', style: TextStyle(color: colors.onSurfaceVariant)))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: bulanKeys.length,
                itemBuilder: (context, index) {
                  int bulan = bulanKeys[index];
                  var items = groupedByMonth[bulan]!;
                  double totalBulan = items.fold(0.0, (sum, g) => sum + g.totalGaji);
                  int lunasBulan = items.where((g) => g.isPaid).length;

                  return _buildThemedContainer(
                    themeMode,
                    radius: 12,
                    child: ListTile(
                      leading: const Icon(Icons.folder_open, color: Colors.blue),
                      title: Text(getBulanNama(bulan), style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface)),
                      subtitle: Text('${items.length} guru • Rp ${formatCurrency(totalBulan)} • $lunasBulan lunas', style: TextStyle(color: colors.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.download, size: 18),
                            onSelected: (value) async {
                              try {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Menyiapkan file...')),
                                );
                                if (value == 'word') {
                                  await DownloadService.exportMonthToWord(tahun, bulan, items);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('File berhasil disimpan di folder Download!'), backgroundColor: Colors.green),
                                  );
                                } else if (value == 'excel') {
                                  await DownloadService.exportMonthToExcel(tahun, bulan, items);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('File berhasil disimpan di folder Download!'), backgroundColor: Colors.green),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal download: $e'), backgroundColor: Colors.red),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'word',
                                child: Row(
                                  children: [
                                    Icon(Icons.description, size: 16, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Text('Word', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'excel',
                                child: Row(
                                  children: [
                                    Icon(Icons.table_chart, size: 16, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Excel', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                            tooltip: 'Export',
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        SoundHelper().playClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiwayatGuruPage(tahun: tahun, bulan: bulan, data: items),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// ================== HALAMAN RIWAYAT PER GURU ==================
class RiwayatGuruPage extends ConsumerWidget {
  final int tahun;
  final int bulan;
  final List<GajiGuru> data;

  const RiwayatGuruPage({super.key, required this.tahun, required this.bulan, required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          title: Text('${getBulanNama(bulan)} $tahun'),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: data.length,
          itemBuilder: (context, index) {
            final gaji = data[index];
            return _buildThemedContainer(
              themeMode,
              radius: 12,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: gaji.isPaid ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  child: Icon(gaji.isPaid ? Icons.check_circle : Icons.pending, color: gaji.isPaid ? Colors.green : Colors.red, size: 18),
                ),
                title: Text(gaji.namaGuru, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface)),
                subtitle: Text(
                  gaji.komponen.isEmpty ? 'Belum ada komponen' : 'Rp ${formatCurrency(gaji.totalGaji)}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gaji.isPaid && gaji.tanggalBayar != null)
                      Text(
                        '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}',
                        style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    IconButton(
                      icon: const Icon(Icons.visibility, size: 18),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: isGlass ? AppColors.glassBg1 : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Slip Gaji ${gaji.namaGuru}', style: TextStyle(color: isGlass ? Colors.white : null)),
                            content: Container(
                              width: double.maxFinite,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRowStatic('ID', gaji.id, colors, isGlass),
                                  _buildDetailRowStatic('Nama Guru', gaji.namaGuru, colors, isGlass),
                                  _buildDetailRowStatic('Periode', '${getBulanNama(gaji.bulan)} ${gaji.tahun}', colors, isGlass),
                                  _buildDetailRowStatic('Role', gaji.role == 'guru' ? 'Guru' : 'Karyawan', colors, isGlass),
                                  if (gaji.keterangan != null && gaji.keterangan!.isNotEmpty) _buildDetailRowStatic('Keterangan', gaji.keterangan!, colors, isGlass),
                                  Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                  if (gaji.komponen.isNotEmpty) ...[
                                    Text('Komposisi Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
                                    const SizedBox(height: 8),
                                    SizedBox(height: 120, child: _buildPieChartStatic(gaji.komponen)),
                                    Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                  ],
                                  Text('Komponen Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
                                  if (gaji.komponen.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text('Tidak ada komponen gaji', style: TextStyle(color: isGlass ? Colors.white70 : colors.onSurfaceVariant)),
                                    )
                                  else
                                    ...gaji.komponen.map(
                                      (k) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          children: [
                                            Expanded(flex: 2, child: Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})', overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                                            Expanded(flex: 1, child: Text('Rp ${formatCurrency(k.jumlah)}', textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                                          ],
                                        ),
                                      ),
                                    ),
                                  Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                  _buildDetailRowStatic('Total', 'Rp ${formatCurrency(gaji.totalGaji)}', colors, isGlass, bold: true),
                                  _buildDetailRowStatic('Status', gaji.isPaid ? 'Lunas' : 'Belum', colors, isGlass),
                                  if (gaji.isPaid && gaji.tanggalBayar != null)
                                    _buildDetailRowStatic('Tanggal Bayar', '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}', colors, isGlass),
                                  if (gaji.metodeBayar != null) _buildDetailRowStatic('Metode', gaji.metodeBayar!, colors, isGlass),
                                  if (gaji.catatan != null && gaji.catatan!.isNotEmpty) _buildDetailRowStatic('Catatan', gaji.catatan!, colors, isGlass),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Detail',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRowStatic(String label, String value, ColorScheme colors, bool isGlass, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: bold ? (isGlass ? Colors.white : colors.onSurface) : (isGlass ? Colors.white70 : colors.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: isGlass ? Colors.white : colors.onSurface), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartStatic(List<KomponenGaji> komponen) {
    Map<String, double> grouped = {};
    for (var k in komponen) {
      grouped[k.kategori] = (grouped[k.kategori] ?? 0) + k.jumlah;
    }
    List<MapEntry<String, double>> entries = grouped.entries.toList();
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          int idx = entry.key;
          var e = entry.value;
          return PieChartSectionData(
            value: e.value,
            title: '${e.key}\n${(e.value / komponen.fold(0.0, (sum, k) => sum + k.jumlah) * 100).toStringAsFixed(1)}%',
            color: colors[idx % colors.length],
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }
}

// ================== HALAMAN ARSIP BELUM BAYAR ==================
class ArchiveUnpaidPage extends ConsumerWidget {
  final List<GajiGuru> records;
  final Function(GajiGuru) onMarkPaid;

  const ArchiveUnpaidPage({super.key, required this.records, required this.onMarkPaid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(title: const Text('Arsip Belum Bayar')),
        body: records.isEmpty
            ? Center(child: Text('Tidak ada data belum bayar di arsip', style: TextStyle(color: colors.onSurfaceVariant)))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final g = records[index];
                  return _buildThemedContainer(
                    themeMode,
                    radius: 12,
                    child: ListTile(
                      leading: const Icon(Icons.pending, color: Colors.orange),
                      title: Text(g.namaGuru, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors.onSurface)),
                      subtitle: Text('${getBulanNama(g.bulan)} ${g.tahun} • Rp ${formatCurrency(g.totalGaji)}', style: TextStyle(color: colors.onSurfaceVariant)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.payment, color: Colors.green),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: isGlass ? AppColors.glassBg1 : null,
                                  title: Text('Konfirmasi Pembayaran', style: TextStyle(color: isGlass ? Colors.white : null)),
                                  content: Text('Tandai gaji ${g.namaGuru} (${getBulanNama(g.bulan)} ${g.tahun}) sebagai lunas?', style: TextStyle(color: isGlass ? Colors.white : null)),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        onMarkPaid(g);
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Gaji ditandai lunas!')),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                      child: const Text('Ya, Bayar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            tooltip: 'Bayar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.visibility),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: isGlass ? AppColors.glassBg1 : null,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text('Slip Gaji ${g.namaGuru}', style: TextStyle(color: isGlass ? Colors.white : null)),
                                  content: Container(
                                    width: double.maxFinite,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRowStatic('ID', g.id, colors, isGlass),
                                        _buildDetailRowStatic('Nama Guru', g.namaGuru, colors, isGlass),
                                        _buildDetailRowStatic('Periode', '${getBulanNama(g.bulan)} ${g.tahun}', colors, isGlass),
                                        _buildDetailRowStatic('Role', g.role == 'guru' ? 'Guru' : 'Karyawan', colors, isGlass),
                                        if (g.keterangan != null && g.keterangan!.isNotEmpty) _buildDetailRowStatic('Keterangan', g.keterangan!, colors, isGlass),
                                        Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                        if (g.komponen.isNotEmpty) ...[
                                          Text('Komposisi Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
                                          const SizedBox(height: 8),
                                          SizedBox(height: 120, child: _buildPieChartStatic(g.komponen)),
                                          Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                        ],
                                        Text('Komponen Gaji:', style: TextStyle(fontWeight: FontWeight.bold, color: isGlass ? Colors.white : colors.onSurface)),
                                        if (g.komponen.isEmpty)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('Tidak ada komponen gaji', style: TextStyle(color: isGlass ? Colors.white70 : colors.onSurfaceVariant)),
                                          )
                                        else
                                          ...g.komponen.map(
                                            (k) => Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 2),
                                              child: Row(
                                                children: [
                                                  Expanded(flex: 2, child: Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})', overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                                                  Expanded(flex: 1, child: Text('Rp ${formatCurrency(k.jumlah)}', textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: isGlass ? Colors.white : colors.onSurface))),
                                                ],
                                              ),
                                            ),
                                          ),
                                        Divider(color: isGlass ? Colors.white.withValues(alpha: 0.3) : null),
                                        _buildDetailRowStatic('Total', 'Rp ${formatCurrency(g.totalGaji)}', colors, isGlass, bold: true),
                                        _buildDetailRowStatic('Status', g.isPaid ? 'Lunas' : 'Belum', colors, isGlass),
                                        if (g.isPaid && g.tanggalBayar != null)
                                          _buildDetailRowStatic('Tanggal Bayar', '${g.tanggalBayar!.day}/${g.tanggalBayar!.month}/${g.tanggalBayar!.year}', colors, isGlass),
                                        if (g.metodeBayar != null) _buildDetailRowStatic('Metode', g.metodeBayar!, colors, isGlass),
                                        if (g.catatan != null && g.catatan!.isNotEmpty) _buildDetailRowStatic('Catatan', g.catatan!, colors, isGlass),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildDetailRowStatic(String label, String value, ColorScheme colors, bool isGlass, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600, color: bold ? (isGlass ? Colors.white : colors.onSurface) : (isGlass ? Colors.white70 : colors.onSurfaceVariant)),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, color: isGlass ? Colors.white : colors.onSurface), overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartStatic(List<KomponenGaji> komponen) {
    Map<String, double> grouped = {};
    for (var k in komponen) {
      grouped[k.kategori] = (grouped[k.kategori] ?? 0) + k.jumlah;
    }
    List<MapEntry<String, double>> entries = grouped.entries.toList();
    List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return PieChart(
      PieChartData(
        sections: entries.asMap().entries.map((entry) {
          int idx = entry.key;
          var e = entry.value;
          return PieChartSectionData(
            value: e.value,
            title: '${e.key}\n${(e.value / komponen.fold(0.0, (sum, k) => sum + k.jumlah) * 100).toStringAsFixed(1)}%',
            color: colors[idx % colors.length],
            radius: 50,
            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
        sectionsSpace: 2,
        centerSpaceRadius: 20,
      ),
    );
  }
}

// ==================== STAT CARD WIDGET ==================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final AppThemeMode themeMode;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _buildThemedContainer(
      themeMode,
      radius: 16,
      margin: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  radius: 20,
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.onSurface)),
              ),
            ),
            Text(subtitle, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ================== HELPER CONTAINER ==================
Widget _buildThemedContainer(
  AppThemeMode themeMode, {
  required Widget child,
  double radius = 16,
  EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 8),
}) {
  if (ThemeHelper.isNeo(themeMode)) {
    return Container(
      margin: margin,
      decoration: neumorphismDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
  if (ThemeHelper.isGlass(themeMode)) {
    return Container(
      margin: margin,
      decoration: glassmorphismDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: child,
        ),
      ),
    );
  }
  if (ThemeHelper.isModern(themeMode)) {
    return Container(
      margin: margin,
      decoration: modernDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
  if (ThemeHelper.isAurora(themeMode)) {
    return Container(
      margin: margin,
      decoration: auroraDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
  if (ThemeHelper.isCyber(themeMode)) {
    return Container(
      margin: margin,
      decoration: cyberpunkDecoration(borderRadius: radius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }

  return Card(
    margin: margin,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
    child: child,
  );
}