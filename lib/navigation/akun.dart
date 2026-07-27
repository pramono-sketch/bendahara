// navigation/akun.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../data.dart';
import '../templates/sound_helper.dart';

// ===================== HEART CLIPPER =====================
class HeartClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();

    path.moveTo(w * 0.5, h * 0.25);

    // Lengkungan kiri
    path.cubicTo(
      w * 0.15, h * 0.00,
      w * -0.05, h * 0.45,
      w * 0.5, h * 0.95,
    );

    // Lengkungan kanan
    path.cubicTo(
      w * 1.05, h * 0.45,
      w * 0.85, h * 0.00,
      w * 0.5, h * 0.25,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
// ===================== HALAMAN AKUN =====================
class AkunPage extends StatefulWidget {
  const AkunPage({super.key});

  @override
  State<AkunPage> createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  String _username = 'Admin Sekolah';
  String _email = 'admin@eduvest.sch.id';
  String _role = 'Administrator';
  String _nis = 'ADM-2026-001';
  String _phone = '0812-3456-7890';
  String _address = 'Jl. Pendidikan No. 123, Jakarta';
  bool _isHeartShape = false; // 🔥 State untuk bentuk avatar

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

  Future<void> _loadProfileData() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      _username = prefs.getString('username') ?? 'Admin Sekolah';
      _email = prefs.getString('email') ?? 'admin@eduvest.sch.id';
      _phone = prefs.getString('phone') ?? '0812-3456-7890';
      _address = prefs.getString('address') ?? 'Jl. Pendidikan No. 123, Jakarta';
      _profileImagePath = prefs.getString('profileImagePath');
      _isHeartShape = prefs.getBool('isHeartShape') ?? false; // 🔥 muat preferensi
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

  Future<void> _saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', _username);
      await prefs.setString('email', _email);
      await prefs.setString('phone', _phone);
      await prefs.setString('address', _address);
      await prefs.setBool('isHeartShape', _isHeartShape); // 🔥 simpan preferensi
      if (_profileImagePath != null) {
        await prefs.setString('profileImagePath', _profileImagePath!);
      } else {
        await prefs.remove('profileImagePath');
      }
    } catch (e) {
      debugPrint('Gagal simpan profil: $e');
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildInfoCard(),
                  const SizedBox(height: 24),
                  _buildMenuCard(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  // ============================================================
  // WIDGET: Header Profil (dengan opsi bentuk hati)
  // ============================================================
  Widget _buildProfileHeader() {
    // Widget avatar yang akan dibungkus dengan ClipPath jika heart shape
    Widget avatar = CircleAvatar(
      radius: 60,
      backgroundImage: _profileImagePath != null
          ? FileImage(File(_profileImagePath!))
          : null,
      backgroundColor: Colors.grey.shade200,
      child: _profileImagePath == null
          ? Text(
              _username.isNotEmpty ? _username[0].toUpperCase() : 'A',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            )
          : null,
    );

    // Jika bentuk hati aktif, bungkus dengan ClipPath
    if (_isHeartShape) {
      avatar = ClipPath(
        clipper: HeartClipper(),
        child: avatar,
      );
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔥 Tampilkan avatar (bisa lingkaran atau hati)
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
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _role,
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _email,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // WIDGET: Kartu Informasi Detail (tidak berubah)
  // ============================================================
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informasi Pengguna',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.badge, 'NIS/NIK', _nis),
            const Divider(),
            _buildInfoRow(Icons.phone, 'No. Telepon', _phone),
            const Divider(),
            _buildInfoRow(Icons.location_on, 'Alamat', _address),
            const Divider(),
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // WIDGET: Kartu Menu Akun (tidak berubah)
  // ============================================================
  Widget _buildMenuCard() {
    return Card(
      elevation: 2,
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
          const Divider(height: 1),
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Ganti Password',
            subtitle: 'Perbarui kata sandi akun',
            onTap: () {
              SoundHelper().playClick();
              _showChangePasswordDialog();
            },
          ),
          const Divider(height: 1),
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : AppColors.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // ============================================================
  // DIALOG: Pilih Foto (tidak berubah)
  // ============================================================
  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                SoundHelper().playClick();
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto profil berhasil diubah')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan foto')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat gambar: $e')),
      );
    }
  }

  // ============================================================
  // DIALOG: Edit Profil (dengan switch bentuk hati)
  // ============================================================
  void _showEditProfileDialog() {
    _nameController.text = _username;
    _emailController.text = _email;
    _phoneController.text = _phone;
    _addressController.text = _address;

    // 🔥 Salin nilai _isHeartShape untuk digunakan di dialog
    bool localHeartShape = _isHeartShape;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
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
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.trim().isEmpty ? 'Email wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    // 🔥 Switch untuk bentuk avatar
                    SwitchListTile(
                      title: const Text('Bentuk Avatar Hati'),
                      subtitle: const Text('Ubah avatar menjadi bentuk love'),
                      value: localHeartShape,
                      onChanged: (val) {
                        setStateDialog(() {
                          localHeartShape = val;
                        });
                      },
                      activeColor: AppColors.primary,
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
                    _isHeartShape = localHeartShape; // 🔥 simpan pilihan
                  });
                  await _saveProfileData();
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil berhasil diperbarui')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG: Ganti Password (tidak berubah)
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
                decoration: const InputDecoration(
                  labelText: 'Password Lama',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Password Baru',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  border: OutlineInputBorder(),
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
              if (newPasswordController.text != confirmPasswordController.text) {
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
  // DIALOG: Logout (tidak berubah)
  // ============================================================
  void _showLogoutDialog() {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Berhasil logout')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}