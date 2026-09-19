// navigation/akun.dart

import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/appearance.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../helpers/sound_helper.dart';
import '../auth/auth_gate.dart'; // TAMBAHAN: Import AuthGate
import '../firebase/firestore_service.dart';

// ============================================================
// HEART CLIPPER
// ============================================================

class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();

    path.moveTo(w * 0.5, h * 0.25);

    path.cubicTo(
      w * 0.15,
      h * 0.00,
      w * -0.05,
      h * 0.45,
      w * 0.5,
      h * 0.95,
    );

    path.cubicTo(
      w * 1.05,
      h * 0.45,
      w * 0.85,
      h * 0.00,
      w * 0.5,
      h * 0.25,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}

// ============================================================
// HALAMAN AKUN
// ============================================================

class AkunPage extends ConsumerStatefulWidget {
  const AkunPage({super.key});

  @override
  ConsumerState<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends ConsumerState<AkunPage> {
  // ==========================================================
  // FIREBASE
  // ==========================================================

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static const String _accountCollection = 'manajemen account';

  // ==========================================================
  // PROFILE DATA
  // ==========================================================

  String _username = '';
  String _email = '';
  String _role = '';

  String _nis = '';
  String _phone = '';
  String _address = '';

  String _joinedSince = '-';

  String? _googlePhotoUrl;

  bool _isHeartShape = false;

  String? _profileImagePath;

  User? _currentUser;

  // ==========================================================
  // IMAGE
  // ==========================================================

  final ImagePicker _picker = ImagePicker();

  // ==========================================================
  // FORM
  // ==========================================================

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _nisController = TextEditingController();

  final _phoneController = TextEditingController();

  final _addressController = TextEditingController();

  // ==========================================================
  // STATE
  // ==========================================================

  bool _isLoading = true;

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadProfileData();
  }

  // ==========================================================
  // LOAD PROFILE
  // ==========================================================

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _profileImagePath = prefs.getString('profileImagePath');

      _isHeartShape = prefs.getBool('isHeartShape') ?? false;

      final User? user = _firebaseAuth.currentUser;

      if (user == null) {
        throw Exception('Sesi pengguna tidak ditemukan.');
      }

      _currentUser = user;

      final DocumentSnapshot<Map<String, dynamic>> account =
          await fetchUserAccount(user.uid);

      final Map<String, dynamic> data = account.data() ?? {};

      _username = _readString(data['nama']);

      if (_username.isEmpty) {
        _username = user.displayName?.trim() ?? '';
      }

      _email = user.email?.trim() ?? _readString(data['email']);

      _role = _readString(data['role']);

      if (_role.isEmpty) {
        _role = 'guru';
      }

      _nis = _readFirstString(data, ['nis', 'nik', 'nisNIK']);

      _phone = _readFirstString(data, ['nomorTelepon', 'phone']);

      _address = _readFirstString(data, ['alamat', 'address']);

      _googlePhotoUrl = _readFirstString(data, ['photoUrl']);

      if (_googlePhotoUrl == null || _googlePhotoUrl!.isEmpty) {
        _googlePhotoUrl = user.photoURL;
      }

      _joinedSince = _formatJoinedDate(
        data['tanggalBergabung'] ?? data['createdAt'],
      );
    } catch (e) {
      debugPrint('Gagal load profil: $e');
    } finally {
      if (!mounted) return;

      setState(() {
        _isLoading = false;

        _nameController.text = _username;

        _emailController.text = _email;

        _nisController.text = _nis;

        _phoneController.text = _phone;

        _addressController.text = _address;
      });
    }
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ==========================================================
  // READ FIRST STRING
  // ==========================================================

  String _readFirstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value = _readString(data[key]);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  String _formatJoinedDate(dynamic value) {
    DateTime? date;

    if (value is Timestamp) {
      date = value.toDate();
    } else if (value is DateTime) {
      date = value;
    } else if (value is String) {
      date = DateTime.tryParse(value);
    }

    if (date == null) {
      return '-';
    }

    const List<String> months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ==========================================================
  // SAVE LOCAL PROFILE CACHE
  // ==========================================================

  Future<void> _saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('username', _username);

      await prefs.setString('email', _email);

      await prefs.setString('nis', _nis);

      await prefs.setString('phone', _phone);

      await prefs.setString('address', _address);

      await prefs.setBool('isHeartShape', _isHeartShape);

      if (_profileImagePath != null) {
        await prefs.setString('profileImagePath', _profileImagePath!);
      } else {
        await prefs.remove('profileImagePath');
      }
    } catch (e) {
      debugPrint('Gagal simpan profil lokal: $e');
    }
  }

  // ==========================================================
  // SAVE FIRESTORE PROFILE
  // ==========================================================

  Future<void> _saveFirestoreProfile({
    required String nama,
    required String nis,
    required String phone,
    required String address,
  }) async {
    final User? user = _currentUser ?? _firebaseAuth.currentUser;

    if (user == null) {
      throw Exception('Sesi pengguna tidak ditemukan.');
    }

    await FirebaseFirestore.instance
        .collection(_accountCollection)
        .doc(user.uid)
        .set(
      {
        'nama': nama,
        'nis': nis,
        'nomorTelepon': phone,
        'alamat': address,
        'email': user.email,
        'role': _role.isEmpty ? 'guru' : _role,
        'provider': 'google.com',
        'photoUrl': _googlePhotoUrl ?? user.photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await user.updateDisplayName(nama);

    _currentUser = user;
  }

  // ==========================================================
  // COPY IMAGE
  // ==========================================================

  Future<String?> _copyImageToPermanentDir(File imageFile) async {
    try {
      final dir = await getApplicationDocumentsDirectory();

      final String fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final File newFile = await imageFile.copy('${dir.path}/$fileName');

      return newFile.path;
    } catch (e) {
      debugPrint('Gagal menyimpan foto: $e');

      return null;
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    final colors = Theme.of(context).colorScheme;

    final scaffoldBackgroundColor =
        ThemeHelper.getScaffoldBackgroundColor(themeMode, colors);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: scaffoldBackgroundColor,

        appBar: AppBar(
          title: const Text('Profil Saya'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _isLoading
                  ? null
                  : () {
                      SoundHelper().playClick();

                      _showEditProfileDialog();
                    },
              tooltip: 'Edit Profil',
            ),
          ],
        ),

        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ScrollReveal(
                      delay: const Duration(milliseconds: 50),
                      child: _buildProfileHeader(),
                    ),

                    const SizedBox(height: 24),

                    ScrollReveal(
                      delay: const Duration(milliseconds: 120),
                      child: _buildInfoCard(),
                    ),

                    const SizedBox(height: 24),

                    ScrollReveal(
                      delay: const Duration(milliseconds: 190),
                      child: _buildMenuCard(),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final themeMode = ref.read(themeModeProvider);

    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    final bool hasLocalImage = _profileImagePath != null &&
        File(_profileImagePath!).existsSync();

    Widget avatar = CircleAvatar(
      radius: 60,
      backgroundImage: hasLocalImage
          ? FileImage(File(_profileImagePath!))
          : _googlePhotoUrl != null && _googlePhotoUrl!.isNotEmpty
              ? NetworkImage(_googlePhotoUrl!)
              : null,
      backgroundColor: colors.surfaceContainerHighest,
      child: !hasLocalImage &&
              (_googlePhotoUrl == null || _googlePhotoUrl!.isEmpty)
          ? Text(
              _username.isNotEmpty
                  ? _username[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            )
          : null,
    );

    if (_isHeartShape) {
      avatar = ClipPath(clipper: HeartClipper(), child: avatar);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                SoundHelper().playClick();

                _showImagePickerDialog();
              },
              child: Stack(
                children: [
                  avatar,
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: colors.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Text(
              _username.isEmpty ? 'Pengguna' : _username,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 6),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _role.isEmpty ? 'Guru' : _role,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _email.isEmpty ? '-' : _email,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD
  // ============================================================

  Widget _buildInfoCard() {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pengguna',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            _buildInfoRow(Icons.badge_outlined, 'NIS/NIK', _nis),

            Divider(color: _getDividerColor()),

            _buildInfoRow(Icons.phone_outlined, 'No. Telepon', _phone),

            Divider(color: _getDividerColor()),

            _buildInfoRow(Icons.location_on_outlined, 'Alamat', _address),

            Divider(color: _getDividerColor()),

            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Bergabung Sejak',
              _joinedSince,
            ),

            Divider(color: _getDividerColor()),

            _buildInfoRow(Icons.login_outlined, 'Provider', 'Google'),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final String displayValue = value.trim().isEmpty ? '-' : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: colors.onSurfaceVariant,
            size: 20,
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            flex: 3,
            child: Text(
              displayValue,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU CARD
  // ============================================================

  Widget _buildMenuCard() {
    return Card(
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.edit_outlined,
            title: 'Edit Profil',
            subtitle: 'Ubah informasi pribadi',
            onTap: () {
              SoundHelper().playClick();

              _showEditProfileDialog();
            },
          ),

          Divider(height: 1, color: _getDividerColor()),

          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Keamanan Akun',
            subtitle: 'Kelola keamanan dan password',
            onTap: () {
              SoundHelper().playClick();

              _showChangePasswordDialog();
            },
          ),

          Divider(height: 1, color: _getDividerColor()),

          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Keluar dari aplikasi',
            onTap: () {
              SoundHelper().playClick();

              _showLogoutDialog();
            },
            isLogout: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MENU ITEM
  // ============================================================

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final themeMode = ref.read(themeModeProvider);

    final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

    final iconColor = isLogout ? colors.error : accentColor;

    final titleColor = isLogout ? colors.error : colors.onSurface;

    return ListTile(
      leading: Icon(icon, color: iconColor),

      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),

      trailing: Icon(
        Icons.chevron_right,
        color: colors.onSurfaceVariant,
      ),

      onTap: onTap,
    );
  }

  // ============================================================
  // DIVIDER COLOR
  // ============================================================

  Color _getDividerColor() {
    final themeMode = ref.read(themeModeProvider);

    return ThemeHelper.dividerColor(themeMode);
  }

  // ============================================================
  // IMAGE PICKER DIALOG
  // ============================================================

  void _showImagePickerDialog() {
    final themeMode = ref.read(themeModeProvider);

    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          ThemeHelper.getScaffoldBackgroundColor(themeMode, colors),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.photo_library,
                color: ThemeHelper.getAccentColor(themeMode, colors),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                SoundHelper().playClick();

                Navigator.pop(ctx);

                _pickImage(ImageSource.gallery);
              },
            ),

            ListTile(
              leading: Icon(
                Icons.photo_camera,
                color: ThemeHelper.getAccentColor(themeMode, colors),
              ),
              title: const Text('Ambil Foto'),
              onTap: () {
                SoundHelper().playClick();

                Navigator.pop(ctx);

                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image == null) {
        return;
      }

      final File imageFile = File(image.path);

      final String? permanentPath =
          await _copyImageToPermanentDir(imageFile);

      if (permanentPath != null) {
        setState(() {
          _profileImagePath = permanentPath;
        });

        await _saveProfileData();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diubah.')),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan foto.')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat gambar: $e')),
      );
    }
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================

  Future<void> _showEditProfileDialog() async {
    _nameController.text = _username;

    _emailController.text = _email;

    _nisController.text = _nis;

    _phoneController.text = _phone;

    _addressController.text = _address;

    bool localHeartShape = _isHeartShape;

    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final themeMode = ref.read(themeModeProvider);

          final colors = Theme.of(context).colorScheme;

          final accentColor = ThemeHelper.getAccentColor(themeMode, colors);

          return AlertDialog(
            title: const Text('Edit Profil'),

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
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';

                          if (value.isEmpty) {
                            return 'Nama wajib diisi.';
                          }

                          if (value.length < 3) {
                            return 'Nama terlalu pendek.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Email Google',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _nisController,
                        decoration: const InputDecoration(
                          labelText: 'NIS/NIK',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'NIS/NIK wajib diisi.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'No. Telepon',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: (v) {
                          final phone = v?.trim() ?? '';

                          if (phone.isEmpty) {
                            return 'Nomor telepon wajib diisi.';
                          }

                          final digits = phone.replaceAll(
                            RegExp(r'[^0-9+]'),
                            '',
                          );

                          if (digits.length < 8) {
                            return 'Nomor telepon tidak valid.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Alamat',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) {
                            return 'Alamat wajib diisi.';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bentuk Avatar Hati'),
                        subtitle: const Text('Ubah avatar menjadi bentuk love'),
                        value: localHeartShape,
                        onChanged: saving
                            ? null
                            : (val) {
                                SoundHelper().playNotification();

                                if (val && !localHeartShape) {
                                  AwesomeDialog(
                                    context: ctx,
                                    dialogType: DialogType.info,
                                    animType: AnimType.bottomSlide,
                                    headerAnimationLoop: false,
                                    title: '💖 Easter Egg!',
                                    desc:
                                        'Selamat! Anda mengaktifkan mode avatar hati.\nSemangat belajar dan berkarya! 🚀',
                                    btnOkOnPress: () {},
                                    btnOkIcon: Icons.favorite,
                                    btnOkColor: accentColor,
                                    btnOkText: '❤️ Mantap!',
                                    useRootNavigator: false,
                                  ).show();
                                }

                                setStateDialog(() {
                                  localHeartShape = val;
                                });
                              },
                        activeColor: accentColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () {
                        SoundHelper().playClick();

                        Navigator.pop(ctx);
                      },
                child: const Text('Batal'),
              ),

              ElevatedButton(
                onPressed: saving
                    ? null
                    : () async {
                        SoundHelper().playClick();

                        if (!_formKey.currentState!.validate()) {
                          return;
                        }

                        final String nama = _nameController.text.trim();

                        final String nis = _nisController.text.trim();

                        final String phone = _phoneController.text.trim();

                        final String address = _addressController.text.trim();

                        setStateDialog(() {
                          saving = true;
                        });

                        try {
                          await _saveFirestoreProfile(
                            nama: nama,
                            nis: nis,
                            phone: phone,
                            address: address,
                          );

                          if (!mounted) {
                            return;
                          }

                          setState(() {
                            _username = nama;
                            _nis = nis;
                            _phone = phone;
                            _address = address;
                            _isHeartShape = localHeartShape;
                          });

                          await _saveProfileData();

                          if (!mounted) {
                            return;
                          }

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profil berhasil diperbarui.'),
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() {
                            saving = false;
                          });

                          if (!mounted) {
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal menyimpan profil: $e'),
                            ),
                          );
                        }
                      },
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<void> _showChangePasswordDialog() async {
    final User? user = _firebaseAuth.currentUser;

    if (user == null) {
      _showLocalError('Sesi pengguna tidak ditemukan.');

      return;
    }

    final bool hasPasswordProvider = user.providerData.any(
      (provider) => provider.providerId == 'password',
    );

    // ----------------------------------------------------------
    // GOOGLE ACCOUNT
    // ----------------------------------------------------------

    if (!hasPasswordProvider) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Keamanan Akun'),
          content: const Text(
            'Akun ini menggunakan Google Sign-In.\n\n'
            'Password akun dikelola langsung oleh Google, '
            'bukan oleh aplikasi ini.',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // PASSWORD PROVIDER
    // ----------------------------------------------------------

    final oldPassword = TextEditingController();

    final newPassword = TextEditingController();

    final confirmPassword = TextEditingController();

    bool saving = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Ganti Password'),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password Lama',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: newPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password Baru',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: confirmPassword,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () {
                          Navigator.pop(ctx);
                        },
                  child: const Text('Batal'),
                ),

                FilledButton(
                  onPressed: saving
                    ? null
                    : () async {
                        final String old = oldPassword.text;

                        final String next = newPassword.text;

                        final String confirm = confirmPassword.text;

                        if (next.length < 6) {
                          _showLocalError(
                            'Password baru minimal 6 karakter.',
                          );

                          return;
                        }

                        if (next != confirm) {
                          _showLocalError(
                            'Konfirmasi password tidak cocok.',
                          );

                          return;
                        }

                        final String? email = user.email;

                        if (email == null || email.isEmpty) {
                          _showLocalError('Email akun tidak tersedia.');

                          return;
                        }

                        setStateDialog(() {
                          saving = true;
                        });

                        try {
                          final credential =
                              EmailAuthProvider.credential(
                            email: email,
                            password: old,
                          );

                          await user.reauthenticateWithCredential(credential);

                          await user.updatePassword(next);

                          if (!mounted) {
                            return;
                          }

                          Navigator.pop(ctx);

                          _showLocalError(
                            'Password berhasil diubah.',
                            success: true,
                          );
                        } on FirebaseAuthException catch (e) {
                          setStateDialog(() {
                            saving = false;
                          });

                          _showLocalError(_firebaseErrorMessage(e));
                        } catch (e) {
                          setStateDialog(() {
                            saving = false;
                          });

                          _showLocalError('Gagal mengubah password: $e');
                        }
                      },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      oldPassword.dispose();
      newPassword.dispose();
      confirmPassword.dispose();
    }
  }

  // ============================================================
  // FIREBASE ERROR
  // ============================================================

  String _firebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
        return 'Password lama salah.';

      case 'invalid-credential':
        return 'Credential akun tidak valid.';

      case 'weak-password':
        return 'Password terlalu lemah.';

      case 'requires-recent-login':
        return 'Silakan login kembali sebelum mengubah password.';

      default:
        return e.message ?? 'Terjadi kesalahan autentikasi.';
    }
  }

  // ============================================================
  // LOCAL MESSAGE
  // ============================================================

  void _showLocalError(String message, {bool success = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),

        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
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
            onPressed: () async {
              SoundHelper().playClick();

              Navigator.pop(ctx);

              await _performLogout();
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),

            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PERFORM LOGOUT (PERBAIKAN: Gunakan AuthGate, bukan AuthPage)
  // ============================================================

  Future<void> _performLogout() async {
    try {
      // --------------------------------------------------------
      // HAPUS CACHE DATA USER LOKAL
      // --------------------------------------------------------

      final prefs = await SharedPreferences.getInstance();

      await prefs.remove('username');
      await prefs.remove('email');
      await prefs.remove('nis');
      await prefs.remove('phone');
      await prefs.remove('address');
      await prefs.remove('profileImagePath');

      // --------------------------------------------------------
      // GOOGLE LOGOUT
      // --------------------------------------------------------

      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}

      // --------------------------------------------------------
      // FIREBASE LOGOUT
      // --------------------------------------------------------

      await _firebaseAuth.signOut();

      if (!mounted) return;

      // --------------------------------------------------------
      // KEMBALI KE AUTHGATE (bukan AuthPage)
      // AuthGate akan listen authStateChanges dan otomatis
      // navigasi ke dashboard setelah login berhasil
      // --------------------------------------------------------

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nisController.dispose();
    _phoneController.dispose();
    _addressController.dispose();

    super.dispose();
  }
}