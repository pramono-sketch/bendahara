// lib/pages/gaji_guru.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data.dart'; // untuk AppColors, formatCurrency, dll
import '../templates/sound_helper.dart';

// ================== KOMPONEN GAJI ==================
class KomponenGaji {
  String nama;
  double jumlah;
  bool isTunjangan; // true = penambah, false = potongan

  KomponenGaji({
    required this.nama,
    required this.jumlah,
    this.isTunjangan = true,
  });

  KomponenGaji copyWith({
    String? nama,
    double? jumlah,
    bool? isTunjangan,
  }) {
    return KomponenGaji(
      nama: nama ?? this.nama,
      jumlah: jumlah ?? this.jumlah,
      isTunjangan: isTunjangan ?? this.isTunjangan,
    );
  }
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
  String? metodeBayar; // 'Tunai', 'Transfer', 'Cek'
  String? catatan;

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
  });

  // Total gaji (penjumlahan tunjangan dikurangi potongan)
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
    );
  }
}

// ================== MASTER DAFTAR GURU (EDITABLE) ==================
List<String> teacherList = [
  'Winarno S.E.S, S.Pd',
  'Ali Faesol, S.Pd.I.',
  'Susi Wulandari, S.Pd',
  'Kris Setyowati, S.Pd',
  'Eko Ardhiyanto, S. Kom.',
  'Aris Khoirun Ma\'dum, S.E',
  'Khoirul Ihsan Z. R, S. Sos.',
  'Didin Arif Setiawan, S. Pd. I',
  'Ust. Ahmad Sholeh, S.Pd.I',
  'Farid Fahmi, S. T.',
  'Rizki Safitri, S. Pd.',
  'Shyecha Syaidatun Nisa\', S. E.',
  'Ali Muhlisin, S. Pd.',
  'Windi Kusumowardani, S. Pd.',
  'Wiendha Kurnia Pranata, S. Pd.',
  'Ustz. Afivatun Nadliyah, Al Hafidzah, M.Pd',
  'Nike Izza Elfana, S.Pd',
  'Novita Nur Farida, S. Pd.',
  'Dwi Luvi Nur Ahmad, S. Kom.',
  'Vera Artanti, S. Kom.',
  'Hikmah Lailatul Kamalia, S. Pd.',
  'Niken Octevani Army, S. T.',
  'Imam Syibawech, S. Kom',
  'Alfida Zumaroh, S. Kom.',
  'Nur Khamim',
  'Mustagfirrin',
];

// ================== DATA GAJI GURU (SEMUA RECORD) ==================
List<GajiGuru> gajiGuruList = [];

// ================== FUNGSI BANTU ==================
String getBulanNama(int bulan) {
  const nama = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return nama[bulan - 1];
}

// ================== GENERATE KOMPONEN DEFAULT ==================
List<KomponenGaji> generateKomponenDefault() {
  return [
    KomponenGaji(nama: 'Gaji Pokok', jumlah: 2500000, isTunjangan: true),
    KomponenGaji(nama: 'Tunjangan Sertifikasi', jumlah: 500000, isTunjangan: true),
    KomponenGaji(nama: 'Tunjangan Transportasi', jumlah: 300000, isTunjangan: true),
    KomponenGaji(nama: 'Potongan Koperasi', jumlah: 100000, isTunjangan: false),
    KomponenGaji(nama: 'Potongan Pensiun', jumlah: 50000, isTunjangan: false),
  ];
}

// ================== SINRONISASI RECORD PER BULAN ==================
void syncSalaryRecordsForMonth(int bulan, int tahun) {
  // Buat record untuk setiap guru di teacherList yang belum punya record di bulan-tahun ini
  for (var guru in teacherList) {
    bool exists = gajiGuruList.any((g) =>
        g.namaGuru == guru && g.bulan == bulan && g.tahun == tahun);
    if (!exists) {
      var komponen = generateKomponenDefault();
      // Variasi kecil untuk demo (opsional)
      // komponen[0] = komponen[0].copyWith(jumlah: 2000000 + Random().nextInt(1500000).toDouble());
      var id = 'GJ${gajiGuruList.length + 1}'.padLeft(5, '0');
      gajiGuruList.add(GajiGuru(
        id: id,
        namaGuru: guru,
        komponen: komponen,
        bulan: bulan,
        tahun: tahun,
        isPaid: false,
        catatan: 'Otomatis dibuat',
      ));
    }
  }
}

// ================== TAMBAH / HAPUS GURU ==================
void addTeacher(String nama) {
  if (nama.trim().isEmpty) return;
  if (!teacherList.contains(nama)) {
    teacherList.add(nama);
    // Buat record untuk bulan saat ini
    final now = DateTime.now();
    syncSalaryRecordsForMonth(now.month, now.year);
  }
}

void removeTeacher(String nama) {
  teacherList.remove(nama);
  // Record tetap ada di gajiGuruList, tapi tidak akan muncul di daftar aktif
}

// ================== INISIALISASI DATA DEMO ==================
void initGajiGuruData() {
  if (gajiGuruList.isNotEmpty) return;

  final random = Random();
  final now = DateTime.now();
  int idCounter = 1;

  // Buat data untuk 6 bulan terakhir (termasuk bulan berjalan)
  for (int i = 5; i >= 0; i--) {
    final month = now.month - i;
    final year = now.year;
    int m = month;
    int y = year;
    if (m <= 0) {
      m += 12;
      y -= 1;
    }

    for (var nama in teacherList) {
      List<KomponenGaji> komponen = generateKomponenDefault();
      // Variasi gaji pokok
      komponen[0] = komponen[0].copyWith(
          jumlah: (2000000 + random.nextInt(1500000)).toDouble());
      // Tambah tunjangan acak
      if (random.nextBool()) {
        komponen.add(KomponenGaji(
          nama: 'Tunjangan Keluarga',
          jumlah: (300000 + random.nextInt(300000)).toDouble(),
          isTunjangan: true,
        ));
      }
      if (random.nextBool()) {
        komponen.add(KomponenGaji(
          nama: 'Tunjangan Kinerja',
          jumlah: (200000 + random.nextInt(400000)).toDouble(),
          isTunjangan: true,
        ));
      }
      if (random.nextBool()) {
        komponen.add(KomponenGaji(
          nama: 'Potongan Koperasi Tambahan',
          jumlah: (50000 + random.nextInt(150000)).toDouble(),
          isTunjangan: false,
        ));
      }

      final isPaid = (i > 0 && random.nextBool()) || (i == 0 && random.nextBool());
      final tanggalBayar = isPaid ? DateTime(y, m, random.nextInt(25) + 1) : null;
      final metode = isPaid ? (random.nextBool() ? 'Transfer' : 'Tunai') : null;
      final catatan = isPaid ? 'Pembayaran periode ${getBulanNama(m)} $y' : 'Menunggu pembayaran';

      final id = 'GJ${idCounter.toString().padLeft(3, '0')}';
      idCounter++;

      gajiGuruList.add(GajiGuru(
        id: id,
        namaGuru: nama,
        komponen: komponen,
        bulan: m,
        tahun: y,
        isPaid: isPaid,
        tanggalBayar: tanggalBayar,
        metodeBayar: metode,
        catatan: catatan,
      ));
    }
  }

  // Pastikan bulan ini semua guru punya record (tambahan jika ada guru baru)
  syncSalaryRecordsForMonth(now.month, now.year);
}

// ================== HALAMAN UTAMA ==================
class GajiGuruPage extends StatefulWidget {
  const GajiGuruPage({super.key});

  @override
  State<GajiGuruPage> createState() => _GajiGuruPageState();
}

class _GajiGuruPageState extends State<GajiGuruPage>
    with SingleTickerProviderStateMixin {
  // Filter
  int? filterBulan;
  int? filterTahun;
  String? filterStatus; // 'Lunas', 'Belum'
  String? filterGuru; // untuk riwayat guru
  String searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi data
    initGajiGuruData();
    // Pastikan bulan ini tersinkron
    final now = DateTime.now();
    syncSalaryRecordsForMonth(now.month, now.year);

    // Default filter ke bulan/tahun saat ini
    filterBulan = now.month;
    filterTahun = now.year;

    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ==================== DATA TERFILTER ====================
  List<GajiGuru> get _filteredList {
    var list = gajiGuruList.where((g) {
      // Hanya tampilkan guru yang masih aktif di teacherList
      if (!teacherList.contains(g.namaGuru)) return false;
      if (filterBulan != null && g.bulan != filterBulan) return false;
      if (filterTahun != null && g.tahun != filterTahun) return false;
      if (filterStatus == 'Lunas' && !g.isPaid) return false;
      if (filterStatus == 'Belum' && g.isPaid) return false;
      if (filterGuru != null && g.namaGuru != filterGuru) return false;
      if (searchQuery.isNotEmpty &&
          !g.namaGuru.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      if (a.tahun != b.tahun) return b.tahun.compareTo(a.tahun);
      return b.bulan.compareTo(a.bulan);
    });
    return list;
  }

  // ==================== STATISTIK ====================
  Map<String, dynamic> get _statistics {
    final now = DateTime.now();
    // Bulan ini
    final bulanIni = gajiGuruList.where((g) =>
        g.bulan == now.month && g.tahun == now.year && teacherList.contains(g.namaGuru));
    final totalBulanIni = bulanIni.fold(0.0, (s, g) => s + g.totalGaji);
    final paidBulanIni = bulanIni.where((g) => g.isPaid).fold(0.0, (s, g) => s + g.totalGaji);
    final belumBulanIni = totalBulanIni - paidBulanIni;
    final countGuruBulanIni = bulanIni.map((g) => g.namaGuru).toSet().length;
    final paidGuruBulanIni = bulanIni.where((g) => g.isPaid).map((g) => g.namaGuru).toSet().length;

    // Bulan lalu
    final bulanLalu = now.month - 1;
    final tahunLalu = bulanLalu <= 0 ? now.year - 1 : now.year;
    final bulanLaluIndex = bulanLalu <= 0 ? 12 : bulanLalu;
    final dataBulanLalu = gajiGuruList.where((g) =>
        g.bulan == bulanLaluIndex && g.tahun == tahunLalu && teacherList.contains(g.namaGuru));
    final totalBulanLalu = dataBulanLalu.fold(0.0, (s, g) => s + g.totalGaji);

    final totalAll = gajiGuruList
        .where((g) => teacherList.contains(g.namaGuru))
        .fold(0.0, (s, g) => s + g.totalGaji);
    final totalPaid = gajiGuruList
        .where((g) => g.isPaid && teacherList.contains(g.namaGuru))
        .fold(0.0, (s, g) => s + g.totalGaji);

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

  // ==================== DATA GRAFIK ====================
  List<Map<String, dynamic>> get _chartData {
    final now = DateTime.now();
    List<Map<String, dynamic>> result = [];
    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year;
      int m = month;
      int y = year;
      if (m <= 0) {
        m += 12;
        y -= 1;
      }
      final data = gajiGuruList
          .where((g) => g.bulan == m && g.tahun == y && teacherList.contains(g.namaGuru));
      final total = data.fold(0.0, (s, g) => s + g.totalGaji);
      final paid = data.where((g) => g.isPaid).fold(0.0, (s, g) => s + g.totalGaji);
      result.add({
        'label': '${getBulanNama(m).substring(0, 3)} $y',
        'total': total,
        'paid': paid,
        'month': m,
        'year': y,
      });
    }
    return result;
  }

  List<String> get _uniqueGuru => teacherList;

  // ==================== DIALOG MANAJEMEN GURU ====================
  void _showManageTeachersDialog() {
    final TextEditingController _newTeacherController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text('Manajemen Guru'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTeacherController,
                          decoration: const InputDecoration(
                            hintText: 'Nama guru baru',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          final nama = _newTeacherController.text.trim();
                          if (nama.isNotEmpty) {
                            addTeacher(nama);
                            _newTeacherController.clear();
                            setStateDialog(() {});
                            setState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: teacherList.length,
                      itemBuilder: (ctx, index) {
                        final nama = teacherList[index];
                        return ListTile(
                          title: Text(nama),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              removeTeacher(nama);
                              setStateDialog(() {});
                              setState(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==================== DIALOG EDIT GAJI ====================
  void _showEditDialog(GajiGuru gaji) {
    // State untuk dialog
    String selectedGuru = gaji.namaGuru;
    List<KomponenGaji> komponen = gaji.komponen.map((k) => k.copyWith()).toList();
    int bulan = gaji.bulan;
    int tahun = gaji.tahun;
    String metodeBayar = gaji.metodeBayar ?? 'Tunai';
    String catatan = gaji.catatan ?? '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          void tambahKomponen(String nama, double jumlah, bool isTunjangan) {
            setStateDialog(() {
              komponen.add(KomponenGaji(nama: nama, jumlah: jumlah, isTunjangan: isTunjangan));
            });
          }

          void hapusKomponen(int idx) {
            setStateDialog(() {
              komponen.removeAt(idx);
            });
          }

          void showTambahKomponenDialog() {
            String nama = '';
            double jumlah = 0;
            bool isTunjangan = true;
            showDialog(
              context: ctx,
              builder: (dialogCtx) => AlertDialog(
                title: const Text('Tambah Komponen Gaji'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nama Komponen'),
                      onChanged: (val) => nama = val,
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => jumlah = double.tryParse(val) ?? 0,
                    ),
                    DropdownButtonFormField<bool>(
                      value: isTunjangan,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Tunjangan (+)')),
                        DropdownMenuItem(value: false, child: Text('Potongan (-)')),
                      ],
                      onChanged: (val) => isTunjangan = val ?? true,
                      decoration: const InputDecoration(labelText: 'Jenis'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
                  ElevatedButton(
                    onPressed: () {
                      if (nama.isNotEmpty && jumlah > 0) {
                        tambahKomponen(nama, jumlah, isTunjangan);
                        Navigator.pop(dialogCtx);
                      } else {
                        ScaffoldMessenger.of(dialogCtx).showSnackBar(
                          const SnackBar(content: Text('Isi nama dan jumlah dengan benar')),
                        );
                      }
                    },
                    child: const Text('Tambah'),
                  ),
                ],
              ),
            );
          }

          final total = komponen.fold(0.0, (sum, k) => sum + (k.isTunjangan ? k.jumlah : -k.jumlah));

          return AlertDialog(
            title: const Text('Edit Gaji'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nama Guru (read only)
                    DropdownButtonFormField<String>(
                      value: selectedGuru,
                      items: teacherList.map((nama) {
                        return DropdownMenuItem(value: nama, child: Text(nama));
                      }).toList(),
                      onChanged: (val) => setStateDialog(() => selectedGuru = val!),
                      decoration: const InputDecoration(labelText: 'Nama Guru', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Bulan & Tahun
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: bulan,
                            items: List.generate(12, (i) => i + 1).map((b) {
                              return DropdownMenuItem(value: b, child: Text(getBulanNama(b)));
                            }).toList(),
                            onChanged: (val) => setStateDialog(() => bulan = val!),
                            decoration: const InputDecoration(labelText: 'Bulan', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(labelText: 'Tahun', border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                            controller: TextEditingController(text: tahun.toString()),
                            onChanged: (val) {
                              final t = int.tryParse(val);
                              if (t != null) setStateDialog(() => tahun = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Komponen
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(child: Text('Komponen', style: TextStyle(fontWeight: FontWeight.bold))),
                                SizedBox(width: 8),
                                Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                                Text('Jenis', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                          ...komponen.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final k = entry.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(child: Text(k.nama, style: const TextStyle(fontSize: 13))),
                                  const SizedBox(width: 8),
                                  Text(formatCurrency(k.jumlah), style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: k.isTunjangan ? Colors.green.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      k.isTunjangan ? 'Tunjangan' : 'Potongan',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: k.isTunjangan ? Colors.green.shade800 : Colors.red.shade800,
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
                                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  'Rp ${formatCurrency(total)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: total >= 0 ? AppColors.success : AppColors.error,
                                  ),
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
                                label: const Text('Tambah'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Metode Bayar
                    DropdownButtonFormField<String>(
                      value: metodeBayar,
                      items: const [
                        DropdownMenuItem(value: 'Tunai', child: Text('Tunai')),
                        DropdownMenuItem(value: 'Transfer', child: Text('Transfer')),
                        DropdownMenuItem(value: 'Giro', child: Text('Giro')),
                      ],
                      onChanged: (val) => setStateDialog(() => metodeBayar = val!),
                      decoration: const InputDecoration(labelText: 'Metode Bayar', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Catatan
                    TextField(
                      decoration: const InputDecoration(labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
                      controller: TextEditingController(text: catatan),
                      onChanged: (val) => catatan = val,
                      maxLines: 2,
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
                  if (selectedGuru.isEmpty || komponen.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Isi nama guru dan minimal satu komponen')),
                    );
                    return;
                  }
                  if (total <= 0) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Total gaji harus positif')),
                    );
                    return;
                  }

                  final index = gajiGuruList.indexOf(gaji);
                  if (index != -1) {
                    gajiGuruList[index] = gajiGuruList[index].copyWith(
                      namaGuru: selectedGuru,
                      komponen: komponen.map((k) => k.copyWith()).toList(),
                      bulan: bulan,
                      tahun: tahun,
                      metodeBayar: metodeBayar,
                      catatan: catatan,
                    );
                  }
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

  // ==================== MARK AS PAID ====================
  void _markAsPaid(GajiGuru gaji) {
    final index = gajiGuruList.indexOf(gaji);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tandai gaji ${gaji.namaGuru} sebagai lunas?'),
            const SizedBox(height: 8),
            Text('Total: Rp ${formatCurrency(gaji.totalGaji)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
              setState(() {
                gajiGuruList[index] = gaji.copyWith(
                  isPaid: true,
                  tanggalBayar: DateTime.now(),
                  catatan:
                      'Dibayar lunas pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                );
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Lunas'),
          ),
        ],
      ),
    );
  }

  // ==================== DELETE RECORD (HANYA UNTUK RECORD YANG TIDAK DIPERLUKAN) ====================
  void _deleteGaji(GajiGuru gaji) {
    final index = gajiGuruList.indexOf(gaji);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Data'),
        content: Text(
            'Yakin hapus gaji ${gaji.namaGuru} periode ${getBulanNama(gaji.bulan)} ${gaji.tahun}?'),
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
              setState(() => gajiGuruList.removeAt(index));
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ==================== SLIP GAJI ====================
  void _showSlipGaji(GajiGuru gaji) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Slip Gaji ${gaji.namaGuru}'),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('ID', gaji.id),
              _detailRow('Nama Guru', gaji.namaGuru),
              _detailRow('Periode', '${getBulanNama(gaji.bulan)} ${gaji.tahun}'),
              const Divider(),
              const Text('Komponen Gaji:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...gaji.komponen.map((k) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${k.isTunjangan ? '+' : '-'} ${k.nama}'),
                        Text('Rp ${formatCurrency(k.jumlah)}'),
                      ],
                    ),
                  )),
              const Divider(),
              _detailRow('Total', 'Rp ${formatCurrency(gaji.totalGaji)}', bold: true),
              _detailRow('Status', gaji.isPaid ? 'Lunas' : 'Belum'),
              if (gaji.isPaid && gaji.tanggalBayar != null)
                _detailRow('Tanggal Bayar',
                    '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}'),
              if (gaji.metodeBayar != null) _detailRow('Metode', gaji.metodeBayar!),
              if (gaji.catatan != null && gaji.catatan!.isNotEmpty)
                _detailRow('Catatan', gaji.catatan!),
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

  Widget _detailRow(String label, String value, {bool bold = false}) {
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
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(value,
                style:
                    TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            Tab(text: 'Riwayat Guru'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboard(),
          _buildListTab(),
          _buildRiwayatTab(),
        ],
      ),
    );
  }

  // ==================== DASHBOARD ====================
  Widget _buildDashboard() {
    final stats = _statistics;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardCards(stats),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 24),
          _buildQuickFilter(),
          const SizedBox(height: 24),
          _buildUnpaidTeachers(),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(Map<String, dynamic> stats) {
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
          color: AppColors.primary,
          subtitle: '${stats['countGuruBulanIni']} guru',
        ),
        _StatCard(
          title: 'Sudah Dibayar',
          value: 'Rp ${formatCurrency(stats['paidBulanIni'])}',
          icon: Icons.check_circle,
          color: AppColors.success,
          subtitle: '${stats['paidGuruBulanIni']} guru',
        ),
        _StatCard(
          title: 'Belum Dibayar',
          value: 'Rp ${formatCurrency(stats['belumBulanIni'])}',
          icon: Icons.pending,
          color: AppColors.error,
          subtitle:
              '${stats['countGuruBulanIni'] - stats['paidGuruBulanIni']} guru',
        ),
        _StatCard(
          title: 'Bulan Lalu',
          value: 'Rp ${formatCurrency(stats['totalBulanLalu'])}',
          icon: Icons.history,
          color: AppColors.warning,
          subtitle: 'Periode sebelumnya',
        ),
      ],
    );
  }

  Widget _buildChart() {
    final data = _chartData;
    final maxTotal = data.fold(0.0, (max, item) => item['total'] > max ? item['total'] : max);
    if (maxTotal == 0) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: Text('Belum ada data gaji')),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Perbandingan Gaji per Bulan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                            return Text(data[index]['label'],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            formatCurrency(value),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    topTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: data.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item['total'],
                          color: Colors.blue.withOpacity(0.6),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: item['paid'],
                          color: Colors.green.withOpacity(0.8),
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
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

  Widget _buildQuickFilter() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Cepat',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  items: List.generate(5, (i) => DateTime.now().year - i).map((t) {
                    return DropdownMenuItem(value: t, child: Text(t.toString()));
                  }).toList(),
                  onChanged: (val) => setState(() => filterTahun = val),
                ),
                if (filterStatus != null || filterBulan != null || filterTahun != null)
                  TextButton(
                    onPressed: () => setState(() {
                      filterStatus = null;
                      filterBulan = null;
                      filterTahun = null;
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

  Widget _buildUnpaidTeachers() {
    final now = DateTime.now();
    final unpaid = gajiGuruList
        .where((g) =>
            g.bulan == now.month &&
            g.tahun == now.year &&
            !g.isPaid &&
            teacherList.contains(g.namaGuru))
        .map((g) => g.namaGuru)
        .toSet()
        .toList();
    if (unpaid.isEmpty) return const SizedBox.shrink();
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.red),
                const SizedBox(width: 8),
                Text('${unpaid.length} guru belum menerima gaji bulan ini',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: unpaid
                  .map((nama) => Chip(
                      label: Text(nama), avatar: const Icon(Icons.person, size: 16)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB DAFTAR GAJI ====================
  Widget _buildListTab() {
    // Sinkronkan data untuk bulan & tahun yang sedang difilter (jika ada)
    if (filterBulan != null && filterTahun != null) {
      syncSalaryRecordsForMonth(filterBulan!, filterTahun!);
    }

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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Tombol untuk mengubah filter bulan/tahun
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () {
                  // Bisa tampilkan dialog untuk pilih bulan/tahun
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pilih Periode'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DropdownButtonFormField<int>(
                            value: filterBulan,
                            hint: const Text('Bulan'),
                            items: List.generate(12, (i) => i + 1).map((b) {
                              return DropdownMenuItem(
                                  value: b, child: Text(getBulanNama(b)));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => filterBulan = val),
                          ),
                          DropdownButtonFormField<int>(
                            value: filterTahun,
                            hint: const Text('Tahun'),
                            items: List.generate(5, (i) => DateTime.now().year - i)
                                .map((t) {
                              return DropdownMenuItem(
                                  value: t, child: Text(t.toString()));
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => filterTahun = val),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup'),
                        ),
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
        Expanded(
          child: _filteredList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada data sesuai filter'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _filteredList.length,
                  itemBuilder: (context, index) {
                    final gaji = _filteredList[index];
                    return _buildGajiCard(gaji);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildGajiCard(GajiGuru gaji) {
    final statusText = gaji.isPaid ? 'Lunas' : 'Belum';
    final statusColor = gaji.isPaid ? AppColors.success : AppColors.error;
    final isOverdue = !gaji.isPaid &&
        (gaji.tahun < DateTime.now().year ||
            (gaji.tahun == DateTime.now().year &&
                gaji.bulan < DateTime.now().month));

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showSlipGaji(gaji),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.15),
                radius: 28,
                child: Icon(gaji.isPaid ? Icons.check_circle : Icons.pending,
                    color: statusColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(gaji.namaGuru,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${getBulanNama(gaji.bulan)} ${gaji.tahun}',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(statusText,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                        if (isOverdue)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('Overdue',
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ),
                        if (gaji.isPaid && gaji.tanggalBayar != null)
                          Text(
                            'Bayar: ${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rp ${formatCurrency(gaji.totalGaji)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!gaji.isPaid)
                        IconButton(
                          icon: const Icon(Icons.payment,
                              color: AppColors.success, size: 20),
                          onPressed: () {
                            SoundHelper().playClick();
                            _markAsPaid(gaji);
                          },
                          tooltip: 'Tandai Lunas',
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () {
                          SoundHelper().playClick();
                          _showEditDialog(gaji);
                        },
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () {
                          SoundHelper().playClick();
                          _deleteGaji(gaji);
                        },
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB RIWAYAT GURU ====================
  Widget _buildRiwayatTab() {
    // Daftar guru dari semua record (termasuk yang sudah dihapus) untuk riwayat
    final allGuru = gajiGuruList.map((g) => g.namaGuru).toSet().toList()..sort();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: filterGuru,
            hint: const Text('Pilih Guru untuk Lihat Riwayat'),
            items: allGuru.map((nama) {
              return DropdownMenuItem(value: nama, child: Text(nama));
            }).toList(),
            onChanged: (val) => setState(() => filterGuru = val),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.history),
            ),
          ),
        ),
        Expanded(
          child: filterGuru == null
              ? const Center(child: Text('Pilih guru untuk melihat riwayat gaji'))
              : _buildRiwayatGuru(filterGuru!),
        ),
      ],
    );
  }

  Widget _buildRiwayatGuru(String namaGuru) {
    final data = gajiGuruList
        .where((g) => g.namaGuru == namaGuru)
        .toList()
      ..sort((a, b) {
        if (a.tahun != b.tahun) return b.tahun.compareTo(a.tahun);
        return b.bulan.compareTo(a.bulan);
      });

    if (data.isEmpty) {
      return const Center(child: Text('Belum ada data gaji untuk guru ini'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final gaji = data[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: gaji.isPaid
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              child: Icon(gaji.isPaid ? Icons.check_circle : Icons.pending,
                  color: gaji.isPaid ? AppColors.success : AppColors.error),
            ),
            title: Text('${getBulanNama(gaji.bulan)} ${gaji.tahun}'),
            subtitle: Text('Total: Rp ${formatCurrency(gaji.totalGaji)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (gaji.isPaid && gaji.tanggalBayar != null)
                  Text(
                    '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}',
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () => _showSlipGaji(gaji),
                  tooltip: 'Detail',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==================== STAT CARD WIDGET ====================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  radius: 20,
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}