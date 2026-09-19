// lib/features/database_akun.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data.dart';
import '../helpers/sound_helper.dart';
import '../helpers/theme_helper.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/custom_animation.dart';
import '../constants/appearance.dart';

// ============================================================
// HELPER COLORS
// ============================================================

Color _getPrimaryTextColor(
  AppThemeMode themeMode,
  ColorScheme colors,
) {
  if (ThemeHelper.isNeo(themeMode)) {
    return AppColors.neoTextPrimary;
  }

  if (ThemeHelper.isGlass(themeMode)) {
    return AppColors.glassTextPrimary;
  }

  if (ThemeHelper.isModern(themeMode)) {
    return AppColors.modernTextPrimary;
  }

  if (ThemeHelper.isAurora(themeMode)) {
    return AppColors.auroraTextPrimary;
  }

  if (ThemeHelper.isCyber(themeMode)) {
    return AppColors.cyberTextPrimary;
  }

  return colors.onSurface;
}

Color _getSecondaryTextColor(
  AppThemeMode themeMode,
  ColorScheme colors,
) {
  if (ThemeHelper.isNeo(themeMode)) {
    return AppColors.neoTextSecondary;
  }

  if (ThemeHelper.isGlass(themeMode)) {
    return AppColors.glassTextSecondary;
  }

  if (ThemeHelper.isModern(themeMode)) {
    return AppColors.modernTextSecondary;
  }

  if (ThemeHelper.isAurora(themeMode)) {
    return AppColors.auroraTextSecondary;
  }

  if (ThemeHelper.isCyber(themeMode)) {
    return AppColors.cyberTextSecondary;
  }

  return colors.onSurfaceVariant;
}

Color _getHeaderTextColor(
  AppThemeMode themeMode,
  ColorScheme colors,
) {
  if (ThemeHelper.isNeo(themeMode)) {
    return AppColors.neoTextPrimary;
  }

  if (ThemeHelper.isGlass(themeMode)) {
    return AppColors.glassTextPrimary;
  }

  if (ThemeHelper.isModern(themeMode)) {
    return AppColors.modernTextPrimary;
  }

  if (ThemeHelper.isAurora(themeMode)) {
    return AppColors.auroraTextPrimary;
  }

  if (ThemeHelper.isCyber(themeMode)) {
    return AppColors.cyberAccent1;
  }

  return colors.onSurface;
}

// ============================================================
// REFERENSI FIREBASE
// ============================================================

final _firestore = FirebaseFirestore.instance;

/// Akun digital biasa.
final _akunDigitalCollection =
    _firestore.collection('akun_digital');

/// Akun digital hasil/import.
final _akunDigitalImportCollection =
    _firestore.collection('digital_accounts');

/// Arsip akun digital siswa.
final _archiveAkunCollection =
    _firestore.collection('akun_digital_archive');

// ============================================================
// RESULT NAIK KELAS
// ============================================================

class _PromotionResult {
  final int archivedCount;
  final int promotedCount;

  const _PromotionResult({
    required this.archivedCount,
    required this.promotedCount,
  });
}

// ============================================================
// PAGE
// ============================================================

class DatabaseAkunPage extends ConsumerStatefulWidget {
  const DatabaseAkunPage({super.key});

  @override
  ConsumerState<DatabaseAkunPage> createState() =>
      _DatabaseAkunPageState();
}

class _DatabaseAkunPageState
    extends ConsumerState<DatabaseAkunPage>
    with SingleTickerProviderStateMixin {
  List<AkunDigital> _allAccounts = [];

  bool _isLoading = true;

  late TabController _tabController;

  String _filterKelasSiswa = 'Semua';
  String _searchQuery = '';

  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _namaSiswaController =
      TextEditingController();

  final _emailController =
      TextEditingController();

  final _penanggungJawabController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _keteranganController =
      TextEditingController();

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

    _tabController = TabController(
      length: 2,
      vsync: this,
    );

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
  // FIRESTORE - LOAD
  // ============================================================

  Future<void> _loadAccounts() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final snapshot =
          await _akunDigitalCollection.get();

      final accounts =
          snapshot.docs.map((doc) {
        final data =
            Map<String, dynamic>.from(
          doc.data(),
        );

        data['id'] = doc.id;

        return AkunDigital.fromJson(
          data,
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _allAccounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Gagal load akun digital: $e',
      );

      if (!mounted) return;

      setState(() {
        _allAccounts = [];
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FIRESTORE - ADD
  // ============================================================

  Future<void> _addAccount(
    AkunDigital account,
  ) async {
    try {
      await _akunDigitalCollection
          .doc(account.id)
          .set(account.toJson());

      await _loadAccounts();
    } catch (e) {
      debugPrint(
        'Gagal tambah akun: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menambah akun: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // FIRESTORE - UPDATE
  // ============================================================

  Future<void> _updateAccount(
    AkunDigital updated,
  ) async {
    try {
      await _akunDigitalCollection
          .doc(updated.id)
          .update(updated.toJson());

      await _loadAccounts();
    } catch (e) {
      debugPrint(
        'Gagal update akun: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui akun: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // FIRESTORE - DELETE
  // ============================================================

  Future<void> _deleteAccount(
    String id,
  ) async {
    try {
      await _akunDigitalCollection
          .doc(id)
          .delete();

      await _loadAccounts();
    } catch (e) {
      debugPrint(
        'Gagal hapus akun: $e',
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus akun: $e',
            ),
          ),
        );
      }
    }
  }

  // ============================================================
  // ACCOUNT DIALOG
  // ============================================================

  void _showAccountDialog({
    AkunDigital? existing,
  }) {
    if (existing != null) {
      _nameController.text =
          existing.name;

      _namaSiswaController.text =
          existing.namaSiswa ?? '';

      _emailController.text =
          existing.email;

      _penanggungJawabController.text =
          existing.penanggungJawab;

      _passwordController.text =
          existing.password;

      _keteranganController.text =
          existing.keterangan;

      _selectedCategory =
          existing.category;

      _selectedKelas =
          existing.kelas;
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

    final themeMode =
        ref.read(themeModeProvider);

    final colors =
        Theme.of(context).colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(themeMode);

    final bool isNeo =
        ThemeHelper.isNeo(themeMode);

    final bool isAurora =
        ThemeHelper.isAurora(themeMode);

    final bool isCyber =
        ThemeHelper.isCyber(themeMode);

    final bool isModern =
        ThemeHelper.isModern(themeMode);

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

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
        ? Colors.white.withValues(
            alpha: 0.12,
          )
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
        ? Colors.white.withValues(
            alpha: 0.30,
          )
        : isNeo
            ? AppColors.neoShadow.withValues(
                alpha: 0.25,
              )
            : isModern
                ? AppColors.modernDivider
                : colors.outlineVariant;

    showDialog(
      context: context,
      builder: (ctx) =>
          StatefulBuilder(
        builder: (
          ctx,
          setStateDialog,
        ) {
          return AlertDialog(
            backgroundColor:
                dialogBackground,

            surfaceTintColor:
                Colors.transparent,

            titleTextStyle:
                TextStyle(
              color: primaryText,
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),

            contentTextStyle:
                TextStyle(
              color: primaryText,
            ),

            title: Text(
              existing == null
                  ? 'Tambah Akun'
                  : 'Edit Akun',
            ),

            content: SizedBox(
              width: double.maxFinite,
              child: Form(
                key: _formKey,
                child:
                    SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller:
                            _nameController,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Nama Akun / Layanan',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                        validator:
                            (v) {
                          if (v ==
                                  null ||
                              v
                                  .trim()
                                  .isEmpty) {
                            return 'Wajib diisi';
                          }

                          return null;
                        },
                      ),

                      if (_selectedCategory ==
                          'siswa') ...[
                        const SizedBox(
                          height: 12,
                        ),

                        TextFormField(
                          controller:
                              _namaSiswaController,
                          style:
                              TextStyle(
                            color:
                                primaryText,
                          ),
                          decoration:
                              InputDecoration(
                            labelText:
                                'Nama Siswa (untuk tampilan)',
                            labelStyle:
                                TextStyle(
                              color:
                                  secondaryText,
                            ),
                            filled: true,
                            fillColor:
                                inputBackground,
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    inputBorder,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    accentColor,
                                width:
                                    1.5,
                              ),
                            ),
                          ),
                          validator:
                              (v) {
                            if (v ==
                                    null ||
                                v
                                    .trim()
                                    .isEmpty) {
                              return 'Wajib diisi';
                            }

                            return null;
                          },
                        ),
                      ],

                      const SizedBox(
                        height: 12,
                      ),

                      TextFormField(
                        controller:
                            _emailController,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Email / Username',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                        validator:
                            (v) {
                          if (v ==
                                  null ||
                              v
                                  .trim()
                                  .isEmpty) {
                            return 'Wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextFormField(
                        controller:
                            _penanggungJawabController,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Penanggung Jawab',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextFormField(
                        controller:
                            _passwordController,
                        obscureText: true,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Password',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                        validator:
                            (v) {
                          if (v ==
                                  null ||
                              v
                                  .trim()
                                  .isEmpty) {
                            return 'Wajib diisi';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      TextFormField(
                        controller:
                            _keteranganController,
                        maxLines: 2,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        decoration:
                            InputDecoration(
                          labelText:
                              'Keterangan',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      DropdownButtonFormField<
                          String>(
                        value:
                            _selectedCategory,
                        dropdownColor:
                            dialogBackground,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                        ),
                        iconEnabledColor:
                            accentColor,
                        items: const [
                          DropdownMenuItem(
                            value: 'guru',
                            child:
                                Text(
                              'Guru',
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'siswa',
                            child:
                                Text(
                              'Siswa',
                            ),
                          ),
                        ],
                        onChanged:
                            (val) {
                          if (val ==
                              null) {
                            return;
                          }

                          setStateDialog(
                            () {
                              _selectedCategory =
                                  val;

                              if (val ==
                                  'guru') {
                                _selectedKelas =
                                    null;

                                _namaSiswaController
                                    .clear();
                              }
                            },
                          );
                        },
                        decoration:
                            InputDecoration(
                          labelText:
                              'Kategori',
                          labelStyle:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                          filled: true,
                          fillColor:
                              inputBackground,
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  inputBorder,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              14,
                            ),
                            borderSide:
                                BorderSide(
                              color:
                                  accentColor,
                              width:
                                  1.5,
                            ),
                          ),
                        ),
                      ),

                      if (_selectedCategory ==
                          'siswa') ...[
                        const SizedBox(
                          height: 12,
                        ),

                        DropdownButtonFormField<
                            String>(
                          value:
                              _selectedKelas,
                          dropdownColor:
                              dialogBackground,
                          style:
                              TextStyle(
                            color:
                                primaryText,
                          ),
                          iconEnabledColor:
                              accentColor,
                          hint: Text(
                            'Pilih Kelas',
                            style:
                                TextStyle(
                              color:
                                  secondaryText,
                            ),
                          ),
                          items:
                              _kelasOptions
                                  .where(
                            (k) =>
                                k !=
                                'Semua',
                          )
                                  .map(
                            (k) =>
                                DropdownMenuItem<
                                    String>(
                              value: k,
                              child:
                                  Text(k),
                            ),
                          ).toList(),
                          onChanged:
                              (val) {
                            setStateDialog(
                              () {
                                _selectedKelas =
                                    val;
                              },
                            );
                          },
                          decoration:
                              InputDecoration(
                            labelText:
                                'Kelas',
                            labelStyle:
                                TextStyle(
                              color:
                                  secondaryText,
                            ),
                            filled:
                                true,
                            fillColor:
                                inputBackground,
                            enabledBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    inputBorder,
                              ),
                            ),
                            focusedBorder:
                                OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(
                                14,
                              ),
                              borderSide:
                                  BorderSide(
                                color:
                                    accentColor,
                                width:
                                    1.5,
                              ),
                            ),
                          ),
                          validator:
                              (v) {
                            if (v ==
                                null) {
                              return 'Pilih kelas';
                            }

                            return null;
                          },
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
                  SoundHelper()
                      .playClick();

                  Navigator.pop(
                    ctx,
                  );
                },
                child:
                    const Text(
                  'Batal',
                ),
              ),

              ElevatedButton(
                onPressed: () {
                  SoundHelper()
                      .playClick();

                  if (!_formKey
                      .currentState!
                      .validate()) {
                    return;
                  }

                  final name =
                      _nameController
                          .text
                          .trim();

                  final namaSiswa =
                      _selectedCategory ==
                              'siswa'
                          ? _namaSiswaController
                              .text
                              .trim()
                          : null;

                  final email =
                      _emailController
                          .text
                          .trim();

                  final penanggungJawab =
                      _penanggungJawabController
                          .text
                          .trim();

                  final password =
                      _passwordController
                          .text
                          .trim();

                  final keterangan =
                      _keteranganController
                          .text
                          .trim();

                  final category =
                      _selectedCategory;

                  final kelas =
                      category ==
                              'siswa'
                          ? _selectedKelas
                          : null;

                  if (existing ==
                      null) {
                    final newAccount =
                        AkunDigital(
                      id: DateTime.now()
                          .millisecondsSinceEpoch
                          .toString(),
                      name: name,
                      namaSiswa:
                          namaSiswa,
                      email: email,
                      penanggungJawab:
                          penanggungJawab,
                      password:
                          password,
                      keterangan:
                          keterangan,
                      category:
                          category,
                      kelas: kelas,
                    );

                    _addAccount(
                      newAccount,
                    );

                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Akun berhasil ditambahkan',
                        ),
                      ),
                    );
                  } else {
                    final updated =
                        AkunDigital(
                      id: existing.id,
                      name: name,
                      namaSiswa:
                          namaSiswa,
                      email: email,
                      penanggungJawab:
                          penanggungJawab,
                      password:
                          password,
                      keterangan:
                          keterangan,
                      category:
                          category,
                      kelas: kelas,
                    );

                    _updateAccount(
                      updated,
                    );

                    ScaffoldMessenger
                        .of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Akun berhasil diperbarui',
                        ),
                      ),
                    );
                  }

                  Navigator.pop(
                    ctx,
                  );
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      accentColor,
                  foregroundColor:
                      isGlass
                          ? AppColors
                              .glassBg1
                          : colors
                              .onPrimary,
                ),
                child: Text(
                  existing ==
                          null
                      ? 'Tambah'
                      : 'Simpan',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // DELETE CONFIRMATION
  // ============================================================

  void _showDeleteConfirmation(
    String id,
    String name,
  ) {
    final themeMode =
        ref.read(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final dialogBackground =
        isGlass
            ? AppColors.glassBg1
            : colors.surface;

    showDialog(
      context: context,
      builder: (ctx) =>
          AlertDialog(
        backgroundColor:
            dialogBackground,

        surfaceTintColor:
            Colors.transparent,

        titleTextStyle:
            TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
        ),

        contentTextStyle:
            TextStyle(
          color: secondaryText,
        ),

        title: const Text(
          'Hapus Akun',
        ),

        content: Text(
          'Yakin ingin menghapus akun "$name"?',
        ),

        actions: [
          TextButton(
            onPressed: () {
              SoundHelper()
                  .playClick();

              Navigator.pop(
                ctx,
              );
            },
            child:
                const Text('Batal'),
          ),

          ElevatedButton(
            onPressed: () async {
              SoundHelper()
                  .playClick();

              await _deleteAccount(
                id,
              );

              if (!ctx.mounted) {
                return;
              }

              Navigator.pop(
                ctx,
              );

              if (mounted) {
                ScaffoldMessenger
                    .of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Akun berhasil dihapus',
                    ),
                  ),
                );
              }
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  colors.error,
              foregroundColor:
                  Colors.white,
            ),
            child:
                const Text(
              'Hapus',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER FOLDER
  // ============================================================

  String _sanitizeFolderId(
    String value,
  ) {
    final cleaned = value
        .trim()
        .replaceAll(
          '/',
          '-',
        )
        .replaceAll(
          '\\',
          '-',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );

    return cleaned;
  }

  // ============================================================
  // EXTRACT CLASS
  // ============================================================

  String? _extractClass(
    Map<String, dynamic> data,
  ) {
    final candidates = [
      data['kelas'],
      data['class'],
      data['kelasSiswa'],
      data['studentClass'],
    ];

    for (final candidate
        in candidates) {
      if (candidate == null) {
        continue;
      }

      final value =
          candidate.toString().trim();

      if (value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  // ============================================================
  // CHECK STUDENT ACCOUNT
  // ============================================================

  bool _isStudentAccountDocument(
    Map<String, dynamic> data,
  ) {
    final rawCategory =
        data['category'] ??
            data['kategori'] ??
            data['role'];

    final category =
        rawCategory
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (category == 'siswa' ||
        category == 'student') {
      return true;
    }

    final kelas =
        _extractClass(data);

    if (kelas != null &&
        _isKnownStudentClass(
          kelas,
        )) {
      return true;
    }

    final namaSiswa =
        data['namaSiswa'] ??
            data['nama_siswa'];

    if (namaSiswa != null &&
        namaSiswa
            .toString()
            .trim()
            .isNotEmpty &&
        kelas != null) {
      return true;
    }

    return false;
  }

  // ============================================================
  // CHECK CLASS
  // ============================================================

  bool _isKnownStudentClass(
    String kelas,
  ) {
    final value =
        kelas.trim().toUpperCase();

    return value.startsWith(
          'X ',
        ) ||
        value.startsWith(
          'XI ',
        ) ||
        value.startsWith(
          'XII ',
        );
  }

  // ============================================================
  // NEXT CLASS
  // ============================================================

  String? _getNextClass(
    String kelas,
  ) {
    final value =
        kelas.trim();

    if (value.startsWith(
      'XII ',
    )) {
      return null;
    }

    if (value.startsWith(
      'XI ',
    )) {
      return 'XII ${value.substring(3)}';
    }

    if (value.startsWith(
      'X ',
    )) {
      return 'XI ${value.substring(2)}';
    }

    return value;
  }

  // ============================================================
  // BATCH
  // ============================================================

  Future<void> _commitBatchOperations(
    List<void Function(WriteBatch)> operations,
  ) async {
    const maxOperationsPerBatch = 450;

    if (operations.isEmpty) {
      return;
    }

    for (
      int start = 0;
      start < operations.length;
      start += maxOperationsPerBatch
    ) {
      final end =
          (start +
                  maxOperationsPerBatch <
              operations.length)
              ? start +
                  maxOperationsPerBatch
              : operations.length;

      final batch =
          _firestore.batch();

      for (
        int i = start;
        i < end;
        i++
      ) {
        operations[i](
          batch,
        );
      }

      await batch.commit();
    }
  }

  // ============================================================
  // PREPARE COLLECTION
  // ============================================================

  Future<({
    int archived,
    int promoted,
    List<void Function(WriteBatch)> operations,
  })> _preparePromotionForCollection({
    required CollectionReference<
            Map<String, dynamic>>
        collection,
    required String sourceName,
    required String folderId,
    required String folderDisplayName,
  }) async {
    final snapshot =
        await collection.get();

    int archivedCount = 0;
    int promotedCount = 0;

    final operations =
        <void Function(WriteBatch)>[];

    for (final doc
        in snapshot.docs) {
      final data =
          Map<String, dynamic>.from(
        doc.data(),
      );

      if (!_isStudentAccountDocument(
        data,
      )) {
        continue;
      }

      final kelas =
          _extractClass(data);

      if (kelas == null ||
          !_isKnownStudentClass(
            kelas,
          )) {
        continue;
      }

      final archiveRef =
          _archiveAkunCollection
              .doc(folderId)
              .collection('accounts')
              .doc(
                '${sourceName}__${doc.id}',
              );

      // ========================================================
      // XII -> ARSIP
      // ========================================================

      if (kelas.startsWith(
        'XII ',
      )) {
        final archiveData =
            Map<String, dynamic>.from(
          data,
        );

        archiveData['id'] =
            data['id'] ??
                doc.id;

        if (archiveData['category'] ==
                null ||
            archiveData['category']
                .toString()
                .trim()
                .isEmpty) {
          archiveData['category'] =
              'siswa';
        }

        archiveData['kelas'] =
            kelas;

        archiveData['kelasAsal'] =
            kelas;

        archiveData['status'] =
            'Lulus';

        archiveData['sumberAkun'] =
            sourceName;

        archiveData['tahunArsip'] =
            folderDisplayName;

        archiveData['archivedAt'] =
            FieldValue.serverTimestamp();

        operations.add(
          (batch) {
            batch.set(
              archiveRef,
              archiveData,
              SetOptions(
                merge: true,
              ),
            );

            batch.delete(
              doc.reference,
            );
          },
        );

        archivedCount++;

        continue;
      }

      // ========================================================
      // X -> XI / XI -> XII
      // ========================================================

      final nextClass =
          _getNextClass(
        kelas,
      );

      if (nextClass != null &&
          nextClass != kelas) {
        operations.add(
          (batch) {
            batch.update(
              doc.reference,
              {
                'kelas': nextClass,
                'updatedAt':
                    FieldValue
                        .serverTimestamp(),
              },
            );
          },
        );

        promotedCount++;
      }
    }

    return (
      archived: archivedCount,
      promoted: promotedCount,
      operations: operations,
    );
  }

  // ============================================================
  // RUN PROMOTION
  // ============================================================

  Future<_PromotionResult>
      _runClassPromotion({
    required String folderId,
    required String folderDisplayName,
  }) async {
    final allOperations =
        <void Function(WriteBatch)>[];

    // ==========================================================
    // AKUN DIGITAL
    // ==========================================================

    final normalResult =
        await _preparePromotionForCollection(
      collection:
          _akunDigitalCollection,
      sourceName:
          'akun_digital',
      folderId: folderId,
      folderDisplayName:
          folderDisplayName,
    );

    allOperations.addAll(
      normalResult.operations,
    );

    // ==========================================================
    // AKUN DIGITAL IMPORT
    // ==========================================================

    final importResult =
        await _preparePromotionForCollection(
      collection:
          _akunDigitalImportCollection,
      sourceName:
          'digital_accounts',
      folderId: folderId,
      folderDisplayName:
          folderDisplayName,
    );

    allOperations.addAll(
      importResult.operations,
    );

    final archivedCount =
        normalResult.archived +
            importResult.archived;

    final promotedCount =
        normalResult.promoted +
            importResult.promoted;

    // ==========================================================
    // FOLDER ARSIP
    // ==========================================================

    if (archivedCount > 0) {
      final folderRef =
          _archiveAkunCollection
              .doc(folderId);

      allOperations.insert(
        0,
        (batch) {
          batch.set(
            folderRef,
            {
              'namaArsip':
                  folderDisplayName,
              'tahunArsip':
                  folderDisplayName,
              'updatedAt':
                  FieldValue
                      .serverTimestamp(),
              'jenis':
                  'arsip_akun_digital_siswa',
            },
            SetOptions(
              merge: true,
            ),
          );
        },
      );
    }

    await _commitBatchOperations(
      allOperations,
    );

    return _PromotionResult(
      archivedCount:
          archivedCount,
      promotedCount:
          promotedCount,
    );
  }

  // ============================================================
  // PROMOTE CLASSES
  // ============================================================

  Future<void> _promoteClasses() async {
    final folderController =
        TextEditingController();

    final themeMode =
        ref.read(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final bool isNeo =
        ThemeHelper.isNeo(
      themeMode,
    );

    final bool isAurora =
        ThemeHelper.isAurora(
      themeMode,
    );

    final bool isCyber =
        ThemeHelper.isCyber(
      themeMode,
    );

    final bool isModern =
        ThemeHelper.isModern(
      themeMode,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final dialogBackground =
        isGlass
            ? AppColors.glassBg1
            : isNeo
                ? AppColors.neoBase
                : isAurora
                    ? AppColors
                        .auroraSurface
                    : isCyber
                        ? AppColors
                            .cyberSurface
                        : isModern
                            ? AppColors
                                .modernSurface
                            : colors
                                .surface;

    final inputBackground =
        isGlass
            ? Colors.white.withValues(
                alpha: 0.12,
              )
            : isNeo
                ? AppColors.neoBaseAlt
                : isAurora
                    ? AppColors
                        .auroraSurface
                    : isCyber
                        ? AppColors
                            .cyberSurface
                        : isModern
                            ? AppColors
                                .modernSurface
                            : colors
                                .surfaceContainerHighest;

    final inputBorder =
        isGlass
            ? Colors.white.withValues(
                alpha: 0.30,
              )
            : isNeo
                ? AppColors.neoShadow
                    .withValues(
                    alpha: 0.25,
                  )
                : isModern
                    ? AppColors
                        .modernDivider
                    : colors
                        .outlineVariant;

    final folderName =
        await showDialog<String>(
      context: context,
      builder: (ctx) =>
          AlertDialog(
        backgroundColor:
            dialogBackground,

        surfaceTintColor:
            Colors.transparent,

        titleTextStyle:
            TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight:
              FontWeight.bold,
        ),

        contentTextStyle:
            TextStyle(
          color: secondaryText,
        ),

        title: const Text(
          'Verifikasi Kenaikan Kelas',
        ),

        content: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Proses ini akan:\n\n'
              '• Kelas X siswa → XI\n'
              '• Kelas XI siswa → XII\n'
              '• Kelas XII siswa → Arsip\n'
              '• Akun dari "akun_digital" ikut diproses\n'
              '• Akun dari "digital_accounts" / import ikut diproses\n'
              '• Akun XII disimpan ke Firebase sebelum dihapus dari akun aktif\n\n'
              'Masukkan nama folder arsip.\n'
              'Contoh: 2025/2026',
            ),

            const SizedBox(
              height: 12,
            ),

            TextField(
              controller:
                  folderController,
              style: TextStyle(
                color: primaryText,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    'Nama folder arsip',
                hintStyle:
                    TextStyle(
                  color:
                      secondaryText
                          .withValues(
                    alpha: 0.8,
                  ),
                ),
                filled: true,
                fillColor:
                    inputBackground,
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  borderSide:
                      BorderSide(
                    color:
                        inputBorder,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                  borderSide:
                      BorderSide(
                    color:
                        accentColor,
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
              SoundHelper()
                  .playClick();

              Navigator.pop(
                ctx,
              );
            },
            child:
                const Text(
              'Batal',
            ),
          ),

          ElevatedButton(
            onPressed: () {
              SoundHelper()
                  .playClick();

              final value =
                  folderController
                      .text
                      .trim();

              if (value.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Nama folder tidak boleh kosong.',
                    ),
                  ),
                );

                return;
              }

              Navigator.pop(
                ctx,
                value,
              );
            },
            style:
                ElevatedButton.styleFrom(
              backgroundColor:
                  accentColor,
              foregroundColor:
                  isGlass
                      ? AppColors
                          .glassBg1
                      : colors.onPrimary,
            ),
            child:
                const Text(
              'Ya, Naikkan Kelas',
            ),
          ),
        ],
      ),
    );

    folderController.dispose();

    if (folderName == null) {
      return;
    }

    final cleanDisplayName =
        folderName.trim();

    if (cleanDisplayName.isEmpty) {
      return;
    }

    final folderId =
        _sanitizeFolderId(
      cleanDisplayName,
    );

    if (folderId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(
            content: Text(
              'Nama folder tidak valid.',
            ),
          ),
        );
      }

      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result =
          await _runClassPromotion(
        folderId:
            folderId,
        folderDisplayName:
            cleanDisplayName,
      );

      await _loadAccounts();

      await recordActivityLog(
        action:
            ActivityAction.edit,
        detail:
            'Kenaikan kelas siswa: '
            '${result.promotedCount} akun dinaikkan, '
            '${result.archivedCount} akun kelas XII diarsipkan '
            'ke "$cleanDisplayName".',
      );

      if (!mounted) {
        return;
      }

      String message;

      if (result.promotedCount ==
              0 &&
          result.archivedCount ==
              0) {
        message =
            'Tidak ada akun siswa yang perlu diproses.';
      } else {
        message =
            'Kenaikan kelas berhasil.\n'
            'Naik kelas: ${result.promotedCount}\n'
            'Diarsipkan: ${result.archivedCount}';
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content:
              Text(message),
        ),
      );
    } catch (
      e,
      stackTrace
    ) {
      debugPrint(
        'Gagal proses kenaikan kelas: $e',
      );

      debugPrintStack(
        stackTrace:
            stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal melakukan kenaikan kelas: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // VIEW ARCHIVE
  // ============================================================

  void _viewArchive() {
    SoundHelper().playClick();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ArchiveAkunPage(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final headerText =
        _getHeaderTextColor(
      themeMode,
      colors,
    );

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final bool isNeo =
        ThemeHelper.isNeo(
      themeMode,
    );

    final bool isAurora =
        ThemeHelper.isAurora(
      themeMode,
    );

    final bool isCyber =
        ThemeHelper.isCyber(
      themeMode,
    );

    final bool isModern =
        ThemeHelper.isModern(
      themeMode,
    );

    final guruList =
        _allAccounts
            .where(
              (a) =>
                  a.category ==
                  'guru',
            )
            .where(
              _matchesSearch,
            )
            .toList();

    final siswaList =
        _allAccounts
            .where(
              (a) =>
                  a.category ==
                  'siswa',
            )
            .where(
              (a) =>
                  a.kelas !=
                  'Lulus',
            )
            .where(
          (a) {
            if (_filterKelasSiswa ==
                'Semua') {
              return true;
            }

            return a.kelas ==
                _filterKelasSiswa;
          },
        )
            .where(
              _matchesSearch,
            )
            .toList();

    final searchBackground =
        isGlass
            ? Colors.white
                .withValues(
                alpha: 0.14,
              )
            : isNeo
                ? AppColors
                    .neoBaseAlt
                : isAurora
                    ? AppColors
                        .auroraSurface
                    : isCyber
                        ? AppColors
                            .cyberSurface
                        : isModern
                            ? AppColors
                                .modernSurface
                            : colors
                                .surfaceContainerHighest;

    final searchBorder =
        isGlass
            ? Colors.white
                .withValues(
                alpha: 0.25,
              )
            : isNeo
                ? AppColors
                    .neoShadow
                    .withValues(
                    alpha: 0.20,
                  )
                : isModern
                    ? AppColors
                        .modernDivider
                    : colors
                        .outlineVariant;

    return ThemeHelper
        .buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor:
            ThemeHelper
                .getScaffoldBackgroundColor(
          themeMode,
          colors,
        ),

        appBar: AppBar(
          backgroundColor:
              isNeo
                  ? AppColors.neoBase
                  : Colors.transparent,

          elevation: 0,

          scrolledUnderElevation:
              0,

          surfaceTintColor:
              Colors.transparent,

          title: Text(
            'Database Akun Digital',
            style: TextStyle(
              color: headerText,
            ),
          ),

          bottom: TabBar(
            controller:
                _tabController,

            indicatorColor:
                accentColor,

            labelColor:
                headerText,

            unselectedLabelColor:
                secondaryText,

            tabs: const [
              Tab(
                icon:
                    Icon(
                  Icons.person,
                ),
                text: 'Guru',
              ),
              Tab(
                icon:
                    Icon(
                  Icons.school,
                ),
                text: 'Siswa',
              ),
            ],
          ),

          actions: [
            IconButton(
              icon: Icon(
                Icons.archive,
                color:
                    headerText,
              ),
              onPressed:
                  _viewArchive,
              tooltip:
                  'Lihat Arsip Akun Digital',
            ),

            IconButton(
              icon: Icon(
                Icons.arrow_upward,
                color:
                    headerText,
              ),
              onPressed:
                  _promoteClasses,
              tooltip:
                  'Kenaikan Kelas',
            ),

            IconButton(
              icon: Icon(
                Icons.add,
                color:
                    headerText,
              ),
              onPressed: () {
                SoundHelper()
                    .playClick();

                _showAccountDialog();
              },
              tooltip:
                  'Tambah Akun',
            ),
          ],
        ),

        body:
            Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets
                      .all(
                8,
              ),
              child:
                  TextField(
                style:
                    TextStyle(
                  color:
                      primaryText,
                ),

                cursorColor:
                    accentColor,

                decoration:
                    InputDecoration(
                  hintText:
                      'Cari akun...',
                  hintStyle:
                      TextStyle(
                    color:
                        secondaryText
                            .withValues(
                      alpha:
                          0.8,
                    ),
                  ),
                  prefixIcon:
                      Icon(
                    Icons.search,
                    color:
                        accentColor,
                  ),
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          searchBorder,
                    ),
                  ),
                  enabledBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          searchBorder,
                    ),
                  ),
                  focusedBorder:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                    borderSide:
                        BorderSide(
                      color:
                          accentColor,
                      width:
                          1.5,
                    ),
                  ),
                  filled: true,
                  fillColor:
                      searchBackground,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 0,
                  ),
                ),

                onChanged:
                    (value) {
                  setState(
                    () {
                      _searchQuery =
                          value
                              .toLowerCase();
                    },
                  );
                },
              ),
            ),

            Expanded(
              child:
                  TabBarView(
                controller:
                    _tabController,
                children: [
                  _buildAccountList(
                    guruList,
                    isGuru:
                        true,
                  ),

                  Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets
                                .all(
                          8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Filter Kelas:',
                              style:
                                  TextStyle(
                                color:
                                    primaryText,
                                fontWeight:
                                    FontWeight
                                        .w500,
                              ),
                            ),

                            const SizedBox(
                              width: 8,
                            ),

                            Expanded(
                              child:
                                  DropdownButton<
                                      String>(
                                value:
                                    _filterKelasSiswa,

                                dropdownColor:
                                    isGlass
                                        ? AppColors
                                            .glassBg1
                                        : colors
                                            .surface,

                                style:
                                    TextStyle(
                                  color:
                                      primaryText,
                                ),

                                iconEnabledColor:
                                    accentColor,

                                items:
                                    _kelasOptions
                                        .map(
                                  (
                                    kelas,
                                  ) {
                                    return DropdownMenuItem<
                                        String>(
                                      value:
                                          kelas,
                                      child:
                                          Text(
                                        kelas,
                                      ),
                                    );
                                  },
                                ).toList(),

                                onChanged:
                                    (val) {
                                  if (val ==
                                      null) {
                                    return;
                                  }

                                  SoundHelper()
                                      .playClick();

                                  setState(
                                    () {
                                      _filterKelasSiswa =
                                          val;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      Expanded(
                        child:
                            _buildAccountList(
                          siswaList,
                          isGuru:
                              false,
                        ),
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

  // ============================================================
  // SEARCH
  // ============================================================

  bool _matchesSearch(
    AkunDigital acc,
  ) {
    if (_searchQuery
        .isEmpty) {
      return true;
    }

    final query =
        _searchQuery
            .toLowerCase();

    return acc.name
            .toLowerCase()
            .contains(query) ||
        (acc.namaSiswa
                ?.toLowerCase()
                .contains(query) ??
            false) ||
        acc.email
            .toLowerCase()
            .contains(query) ||
        acc.penanggungJawab
            .toLowerCase()
            .contains(query) ||
        (acc.kelas
                ?.toLowerCase()
                .contains(query) ??
            false);
  }

  // ============================================================
  // ACCOUNT LIST
  // ============================================================

  Widget _buildAccountList(
    List<AkunDigital> accounts, {
    required bool isGuru,
  }) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    if (_isLoading) {
      return Center(
        child:
            CircularProgressIndicator(
          color:
              accentColor,
        ),
      );
    }

    // ==========================================================
    // EMPTY DATA -> LOTTIE ERROR 404
    // ==========================================================

    if (accounts.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              const LottieError(
                size: 190,
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Belum ada akun '
                '${isGuru ? 'guru' : 'siswa aktif'}',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 18,
                  color:
                      primaryText,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              Text(
                'Tekan tombol + di atas '
                'untuk menambahkan',
                textAlign:
                    TextAlign.center,
                style:
                    TextStyle(
                  fontSize: 14,
                  color:
                      secondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount:
          accounts.length,

      padding:
          const EdgeInsets.only(
        top: 4,
        bottom: 12,
      ),

      itemBuilder:
          (context, index) {
        final acc =
            accounts[index];

        return ScrollReveal(
          delay: Duration(
            milliseconds:
                50 * index,
          ),
          child:
              _buildAccountCard(
            acc,
            themeMode,
          ),
        );
      },
    );
  }

  // ============================================================
  // ACCOUNT CARD
  // ============================================================

  Widget _buildAccountCard(
    AkunDigital acc,
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final displayTitle =
        acc.name;

    final displaySubtitle =
        acc.category ==
                'siswa'
            ? (acc.namaSiswa
                        ?.isNotEmpty ==
                    true
                ? acc.namaSiswa!
                : '-')
            : acc.email;

    final tile =
        ExpansionTile(
      backgroundColor:
          Colors.transparent,

      collapsedBackgroundColor:
          Colors.transparent,

      textColor:
          primaryText,

      iconColor:
          accentColor,

      collapsedTextColor:
          primaryText,

      collapsedIconColor:
          secondaryText,

      leading:
          CircleAvatar(
        backgroundColor:
            isGlass
                ? Colors.white
                    .withValues(
                    alpha:
                        0.18,
                  )
                : accentColor,

        child: Icon(
          acc.category ==
                  'guru'
              ? Icons.person
              : Icons.school,

          color: isGlass
              ? Colors.white
              : colors.onPrimary,
        ),
      ),

      title: Text(
        displayTitle,
        style: TextStyle(
          fontWeight:
              FontWeight.bold,
          color:
              primaryText,
        ),
        overflow:
            TextOverflow.ellipsis,
        maxLines: 1,
      ),

      subtitle: Text(
        displaySubtitle,
        style: TextStyle(
          color:
              secondaryText,
        ),
        overflow:
            TextOverflow.ellipsis,
        maxLines: 1,
      ),

      onExpansionChanged:
          (_) =>
              SoundHelper()
                  .playClick(),

      trailing:
          Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          if (acc.category ==
                  'siswa' &&
              acc.kelas != null)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 8,
              ),
              child:
                  Chip(
                label:
                    Text(
                  acc.kelas!,
                  style:
                      TextStyle(
                    color: isGlass
                        ? Colors
                            .white
                        : primaryText,
                    fontSize:
                        11,
                    fontWeight:
                        FontWeight
                            .w600,
                  ),
                ),
                backgroundColor:
                    acc.kelas ==
                            'Lulus'
                        ? secondaryText
                            .withValues(
                            alpha:
                                0.18,
                          )
                        : accentColor
                            .withValues(
                            alpha:
                                0.14,
                          ),
                side:
                    BorderSide(
                  color:
                      accentColor
                          .withValues(
                    alpha:
                        0.20,
                  ),
                ),
                padding:
                    EdgeInsets.zero,
                visualDensity:
                    VisualDensity
                        .compact,
              ),
            ),

          IconButton(
            icon:
                Icon(
              Icons
                  .edit_outlined,
              size: 20,
              color:
                  accentColor,
            ),
            onPressed:
                () {
              SoundHelper()
                  .playClick();

              _showAccountDialog(
                existing: acc,
              );
            },
            tooltip:
                'Edit',
            constraints:
                const BoxConstraints(),
            padding:
                EdgeInsets.zero,
          ),

          IconButton(
            icon:
                Icon(
              Icons
                  .delete_outline,
              size: 20,
              color:
                  colors.error,
            ),
            onPressed:
                () {
              SoundHelper()
                  .playClick();

              _showDeleteConfirmation(
                acc.id,
                acc.name,
              );
            },
            tooltip:
                'Hapus',
            constraints:
                const BoxConstraints(),
            padding:
                EdgeInsets.zero,
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child:
              Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              if (acc.category ==
                      'siswa' &&
                  acc.namaSiswa
                          ?.isNotEmpty ==
                      true)
                _infoRow(
                  'Nama Siswa',
                  acc.namaSiswa!,
                  themeMode,
                ),

              _infoRow(
                'Layanan',
                acc.name,
                themeMode,
              ),

              _infoRow(
                'Email',
                acc.email,
                themeMode,
              ),

              _infoRow(
                'Penanggung Jawab',
                acc.penanggungJawab,
                themeMode,
              ),

              _infoRow(
                'Keterangan',
                acc.keterangan,
                themeMode,
              ),

              _infoRow(
                'Password',
                acc.password,
                themeMode,
              ),

              if (acc.category ==
                      'siswa' &&
                  acc.kelas != null)
                _infoRow(
                  'Kelas',
                  acc.kelas!,
                  themeMode,
                ),
            ],
          ),
        ),
      ],
    );

    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      child:
          _buildThemedContainer(
        borderRadius:
            ThemeHelper.isCyber(
          themeMode,
        )
                ? 12
                : 18,
        child:
            tile,
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _infoRow(
    String label,
    String value,
    AppThemeMode themeMode,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    return Padding(
      padding:
          const EdgeInsets
              .symmetric(
        vertical: 4,
      ),
      child:
          Row(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          SizedBox(
            width:
                120,
            child:
                Text(
              label,
              style:
                  TextStyle(
                color:
                    secondaryText,
                fontSize:
                    13,
              ),
            ),
          ),

          Expanded(
            child:
                Text(
              value.isEmpty
                  ? '-'
                  : value,
              style:
                  TextStyle(
                fontWeight:
                    FontWeight.w500,
                color:
                    primaryText,
                fontSize:
                    13,
              ),
              overflow:
                  TextOverflow
                      .ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // THEMED CONTAINER
  // ============================================================

  Widget _buildThemedContainer({
    required Widget child,
    double borderRadius = 18,
  }) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    if (ThemeHelper.isNeo(
      themeMode,
    )) {
      return Container(
        decoration:
            neumorphismDecoration(
          borderRadius:
              borderRadius,
          isPressed: false,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            borderRadius,
          ),
          child: child,
        ),
      );
    }

    if (ThemeHelper.isGlass(
      themeMode,
    )) {
      return Container(
        decoration:
            glassmorphismDecoration(
          borderRadius:
              borderRadius,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            borderRadius,
          ),
          child:
              BackdropFilter(
            filter:
                ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child: child,
          ),
        ),
      );
    }

    if (ThemeHelper.isModern(
      themeMode,
    )) {
      return Container(
        decoration:
            modernDecoration(
          borderRadius:
              borderRadius,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            borderRadius,
          ),
          child: child,
        ),
      );
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return Container(
        decoration:
            auroraDecoration(
          borderRadius:
              borderRadius,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            borderRadius,
          ),
          child: child,
        ),
      );
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return Container(
        decoration:
            cyberpunkDecoration(
          borderRadius:
              borderRadius,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            borderRadius,
          ),
          child: child,
        ),
      );
    }

    return Card(
      margin:
          EdgeInsets.zero,
      clipBehavior:
          Clip.antiAlias,
      elevation: 0,
      color:
          colors.surfaceContainerHighest,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          borderRadius,
        ),
      ),
      child: child,
    );
  }
}

// ============================================================
// HALAMAN ARSIP AKUN DIGITAL
// ============================================================

class ArchiveAkunPage
    extends ConsumerWidget {
  const ArchiveAkunPage({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final headerText =
        _getHeaderTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    return ThemeHelper
        .buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor:
            ThemeHelper
                .getScaffoldBackgroundColor(
          themeMode,
          colors,
        ),

        appBar:
            AppBar(
          backgroundColor:
              ThemeHelper.isNeo(
            themeMode,
          )
                  ? AppColors
                      .neoBase
                  : Colors
                      .transparent,

          elevation: 0,

          scrolledUnderElevation:
              0,

          surfaceTintColor:
              Colors.transparent,

          title: Text(
            'Arsip Akun Digital Siswa',
            style:
                TextStyle(
              color:
                  headerText,
            ),
          ),
        ),

        body:
            StreamBuilder<
                QuerySnapshot<
                    Map<String,
                        dynamic>>>(
          stream:
              _archiveAkunCollection
                  .orderBy(
                    'updatedAt',
                    descending:
                        true,
                  )
                  .snapshots(),

          builder: (
            context,
            snapshot,
          ) {
            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return Center(
                child:
                    CircularProgressIndicator(
                  color:
                      accentColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            190,
                      ),
                      const SizedBox(
                        height:
                            8,
                      ),
                      Text(
                        'Gagal membaca arsip',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),
                      const SizedBox(
                        height:
                            8,
                      ),
                      Text(
                        '${snapshot.error}',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                          fontSize:
                              13,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final docs =
                snapshot.data?.docs ??
                    [];

            // ==================================================
            // EMPTY ARCHIVE -> LOTTIE
            // ==================================================

            if (docs.isEmpty) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            210,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Belum ada arsip akun digital',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Arsip siswa yang telah lulus '
                        'akan muncul di sini.',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                          fontSize:
                              14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView
                .builder(
              padding:
                  const EdgeInsets
                      .all(
                12,
              ),
              itemCount:
                  docs.length,
              itemBuilder: (
                context,
                index,
              ) {
                final doc =
                    docs[index];

                final data =
                    doc.data();

                final folderId =
                    doc.id;

                final folderName =
                    (data['namaArsip'] ??
                            data[
                                'tahunArsip'] ??
                            folderId)
                        .toString();

                return ScrollReveal(
                  delay:
                      Duration(
                    milliseconds:
                        50 * index,
                  ),
                  child:
                      Container(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      vertical: 6,
                    ),
                    child:
                        _ArchiveThemeContainer(
                      themeMode:
                          themeMode,
                      child:
                          ListTile(
                        leading:
                            Icon(
                          Icons
                              .folder,
                          color:
                              isGlass
                                  ? Colors
                                      .amberAccent
                                  : Colors
                                      .amber,
                        ),

                        title:
                            Text(
                          folderName,
                          style:
                              TextStyle(
                            color:
                                primaryText,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        subtitle:
                            Text(
                          'Lihat detail arsip',
                          style:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                        ),

                        trailing:
                            Icon(
                          Icons
                              .chevron_right,
                          color:
                              secondaryText,
                        ),

                        onTap:
                            () {
                          SoundHelper()
                              .playClick();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ArchiveAkunClassPage(
                                tahun:
                                    folderName,
                                folderId:
                                    folderId,
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
// HALAMAN ARSIP PER KELAS
// ============================================================

class ArchiveAkunClassPage
    extends ConsumerWidget {
  final String tahun;
  final String folderId;

  const ArchiveAkunClassPage({
    super.key,
    required this.tahun,
    required this.folderId,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final headerText =
        _getHeaderTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    return ThemeHelper
        .buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor:
            ThemeHelper
                .getScaffoldBackgroundColor(
          themeMode,
          colors,
        ),

        appBar:
            AppBar(
          backgroundColor:
              ThemeHelper.isNeo(
            themeMode,
          )
                  ? AppColors
                      .neoBase
                  : Colors
                      .transparent,

          elevation: 0,

          scrolledUnderElevation:
              0,

          surfaceTintColor:
              Colors.transparent,

          title: Text(
            'Arsip $tahun',
            style:
                TextStyle(
              color:
                  headerText,
            ),
          ),
        ),

        body:
            FutureBuilder<
                QuerySnapshot>(
          future:
              _archiveAkunCollection
                  .doc(
                    folderId,
                  )
                  .collection(
                    'accounts',
                  )
                  .get(),

          builder: (
            context,
            snapshot,
          ) {
            if (snapshot
                    .connectionState ==
                ConnectionState
                    .waiting) {
              return Center(
                child:
                    CircularProgressIndicator(
                  color:
                      accentColor,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .all(
                    24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            190,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Gagal membaca isi arsip',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        '${snapshot.error}',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final akunList =
                snapshot.data?.docs
                        .map(
                          (doc) {
                            final raw =
                                doc.data();

                            if (raw
                                is! Map<String,
                                    dynamic>) {
                              return null;
                            }

                            final data =
                                Map<String,
                                    dynamic>.from(
                              raw,
                            );

                            data['id'] =
                                data[
                                        'id'] ??
                                    doc.id;

                            return AkunDigital
                                .fromJson(
                              data,
                            );
                          },
                        )
                        .whereType<
                            AkunDigital>()
                        .toList() ??
                    [];

            // ==================================================
            // EMPTY ACCOUNT ARCHIVE
            // ==================================================

            if (akunList.isEmpty) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            210,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Tidak ada akun di arsip ini',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Belum terdapat data akun siswa '
                        'pada arsip "$tahun".',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                          fontSize:
                              14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final Map<
                    String,
                    List<
                        AkunDigital>>
                kelasMap = {};

            for (final acc
                in akunList) {
              final kelas =
                  acc.kelas
                              ?.trim()
                              .isNotEmpty ==
                          true
                      ? acc.kelas!
                      : 'Kelas Tidak Diketahui';

              kelasMap
                  .putIfAbsent(
                kelas,
                () => [],
              )
                  .add(
                acc,
              );
            }

            final kelasKeys =
                kelasMap.keys.toList()
                  ..sort();

            // ==================================================
            // EMPTY CLASS
            // ==================================================

            if (kelasKeys.isEmpty) {
              return Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            210,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Tidak ada data kelas',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Belum ada kelas yang tersimpan '
                        'dalam arsip ini.',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView
                .builder(
              padding:
                  const EdgeInsets
                      .all(
                12,
              ),
              itemCount:
                  kelasKeys.length,
              itemBuilder: (
                context,
                index,
              ) {
                final kelas =
                    kelasKeys[index];

                final kelasAkunList =
                    kelasMap[
                        kelas]!;

                return ScrollReveal(
                  delay:
                      Duration(
                    milliseconds:
                        50 * index,
                  ),
                  child:
                      Container(
                    margin:
                        const EdgeInsets
                            .symmetric(
                      vertical: 6,
                    ),
                    child:
                        _ArchiveThemeContainer(
                      themeMode:
                          themeMode,
                      child:
                          ListTile(
                        leading:
                            Icon(
                          Icons
                              .folder_open,
                          color:
                              getMajorColor(
                            kelas,
                          ),
                        ),

                        title:
                            Text(
                          kelas,
                          style:
                              TextStyle(
                            color:
                                primaryText,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),

                        subtitle:
                            Text(
                          '${kelasAkunList.length} akun',
                          style:
                              TextStyle(
                            color:
                                secondaryText,
                          ),
                        ),

                        trailing:
                            Icon(
                          Icons
                              .chevron_right,
                          color:
                              secondaryText,
                        ),

                        onTap:
                            () {
                          SoundHelper()
                              .playClick();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) =>
                                      ArchiveAkunListPage(
                                tahun:
                                    tahun,
                                kelas:
                                    kelas,
                                akunList:
                                    kelasAkunList,
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
// HALAMAN LIST ARSIP
// ============================================================

class ArchiveAkunListPage
    extends ConsumerWidget {
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
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final themeMode =
        ref.watch(
      themeModeProvider,
    );

    final colors =
        Theme.of(context).colorScheme;

    final bool isGlass =
        ThemeHelper.isGlass(
      themeMode,
    );

    final primaryText =
        _getPrimaryTextColor(
      themeMode,
      colors,
    );

    final secondaryText =
        _getSecondaryTextColor(
      themeMode,
      colors,
    );

    final accentColor =
        ThemeHelper.getAccentColor(
      themeMode,
      colors,
    );

    final headerText =
        _getHeaderTextColor(
      themeMode,
      colors,
    );

    return ThemeHelper
        .buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor:
            ThemeHelper
                .getScaffoldBackgroundColor(
          themeMode,
          colors,
        ),

        appBar:
            AppBar(
          backgroundColor:
              ThemeHelper.isNeo(
            themeMode,
          )
                  ? AppColors
                      .neoBase
                  : Colors
                      .transparent,

          elevation: 0,

          scrolledUnderElevation:
              0,

          surfaceTintColor:
              Colors.transparent,

          title: Text(
            '$kelas - $tahun',
            style:
                TextStyle(
              color:
                  headerText,
            ),
          ),
        ),

        // ======================================================
        // EMPTY LIST -> LOTTIE
        // ======================================================

        body: akunList.isEmpty
            ? Center(
                child:
                    Padding(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal:
                        24,
                  ),
                  child:
                      Column(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                    children: [
                      const LottieError(
                        size:
                            210,
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Tidak ada akun siswa',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              primaryText,
                          fontSize:
                              18,
                          fontWeight:
                              FontWeight
                                  .w600,
                        ),
                      ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      Text(
                        'Belum ada akun yang tersimpan '
                        'pada kelas "$kelas".',
                        textAlign:
                            TextAlign
                                .center,
                        style:
                            TextStyle(
                          color:
                              secondaryText,
                          fontSize:
                              14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets
                        .all(
                  12,
                ),
                itemCount:
                    akunList.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final a =
                      akunList[index];

                  return ScrollReveal(
                    delay:
                        Duration(
                      milliseconds:
                          50 * index,
                    ),
                    child:
                        Container(
                      margin:
                          const EdgeInsets
                              .symmetric(
                        vertical:
                            6,
                      ),
                      child:
                          _ArchiveThemeContainer(
                        themeMode:
                            themeMode,
                        child:
                            ListTile(
                          leading:
                              Icon(
                            Icons
                                .account_circle,
                            color:
                                isGlass
                                    ? Colors
                                        .white
                                    : secondaryText,
                          ),

                          title:
                              Text(
                            a.namaSiswa ??
                                a.name,
                            style:
                                TextStyle(
                              color:
                                  primaryText,
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            maxLines:
                                1,
                          ),

                          subtitle:
                              Text(
                            'Email: ${a.email} • ${a.penanggungJawab}',
                            style:
                                TextStyle(
                              color:
                                  secondaryText,
                            ),
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            maxLines:
                                1,
                          ),

                          trailing:
                              IconButton(
                            icon:
                                Icon(
                              Icons
                                  .remove_red_eye,
                              color:
                                  accentColor,
                            ),
                            onPressed:
                                () {
                              SoundHelper()
                                  .playClick();

                              ScaffoldMessenger
                                  .of(
                                context,
                              ).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text(
                                    'Akun sudah diarsipkan (lulus)',
                                  ),
                                ),
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
// ARCHIVE THEME CONTAINER
// ============================================================

class _ArchiveThemeContainer
    extends StatelessWidget {
  final AppThemeMode themeMode;
  final Widget child;

  const _ArchiveThemeContainer({
    required this.themeMode,
    required this.child,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final colors =
        Theme.of(context).colorScheme;

    if (ThemeHelper.isNeo(
      themeMode,
    )) {
      return Container(
        decoration:
            neumorphismDecoration(
          borderRadius:
              18,
          isPressed:
              false,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child:
              child,
        ),
      );
    }

    if (ThemeHelper.isGlass(
      themeMode,
    )) {
      return Container(
        decoration:
            glassmorphismDecoration(
          borderRadius:
              18,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child:
              BackdropFilter(
            filter:
                ImageFilter.blur(
              sigmaX: 12,
              sigmaY: 12,
            ),
            child:
                child,
          ),
        ),
      );
    }

    if (ThemeHelper.isModern(
      themeMode,
    )) {
      return Container(
        decoration:
            modernDecoration(
          borderRadius:
              18,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child:
              child,
        ),
      );
    }

    if (ThemeHelper.isAurora(
      themeMode,
    )) {
      return Container(
        decoration:
            auroraDecoration(
          borderRadius:
              18,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            18,
          ),
          child:
              child,
        ),
      );
    }

    if (ThemeHelper.isCyber(
      themeMode,
    )) {
      return Container(
        decoration:
            cyberpunkDecoration(
          borderRadius:
              12,
        ),
        child:
            ClipRRect(
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          child:
              child,
        ),
      );
    }

    return Card(
      margin:
          EdgeInsets.zero,
      clipBehavior:
          Clip.antiAlias,
      elevation: 0,
      color:
          colors.surfaceContainerHighest,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child:
          child,
    );
  }
}