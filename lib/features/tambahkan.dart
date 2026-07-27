// features/tambahkan.dart
import 'package:flutter/material.dart';
import '../data.dart';

// ================== HALAMAN MANAJEMEN SISWA ==================
class ManageStudentsPage extends StatefulWidget {
  const ManageStudentsPage({super.key});

  @override
  State<ManageStudentsPage> createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  List<Student> get _activeStudents =>
      dummyStudents.where((s) => s.isActive).toList();

  String _filterKelas = 'Semua';

  List<String> get _kelasOptions {
    final set = <String>{};
    for (var s in _activeStudents) {
      set.add(s.kelas);
    }
    return ['Semua', ...set.toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    final filteredStudents = _filterKelas == 'Semua'
        ? _activeStudents
        : _activeStudents.where((s) => s.kelas == _filterKelas).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Data Siswa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddStudentDialog,
            tooltip: 'Tambah Siswa Baru',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('Filter Kelas: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _filterKelas,
                        items: _kelasOptions.map((kelas) {
                          return DropdownMenuItem(
                            value: kelas,
                            child: Text(kelas),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _filterKelas = val!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _promoteClasses,
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Naik Kelas'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAddClassXDialog,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Tambah Kelas X'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _managePayments,
                    icon: const Icon(Icons.payment),
                    label: const Text('Kelola Pembayaran (per Kelas)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final s = filteredStudents[index];
                final majorColor = getMajorColor(s.kelas);
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: majorColor.withOpacity(0.2),
                      child: Text(
                        s.name[0],
                        style: TextStyle(
                          color: majorColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(s.name),
                    subtitle: Text('${s.nis} • ${s.kelas}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditStudentDialog(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteStudent(s),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ================== FUNGSI NAIK KELAS ==================
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
              '• Mengarsipkan semua siswa kelas XII (lulus) ke folder arsip\n'
              '• Menaikkan kelas XI ke XII\n'
              '• Menaikkan kelas X ke XI\n\n'
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
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final folderName = folderController.text.trim();
              if (folderName.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Nama folder tidak boleh kosong!'),
                  ),
                );
                return;
              }

              archiveGraduatedStudents(folderName);
              processClassPromotion();

              dummyLogs.insert(
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
                setState(() {});
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

  // ================== KELOLA PEMBAYARAN ==================
  void _managePayments() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Kelas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: gradeLevels.map((grade) {
            return ListTile(
              title: Text('Kelas $grade'),
              onTap: () {
                Navigator.pop(ctx);
                _showPaymentEditor(grade);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showPaymentEditor(String grade) {
    List<PaymentItem> currentList = defaultPaymentsByClass[grade] ?? [];
    List<PaymentItem> tempList = currentList.map((p) => p.copyWith()).toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: Text('Kelola Pembayaran Kelas $grade'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
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
                                onPressed: () {
                                  _editPaymentItem(context, item, (newItem) {
                                    tempList[index] = newItem;
                                    setStateDialog(() {});
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                onPressed: () {
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
                    onPressed: () {
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
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  defaultPaymentsByClass[grade] = tempList
                      .map((p) => p.copyWith())
                      .toList();
                  dummyLogs.insert(
                    0,
                    ActivityLog(
                      user: 'Admin',
                      action: ActivityAction.edit,
                      detail: 'Update pembayaran untuk kelas $grade',
                      timestamp: DateTime.now(),
                    ),
                  );
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pembayaran kelas $grade diperbarui'),
                    ),
                  );
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _editPaymentItem(
    BuildContext context,
    PaymentItem item,
    Function(PaymentItem) onSaved,
  ) {
    final TextEditingController nameController = TextEditingController(
      text: item.type,
    );
    final TextEditingController amountController = TextEditingController(
      text: item.amount.toString(),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Pembayaran'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              final newAmount =
                  double.tryParse(amountController.text.trim()) ?? 0;
              if (newName.isEmpty || newAmount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan nominal harus diisi dengan benar'),
                  ),
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
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _addNewPaymentItem(BuildContext context, Function(PaymentItem) onAdd) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Item Pembayaran'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Pembayaran'),
            ),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (name.isEmpty || amount <= 0) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Nama dan nominal harus diisi dengan benar'),
                  ),
                );
                return;
              }
              final newItem = PaymentItem(type: name, amount: amount);
              onAdd(newItem);
              Navigator.pop(ctx);
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  // ================== FUNGSI CRUD SISWA ==================
  void _showAddStudentDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '', nis = '', alamat = '', phone = '';
    String? selectedKelas;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Siswa Baru'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  onSaved: (v) => name = v!,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'NIS'),
                  onSaved: (v) => nis = v!,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    for (var grade in gradeLevels)
                      for (var major in majors)
                        DropdownMenuItem(
                          value: '$grade $major',
                          child: Text('$grade $major'),
                        ),
                  ],
                  onChanged: (v) => selectedKelas = v,
                  validator: (v) => v == null ? 'Pilih kelas' : null,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  onSaved: (v) => alamat = v!,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  onSaved: (v) => phone = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final newStudent = createStudentWithPayments(
                  id: 'STD${(dummyStudents.length + 1).toString().padLeft(3, '0')}',
                  name: name,
                  nis: nis,
                  kelas: selectedKelas!,
                  alamat: alamat,
                  phone: phone,
                );
                setState(() {
                  dummyStudents.add(newStudent);
                });
                dummyLogs.insert(
                  0,
                  ActivityLog(
                    user: 'Admin',
                    action: ActivityAction.tambah,
                    detail: 'Menambah siswa $name',
                    timestamp: DateTime.now(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showEditStudentDialog(Student student) {
    final _formKey = GlobalKey<FormState>();
    String name = student.name;
    String nis = student.nis;
    String alamat = student.alamat;
    String phone = student.phone;
    String? selectedKelas = student.kelas;
    String selectedGender = getExtraInfo(
      student.id,
      'jenisKelamin',
    ); // ambil gender saat ini

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Siswa'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                  onChanged: (v) => name = v,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  initialValue: nis,
                  decoration: const InputDecoration(labelText: 'NIS'),
                  onChanged: (v) => nis = v,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedKelas,
                  decoration: const InputDecoration(labelText: 'Kelas'),
                  items: [
                    for (var grade in gradeLevels)
                      for (var major in majors)
                        DropdownMenuItem(
                          value: '$grade $major',
                          child: Text('$grade $major'),
                        ),
                  ],
                  onChanged: (v) => selectedKelas = v,
                  validator: (v) => v == null ? 'Pilih kelas' : null,
                ),
                TextFormField(
                  initialValue: alamat,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  onChanged: (v) => alamat = v,
                ),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'No. Telepon'),
                  onChanged: (v) => phone = v,
                ),
                // DROPDOWN JENIS KELAMIN
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: const InputDecoration(labelText: 'Jenis Kelamin'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Laki-laki',
                      child: Text('Laki-laki'),
                    ),
                    DropdownMenuItem(
                      value: 'Perempuan',
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (v) => selectedGender = v!,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  student.name = name;
                  student.nis = nis;
                  student.kelas = selectedKelas!;
                  student.alamat = alamat;
                  student.phone = phone;
                  // Simpan gender ke extraInfo
                  setExtraInfo(student.id, 'jenisKelamin', selectedGender);
                });
                dummyLogs.insert(
                  0,
                  ActivityLog(
                    user: 'Admin',
                    action: ActivityAction.edit,
                    detail: 'Mengedit siswa $name',
                    timestamp: DateTime.now(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteStudent(Student student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: Text('Yakin ingin menghapus ${student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                dummyStudents.remove(student);
              });
              dummyLogs.insert(
                0,
                ActivityLog(
                  user: 'Admin',
                  action: ActivityAction.hapus,
                  detail: 'Menghapus siswa ${student.name}',
                  timestamp: DateTime.now(),
                ),
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddClassXDialog() {
    int tkjCount = 5, rplCount = 5, tkrCount = 5;
    final _formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Kelas X'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('TKJ:'),
                  Expanded(
                    child: TextFormField(
                      initialValue: '5',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => tkjCount = int.tryParse(v) ?? 0,
                      validator: (v) =>
                          int.tryParse(v!) == null ? 'Angka' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('RPL:'),
                  Expanded(
                    child: TextFormField(
                      initialValue: '5',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => rplCount = int.tryParse(v) ?? 0,
                      validator: (v) =>
                          int.tryParse(v!) == null ? 'Angka' : null,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('TKR:'),
                  Expanded(
                    child: TextFormField(
                      initialValue: '5',
                      keyboardType: TextInputType.number,
                      onChanged: (v) => tkrCount = int.tryParse(v) ?? 0,
                      validator: (v) =>
                          int.tryParse(v!) == null ? 'Angka' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  int idCounter = dummyStudents.length + 1;
                  int nisCounter = dummyStudents.length + 1;
                  void addStudentsForMajor(String major, int count) {
                    for (int i = 1; i <= count; i++) {
                      final name = 'Siswa X $major $i';
                      final nis =
                          '2026${(nisCounter++).toString().padLeft(3, '0')}';
                      final id =
                          'STD${(idCounter++).toString().padLeft(3, '0')}';
                      final newStudent = createStudentWithPayments(
                        id: id,
                        name: name,
                        nis: nis,
                        kelas: 'X $major',
                        alamat: 'Jl. Merdeka No. $idCounter',
                        phone: '08123456${(700 + idCounter).toString()}',
                      );
                      dummyStudents.add(newStudent);
                    }
                  }

                  addStudentsForMajor('TKJ', tkjCount);
                  addStudentsForMajor('RPL', rplCount);
                  addStudentsForMajor('TKR', tkrCount);
                });
                dummyLogs.insert(
                  0,
                  ActivityLog(
                    user: 'Admin',
                    action: ActivityAction.tambah,
                    detail:
                        'Menambah kelas X (TKJ:$tkjCount, RPL:$rplCount, TKR:$tkrCount)',
                    timestamp: DateTime.now(),
                  ),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }
}
