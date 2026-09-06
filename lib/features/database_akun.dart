// features/database_akun.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';
import '../templates/sound_helper.dart';
import '../constants/appearance.dart'; // 🔥 import warna

// ============================================================
// HALAMAN UTAMA
// ============================================================
class DatabaseAkunPage extends StatefulWidget {
  const DatabaseAkunPage({super.key});

  @override
  State<DatabaseAkunPage> createState() => _DatabaseAkunPageState();
}

class _DatabaseAkunPageState extends State<DatabaseAkunPage>
    with SingleTickerProviderStateMixin {
  List<AkunDigital> _allAccounts = [];
  bool _isLoading = true;

  // Tab controller
  late TabController _tabController;

  // Filter untuk Siswa (kelas)
  String _filterKelasSiswa = 'Semua';

  // Pencarian
  String _searchQuery = '';

  // Controller untuk form
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _namaSiswaController = TextEditingController(); // tambahan
  final _emailController = TextEditingController();
  final _penanggungJawabController = TextEditingController();
  final _passwordController = TextEditingController();
  final _keteranganController = TextEditingController();
  String _selectedCategory = 'guru';
  String? _selectedKelas;

  // Daftar pilihan kelas
  final List<String> _kelasOptions = [
    'Semua',
    'X RPL',
    'X TKJ',
    'X TKR',
    'XI RPL',
    'XI TKJ',
    'XI TKR',
    'XII RPL',
    'XII TKJ',
    'XII TKR',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAccounts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _namaSiswaController.dispose();
    _emailController.dispose();
    _penanggungJawabController.dispose();
    _passwordController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  // ===================== LOAD & SAVE =====================
  Future<void> _loadAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString('akunDigital');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        setState(() {
          _allAccounts =
              jsonList.map((e) => AkunDigital.fromJson(e)).toList();
        });
      } else {
        _allAccounts = [];
      }
    } catch (e) {
      debugPrint('Gagal load akun: $e');
      _allAccounts = [];
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString =
          json.encode(_allAccounts.map((a) => a.toJson()).toList());
      await prefs.setString('akunDigital', jsonString);
    } catch (e) {
      debugPrint('Gagal simpan akun: $e');
    }
  }

  // ===================== CRUD =====================
  void _addAccount(AkunDigital account) {
    setState(() => _allAccounts.add(account));
    _saveAccounts();
  }

  void _updateAccount(AkunDigital updated) {
    final index = _allAccounts.indexWhere((a) => a.id == updated.id);
    if (index != -1) {
      setState(() => _allAccounts[index] = updated);
      _saveAccounts();
    }
  }

  void _deleteAccount(String id) {
    setState(() => _allAccounts.removeWhere((a) => a.id == id));
    _saveAccounts();
  }

  // ===================== DIALOG TAMBAH / EDIT =====================
  void _showAccountDialog({AkunDigital? existing}) {

    if (existing != null) {
      _nameController.text = existing.name;
      _namaSiswaController.text = existing.namaSiswa ?? '';
      _emailController.text = existing.email;
      _penanggungJawabController.text = existing.penanggungJawab;
      _passwordController.text = existing.password;
      _keteranganController.text = existing.keterangan;
      _selectedCategory = existing.category;
      _selectedKelas = existing.kelas;
    } else {
      _nameController.clear();
      _namaSiswaController.clear();
      _emailController.clear();
      _penanggungJawabController.clear();
      _passwordController.clear();
      _keteranganController.clear();
      _selectedCategory = 'guru';
      _selectedKelas = null;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text(existing == null ? 'Tambah Akun' : 'Edit Akun'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Akun / Layanan
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Akun / Layanan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Nama Siswa (hanya jika kategori siswa)
                      if (_selectedCategory == 'siswa')
                        TextFormField(
                          controller: _namaSiswaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Siswa (untuk tampilan)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      if (_selectedCategory == 'siswa') const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email / Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Penanggung Jawab
                      TextFormField(
                        controller: _penanggungJawabController,
                        decoration: const InputDecoration(
                          labelText: 'Penanggung Jawab',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),

                      // Keterangan
                      TextFormField(
                        controller: _keteranganController,
                        decoration: const InputDecoration(
                          labelText: 'Keterangan',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Kategori (Guru / Siswa)
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        items: const [
                          DropdownMenuItem(value: 'guru', child: Text('Guru')),
                          DropdownMenuItem(
                              value: 'siswa', child: Text('Siswa')),
                        ],
                        onChanged: (val) {
                          setStateDialog(() {
                            _selectedCategory = val!;
                            if (val == 'guru') _selectedKelas = null;
                            // reset nama siswa
                            if (val == 'guru') _namaSiswaController.clear();
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Kelas (hanya jika siswa)
                      if (_selectedCategory == 'siswa')
                        DropdownButtonFormField<String>(
                          value: _selectedKelas,
                          hint: const Text('Pilih Kelas'),
                          items: _kelasOptions
                              .where((k) => k != 'Semua')
                              .map((k) => DropdownMenuItem(
                                    value: k,
                                    child: Text(k),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            setStateDialog(() => _selectedKelas = val);
                          },
                          decoration: const InputDecoration(
                            labelText: 'Kelas',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v == null ? 'Pilih kelas' : null,
                        ),
                    ],
                  ),
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
                  if (_formKey.currentState!.validate()) {
                    final name = _nameController.text.trim();
                    final namaSiswa = _selectedCategory == 'siswa'
                        ? _namaSiswaController.text.trim()
                        : null;
                    final email = _emailController.text.trim();
                    final penanggungJawab =
                        _penanggungJawabController.text.trim();
                    final password = _passwordController.text.trim();
                    final keterangan = _keteranganController.text.trim();
                    final category = _selectedCategory;
                    final kelas =
                        category == 'siswa' ? _selectedKelas : null;

                    if (existing == null) {
                      // Tambah baru
                      final newAccount = AkunDigital(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        namaSiswa: namaSiswa,
                        email: email,
                        penanggungJawab: penanggungJawab,
                        password: password,
                        keterangan: keterangan,
                        category: category,
                        kelas: kelas,
                      );
                      _addAccount(newAccount);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Akun berhasil ditambahkan')),
                      );
                    } else {
                      // Update
                      final updated = AkunDigital(
                        id: existing.id,
                        name: name,
                        namaSiswa: namaSiswa,
                        email: email,
                        penanggungJawab: penanggungJawab,
                        password: password,
                        keterangan: keterangan,
                        category: category,
                        kelas: kelas,
                      );
                      _updateAccount(updated);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Akun berhasil diperbarui')),
                      );
                    }
                    Navigator.pop(ctx);
                  }
                },
                child: Text(existing == null ? 'Tambah' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ===================== KONFIRMASI HAPUS =====================
  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun'),
        content: Text('Yakin ingin menghapus akun "$name"?'),
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
              _deleteAccount(id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Akun berhasil dihapus')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // ===================== NAIK KELAS (PROMOSI) =====================
  void _promoteClasses() {
    final TextEditingController folderController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verifikasi Kenaikan Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proses ini akan:\n'
              '• Mengarsipkan semua siswa kelas XII (lulus) ke folder arsip siswa\n'
              '• Menaikkan kelas siswa X→XI, XI→XII\n'
              '• Mengarsipkan akun digital siswa kelas XII ke folder arsip akun digital\n'
              '• Menaikkan kelas akun digital siswa X→XI, XI→XII\n\n'
              'Catatan: Siswa baru untuk kelas X harus ditambahkan secara manual.\n\n'
              'Masukkan nama folder untuk arsip (misal: "2025/2026" atau "Angkatan 2025"):',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: folderController,
              decoration: const InputDecoration(
                hintText: 'Nama folder arsip',
                border: OutlineInputBorder(),
              ),
            ),
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
              final folderName = folderController.text.trim();
              if (folderName.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Nama folder tidak boleh kosong!'),
                  ),
                );
                return;
              }

              // 1. Proses kenaikan kelas untuk data siswa (sampleStudents)
              archiveGraduatedStudents(folderName, sampleStudents); // arsip siswa XII
              processClassPromotion(sampleStudents); // naikkan X→XI, XI→XII

              // 2. Proses kenaikan kelas untuk akun digital siswa
              //    Arsipkan akun XII ke arsipAkunSiswa
              archiveGraduatedAccounts(folderName, _allAccounts);
              //    Naikkan akun X→XI, XI→XII
              promoteAccounts(_allAccounts);

              // 3. Simpan perubahan akun digital ke SharedPreferences
              _saveAccounts();

              // 4. Catat log
              localLogs.insert(
                0,
                ActivityLog(
                  user: 'Admin',
                  action: ActivityAction.edit,
                  detail: 'Kenaikan kelas dengan arsip "$folderName"',
                  timestamp: DateTime.now(),
                ),
              );

              Navigator.pop(ctx);
              if (mounted) {
                setState(() {}); // refresh tampilan
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Kenaikan kelas berhasil! Arsip: "$folderName"',
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text('Ya, Naikkan Kelas'),
          ),
        ],
      ),
    );
  }

  // ===================== LIHAT ARSIP AKUN DIGITAL =====================
  void _viewArchive() {
    SoundHelper().playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ArchiveAkunPage()),
    ).then((_) => setState(() {}));
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    // Filter guru (tanpa filter kelas)
    List<AkunDigital> guruList = _allAccounts
        .where((a) => a.category == 'guru')
        .where((a) => _matchesSearch(a))
        .toList();

    // Filter siswa: hanya yang belum lulus (kelas != 'Lulus') dan sesuai filter kelas & pencarian
    List<AkunDigital> siswaList = _allAccounts
        .where((a) => a.category == 'siswa')
        .where((a) => a.kelas != 'Lulus') // hilangkan siswa lulus
        .where((a) {
          if (_filterKelasSiswa == 'Semua') return true;
          return a.kelas == _filterKelasSiswa;
        })
        .where((a) => _matchesSearch(a))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Akun Digital'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Guru'),
            Tab(icon: Icon(Icons.school), text: 'Siswa'),
          ],
        ),
        actions: [
          // Tombol Arsip (khusus untuk akun digital)
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _viewArchive,
            tooltip: 'Lihat Arsip Akun Digital',
          ),
          // Tombol Naik Kelas
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: _promoteClasses,
            tooltip: 'Kenaikan Kelas',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              SoundHelper().playClick();
              _showAccountDialog();
            },
            tooltip: 'Tambah Akun',
          ),
        ],
      ),
      body: Column(
        children: [
          // Pencarian
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari akun...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // TAB GURU
                _buildAccountList(guruList, isGuru: true),

                // TAB SISWA (dengan filter kelas)
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          const Text('Filter Kelas:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _filterKelasSiswa,
                              items: _kelasOptions.map((kelas) {
                                return DropdownMenuItem(
                                  value: kelas,
                                  child: Text(kelas),
                                );
                              }).toList(),
                              onChanged: (val) {
                                SoundHelper().playClick();
                                setState(() => _filterKelasSiswa = val!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildAccountList(siswaList, isGuru: false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===================== FUNGSI BANTU PENCARIAN =====================
  bool _matchesSearch(AkunDigital acc) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return acc.name.toLowerCase().contains(query) ||
        (acc.namaSiswa?.toLowerCase().contains(query) ?? false) ||
        acc.email.toLowerCase().contains(query) ||
        acc.penanggungJawab.toLowerCase().contains(query) ||
        (acc.kelas?.toLowerCase().contains(query) ?? false);
  }

  // ===================== WIDGET LIST AKUN =====================
  Widget _buildAccountList(List<AkunDigital> accounts, {required bool isGuru}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGuru ? Icons.person_outline : Icons.cast_for_education,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada akun ${isGuru ? 'guru' : 'siswa aktif'}',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + di atas untuk menambahkan',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final acc = accounts[index];
        return _buildAccountCard(acc);
      },
    );
  }

  // ===================== WIDGET KARTU AKUN =====================
Widget _buildAccountCard(AkunDigital acc) {
  // Data untuk tampilan
  final displayTitle = acc.name;

  final displaySubtitle = acc.category == 'siswa'
      ? (acc.namaSiswa?.isNotEmpty == true
          ? acc.namaSiswa!
          : '-')
      : acc.email;

  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Icon(
          acc.category == 'guru' ? Icons.person : Icons.school,
          color: Colors.white,
        ),
      ),
      title: Text(
        displayTitle,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Text(
        displaySubtitle,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      onExpansionChanged: (_) => SoundHelper().playClick(),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (acc.category == 'siswa' && acc.kelas != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(acc.kelas!),
                backgroundColor: acc.kelas == 'Lulus'
                    ? Colors.grey.shade300
                    : Colors.blue.shade100,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              SoundHelper().playClick();
              _showAccountDialog(existing: acc);
            },
            tooltip: 'Edit',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.red,
            ),
            onPressed: () {
              SoundHelper().playClick();
              _showDeleteConfirmation(acc.id, acc.name);
            },
            tooltip: 'Hapus',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: 4),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (acc.category == 'siswa' &&
                  acc.namaSiswa?.isNotEmpty == true)
                _infoRow('Nama Siswa', acc.namaSiswa!),
              _infoRow('Layanan', acc.name),
              _infoRow('Email', acc.email),
              _infoRow('Penanggung Jawab', acc.penanggungJawab),
              _infoRow('Keterangan', acc.keterangan),
              _infoRow('Password', acc.password),
              if (acc.category == 'siswa' && acc.kelas != null)
                _infoRow('Kelas', acc.kelas!),
            ],
          ),
        ),
      ],
    ),
  );
}
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HALAMAN ARSIP AKUN DIGITAL (tidak berubah)
// ============================================================
class ArchiveAkunPage extends StatelessWidget {
  const ArchiveAkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tahunKeys = arsipAkunSiswa.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Arsip Akun Digital Siswa')),
      body: tahunKeys.isEmpty
          ? const Center(child: Text('Belum ada arsip akun digital'))
          : ListView.builder(
              itemCount: tahunKeys.length,
              itemBuilder: (context, index) {
                final tahun = tahunKeys[index];
                final kelasMap = arsipAkunSiswa[tahun]!;
                final totalAkun = kelasMap.values.fold(
                  0,
                  (sum, list) => sum + list.length,
                );

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.amber),
                    title: Text(tahun),
                    subtitle: Text(
                      '$totalAkun akun • ${kelasMap.length} kelas',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      SoundHelper().playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveAkunClassPage(tahun: tahun),
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

class ArchiveAkunClassPage extends StatelessWidget {
  final String tahun;
  const ArchiveAkunClassPage({super.key, required this.tahun});

  @override
  Widget build(BuildContext context) {
    final kelasMap = arsipAkunSiswa[tahun] ?? {};
    final kelasKeys = kelasMap.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Arsip $tahun')),
      body: kelasKeys.isEmpty
          ? const Center(child: Text('Kosong'))
          : ListView.builder(
              itemCount: kelasKeys.length,
              itemBuilder: (context, index) {
                final kelas = kelasKeys[index];
                final akunList = kelasMap[kelas]!;

                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.folder_open,
                      color: getMajorColor(kelas),
                    ),
                    title: Text(kelas),
                    subtitle: Text('${akunList.length} akun'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      SoundHelper().playClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveAkunListPage(
                            tahun: tahun,
                            kelas: kelas,
                            akunList: akunList,
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

class ArchiveAkunListPage extends StatelessWidget {
  final String tahun;
  final String kelas;
  final List<AkunDigital> akunList;

  const ArchiveAkunListPage({
    super.key,
    required this.tahun,
    required this.kelas,
    required this.akunList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$kelas - $tahun')),
      body: ListView.builder(
        itemCount: akunList.length,
        itemBuilder: (context, index) {
          final a = akunList[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.grey),
              title: Text(
                a.namaSiswa ?? a.name,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              subtitle: Text(
                'Email: ${a.email} • ${a.penanggungJawab}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
                onPressed: () {
                  SoundHelper().playClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Akun sudah diarsipkan (lulus)')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}