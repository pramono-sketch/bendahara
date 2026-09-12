// lib/features/database_akun.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data.dart';
import '../helpers/sound_helper.dart';
import '../helpers/theme_helper.dart';
import '../helpers/scroll_reveal.dart';
import '../constants/appearance.dart';

// ============================================================
// HELPER COLORS (Disesuaikan agar Dark Mode berfungsi sempurna)
// ============================================================

Color _getPrimaryTextColor(AppThemeMode themeMode, ColorScheme colors) {
  if (ThemeHelper.isNeo(themeMode)) return AppColors.neoTextPrimary;
  if (ThemeHelper.isGlass(themeMode)) return AppColors.glassTextPrimary;
  if (ThemeHelper.isModern(themeMode)) return AppColors.modernTextPrimary;
  if (ThemeHelper.isAurora(themeMode)) return AppColors.auroraTextPrimary;
  if (ThemeHelper.isCyber(themeMode)) return AppColors.cyberTextPrimary;
  return colors.onSurface;
}

Color _getSecondaryTextColor(AppThemeMode themeMode, ColorScheme colors) {
  if (ThemeHelper.isNeo(themeMode)) return AppColors.neoTextSecondary;
  if (ThemeHelper.isGlass(themeMode)) return AppColors.glassTextSecondary;
  if (ThemeHelper.isModern(themeMode)) return AppColors.modernTextSecondary;
  if (ThemeHelper.isAurora(themeMode)) return AppColors.auroraTextSecondary;
  if (ThemeHelper.isCyber(themeMode)) return AppColors.cyberTextSecondary;
  return colors.onSurfaceVariant;
}

Color _getHeaderTextColor(AppThemeMode themeMode, ColorScheme colors) {
  if (ThemeHelper.isNeo(themeMode)) return AppColors.neoTextPrimary;
  if (ThemeHelper.isGlass(themeMode)) return AppColors.glassTextPrimary;
  if (ThemeHelper.isModern(themeMode)) return AppColors.modernTextPrimary;
  if (ThemeHelper.isAurora(themeMode)) return AppColors.auroraTextPrimary;
  if (ThemeHelper.isCyber(themeMode)) return AppColors.cyberAccent1;
  return colors.onSurface;
}

// ============================================================
// HALAMAN UTAMA
// ============================================================

class DatabaseAkunPage extends ConsumerStatefulWidget {
  const DatabaseAkunPage({super.key});

  @override
  ConsumerState<DatabaseAkunPage> createState() => _DatabaseAkunPageState();
}

class _DatabaseAkunPageState extends ConsumerState<DatabaseAkunPage>
    with SingleTickerProviderStateMixin {
  List<AkunDigital> _allAccounts = [];
  bool _isLoading = true;

  late TabController _tabController;
  String _filterKelasSiswa = 'Semua';
  String _searchQuery = '';

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _namaSiswaController = TextEditingController();
  final _emailController = TextEditingController();
  final _penanggungJawabController = TextEditingController();
  final _passwordController = TextEditingController();
  final _keteranganController = TextEditingController();

  String _selectedCategory = 'guru';
  String? _selectedKelas;

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

  // ============================================================
  // FIRESTORE INTEGRATION
  // ============================================================

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('akun_digital').get();
      if (mounted) {
        setState(() {
          _allAccounts = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return AkunDigital.fromJson(data);
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Gagal load akun: $e');
      _allAccounts = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAccount(AkunDigital account) async {
    try {
      await FirebaseFirestore.instance.collection('akun_digital').doc(account.id).set(account.toJson());
      await _loadAccounts();
    } catch (e) {
      debugPrint('Gagal tambah akun: $e');
    }
  }

  Future<void> _updateAccount(AkunDigital updated) async {
    try {
      await FirebaseFirestore.instance.collection('akun_digital').doc(updated.id).update(updated.toJson());
      await _loadAccounts();
    } catch (e) {
      debugPrint('Gagal update akun: $e');
    }
  }

  Future<void> _deleteAccount(String id) async {
    try {
      await FirebaseFirestore.instance.collection('akun_digital').doc(id).delete();
      await _loadAccounts();
    } catch (e) {
      debugPrint('Gagal hapus akun: $e');
    }
  }

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

    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);
    final bool isAurora = ThemeHelper.isAurora(themeMode);
    final bool isCyber = ThemeHelper.isCyber(themeMode);
    final bool isModern = ThemeHelper.isModern(themeMode);

    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    
    final dialogBackground = isGlass
        ? AppColors.glassBg1
        : isNeo
            ? AppColors.neoBase
            : isAurora
                ? AppColors.auroraSurface
                : isCyber
                    ? AppColors.cyberSurface
                    : isModern
                        ? AppColors.modernSurface
                        : colors.surface;

    final inputBackground = isGlass
        ? Colors.white.withValues(alpha: 0.12)
        : isNeo
            ? AppColors.neoBaseAlt
            : isAurora
                ? AppColors.auroraSurface
                : isCyber
                    ? AppColors.cyberSurface
                    : isModern
                        ? AppColors.modernSurface
                        : colors.surfaceContainerHighest;

    final inputBorder = isGlass
        ? Colors.white.withValues(alpha: 0.30)
        : isNeo
            ? AppColors.neoShadow.withValues(alpha: 0.25)
            : isModern
                ? AppColors.modernDivider
                : colors.outlineVariant;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: dialogBackground,
            surfaceTintColor: Colors.transparent,
            titleTextStyle: TextStyle(
              color: primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            contentTextStyle: TextStyle(color: primaryText),
            title: Text(existing == null ? 'Tambah Akun' : 'Edit Akun'),
            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: primaryText),
                        decoration: InputDecoration(
                          labelText: 'Nama Akun / Layanan',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      if (_selectedCategory == 'siswa') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _namaSiswaController,
                          style: TextStyle(color: primaryText),
                          decoration: InputDecoration(
                            labelText: 'Nama Siswa (untuk tampilan)',
                            labelStyle: TextStyle(color: secondaryText),
                            filled: true,
                            fillColor: inputBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        style: TextStyle(color: primaryText),
                        decoration: InputDecoration(
                          labelText: 'Email / Username',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _penanggungJawabController,
                        style: TextStyle(color: primaryText),
                        decoration: InputDecoration(
                          labelText: 'Penanggung Jawab',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(color: primaryText),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _keteranganController,
                        maxLines: 2,
                        style: TextStyle(color: primaryText),
                        decoration: InputDecoration(
                          labelText: 'Keterangan',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: dialogBackground,
                        style: TextStyle(color: primaryText),
                        iconEnabledColor: accentColor,
                        items: const [
                          DropdownMenuItem(value: 'guru', child: Text('Guru')),
                          DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setStateDialog(() {
                            _selectedCategory = val;
                            if (val == 'guru') {
                              _selectedKelas = null;
                              _namaSiswaController.clear();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          labelStyle: TextStyle(color: secondaryText),
                          filled: true,
                          fillColor: inputBackground,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: inputBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: accentColor,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_selectedCategory == 'siswa') ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedKelas,
                          dropdownColor: dialogBackground,
                          style: TextStyle(color: primaryText),
                          iconEnabledColor: accentColor,
                          hint: Text('Pilih Kelas', style: TextStyle(color: secondaryText)),
                          items: _kelasOptions
                              .where((k) => k != 'Semua')
                              .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                              .toList(),
                          onChanged: (val) {
                            setStateDialog(() => _selectedKelas = val);
                          },
                          decoration: InputDecoration(
                            labelText: 'Kelas',
                            labelStyle: TextStyle(color: secondaryText),
                            filled: true,
                            fillColor: inputBackground,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: inputBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: accentColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (v) => v == null ? 'Pilih kelas' : null,
                        ),
                      ],
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
                    final namaSiswa = _selectedCategory == 'siswa' ? _namaSiswaController.text.trim() : null;
                    final email = _emailController.text.trim();
                    final penanggungJawab = _penanggungJawabController.text.trim();
                    final password = _passwordController.text.trim();
                    final keterangan = _keteranganController.text.trim();
                    final category = _selectedCategory;
                    final kelas = category == 'siswa' ? _selectedKelas : null;

                    if (existing == null) {
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isGlass ? AppColors.glassBg1 : colors.onPrimary,
                ),
                child: Text(existing == null ? 'Tambah' : 'Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final dialogBackground = isGlass ? AppColors.glassBg1 : colors.surface;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: secondaryText),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _promoteClasses() async {
    final TextEditingController folderController = TextEditingController();
    final themeMode = ref.read(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);
    final bool isAurora = ThemeHelper.isAurora(themeMode);
    final bool isCyber = ThemeHelper.isCyber(themeMode);
    final bool isModern = ThemeHelper.isModern(themeMode);

    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    
    final dialogBackground = isGlass
        ? AppColors.glassBg1
        : isNeo
            ? AppColors.neoBase
            : isAurora
                ? AppColors.auroraSurface
                : isCyber
                    ? AppColors.cyberSurface
                    : isModern
                        ? AppColors.modernSurface
                        : colors.surface;

    final inputBackground = isGlass
        ? Colors.white.withValues(alpha: 0.12)
        : isNeo
            ? AppColors.neoBaseAlt
            : isAurora
                ? AppColors.auroraSurface
                : isCyber
                    ? AppColors.cyberSurface
                    : isModern
                        ? AppColors.modernSurface
                        : colors.surfaceContainerHighest;

    final inputBorder = isGlass
        ? Colors.white.withValues(alpha: 0.30)
        : isNeo
            ? AppColors.neoShadow.withValues(alpha: 0.25)
            : isModern
                ? AppColors.modernDivider
                : colors.outlineVariant;

    // Tampilkan dialog untuk mendapatkan nama folder
    final folderName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBackground,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: secondaryText),
        title: const Text('Verifikasi Kenaikan Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proses ini akan:\n'
              '• Mengarsipkan semua akun siswa kelas XII (lulus) ke arsip Firebase\n'
              '• Menaikkan kelas akun siswa X→XI, XI→XII\n\n'
              'Catatan: Akun siswa baru untuk kelas X harus ditambahkan secara manual.\n\n'
              'Masukkan nama folder untuk arsip (misal: "2025/2026" atau "Angkatan 2025"):',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: folderController,
              style: TextStyle(color: primaryText),
              decoration: InputDecoration(
                hintText: 'Nama folder arsip',
                hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.8)),
                filled: true,
                fillColor: inputBackground,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: accentColor,
                    width: 1.5,
                  ),
                ),
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
              Navigator.pop(ctx, folderController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: isGlass ? AppColors.glassBg1 : colors.onPrimary,
            ),
            child: const Text('Ya, Naikkan Kelas'),
          ),
        ],
      ),
    );

    // Jika user batal atau input kosong
    if (folderName == null) return;
    
    if (folderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama folder tidak boleh kosong!')),
      );
      return;
    }

    // Jalankan proses Firebase setelah dialog tertutup
    setState(() => _isLoading = true);

    try {
      // 1. Archive XII grader students
      final batch = FirebaseFirestore.instance.batch();
      final snapshot = await FirebaseFirestore.instance.collection('akun_digital')
          .where('category', isEqualTo: 'siswa')
          .where('kelas', whereIn: ['XII RPL', 'XII TKJ', 'XII TKR'])
          .get();
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final archiveRef = FirebaseFirestore.instance.collection('akun_digital_archive').doc(folderName).collection('accounts').doc(doc.id);
        batch.set(archiveRef, data);
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 2. Promote X and XI
      final batch2 = FirebaseFirestore.instance.batch();
      final promoteSnapshot = await FirebaseFirestore.instance.collection('akun_digital')
          .where('category', isEqualTo: 'siswa')
          .get();

      for (var doc in promoteSnapshot.docs) {
        final data = doc.data();
        final kelas = data['kelas'] as String?;
        if (kelas != null) {
          String newKelas = kelas;
          if (kelas.startsWith('XI ')) {
            newKelas = 'XII ' + kelas.substring(3);
          } else if (kelas.startsWith('X ')) {
            newKelas = 'XI ' + kelas.substring(2);
          }
          if (newKelas != kelas) {
            batch2.update(doc.reference, {'kelas': newKelas});
          }
        }
      }
      await batch2.commit();

      localLogs.insert(
        0,
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.edit,
          detail: 'Kenaikan kelas akun digital dengan arsip "$folderName"',
          timestamp: DateTime.now(),
        ),
      );

      await _loadAccounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kenaikan kelas berhasil! Arsip: "$folderName"')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  void _viewArchive() {
    SoundHelper().playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ArchiveAkunPage()),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final headerText = _getHeaderTextColor(themeMode, colors);

    final bool isGlass = ThemeHelper.isGlass(themeMode);
    final bool isNeo = ThemeHelper.isNeo(themeMode);
    final bool isAurora = ThemeHelper.isAurora(themeMode);
    final bool isCyber = ThemeHelper.isCyber(themeMode);
    final bool isModern = ThemeHelper.isModern(themeMode);

    final List<AkunDigital> guruList = _allAccounts
        .where((a) => a.category == 'guru')
        .where((a) => _matchesSearch(a))
        .toList();

    final List<AkunDigital> siswaList = _allAccounts
        .where((a) => a.category == 'siswa')
        .where((a) => a.kelas != 'Lulus')
        .where((a) {
          if (_filterKelasSiswa == 'Semua') return true;
          return a.kelas == _filterKelasSiswa;
        })
        .where((a) => _matchesSearch(a))
        .toList();

    final searchBackground = isGlass
        ? Colors.white.withValues(alpha: 0.14)
        : isNeo
            ? AppColors.neoBaseAlt
            : isAurora
                ? AppColors.auroraSurface
                : isCyber
                    ? AppColors.cyberSurface
                    : isModern
                        ? AppColors.modernSurface
                        : colors.surfaceContainerHighest;

    final searchBorder = isGlass
        ? Colors.white.withValues(alpha: 0.25)
        : isNeo
            ? AppColors.neoShadow.withValues(alpha: 0.20)
            : isModern
                ? AppColors.modernDivider
                : colors.outlineVariant;

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          backgroundColor: isNeo ? AppColors.neoBase : Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Database Akun Digital',
            style: TextStyle(color: headerText),
          ),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: accentColor,
            labelColor: headerText,
            unselectedLabelColor: secondaryText,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Guru'),
              Tab(icon: Icon(Icons.school), text: 'Siswa'),
            ],
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.archive, color: headerText),
              onPressed: _viewArchive,
              tooltip: 'Lihat Arsip Akun Digital',
            ),
            IconButton(
              icon: Icon(Icons.arrow_upward, color: headerText),
              onPressed: _promoteClasses,
              tooltip: 'Kenaikan Kelas',
            ),
            IconButton(
              icon: Icon(Icons.add, color: headerText),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                style: TextStyle(color: primaryText),
                cursorColor: accentColor,
                decoration: InputDecoration(
                  hintText: 'Cari akun...',
                  hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.8)),
                  prefixIcon: Icon(Icons.search, color: accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: searchBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: searchBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accentColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: searchBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAccountList(guruList, isGuru: true),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              'Filter Kelas:',
                              style: TextStyle(
                                color: primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _filterKelasSiswa,
                                dropdownColor: isGlass ? AppColors.glassBg1 : colors.surface,
                                style: TextStyle(color: primaryText),
                                iconEnabledColor: accentColor,
                                items: _kelasOptions.map((kelas) {
                                  return DropdownMenuItem(
                                    value: kelas,
                                    child: Text(kelas),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  SoundHelper().playClick();
                                  setState(() => _filterKelasSiswa = val);
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
      ),
    );
  }

  bool _matchesSearch(AkunDigital acc) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return acc.name.toLowerCase().contains(query) ||
        (acc.namaSiswa?.toLowerCase().contains(query) ?? false) ||
        acc.email.toLowerCase().contains(query) ||
        acc.penanggungJawab.toLowerCase().contains(query) ||
        (acc.kelas?.toLowerCase().contains(query) ?? false);
  }

  Widget _buildAccountList(List<AkunDigital> accounts, {required bool isGuru}) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isGuru ? Icons.person_outline : Icons.cast_for_education,
              size: 80,
              color: secondaryText.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada akun ${isGuru ? 'guru' : 'siswa aktif'}',
              style: TextStyle(
                fontSize: 18,
                color: primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + di atas untuk menambahkan',
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: accounts.length,
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemBuilder: (context, index) {
        final acc = accounts[index];
        return ScrollReveal(
          delay: Duration(milliseconds: 50 * index),
          child: _buildAccountCard(acc, themeMode),
        );
      },
    );
  }

  Widget _buildAccountCard(AkunDigital acc, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    final displayTitle = acc.name;
    final displaySubtitle = acc.category == 'siswa'
        ? (acc.namaSiswa?.isNotEmpty == true ? acc.namaSiswa! : '-')
        : acc.email;

    final Widget tile = ExpansionTile(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      textColor: primaryText,
      iconColor: accentColor,
      collapsedTextColor: primaryText,
      collapsedIconColor: secondaryText,
      leading: CircleAvatar(
        backgroundColor: isGlass ? Colors.white.withValues(alpha: 0.18) : accentColor,
        child: Icon(
          acc.category == 'guru' ? Icons.person : Icons.school,
          color: isGlass ? Colors.white : colors.onPrimary,
        ),
      ),
      title: Text(
        displayTitle,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      subtitle: Text(
        displaySubtitle,
        style: TextStyle(color: secondaryText),
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
                label: Text(
                  acc.kelas!,
                  style: TextStyle(
                    color: isGlass ? Colors.white : primaryText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: acc.kelas == 'Lulus'
                    ? secondaryText.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.14),
                side: BorderSide(color: accentColor.withValues(alpha: 0.20)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: accentColor),
            onPressed: () {
              SoundHelper().playClick();
              _showAccountDialog(existing: acc);
            },
            tooltip: 'Edit',
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
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
              if (acc.category == 'siswa' && acc.namaSiswa?.isNotEmpty == true)
                _infoRow('Nama Siswa', acc.namaSiswa!, themeMode),
              _infoRow('Layanan', acc.name, themeMode),
              _infoRow('Email', acc.email, themeMode),
              _infoRow('Penanggung Jawab', acc.penanggungJawab, themeMode),
              _infoRow('Keterangan', acc.keterangan, themeMode),
              _infoRow('Password', acc.password, themeMode),
              if (acc.category == 'siswa' && acc.kelas != null)
                _infoRow('Kelas', acc.kelas!, themeMode),
            ],
          ),
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: _buildThemedContainer(
        borderRadius: ThemeHelper.isCyber(themeMode) ? 12 : 18,
        child: tile,
      ),
    );
  }

  Widget _infoRow(String label, String value, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: secondaryText,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: primaryText,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemedContainer({
    required Widget child,
    double borderRadius = 18,
  }) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    if (ThemeHelper.isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(borderRadius: borderRadius, isPressed: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: child,
          ),
        ),
      );
    }
    if (ThemeHelper.isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: child,
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: child,
    );
  }
}

// ============================================================
// HALAMAN ARSIP AKUN DIGITAL
// ============================================================

class ArchiveAkunPage extends ConsumerWidget {
  const ArchiveAkunPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final headerText = _getHeaderTextColor(themeMode, colors);
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          backgroundColor: ThemeHelper.isNeo(themeMode) ? AppColors.neoBase : Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Arsip Akun Digital Siswa',
            style: TextStyle(color: headerText),
          ),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('akun_digital_archive').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: accentColor));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('Belum ada arsip akun digital', style: TextStyle(color: secondaryText)));
            }
            
            final tahunKeys = snapshot.data!.docs.map((doc) => doc.id).toList()..sort((a, b) => b.compareTo(a));
            
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tahunKeys.length,
              itemBuilder: (context, index) {
                final tahun = tahunKeys[index];

                return ScrollReveal(
                  delay: Duration(milliseconds: 50 * index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: _ArchiveThemeContainer(
                      themeMode: themeMode,
                      child: ListTile(
                        leading: Icon(
                          Icons.folder,
                          color: isGlass ? Colors.amberAccent : Colors.amber,
                        ),
                        title: Text(
                          tahun,
                          style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          'Lihat detail arsip',
                          style: TextStyle(color: secondaryText),
                        ),
                        trailing: Icon(Icons.chevron_right, color: secondaryText),
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
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN ARSIP PER KELAS
// ============================================================

class ArchiveAkunClassPage extends ConsumerWidget {
  final String tahun;

  const ArchiveAkunClassPage({super.key, required this.tahun});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;

    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final headerText = _getHeaderTextColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          backgroundColor: ThemeHelper.isNeo(themeMode) ? AppColors.neoBase : Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            'Arsip $tahun',
            style: TextStyle(color: headerText),
          ),
        ),
        body: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('akun_digital_archive').doc(tahun).collection('accounts').get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: ThemeHelper.getAccentColor(themeMode, colors)));
            }
            
            final akunList = snapshot.data?.docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              data['id'] = doc.id;
              return AkunDigital.fromJson(data);
            }).toList() ?? [];

            final Map<String, List<AkunDigital>> kelasMap = {};
            for (var acc in akunList) {
              kelasMap.putIfAbsent(acc.kelas ?? 'Lulus', () => []).add(acc);
            }
            final kelasKeys = kelasMap.keys.toList()..sort();

            if (kelasKeys.isEmpty) {
              return Center(child: Text('Kosong', style: TextStyle(color: secondaryText)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: kelasKeys.length,
              itemBuilder: (context, index) {
                final kelas = kelasKeys[index];
                final kelasAkunList = kelasMap[kelas]!;

                return ScrollReveal(
                  delay: Duration(milliseconds: 50 * index),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: _ArchiveThemeContainer(
                      themeMode: themeMode,
                      child: ListTile(
                        leading: Icon(Icons.folder_open, color: getMajorColor(kelas)),
                        title: Text(
                          kelas,
                          style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${kelasAkunList.length} akun',
                          style: TextStyle(color: secondaryText),
                        ),
                        trailing: Icon(Icons.chevron_right, color: secondaryText),
                        onTap: () {
                          SoundHelper().playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ArchiveAkunListPage(
                                tahun: tahun,
                                kelas: kelas,
                                akunList: kelasAkunList,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// HALAMAN DAFTAR ARSIP
// ============================================================

class ArchiveAkunListPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = Theme.of(context).colorScheme;
    final bool isGlass = ThemeHelper.isGlass(themeMode);

    final primaryText = _getPrimaryTextColor(themeMode, colors);
    final secondaryText = _getSecondaryTextColor(themeMode, colors);
    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);
    final headerText = _getHeaderTextColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
        appBar: AppBar(
          backgroundColor: ThemeHelper.isNeo(themeMode) ? AppColors.neoBase : Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text(
            '$kelas - $tahun',
            style: TextStyle(color: headerText),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: akunList.length,
          itemBuilder: (context, index) {
            final a = akunList[index];

            return ScrollReveal(
              delay: Duration(milliseconds: 50 * index),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: _ArchiveThemeContainer(
                  themeMode: themeMode,
                  child: ListTile(
                    leading: Icon(
                      Icons.account_circle,
                      color: isGlass ? Colors.white : secondaryText,
                    ),
                    title: Text(
                      a.namaSiswa ?? a.name,
                      style: TextStyle(color: primaryText, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(
                      'Email: ${a.email} • ${a.penanggungJawab}',
                      style: TextStyle(color: secondaryText),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_red_eye, color: accentColor),
                      onPressed: () {
                        SoundHelper().playClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Akun sudah diarsipkan (lulus)')),
                        );
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// CONTAINER TEMA UNTUK HALAMAN ARSIP
// ============================================================

class _ArchiveThemeContainer extends StatelessWidget {
  final AppThemeMode themeMode;
  final Widget child;

  const _ArchiveThemeContainer({
    required this.themeMode,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (ThemeHelper.isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(borderRadius: 18, isPressed: false),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: child,
          ),
        ),
      );
    }
    if (ThemeHelper.isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: 18),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: child,
        ),
      );
    }
    if (ThemeHelper.isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: child,
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}