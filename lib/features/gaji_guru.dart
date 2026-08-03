// lib/features/gaji_guru.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data.dart';
import '../templates/sound_helper.dart';

// ================== KOMPONEN GAJI ==================
class KomponenGaji {
  String nama;
  double jumlah;
  bool isTunjangan;
  String kategori; // 'Umum', 'Absen', 'Kehadiran', 'Total Jam Mengajar', 'Jabatan Tambahan'

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
  bool isArchived; // baru: menandai data yang sudah diarsipkan (tidak ditampilkan di daftar aktif)

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
    );
  }
}

// ================== MASTER DAFTAR GURU & STATE GLOBAL ==================
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

Set<String> inactiveTeachers = {}; // guru yang tidak aktif (keluar/pensiun)
int currentBulan = DateTime.now().month;
int currentTahun = DateTime.now().year;
List<GajiGuru> gajiGuruList = [];

String getBulanNama(int bulan) {
  const nama = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  return nama[bulan - 1];
}

List<KomponenGaji> generateKomponenDefault() {
  return []; // KOSONG
}

void addTeacher(String nama) {
  if (nama.trim().isEmpty) return;
  if (!teacherList.contains(nama)) {
    teacherList.add(nama);
  }
}

void removeTeacher(String nama) {
  teacherList.remove(nama);
  inactiveTeachers.remove(nama); // jika dinonaktifkan, hapus dari nonaktif
}

void moveTeacher(int fromIndex, int toIndex) {
  if (fromIndex == toIndex) return;
  final item = teacherList.removeAt(fromIndex);
  teacherList.insert(toIndex, item);
}

void toggleTeacherActive(String nama) {
  if (inactiveTeachers.contains(nama)) {
    inactiveTeachers.remove(nama);
  } else {
    inactiveTeachers.add(nama);
  }
}

void initGajiGuruData() {
  // kosong
}

// ================== HALAMAN UTAMA ==================
class GajiGuruPage extends StatefulWidget {
  const GajiGuruPage({super.key});

  @override
  State<GajiGuruPage> createState() => _GajiGuruPageState();
}

class _GajiGuruPageState extends State<GajiGuruPage>
    with SingleTickerProviderStateMixin {
  int? filterBulan;
  int? filterTahun;
  String? filterStatus;
  String? filterGuru;
  String searchQuery = '';

  // Bulk selection
  bool _selectionMode = false;
  Set<String> selectedIds = {};

  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi filter dengan currentBulan/Tahun global
    filterBulan = currentBulan;
    filterTahun = currentTahun;

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

  // ==================== SIMULASI PERGANTIAN BULAN GLOBAL ====================
  void _simulateMonthChange() {
    setState(() {
      // Naikkan bulan global
      currentBulan += 1;
      if (currentBulan > 12) {
        currentBulan = 1;
        currentTahun += 1;
      }
      // Filter ikut berubah agar daftar menampilkan bulan baru
      filterBulan = currentBulan;
      filterTahun = currentTahun;
      // Kosongkan seleksi
      selectedIds.clear();
      _selectionMode = false;

      // (Opsional) Tandai data bulan lalu yang belum lunas sebagai arsip
      _archiveUnpaidPreviousMonth();
    });
  }

  void _archiveUnpaidPreviousMonth() {
    // Data bulan lalu (sebelum kenaikan) tidak perlu diubah,
    // karena arsip sudah tersimpan di Riwayat.
    // Namun kita bisa menambahkan flag isArchived jika diperlukan.
    // Di sini kita hanya contoh: tidak melakukan apa-apa karena data tetap tersimpan.
    // Jika ingin, bisa loop gajiGuruList dan set isArchived = true untuk bulan sebelumnya yang belum lunas.
  }

  GajiGuru _getOrCreateGajiRecord(String namaGuru, int bulan, int tahun) {
    var existing = gajiGuruList.firstWhere(
      (g) => g.namaGuru == namaGuru && g.bulan == bulan && g.tahun == tahun,
      orElse: () => GajiGuru(
        id: '',
        namaGuru: '',
        komponen: [],
        bulan: bulan,
        tahun: tahun,
      ),
    );
    if (existing.namaGuru.isNotEmpty) {
      return existing;
    }

    var komponen = <KomponenGaji>[];
    var id = 'GJ${gajiGuruList.length + 1}'.padLeft(5, '0');
    var baru = GajiGuru(
      id: id,
      namaGuru: namaGuru,
      komponen: komponen,
      bulan: bulan,
      tahun: tahun,
      isPaid: false,
      tanggalBayar: null,
      metodeBayar: null,
      catatan: null,
      isArchived: false,
    );
    gajiGuruList.add(baru);
    return baru;
  }

  List<Map<String, dynamic>> get _guruListWithSalary {
    // Hanya guru aktif (tidak ada di inactiveTeachers)
    var activeGuru = teacherList.where((nama) => !inactiveTeachers.contains(nama)).toList();

    var filteredGuru = activeGuru.where((nama) {
      if (searchQuery.isNotEmpty &&
          !nama.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      if (filterStatus != null && filterBulan != null && filterTahun != null) {
        var record = gajiGuruList.firstWhere(
          (g) => g.namaGuru == nama && g.bulan == filterBulan! && g.tahun == filterTahun!,
          orElse: () => GajiGuru(
            id: '',
            namaGuru: '',
            komponen: [],
            bulan: filterBulan!,
            tahun: filterTahun!,
          ),
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
    for (var nama in filteredGuru) {
      if (filterBulan != null && filterTahun != null) {
        var record = gajiGuruList.firstWhere(
          (g) => g.namaGuru == nama && g.bulan == filterBulan! && g.tahun == filterTahun!,
          orElse: () => GajiGuru(
            id: '',
            namaGuru: '',
            komponen: [],
            bulan: filterBulan!,
            tahun: filterTahun!,
          ),
        );
        if (record.namaGuru.isNotEmpty) {
          result.add({
            'nama': nama,
            'record': record,
          });
        } else {
          result.add({
            'nama': nama,
            'record': null,
          });
        }
      } else {
        result.add({
          'nama': nama,
          'record': null,
        });
      }
    }
    return result;
  }

  // ==================== STATISTIK (berdasarkan currentBulan/Tahun) ====================
  Map<String, dynamic> get _statistics {
    final bulanIni = gajiGuruList.where((g) =>
        g.bulan == currentBulan && g.tahun == currentTahun && teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru));
    final totalBulanIni = bulanIni.fold(0.0, (s, g) => s + g.totalGaji);
    final paidBulanIni = bulanIni.where((g) => g.isPaid).fold(0.0, (s, g) => s + g.totalGaji);
    final belumBulanIni = totalBulanIni - paidBulanIni;
    final countGuruBulanIni = bulanIni.map((g) => g.namaGuru).toSet().length;
    final paidGuruBulanIni = bulanIni.where((g) => g.isPaid).map((g) => g.namaGuru).toSet().length;

    // Bulan lalu
    int bulanLalu = currentBulan - 1;
    int tahunLalu = currentTahun;
    if (bulanLalu <= 0) {
      bulanLalu = 12;
      tahunLalu -= 1;
    }
    final dataBulanLalu = gajiGuruList.where((g) =>
        g.bulan == bulanLalu && g.tahun == tahunLalu && teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru));
    final totalBulanLalu = dataBulanLalu.fold(0.0, (s, g) => s + g.totalGaji);

    final totalAll = gajiGuruList
        .where((g) => teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru))
        .fold(0.0, (s, g) => s + g.totalGaji);
    final totalPaid = gajiGuruList
        .where((g) => g.isPaid && teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru))
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
      final data = gajiGuruList
          .where((g) => g.bulan == m && g.tahun == y && teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru));
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

  // ==================== DIALOG MANAJEMEN GURU (dengan toggle aktif/nonaktif) ====================
  void _showManageTeachersDialog() {
    final TextEditingController _newTeacherController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            elevation: 8,
            child: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Manajemen Guru',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newTeacherController,
                          decoration: InputDecoration(
                            hintText: 'Nama guru baru...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final nama = _newTeacherController.text.trim();
                          if (nama.isNotEmpty) {
                            addTeacher(nama);
                            _newTeacherController.clear();
                            setStateDialog(() {});
                            setState(() {});
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Text('Tambah'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: teacherList.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        moveTeacher(oldIndex, newIndex);
                        setStateDialog(() {});
                        setState(() {});
                      },
                      itemBuilder: (context, index) {
                        final nama = teacherList[index];
                        final isInactive = inactiveTeachers.contains(nama);
                        return Card(
                          key: ValueKey(nama),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            leading: const Icon(Icons.drag_handle, color: Colors.grey),
                            title: Text(
                              nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: isInactive ? Colors.grey : Colors.black,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isInactive ? Icons.person_off : Icons.person,
                                    color: isInactive ? Colors.orange : Colors.green,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    toggleTeacherActive(nama);
                                    setStateDialog(() {});
                                    setState(() {});
                                  },
                                  tooltip: isInactive ? 'Aktifkan' : 'Nonaktifkan',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                  onPressed: () {
                                    showDialog(
                                      context: ctx,
                                      builder: (confirmCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        title: const Text('Konfirmasi Hapus'),
                                        content: Text('Yakin ingin menghapus guru "$nama" dari daftar?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(confirmCtx),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              removeTeacher(nama);
                                              Navigator.pop(confirmCtx);
                                              setStateDialog(() {});
                                              setState(() {});
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            child: const Text('Hapus'),
                                          ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Tutup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DIALOG EDIT GAJI (tanpa dropdown nama guru, bulan & tahun readonly) ====================
  void _showEditDialog(GajiGuru gaji) {
    String selectedGuru = gaji.namaGuru;
    List<KomponenGaji> komponen = gaji.komponen.map((k) => k.copyWith()).toList();
    int bulan = gaji.bulan;
    int tahun = gaji.tahun;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          void tambahKomponen(String nama, double jumlah, bool isTunjangan, String kategori) {
            setStateDialog(() {
              komponen.add(KomponenGaji(
                nama: nama,
                jumlah: jumlah,
                isTunjangan: isTunjangan,
                kategori: kategori,
              ));
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
            String kategori = 'Umum';

            showDialog(
              context: ctx,
              builder: (dialogCtx) => StatefulBuilder(
                builder: (dialogCtx, setStateDialog2) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Tambah Komponen Gaji'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nama komponen hanya ditampilkan jika kategori == 'Umum'
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
                          onChanged: (val) => jumlah = double.tryParse(val) ?? 0,
                        ),
                        DropdownButtonFormField<String>(
                          value: kategori,
                          items: const [
                            DropdownMenuItem(value: 'Umum', child: Text('Umum')),
                            DropdownMenuItem(value: 'Absen', child: Text('Absen')),
                            DropdownMenuItem(value: 'Kehadiran', child: Text('Kehadiran')),
                            DropdownMenuItem(value: 'Total Jam Mengajar', child: Text('Total Jam Mengajar')),
                            DropdownMenuItem(value: 'Jabatan Tambahan', child: Text('Jabatan Tambahan')),
                          ],
                          onChanged: (val) {
                            setStateDialog2(() {
                              kategori = val!;
                              // Untuk kategori selain Umum, nama otomatis = kategori
                              if (kategori != 'Umum') {
                                nama = kategori;
                              } else {
                                nama = '';
                              }
                            });
                          },
                          decoration: const InputDecoration(labelText: 'Kategori'),
                        ),
                        DropdownButtonFormField<bool>(
                          value: isTunjangan,
                          items: const [
                            DropdownMenuItem(value: true, child: Text('Tunjangan (+)')),
                            DropdownMenuItem(value: false, child: Text('Potongan (-)')),
                          ],
                          onChanged: (val) => setStateDialog2(() => isTunjangan = val ?? true),
                          decoration: const InputDecoration(labelText: 'Jenis'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Batal')),
                      ElevatedButton(
                        onPressed: () {
                          // Validasi
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
                          // Untuk kategori non-Umum, nama sudah diisi otomatis
                          if (kategori != 'Umum') {
                            nama = kategori;
                          }
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Edit Gaji', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('Guru: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              selectedGuru,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Text(
                              getBulanNama(bulan),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Text(
                              tahun.toString(),
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
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
                                Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(width: 8),
                              ],
                            ),
                          ),
                          if (komponen.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Belum ada komponen gaji. Tambahkan komponen dengan tombol di bawah.',
                                style: TextStyle(color: Colors.grey),
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
                                        k.kategori,
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
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Pilih nama guru')),
                    );
                    return;
                  }
                  if (komponen.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Tambahkan minimal satu komponen gaji')),
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

  void _markAsPaid(GajiGuru gaji) {
    final index = gajiGuruList.indexOf(gaji);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _deleteGaji(GajiGuru gaji) {
    final index = gajiGuruList.indexOf(gaji);
    if (index == -1) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _showSlipGaji(GajiGuru gaji) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              if (gaji.komponen.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Tidak ada komponen gaji', style: TextStyle(color: Colors.grey)),
                )
              else
                ...gaji.komponen.map((k) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})'),
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
            icon: const Icon(Icons.recycling, color: Colors.orange),
            onPressed: () {
              SoundHelper().playClick();
              _simulateMonthChange();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Debug: Bulan berubah ke ${getBulanNama(currentBulan)} $currentTahun'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            tooltip: 'Debug: Simulasi Pergantian Bulan (Global)',
          ),
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
    final bulanIniRecords = gajiGuruList.where((g) =>
        g.bulan == currentBulan && g.tahun == currentTahun && teacherList.contains(g.namaGuru) && !inactiveTeachers.contains(g.namaGuru)).toList();
    final paidTeachers = bulanIniRecords.where((g) => g.isPaid).map((g) => g.namaGuru).toSet().toList();
    final unpaidTeachers = bulanIniRecords.where((g) => !g.isPaid).map((g) => g.namaGuru).toSet().toList();

    final totalBulanIni = stats['totalBulanIni'] as double;
    final totalBulanLalu = stats['totalBulanLalu'] as double;
    double selisih = totalBulanIni - totalBulanLalu;
    double persentase = totalBulanLalu > 0 ? (selisih / totalBulanLalu) * 100 : 0;

    // Arsip belum bayar (semua bulan kecuali current)
    final arsipBelumBayar = gajiGuruList.where((g) =>
        !(g.bulan == currentBulan && g.tahun == currentTahun) &&
        !g.isPaid &&
        teacherList.contains(g.namaGuru) &&
        !inactiveTeachers.contains(g.namaGuru));
    final totalArsipBelum = arsipBelumBayar.fold(0.0, (sum, g) => sum + g.totalGaji);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDashboardCards(stats),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Perbandingan Bulan Ini vs Bulan Lalu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bulan Ini', style: TextStyle(fontSize: 12, color: Colors.blue)),
                              Text('Rp ${formatCurrency(totalBulanIni)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Bulan Lalu', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('Rp ${formatCurrency(totalBulanLalu)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                      color: selisih >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(selisih >= 0 ? Icons.trending_up : Icons.trending_down,
                            color: selisih >= 0 ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          '${selisih >= 0 ? '+' : ''}Rp ${formatCurrency(selisih)} (${persentase.toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selisih >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildChart(),
          const SizedBox(height: 24),
          _buildQuickFilter(),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Gaji Bulan Ini (${getBulanNama(currentBulan)} $currentTahun)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${paidTeachers.length} Guru',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Lunas', style: TextStyle(fontSize: 12, color: AppColors.success)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${unpaidTeachers.length} Guru',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              const Text('Belum Lunas', style: TextStyle(fontSize: 12, color: AppColors.error)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (unpaidTeachers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: unpaidTeachers.map((nama) => Chip(
                        label: Text(nama, overflow: TextOverflow.ellipsis),
                        avatar: const Icon(Icons.person, size: 16),
                        backgroundColor: Colors.red.shade50,
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildUnpaidTeachers(),
          const SizedBox(height: 24),
          // Kartu Arsip Belum Bayar
          if (totalArsipBelum > 0)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.archive, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Arsip Belum Bayar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Total gaji belum lunas dari bulan-bulan sebelumnya:'),
                    const SizedBox(height: 4),
                    Text('Rp ${formatCurrency(totalArsipBelum)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ArchiveUnpaidPage(records: arsipBelumBayar.toList()),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Lihat Arsip'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Kartu Guru Nonaktif
          if (inactiveTeachers.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_off, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Text('Guru Nonaktif',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: inactiveTeachers.map((nama) => Chip(
                        label: Text(nama, overflow: TextOverflow.ellipsis),
                        avatar: const Icon(Icons.person_off, size: 16),
                        backgroundColor: Colors.grey.shade300,
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
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

  Widget _buildUnpaidTeachers() {
    final unpaid = gajiGuruList
        .where((g) =>
            g.bulan == currentBulan &&
            g.tahun == currentTahun &&
            !g.isPaid &&
            teacherList.contains(g.namaGuru) &&
            !inactiveTeachers.contains(g.namaGuru))
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
                      label: Text(nama, overflow: TextOverflow.ellipsis),
                      avatar: const Icon(Icons.person, size: 16)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB DAFTAR GAJI (dengan Selection Mode) ====================
  Widget _buildListTab() {
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
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _selectionMode ? Icons.close : Icons.checklist,
                  color: _selectionMode ? Colors.red : Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    _selectionMode = !_selectionMode;
                    if (!_selectionMode) {
                      selectedIds.clear();
                    }
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            items: List.generate(5, (i) => currentTahun - i)
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
        if (_selectionMode && selectedCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                Text('$selectedCount terpilih',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    _bulkMarkPaid();
                  },
                  icon: const Icon(Icons.payment, color: AppColors.success),
                  label: const Text('Tandai Lunas'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    _bulkDelete();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Hapus'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear),
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
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Tidak ada guru yang cocok'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: guruData.length,
                  itemBuilder: (context, index) {
                    final item = guruData[index];
                    final nama = item['nama'] as String;
                    final record = item['record'] as GajiGuru?;
                    return _buildCompactGajiCard(nama, record, index);
                  },
                ),
        ),
      ],
    );
  }

  // ==================== BULK ACTION ====================
  void _bulkMarkPaid() {
    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Bulk'),
        content: Text('Tandai ${selectedIds.length} gaji sebagai lunas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var id in selectedIds) {
                  final index = gajiGuruList.indexWhere((g) => g.id == id);
                  if (index != -1) {
                    gajiGuruList[index] = gajiGuruList[index].copyWith(
                      isPaid: true,
                      tanggalBayar: DateTime.now(),
                      catatan:
                          'Dibayar lunas (bulk) pada ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    );
                  }
                }
                selectedIds.clear();
                _selectionMode = false;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            child: const Text('Ya, Lunas Semua'),
          ),
        ],
      ),
    );
  }

  void _bulkDelete() {
    if (selectedIds.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Bulk'),
        content: Text('Hapus ${selectedIds.length} data gaji?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
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

  // ==================== CARD GAJI RINGKAS (dengan selection mode) ====================
  Widget _buildCompactGajiCard(String namaGuru, GajiGuru? record, int index) {
    if (record == null) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.person, color: Colors.grey),
          title: Text(namaGuru, overflow: TextOverflow.ellipsis),
          subtitle: const Text('Belum ada data gaji untuk periode ini'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.primary, size: 24),
                onPressed: () {
                  if (filterBulan != null && filterTahun != null) {
                    var baru = _getOrCreateGajiRecord(namaGuru, filterBulan!, filterTahun!);
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              )
            else
              CircleAvatar(
                backgroundColor: record.isPaid ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                radius: 16,
                child: Icon(
                  record.isPaid ? Icons.check_circle : Icons.pending,
                  color: record.isPaid ? AppColors.success : AppColors.error,
                  size: 16,
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
        title: Text(
          namaGuru,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          record.komponen.isEmpty
              ? 'Belum ada komponen'
              : 'Rp ${formatCurrency(total)}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: record.komponen.isEmpty ? FontWeight.normal : FontWeight.w500,
            color: record.komponen.isEmpty ? Colors.grey : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!record.isPaid && record.komponen.isNotEmpty && !_selectionMode)
              IconButton(
                icon: const Icon(Icons.payment, color: AppColors.success, size: 20),
                onPressed: () {
                  SoundHelper().playClick();
                  _markAsPaid(record);
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
                  _deleteGaji(record);
                },
                tooltip: 'Hapus',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            if (_selectionMode)
              IconButton(
                icon: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : Colors.grey,
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

  // ==================== TAB RIWAYAT GURU (File Explorer style) ====================
  Widget _buildRiwayatTab() {
    // Hanya tampilkan data yang belum diarsipkan (isArchived = false) atau semua? Biarkan semua.
    // Kelompokkan berdasarkan tahun
    Map<int, List<GajiGuru>> groupedByYear = {};
    for (var g in gajiGuruList) {
      groupedByYear.putIfAbsent(g.tahun, () => []).add(g);
    }

    var tahunKeys = groupedByYear.keys.toList()..sort((a, b) => b.compareTo(a));

    if (tahunKeys.isEmpty) {
      return const Center(child: Text('Belum ada data gaji yang diarsipkan'));
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

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.folder, color: Colors.amber),
            title: Text('$tahun', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$totalGuru guru • Rp ${formatCurrency(totalNominal)} • $totalLunas lunas'),
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
class RiwayatBulanPage extends StatelessWidget {
  final int tahun;
  final List<GajiGuru> data;

  const RiwayatBulanPage({super.key, required this.tahun, required this.data});

  @override
  Widget build(BuildContext context) {
    Map<int, List<GajiGuru>> groupedByMonth = {};
    for (var g in data) {
      groupedByMonth.putIfAbsent(g.bulan, () => []).add(g);
    }
    var bulanKeys = groupedByMonth.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text('Arsip $tahun'),
      ),
      body: bulanKeys.isEmpty
          ? const Center(child: Text('Tidak ada data bulan'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: bulanKeys.length,
              itemBuilder: (context, index) {
                int bulan = bulanKeys[index];
                var items = groupedByMonth[bulan]!;
                double totalBulan = items.fold(0.0, (sum, g) => sum + g.totalGaji);
                int lunasBulan = items.where((g) => g.isPaid).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.folder_open, color: Colors.blue),
                    title: Text(getBulanNama(bulan), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${items.length} guru • Rp ${formatCurrency(totalBulan)} • $lunasBulan lunas'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download, size: 18),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Export ${getBulanNama(bulan)} $tahun ke Excel (placeholder)')),
                            );
                          },
                          tooltip: 'Export Bulan Ini',
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      SoundHelper().playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RiwayatGuruPage(
                            tahun: tahun,
                            bulan: bulan,
                            data: items,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ================== HALAMAN RIWAYAT PER GURU ==================
class RiwayatGuruPage extends StatelessWidget {
  final int tahun;
  final int bulan;
  final List<GajiGuru> data;

  const RiwayatGuruPage({
    super.key,
    required this.tahun,
    required this.bulan,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${getBulanNama(bulan)} $tahun'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final gaji = data[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: gaji.isPaid
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                child: Icon(gaji.isPaid ? Icons.check_circle : Icons.pending,
                    color: gaji.isPaid ? AppColors.success : AppColors.error, size: 18),
              ),
              title: Text(gaji.namaGuru, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                gaji.komponen.isEmpty
                    ? 'Belum ada komponen'
                    : 'Rp ${formatCurrency(gaji.totalGaji)}',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (gaji.isPaid && gaji.tanggalBayar != null)
                    Text(
                      '${gaji.tanggalBayar!.day}/${gaji.tanggalBayar!.month}/${gaji.tanggalBayar!.year}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                if (gaji.komponen.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text('Tidak ada komponen gaji', style: TextStyle(color: Colors.grey)),
                                  )
                                else
                                  ...gaji.komponen.map((k) => Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})'),
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
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Tutup'),
                            ),
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
}

// ================== HALAMAN ARSIP BELUM BAYAR ==================
class ArchiveUnpaidPage extends StatelessWidget {
  final List<GajiGuru> records;

  const ArchiveUnpaidPage({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arsip Belum Bayar'),
      ),
      body: records.isEmpty
          ? const Center(child: Text('Tidak ada data belum bayar di arsip'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final g = records[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.pending, color: Colors.orange),
                    title: Text(g.namaGuru, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${getBulanNama(g.bulan)} ${g.tahun} • Rp ${formatCurrency(g.totalGaji)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Text('Slip Gaji ${g.namaGuru}'),
                            content: Container(
                              width: double.maxFinite,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _detailRow('ID', g.id),
                                  _detailRow('Nama Guru', g.namaGuru),
                                  _detailRow('Periode', '${getBulanNama(g.bulan)} ${g.tahun}'),
                                  const Divider(),
                                  const Text('Komponen Gaji:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  if (g.komponen.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text('Tidak ada komponen gaji', style: TextStyle(color: Colors.grey)),
                                    )
                                  else
                                    ...g.komponen.map((k) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('${k.isTunjangan ? '+' : '-'} ${k.nama} (${k.kategori})'),
                                              Text('Rp ${formatCurrency(k.jumlah)}'),
                                            ],
                                          ),
                                        )),
                                  const Divider(),
                                  _detailRow('Total', 'Rp ${formatCurrency(g.totalGaji)}', bold: true),
                                  _detailRow('Status', g.isPaid ? 'Lunas' : 'Belum'),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Tutup'),
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