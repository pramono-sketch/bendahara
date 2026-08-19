// features/tambahkan.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../service/import_tambahkan.dart';
import '../templates/sound_helper.dart';

// ============================================================
// ================== HALAMAN MANAJEMEN SISWA ==================
// ============================================================

class ManageStudentsPage extends ConsumerStatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  ConsumerState<ManageStudentsPage> createState() =>
      _ManageStudentsPageState();
}

class _ManageStudentsPageState extends ConsumerState<ManageStudentsPage> {
  final ExcelImportManager _excelImporter = ExcelImportManager();
  
  String _filterKelas = 'Semua';

  // ═════════════════════════════════════════════════════════════
  // ================== THEME HELPERS ==================
  // ═════════════════════════════════════════════════════════════

  bool _isNeo(AppThemeMode mode) => mode == AppThemeMode.neumorphism;
  bool _isGlass(AppThemeMode mode) => mode == AppThemeMode.glassmorphism;
  bool _isModern(AppThemeMode mode) => mode == AppThemeMode.modern;
  bool _isAurora(AppThemeMode mode) => mode == AppThemeMode.aurora;
  bool _isCyber(AppThemeMode mode) => mode == AppThemeMode.cyberpunk;

  Widget _buildThemedBackground({
    required AppThemeMode themeMode,
    required Widget child,
  }) {
    if (_isGlass(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.glassBg1,
              AppColors.glassBg2,
              AppColors.glassBg3,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (_isAurora(themeMode)) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.auroraBg,
              AppColors.auroraBg2,
              AppColors.auroraBg3,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: child,
      );
    }

    if (_isCyber(themeMode)) {
      return Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 0.8,
            colors: [
              AppColors.cyberBg,
              AppColors.cyberSurface.withValues(alpha: 0.5),
              AppColors.cyberBg,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: child,
      );
    }

    return child;
  }

  Color _dividerColor(AppThemeMode mode) {
    if (_isNeo(mode)) return AppColors.neoShadow.withValues(alpha: 0.20);
    if (_isGlass(mode)) return Colors.white.withValues(alpha: 0.2);
    if (_isModern(mode)) return AppColors.modernDivider.withValues(alpha: 0.6);
    if (_isAurora(mode)) return AppColors.auroraAccent1.withValues(alpha: 0.12);
    if (_isCyber(mode)) return AppColors.cyberAccent1.withValues(alpha: 0.15);
    return Colors.transparent;
  }

  Widget _buildSectionHeader({
    required String title,
    required AppThemeMode themeMode,
  }) {
    final colors = Theme.of(context).colorScheme;

    Color labelColor;
    if (_isNeo(themeMode)) {
      labelColor = AppColors.neoTextSecondary;
    } else if (_isGlass(themeMode)) {
      labelColor = Colors.white.withValues(alpha: 0.8);
    } else if (_isModern(themeMode)) {
      labelColor = AppColors.modernPrimary;
    } else if (_isAurora(themeMode)) {
      labelColor = AppColors.auroraAccent1;
    } else if (_isCyber(themeMode)) {
      labelColor = AppColors.cyberAccent1;
    } else {
      labelColor = colors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, top: 2, bottom: 2),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: labelColor,
        ),
      ),
    );
  }

  Widget _buildSectionGroup({
    required AppThemeMode themeMode,
    required List<Widget> children,
  }) {
    if (_isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(borderRadius: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );
    }

    if (_isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    if (_isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      );
    }

    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildDecoratedCard(AppThemeMode themeMode, Widget child) {
    if (_isNeo(themeMode)) {
      return Container(
        decoration: neumorphismDecoration(borderRadius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      );
    }
    if (_isGlass(themeMode)) {
      return Container(
        decoration: glassmorphismDecoration(borderRadius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: child,
          ),
        ),
      );
    }
    if (_isModern(themeMode)) {
      return Container(
        decoration: modernDecoration(borderRadius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      );
    }
    if (_isAurora(themeMode)) {
      return Container(
        decoration: auroraDecoration(borderRadius: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      );
    }
    if (_isCyber(themeMode)) {
      return Container(
        decoration: cyberpunkDecoration(borderRadius: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      );
    }
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: child,
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== CUSTOM THEMED DIALOG ==================
  // ═════════════════════════════════════════════════════════════

  Future<T?> showAppDialog<T>({
    required Widget title,
    required Widget content,
    List<Widget> actions = const [],
  }) {
    final themeMode = ref.read(themeModeProvider);

    return showDialog<T>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: _buildSectionGroup(
            themeMode: themeMode,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DefaultTextStyle(
                      style: Theme.of(ctx).textTheme.titleLarge ?? const TextStyle(),
                      child: title,
                    ),
                    const SizedBox(height: 20),
                    Flexible(
                      child: SingleChildScrollView(
                        child: content,
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== FIRESTORE ACTIONS ==================
  // ═════════════════════════════════════════════════════════════

  Future<void> _addLog(ActivityAction action, String detail) async {
    try {
      await addActivityLog(ActivityLog(
        user: 'Admin',
        action: action,
        detail: detail,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      debugPrint("Error adding log: $e");
    }
  }

  // ═════════════════════════════════════════════════════════════
  // ================== FUNGSI NAIK KELAS ==================
  // ═════════════════════════════════════════════════════════════

  void _promoteClasses() {
    final TextEditingController folderController = TextEditingController();

    showAppDialog(
      
      title: const Row(
        children: [
          Icon(Icons.arrow_upward, color: Colors.purple),
          SizedBox(width: 8),
          Text('Verifikasi Kenaikan'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Proses ini akan:\n'
              '• Mengarsipkan semua siswa kelas XII (lulus)\n'
              '• Menaikkan kelas XI → XII\n'
              '• Menaikkan kelas X → XI\n\n'
              'Siswa baru kelas X harus ditambahkan manual.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: folderController,
            decoration: const InputDecoration(
              labelText: 'Nama Folder Arsip',
              hintText: 'contoh: "2025/2026"',
              prefixIcon: Icon(Icons.folder_outlined),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            final folderName = folderController.text.trim();
            if (folderName.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama folder tidak boleh kosong!')),
              );
              return;
            }

            try {
              await archiveGraduatedStudentsFirestore(folderName);
              await promoteStudentsFirestore();
              await _addLog(ActivityAction.edit, 'Kenaikan kelas dengan arsip "$folderName"');

              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Kenaikan kelas berhasil! Arsip: "$folderName"')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Ya, Naikkan Kelas'),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== KELOLA PEMBAYARAN ==================
  // ═════════════════════════════════════════════════════════════

  void _managePayments() {
    showAppDialog(
      
      title: const Text('Pilih Kelas'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: gradeLevels.length,
          itemBuilder: (context, index) {
            final grade = gradeLevels[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                child: Text(grade, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              title: Text('Kelas $grade'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await SoundHelper().playClick();
                if (mounted) Navigator.pop(context);
                _showPaymentEditor(grade);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Tutup'),
        ),
      ],
    );
  }

  void _showPaymentEditor(String grade) {
    List<PaymentItem> currentList = defaultPaymentsByClass[grade] ?? [];
    List<PaymentItem> tempList = currentList.map((p) => p.copyWith()).toList();

    showAppDialog(
      
      title: Text('Kelola Pembayaran Kelas $grade'),
      content: StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tempList.length,
                    itemBuilder: (context, index) {
                      final item = tempList[index];
                      return ListTile(
                        title: Text(item.type),
                        subtitle: Text('Rp ${formatCurrency(item.amount)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18),
                              onPressed: () async {
                                await SoundHelper().playClick();
                                _editPaymentItem(context, item, (newItem) {
                                  tempList[index] = newItem;
                                  setStateDialog(() {});
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                              onPressed: () async {
                                await SoundHelper().playClick();
                                tempList.removeAt(index);
                                setStateDialog(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    await SoundHelper().playClick();
                    _addNewPaymentItem(context, (newItem) {
                      tempList.add(newItem);
                      setStateDialog(() {});
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            defaultPaymentsByClass[grade] = tempList.map((p) => p.copyWith()).toList();
            await _addLog(ActivityAction.edit, 'Update pembayaran untuk kelas $grade');
            if (mounted) Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pembayaran kelas $grade diperbarui (Lokal)')),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _editPaymentItem(BuildContext context, PaymentItem item, Function(PaymentItem) onSaved) {
    final TextEditingController nameController = TextEditingController(text: item.type);
    final TextEditingController amountController = TextEditingController(text: item.amount.toString());

    showAppDialog(
      
      title: const Text('Edit Item Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama Pembayaran'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            final newName = nameController.text.trim();
            final newAmount = double.tryParse(amountController.text.trim()) ?? 0;
            if (newName.isEmpty || newAmount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama dan nominal harus diisi dengan benar')),
              );
              return;
            }
            final updatedItem = PaymentItem(
              type: newName,
              amount: newAmount,
              status: PaymentStatus.belumBayar,
              paidAmount: 0,
            );
            onSaved(updatedItem);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _addNewPaymentItem(BuildContext context, Function(PaymentItem) onAdd) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    showAppDialog(
      
      title: const Text('Tambah Item Pembayaran'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Nama Pembayaran'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            final name = nameController.text.trim();
            final amount = double.tryParse(amountController.text.trim()) ?? 0;
            if (name.isEmpty || amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nama dan nominal harus diisi dengan benar')),
              );
              return;
            }
            final newItem = PaymentItem(type: name, amount: amount);
            onAdd(newItem);
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== FUNGSI CRUD SISWA (FIRESTORE) ==================
  // ═════════════════════════════════════════════════════════════

  void _showAddStudentDialog() {
    final formKey = GlobalKey<FormState>();
    String name = '', nis = '', alamat = '', phone = '';
    String? selectedKelas;

    showAppDialog(
      
      title: const Row(
        children: [
          Icon(Icons.person_add, color: Colors.blue),
          SizedBox(width: 8),
          Text('Tambah Siswa Baru'),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
              onSaved: (v) => name = v!,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'NIS', prefixIcon: Icon(Icons.badge_outlined)),
              onSaved: (v) => nis = v!,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Kelas', prefixIcon: Icon(Icons.school_outlined)),
              items: [
                for (var grade in gradeLevels)
                  for (var major in majors)
                    DropdownMenuItem(value: '$grade $major', child: Text('$grade $major')),
              ],
              onChanged: (v) => selectedKelas = v,
              validator: (v) => v == null ? 'Pilih kelas' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined)),
              onSaved: (v) => alamat = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'No. Telepon', prefixIcon: Icon(Icons.phone_outlined)),
              onSaved: (v) => phone = v!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (formKey.currentState!.validate()) {
              formKey.currentState!.save();
              final newStudent = createStudentWithPayments(
                id: 'STD${DateTime.now().millisecondsSinceEpoch}',
                name: name,
                nis: nis,
                kelas: selectedKelas!,
                alamat: alamat,
                phone: phone,
              );
              try {
                await saveStudent(newStudent);
                await _addLog(ActivityAction.tambah, 'Menambah siswa $name');
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal menyimpan: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _showEditStudentDialog(Student student) {
    final formKey = GlobalKey<FormState>();
    String name = student.name;
    String nis = student.nis;
    String alamat = student.alamat;
    String phone = student.phone;
    String? selectedKelas = student.kelas;
    String selectedGender = getExtraInfo(student.id, 'jenisKelamin');

    showAppDialog(
      
      title: const Row(
        children: [
          Icon(Icons.edit, color: Colors.orange),
          SizedBox(width: 8),
          Text('Edit Siswa'),
        ],
      ),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline)),
              onChanged: (v) => name = v,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: nis,
              decoration: const InputDecoration(labelText: 'NIS', prefixIcon: Icon(Icons.badge_outlined)),
              onChanged: (v) => nis = v,
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedKelas,
              decoration: const InputDecoration(labelText: 'Kelas', prefixIcon: Icon(Icons.school_outlined)),
              items: [
                for (var grade in gradeLevels)
                  for (var major in majors)
                    DropdownMenuItem(value: '$grade $major', child: Text('$grade $major')),
              ],
              onChanged: (v) => selectedKelas = v,
              validator: (v) => v == null ? 'Pilih kelas' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: alamat,
              decoration: const InputDecoration(labelText: 'Alamat', prefixIcon: Icon(Icons.location_on_outlined)),
              onChanged: (v) => alamat = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: phone,
              decoration: const InputDecoration(labelText: 'No. Telepon', prefixIcon: Icon(Icons.phone_outlined)),
              onChanged: (v) => phone = v,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedGender,
              decoration: const InputDecoration(labelText: 'Jenis Kelamin', prefixIcon: Icon(Icons.wc_outlined)),
              items: const [
                DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
                DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
              ],
              onChanged: (v) => selectedGender = v!,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (formKey.currentState!.validate()) {
              student.name = name;
              student.nis = nis;
              student.kelas = selectedKelas!;
              student.alamat = alamat;
              student.phone = phone;
              setExtraInfo(student.id, 'jenisKelamin', selectedGender);

              try {
                await saveStudent(student);
                await _addLog(ActivityAction.edit, 'Mengedit siswa $name');
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal update: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  void _deleteStudent(Student student) {
    showAppDialog(
      
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red),
          SizedBox(width: 8),
          Text('Hapus Siswa'),
        ],
      ),
      content: Text('Yakin ingin menghapus ${student.name}?'),
      actions: [
        TextButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            try {
              await deleteStudent(student.id);
              await _addLog(ActivityAction.hapus, 'Menghapus siswa ${student.name}');
              if (mounted) Navigator.pop(context);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal hapus: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hapus'),
        ),
      ],
    );
  }

  void _showAddClassXDialog() {
    int tkjCount = 5, rplCount = 5, tkrCount = 5;
    final formKey = GlobalKey<FormState>();

    showAppDialog(
      
      title: const Row(
        children: [
          Icon(Icons.group_add, color: Colors.teal),
          SizedBox(width: 8),
          Text('Tambah Kelas X'),
        ],
      ),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var entry in [
                ('TKJ', tkjCount, (v) => tkjCount = v),
                ('RPL', rplCount, (v) => rplCount = v),
                ('TKR', tkrCount, (v) => tkrCount = v),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 50, child: Text('${entry.$1}:')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: '5',
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Jumlah',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (v) => entry.$3(int.tryParse(v) ?? 0),
                          validator: (v) => int.tryParse(v!) == null ? 'Angka' : null,
                        ),
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
          onPressed: () async {
            await SoundHelper().playClick();
            if (mounted) Navigator.pop(context);
          },
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () async {
            await SoundHelper().playClick();
            if (formKey.currentState!.validate()) {
              try {
                int counter = DateTime.now().millisecondsSinceEpoch;
                Future<void> addStudentsForMajor(String major, int count) async {
                  for (int i = 1; i <= count; i++) {
                    final newStudent = createStudentWithPayments(
                      id: 'STD${counter++}',
                      name: 'Siswa X $major $i',
                      nis: '2026${counter++}',
                      kelas: 'X $major',
                      alamat: 'Jl. Merdeka No. $counter',
                      phone: '08123456$counter',
                    );
                    await saveStudent(newStudent);
                  }
                }

                await addStudentsForMajor('TKJ', tkjCount);
                await addStudentsForMajor('RPL', rplCount);
                await addStudentsForMajor('TKR', tkrCount);
                
                await _addLog(ActivityAction.tambah, 'Menambah kelas X (TKJ:$tkjCount, RPL:$rplCount, TKR:$tkrCount)');
                
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal tambah kelas X: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== SHOW GUIDE DIALOG ==================
  // ═════════════════════════════════════════════════════════════

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) => GuideDialog(
        onExport: () => _excelImporter.exportGuideFile(context),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== BUILD UI SECTIONS ==================
  // ═════════════════════════════════════════════════════════════

  Widget _buildStatsSection(AppThemeMode themeMode, List<Student> students) {
    final colors = Theme.of(context).colorScheme;

    int countByMajor(String major) =>
        students.where((s) => s.kelas.contains(major)).length;

    return _buildSectionGroup(
      themeMode: themeMode,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Row(
            children: [
              _buildStatItem(label: 'Total', value: students.length.toString(), color: colors.primary, icon: Icons.groups),
              _buildStatDivider(themeMode),
              _buildStatItem(label: 'TKJ', value: countByMajor('TKJ').toString(), color: Colors.red, icon: Icons.computer),
              _buildStatDivider(themeMode),
              _buildStatItem(label: 'RPL', value: countByMajor('RPL').toString(), color: Colors.green, icon: Icons.code),
              _buildStatDivider(themeMode),
              _buildStatItem(label: 'TKR', value: countByMajor('TKR').toString(), color: Colors.blue, icon: Icons.build),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }

  Widget _buildStatDivider(AppThemeMode mode) {
    return Container(
      width: 1,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: _dividerColor(mode),
    );
  }

  Widget _buildQuickActionsSection(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;

    final actions = <_ActionItem>[
      _ActionItem(icon: Icons.person_add, label: 'Tambah', color: colors.primary, onTap: _showAddStudentDialog),
      _ActionItem(icon: Icons.upload_file, label: 'Import', color: Colors.teal, onTap: () => _excelImporter.showImportFileDialog(context)),
      _ActionItem(icon: Icons.menu_book, label: 'Petunjuk', color: Colors.indigo, onTap: _showGuideDialog),
      _ActionItem(icon: Icons.group_add_outlined, label: 'Kelas X', color: Colors.orange, onTap: _showAddClassXDialog),
      _ActionItem(icon: Icons.payment, label: 'Bayaran', color: Colors.deepPurple, onTap: _managePayments),
      _ActionItem(icon: Icons.arrow_upward, label: 'Naik Kelas', color: Colors.pink, onTap: _promoteClasses),
    ];

    return _buildSectionGroup(
      themeMode: themeMode,
      children: [
        SizedBox(
          height: 95,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final a = actions[index];
              return _buildActionChip(a);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(_ActionItem action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await SoundHelper().playClick();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: action.color.withOpacity(0.20), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(action.icon, color: action.color, size: 24),
              const SizedBox(height: 6),
              Text(
                action.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: action.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(AppThemeMode themeMode, List<String> kelasOptions) {
    return _buildSectionGroup(
      themeMode: themeMode,
      children: [
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: kelasOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final kelas = kelasOptions[index];
              final isSelected = _filterKelas == kelas;
              final colors = Theme.of(context).colorScheme;

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await SoundHelper().playClick();
                    setState(() => _filterKelas = kelas);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary : colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? colors.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        kelas,
                        style: TextStyle(
                          color: isSelected ? colors.onPrimary : colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(Student s, AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final majorColor = getMajorColor(s.kelas);
    final gender = getExtraInfo(s.id, 'jenisKelamin');

    Widget content = ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: majorColor.withOpacity(0.15),
        child: Text(
          s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
          style: TextStyle(color: majorColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              s.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (gender.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (gender == 'Laki-laki' ? Colors.blue : Colors.pink).withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                gender == 'Laki-laki' ? 'L' : 'P',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: gender == 'Laki-laki' ? Colors.blue : Colors.pink,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.badge_outlined, size: 14, color: colors.outline),
                const SizedBox(width: 4),
                Text(s.nis, style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined, size: 14, color: majorColor),
                const SizedBox(width: 4),
                Text(
                  s.kelas,
                  style: TextStyle(fontSize: 12, color: majorColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () async {
              await SoundHelper().playClick();
              _showEditStudentDialog(s);
            },
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.red,
            onPressed: () async {
              await SoundHelper().playClick();
              _deleteStudent(s);
            },
            tooltip: 'Hapus',
          ),
        ],
      ),
    );

    return _buildDecoratedCard(themeMode, content);
  }

  Widget _buildEmptyState(AppThemeMode themeMode) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return _buildDecoratedCard(
      themeMode,
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: colors.outline.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Tidak ada siswa', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Tambahkan siswa baru atau ubah filter kelas', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════
  // ================== BUILD ==================
  // ═════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return _buildThemedBackground(
      themeMode: themeMode,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await SoundHelper().playClick();
              if (mounted) Navigator.pop(context);
            },
          ),
          title: const Text('Manajemen Data Siswa'),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () async {
                await SoundHelper().playClick();
                _showAddStudentDialog();
              },
              tooltip: 'Tambah Siswa',
            ),
            IconButton(
              icon: const Icon(Icons.upload_file_outlined),
              onPressed: () async {
                await SoundHelper().playClick();
                _excelImporter.showImportFileDialog(context);
              },
              tooltip: 'Import Excel',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) async {
                await SoundHelper().playClick();
                switch (value) {
                  case 'guide':
                    _showGuideDialog();
                    break;
                  case 'class_x':
                    _showAddClassXDialog();
                    break;
                  case 'payments':
                    _managePayments();
                    break;
                  case 'promote':
                    _promoteClasses();
                    break;
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'guide', child: ListTile(leading: Icon(Icons.help_outline), title: Text('Petunjuk Import'), contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'class_x', child: ListTile(leading: Icon(Icons.group_add), title: Text('Tambah Kelas X'), contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'payments', child: ListTile(leading: Icon(Icons.payment), title: Text('Kelola Pembayaran'), contentPadding: EdgeInsets.zero)),
                const PopupMenuItem(value: 'promote', child: ListTile(leading: Icon(Icons.arrow_upward), title: Text('Naik Kelas'), contentPadding: EdgeInsets.zero)),
              ],
            ),
          ],
        ),
        body: FutureBuilder<List<Student>>(
          future: fetchActiveStudents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error memuat data: ${snapshot.error}'));
            }

            final allStudents = snapshot.data ?? [];
            final kelasOptions = ['Semua', ...{for (var s in allStudents) s.kelas}];

            final filteredStudents = _filterKelas == 'Semua'
                ? allStudents
                : allStudents.where((s) => s.kelas == _filterKelas).toList();

            return RefreshIndicator(
              onRefresh: () async {
                setState(() {}); // Trigger rebuild to refetch
              },
              child: CustomScrollView(
                slivers: [
                  // ─── STATISTIK ───
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildStatsSection(themeMode, allStudents)),
                  ),

                  // ─── AKSI CEPAT ───
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildSectionHeader(title: 'Aksi Cepat', themeMode: themeMode)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildQuickActionsSection(themeMode)),
                  ),

                  // ─── FILTER ───
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildSectionHeader(title: 'Filter Kelas', themeMode: themeMode)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(child: _buildFilterSection(themeMode, kelasOptions)),
                  ),

                  // ─── DAFTAR SISWA ───
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _buildSectionHeader(
                        title: filteredStudents.isEmpty ? 'Daftar Siswa' : 'Daftar Siswa (${filteredStudents.length})',
                        themeMode: themeMode,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: filteredStudents.isEmpty
                        ? SliverToBoxAdapter(child: _buildEmptyState(themeMode))
                        : SliverList.builder(
                            itemCount: filteredStudents.length,
                            itemBuilder: (context, index) {
                              final s = filteredStudents[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: index < filteredStudents.length - 1 ? 10 : 0),
                                child: _buildStudentCard(s, themeMode),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// ================== HELPER CLASS ==================
// ============================================================

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}