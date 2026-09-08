// navigation/akun.dart

import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/appearance.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../templates/sound_helper.dart';

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

    // Lengkungan kiri
    path.cubicTo(w * 0.15, h * 0.00, w * -0.05, h * 0.45, w * 0.5, h * 0.95);

    // Lengkungan kanan
    path.cubicTo(w * 1.05, h * 0.45, w * 0.85, h * 0.00, w * 0.5, h * 0.25);

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
  String _username = 'Admin Sekolah';
  String _email = 'admin@eduvest.sch.id';
  String _role = 'Administrator';
  String _nis = 'ADM-2026-001';
  String _phone = '0812-3456-7890';
  String _address = 'Jl. Pendidikan No. 123, Jakarta';

  bool _isHeartShape = false;

  String? _profileImagePath;

  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _emailController = TextEditingController();

  final _phoneController = TextEditingController();

  final _addressController = TextEditingController();

  bool _isLoading = true;

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
      WidgetsFlutterBinding.ensureInitialized();

      final prefs = await SharedPreferences.getInstance();

      _username = prefs.getString('username') ?? 'Admin Sekolah';

      _email = prefs.getString('email') ?? 'admin@eduvest.sch.id';

      _phone = prefs.getString('phone') ?? '0812-3456-7890';

      _address =
          prefs.getString('address') ?? 'Jl. Pendidikan No. 123, Jakarta';

      _profileImagePath = prefs.getString('profileImagePath');

      _isHeartShape = prefs.getBool('isHeartShape') ?? false;
    } catch (e) {
      debugPrint('Gagal load profil: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;

          _nameController.text = _username;

          _emailController.text = _email;

          _phoneController.text = _phone;

          _addressController.text = _address;
        });
      }
    }
  }

  // ==========================================================
  // SAVE PROFILE
  // ==========================================================

  Future<void> _saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('username', _username);

      await prefs.setString('email', _email);

      await prefs.setString('phone', _phone);

      await prefs.setString('address', _address);

      await prefs.setBool('isHeartShape', _isHeartShape);

      if (_profileImagePath != null) {
        await prefs.setString('profileImagePath', _profileImagePath!);
      } else {
        await prefs.remove('profileImagePath');
      }
    } catch (e) {
      debugPrint('Gagal simpan profil: $e');
    }
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

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profil Saya'),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
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
                    // ==================================================
                    // PROFILE HEADER
                    // ==================================================
                    ScrollReveal(
                      delay: const Duration(milliseconds: 50),
                      child: _buildProfileHeader(),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // USER INFO
                    // ==================================================
                    ScrollReveal(
                      delay: const Duration(milliseconds: 120),
                      child: _buildInfoCard(),
                    ),

                    const SizedBox(height: 24),

                    // ==================================================
                    // ACCOUNT MENU
                    // ==================================================
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

    Widget avatar = CircleAvatar(
      radius: 60,
      backgroundImage: _profileImagePath != null
          ? FileImage(File(_profileImagePath!))
          : null,
      backgroundColor: colors.surfaceContainerHighest,
      child: _profileImagePath == null
          ? Text(
              _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
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
              _username,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 4),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _role,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              _email,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
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

            _buildInfoRow(Icons.badge, 'NIS/NIK', _nis),

            Divider(color: _getDividerColor()),

            _buildInfoRow(Icons.phone, 'No. Telepon', _phone),

            Divider(color: _getDividerColor()),

            _buildInfoRow(Icons.location_on, 'Alamat', _address),

            Divider(color: _getDividerColor()),

            _buildInfoRow(
              Icons.calendar_today,
              'Bergabung Sejak',
              '1 Januari 2025',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO ROW
  // ============================================================

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colors.onSurfaceVariant, size: 20),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
            ),
          ),

          Expanded(
            flex: 3,
            child: Text(
              value,
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
            title: 'Ganti Password',
            subtitle: 'Perbarui kata sandi akun',
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
        style: TextStyle(color: titleColor, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: colors.onSurfaceVariant),
      ),
      trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
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
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.primary),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                SoundHelper().playClick();

                Navigator.pop(ctx);

                _pickImage(ImageSource.gallery);
              },
            ),

            ListTile(
              leading: Icon(Icons.photo_camera, color: colors.primary),
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

      if (image != null) {
        final File imageFile = File(image.path);

        final String? permanentPath = await _copyImageToPermanentDir(imageFile);

        if (permanentPath != null) {
          setState(() {
            _profileImagePath = permanentPath;
          });

          await _saveProfileData();

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diubah')),
          );
        } else {
          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Gagal menyimpan foto')));
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat gambar: $e')));
    }
  }

  // ============================================================
  // EDIT PROFILE DIALOG
  // ============================================================

  void _showEditProfileDialog() {
    _nameController.text = _username;

    _emailController.text = _email;

    _phoneController.text = _phone;

    _addressController.text = _address;

    bool localHeartShape = _isHeartShape;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          final colors = Theme.of(context).colorScheme;

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
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                        ),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) =>
                            v!.trim().isEmpty ? 'Email wajib diisi' : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'No. Telepon',
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(labelText: 'Alamat'),
                        maxLines: 2,
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Bentuk Avatar Hati'),

                        subtitle: const Text('Ubah avatar menjadi bentuk love'),

                        value: localHeartShape,

                        onChanged: (val) {
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
                              btnOkColor: colors.primary,
                              btnOkText: '❤️ Mantap!',
                              useRootNavigator: false,
                            ).show();
                          }

                          setStateDialog(() {
                            localHeartShape = val;
                          });
                        },

                        activeColor: colors.primary,
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
                onPressed: () async {
                  SoundHelper().playClick();

                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      _username = _nameController.text.trim();

                      _email = _emailController.text.trim();

                      _phone = _phoneController.text.trim();

                      _address = _addressController.text.trim();

                      _isHeartShape = localHeartShape;
                    });

                    await _saveProfileData();

                    if (!mounted) return;

                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profil berhasil diperbarui'),
                      ),
                    );
                  }
                },
                child: const Text('Simpan'),
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

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ganti Password'),

        content: SizedBox(
          width: double.maxFinite,

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              TextField(
                controller: oldPasswordController,
                decoration: const InputDecoration(labelText: 'Password Lama'),
                obscureText: true,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                obscureText: true,
              ),

              const SizedBox(height: 12),

              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                ),
                obscureText: true,
              ),
            ],
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

              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password baru tidak cocok')),
                );

                return;
              }

              if (newPasswordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password minimal 6 karakter')),
                );

                return;
              }

              Navigator.pop(ctx);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password berhasil diubah')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  void _showLogoutDialog() {
    final colors = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),

        content: const Text('Apakah Anda yakin ingin keluar?'),

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

              Navigator.pop(ctx);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));
            },

            style: ElevatedButton.styleFrom(backgroundColor: colors.error),

            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();

    _emailController.dispose();

    _phoneController.dispose();

    _addressController.dispose();

    super.dispose();
  }
}
