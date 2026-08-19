// simulation/FAB_helper.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../templates/sound_helper.dart';
import '../features/ai_assistant.dart';

class SimulasiHelper {
  // ============================================================
  // ================== SHOW SIMULATION DIALOG ==================
  // ============================================================

  static void showSimulationDialog(
    BuildContext parentContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
  ) {
    if (!parentContext.mounted) return;

    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(parentContext).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                // ================= HEADER =================
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.developer_mode, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Mode Simulasi Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================= TAB BAR =================
                const TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: [
                    Tab(text: 'Siswa'),
                    Tab(text: 'Akademik'),
                    Tab(text: 'Sistem'),
                  ],
                ),

                // ================= TAB CONTENT =================
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSiswaTab(parentContext, onUpdate, refreshCallback, sheetContext),
                      _buildAkademikTab(parentContext, onUpdate, refreshCallback, sheetContext),
                      _buildSistemTab(parentContext, onUpdate, refreshCallback, sheetContext),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ================== TAB BUILDERS ============================
  // ============================================================

  static Widget _buildSiswaTab(
    BuildContext parentContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
    BuildContext sheetContext,
  ) {
    final items = [
      {
        'title': 'Tambah 1 Siswa',
        'subtitle': 'Generate 1 siswa random',
        'icon': Icons.person_add,
        'color': Colors.green,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _addSingleStudent(),
          '1 siswa berhasil ditambahkan!', Colors.green, false,
        ),
      },
      {
        'title': 'Tambah 5 Siswa',
        'subtitle': 'Generate 5 siswa random',
        'icon': Icons.group_add,
        'color': Colors.blue,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _addMultipleStudents(5),
          '5 siswa berhasil ditambahkan!', Colors.blue, false,
        ),
      },
      {
        'title': 'Generate Dummy',
        'subtitle': 'Isi dengan 45 siswa dummy',
        'icon': Icons.shuffle,
        'color': Colors.purple,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _seedDummyStudents(),
          '45 siswa dummy berhasil ditambahkan!', Colors.purple, true,
          confirmTitle: 'Generate Data Dummy',
          confirmMsg: 'Akan menambahkan 45 siswa dummy. Lanjutkan?',
        ),
      },
      {
        'title': 'Reset Data Siswa',
        'subtitle': 'Hapus semua & generate baru',
        'icon': Icons.restart_alt,
        'color': Colors.teal,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async {
            await _clearAllStudents();
            await _seedDummyStudents();
          },
          'Data siswa telah direset!', Colors.teal, true,
          confirmTitle: 'Reset Data Siswa',
          confirmMsg: 'Semua data akan dihapus dan digenerate ulang. Lanjutkan?',
        ),
      },
    ];
    return _buildGrid(items);
  }

  static Widget _buildAkademikTab(
    BuildContext parentContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
    BuildContext sheetContext,
  ) {
    final items = [
      {
        'title': 'Naik Kelas',
        'subtitle': 'X → XI, XI → XII',
        'icon': Icons.upload_file,
        'color': Colors.indigo,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await promoteStudentsFirestore(),
          'Semua siswa telah naik kelas!', Colors.indigo, true,
          confirmTitle: 'Naik Kelas',
          confirmMsg: 'Semua siswa aktif akan naik kelas. Lanjutkan?',
        ),
      },
      {
        'title': 'Arsip Lulusan',
        'subtitle': 'XII diarsipkan & nonaktif',
        'icon': Icons.archive,
        'color': Colors.brown,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await archiveGraduatedStudentsFirestore('Simulasi 2024'),
          'Lulusan berhasil diarsipkan!', Colors.brown, true,
          confirmTitle: 'Arsip Lulusan',
          confirmMsg: 'Siswa kelas XII akan dinonaktifkan. Lanjutkan?',
        ),
      },
      {
        'title': 'Bulan Baru',
        'subtitle': 'Hapus semua transaksi',
        'icon': Icons.calendar_month,
        'color': Colors.cyan,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _clearAllTransactions(),
          'Transaksi bulan baru telah direset!', Colors.cyan, true,
          confirmTitle: 'Simulasi Bulan Baru',
          confirmMsg: 'Semua transaksi akan dihapus untuk memulai bulan baru. Lanjutkan?',
        ),
      },
      {
        'title': 'Tandai Lunas',
        'subtitle': 'Set semua siswa lunas',
        'icon': Icons.payment,
        'color': Colors.orange,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _markAllPaid(),
          'Semua siswa telah ditandai lunas!', Colors.orange, true,
          confirmTitle: 'Tandai Semua Lunas',
          confirmMsg: 'Yakin ingin menandai semua pembayaran lunas?',
        ),
      },
    ];
    return _buildGrid(items);
  }

  static Widget _buildSistemTab(
    BuildContext parentContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
    BuildContext sheetContext,
  ) {
    final items = [
      {
        'title': 'Hapus Semua Siswa',
        'subtitle': 'Kosongkan koleksi siswa',
        'icon': Icons.delete_sweep,
        'color': Colors.red,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _clearAllStudents(),
          'Semua siswa telah dihapus!', Colors.red, true,
          confirmTitle: 'Hapus Semua Siswa',
          confirmMsg: 'Yakin ingin menghapus semua data siswa?',
        ),
      },
      {
        'title': 'Hapus Log Aktivitas',
        'subtitle': 'Bersihkan riwayat aktivitas',
        'icon': Icons.cleaning_services,
        'color': Colors.pink,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async => await _clearAllLogs(),
          'Log aktivitas dibersihkan!', Colors.pink, true,
          confirmTitle: 'Hapus Log',
          confirmMsg: 'Yakin ingin menghapus semua log aktivitas?',
        ),
      },
      {
        'title': 'Reset Total DB',
        'subtitle': 'Hapus siswa, transaksi & log',
        'icon': Icons.dangerous,
        'color': Colors.black87,
        'onTap': () => _executeAction(
          parentContext, sheetContext, onUpdate, refreshCallback,
          () async {
            await _clearAllStudents();
            await _clearAllTransactions();
            await _clearAllLogs();
          },
          'Database telah direset total!', Colors.black87, true,
          confirmTitle: 'RESET TOTAL DATABASE',
          confirmMsg: 'PERINGATAN: Semua data siswa, transaksi, dan log akan hilang. Lanjutkan?',
        ),
      },
    ];
    return _buildGrid(items);
  }

  // ============================================================
  // ================== UI GRID BUILDER ========================
  // ============================================================

  static Widget _buildGrid(List<Map<String, dynamic>> items) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: item['onTap'] as VoidCallback,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item['icon'] as IconData, color: item['color'] as Color),
                  ),
                  const Spacer(),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'] as String,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ================== ACTION EXECUTOR =========================
  // ============================================================

  static void _executeAction(
    BuildContext parentContext,
    BuildContext sheetContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
    Future<void> Function() action,
    String successMessage,
    Color color,
    bool needConfirmation, {
    String? confirmTitle,
    String? confirmMsg,
  }) {
    Navigator.of(sheetContext).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!parentContext.mounted) return;

      void runAction() {
        if (!parentContext.mounted) return;
        _executeWithSnackBar(
          parentContext,
          action,
          successMessage,
          color,
          onUpdate,
          refreshCallback,
        );
      }

      if (needConfirmation) {
        _showConfirmDialog(
          parentContext,
          confirmTitle!,
          confirmMsg!,
          runAction,
        );
      } else {
        runAction();
      }
    });
  }

  // ============================================================
  // ================== FUNGSI SIMULASI =========================
  // ============================================================

  static Future<void> _addSingleStudent() async {
    final student = _createRandomStudent();
    await saveStudent(student);
  }

  static Future<void> _addMultipleStudents(int count) async {
    for (int i = 0; i < count; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      final student = _createRandomStudent();
      await saveStudent(student);
    }
  }

  static Future<void> _clearAllStudents() async {
    final all = await fetchAllStudents();
    final batch = firestore.FirebaseFirestore.instance.batch();
    for (final student in all) {
      final docRef = studentsCollection.doc(student.id);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  static Future<void> _seedDummyStudents() async {
    await seedFirestoreIfEmpty();
  }

  static Future<void> _markAllPaid() async {
    final students = await fetchActiveStudents();
    for (final student in students) {
      for (final payment in student.payments) {
        if (payment.status != PaymentStatus.lunas) {
          payment.status = PaymentStatus.lunas;
          payment.paidAmount = payment.amount;
          payment.lastPaymentDate = DateTime.now();
        }
      }
      await saveStudent(student);
    }
  }

  static Future<void> _clearAllTransactions() async {
    final snapshot = await transactionsCollection.get();
    final batch = firestore.FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Future<void> _clearAllLogs() async {
    final snapshot = await logsCollection.get();
    final batch = firestore.FirebaseFirestore.instance.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  static Student _createRandomStudent() {
    final random = Random();
    final grade = gradeLevels[random.nextInt(gradeLevels.length)];
    final major = majors[random.nextInt(majors.length)];
    
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final randomSuffix = random.nextInt(99);
    
    final id = 'STD$uniqueId$randomSuffix';
    final nis = '2026$uniqueId';
    final name = 'Siswa $grade $major $randomSuffix';

    return Student(
      id: id,
      name: name,
      nis: nis,
      kelas: '$grade $major',
      alamat: 'Jl. Simulasi No. $randomSuffix',
      phone: '08123456${random.nextInt(9999) + 1000}',
      payments: getDefaultPaymentsForClass('$grade $major'),
      isActive: true,
    );
  }

  // ============================================================
  // ================== CONFIRM DIALOG ==========================
  // ============================================================

  static void _showConfirmDialog(
    BuildContext parentContext,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!parentContext.mounted) return;
                  onConfirm();
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Lanjutkan'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ================== SNACKBAR & EXECUTE ======================
  // ============================================================

  static void _showSnackBar(BuildContext context, String message, Color color) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void _executeWithSnackBar(
    BuildContext parentContext,
    Future<void> Function() action,
    String successMessage,
    Color color,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
  ) {
    Future<void>(() async {
      try {
        await action();
        if (!parentContext.mounted) return;

        _showSnackBar(parentContext, successMessage, color);
        onUpdate();
        refreshCallback?.call();
      } catch (e) {
        if (!parentContext.mounted) return;
        _showSnackBar(parentContext, 'Error: $e', Colors.red);
      }
    });
  }
}

// ============================================================
// ==================== AKSI HELPER ============================
// ============================================================

class AksiHelper {
  static VoidCallback? _refreshCallback;

  static void setRefreshCallback(VoidCallback? callback) {
    _refreshCallback = callback;
  }

  static void showFABMenu(BuildContext parentContext, VoidCallback onUpdate) {
    if (!parentContext.mounted) return;

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Menu Cepat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(
                  icon: Icons.add_card,
                  label: 'Tambah\nTransaksi',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!parentContext.mounted) return;
                      showAddTransactionDialog(parentContext, onUpdate);
                    });
                  },
                ),
                _buildQuickAction(
                  icon: Icons.calculate,
                  label: 'Kalkulator',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!parentContext.mounted) return;
                      showCalculatorDialog(parentContext);
                    });
                  },
                ),
                _buildQuickAction(
                  icon: Icons.developer_mode,
                  label: 'Simulasi\nData',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!parentContext.mounted) return;
                      SimulasiHelper.showSimulationDialog(
                        parentContext,
                        onUpdate,
                        _refreshCallback,
                      );
                    });
                  },
                ),
                _buildQuickAction(
                  icon: Icons.auto_awesome,
                  label: 'AI\nAssistant',
                  onTap: () {
                    SoundHelper().playClick();
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!parentContext.mounted) return;
                      Navigator.of(parentContext).push(
                        MaterialPageRoute(
                          builder: (_) => const AIAssistantPage(),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  static void showAddTransactionDialog(
    BuildContext parentContext,
    VoidCallback onUpdate,
  ) {
    if (!parentContext.mounted) return;

    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    TransType selectedType = TransType.pemasukan;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Transaksi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<TransType>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(
                        value: TransType.pemasukan,
                        child: Text('Pemasukan'),
                      ),
                      DropdownMenuItem(
                        value: TransType.pengeluaran,
                        child: Text('Pengeluaran'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => selectedType = value);
                    },
                    decoration: const InputDecoration(labelText: 'Jenis'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Deskripsi'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Jumlah (Rp)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    SoundHelper().playClick();
                    Navigator.of(dialogContext).pop();
                    descCtrl.dispose();
                    amountCtrl.dispose();
                  },
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    SoundHelper().playClick();
                    if (descCtrl.text.trim().isEmpty ||
                        amountCtrl.text.trim().isEmpty) return;

                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
                    final description = descCtrl.text.trim();
                    final now = DateTime.now();

                    // 🔥 PERBAIKAN: ganti dummyTransactions → localTransactions
                    localTransactions.insert(
                      0,
                      Transaction(
                        id: 'TRX${localTransactions.length + 1}',
                        type: selectedType,
                        amount: amount,
                        description: description,
                        date: now,
                      ),
                    );

                    // 🔥 PERBAIKAN: ganti dummyLogs → localLogs
                    localLogs.insert(
                      0,
                      ActivityLog(
                        user: 'Admin',
                        action: ActivityAction.tambah,
                        detail: 'Tambah transaksi $description',
                        timestamp: now,
                      ),
                    );

                    Navigator.of(dialogContext).pop();
                    descCtrl.dispose();
                    amountCtrl.dispose();
                    onUpdate();
                    _refreshCallback?.call();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static void showCalculatorDialog(BuildContext parentContext) {
    if (!parentContext.mounted) return;
    showDialog(
      context: parentContext,
      builder: (_) => const CalculatorDialog(),
    );
  }
}

// ============================================================
// ================== KALKULATOR DIALOG ==========================
// ============================================================

class CalculatorDialog extends StatefulWidget {
  const CalculatorDialog({super.key});

  @override
  State<CalculatorDialog> createState() => _CalculatorDialogState();
}

class _CalculatorDialogState extends State<CalculatorDialog> {
  String _display = '0';
  String _expression = '';
  String _operator = '';
  double _firstOperand = 0;

  bool _newNumber = true;
  bool _isResult = false;

  void _pressDigit(String digit) {
    SoundHelper().playClick();
    setState(() {
      if (_isResult) {
        _display = digit;
        _expression = '';
        _isResult = false;
        _newNumber = false;
        return;
      }
      if (digit == '.' && _display.contains('.')) return;
      if (_newNumber) {
        _display = digit == '.' ? '0.' : digit;
        _newNumber = false;
      } else {
        if (_display.length < 15) _display += digit;
      }
    });
  }

  void _pressOperator(String op) {
    SoundHelper().playClick();
    if (_operator.isNotEmpty && !_newNumber) _calculateResult();
    setState(() {
      _firstOperand = double.tryParse(_display) ?? 0;
      _operator = op;
      _expression = '$_display $op ';
      _newNumber = true;
      _isResult = false;
    });
  }

  void _calculateResult() {
    final second = double.tryParse(_display) ?? 0;
    double result = 0;
    String resultStr = '';

    switch (_operator) {
      case '+':
        result = _firstOperand + second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} + ${second.toStringAsFixed(0)} =';
        break;
      case '-':
        result = _firstOperand - second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} - ${second.toStringAsFixed(0)} =';
        break;
      case '×':
        result = _firstOperand * second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} × ${second.toStringAsFixed(0)} =';
        break;
      case '÷':
        if (second == 0) {
          setState(() {
            _display = 'Error';
            _operator = '';
            _newNumber = true;
            _isResult = true;
          });
          return;
        }
        result = _firstOperand / second;
        resultStr = '${_firstOperand.toStringAsFixed(0)} ÷ ${second.toStringAsFixed(0)} =';
        break;
      default:
        return;
    }

    String displayResult = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    if (displayResult.length > 15) displayResult = result.toStringAsExponential(2);

    setState(() {
      _display = displayResult;
      _expression = resultStr;
      _operator = '';
      _newNumber = true;
      _isResult = true;
    });
  }

  void _pressEquals() {
    if (_operator.isEmpty) return;
    SoundHelper().playClick();
    _calculateResult();
  }

  void _pressClear() {
    SoundHelper().playClick();
    setState(() {
      _display = '0';
      _expression = '';
      _operator = '';
      _firstOperand = 0;
      _newNumber = true;
      _isResult = false;
    });
  }

  void _pressDelete() {
    SoundHelper().playClick();
    if (_isResult) {
      _pressClear();
      return;
    }
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
        _newNumber = true;
      }
    });
  }

  void _pressPercent() {
    SoundHelper().playClick();
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = value / 100;
      _display = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
      _isResult = true;
    });
  }

  void _pressPlusMinus() {
    SoundHelper().playClick();
    setState(() {
      final value = double.tryParse(_display) ?? 0;
      final result = value * -1;
      _display = result.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kalkulator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    SoundHelper().playClick();
                    Navigator.of(context).pop();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.surface, Colors.grey.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_expression.isNotEmpty)
                    Text(
                      _expression,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    _display,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _display == 'Error' ? AppColors.error : AppColors.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    _calcButton('AC', _pressClear, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('⌫', _pressDelete, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('%', _pressPercent, color: Colors.grey.shade200, textColor: AppColors.textPrimary),
                    _calcButton('÷', () => _pressOperator('÷'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('7', () => _pressDigit('7')),
                    _calcButton('8', () => _pressDigit('8')),
                    _calcButton('9', () => _pressDigit('9')),
                    _calcButton('×', () => _pressOperator('×'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('4', () => _pressDigit('4')),
                    _calcButton('5', () => _pressDigit('5')),
                    _calcButton('6', () => _pressDigit('6')),
                    _calcButton('-', () => _pressOperator('-'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('1', () => _pressDigit('1')),
                    _calcButton('2', () => _pressDigit('2')),
                    _calcButton('3', () => _pressDigit('3')),
                    _calcButton('+', () => _pressOperator('+'), color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _calcButton('0', () => _pressDigit('0'), flex: 2),
                    _calcButton('.', () => _pressDigit('.')),
                    _calcButton('±', _pressPlusMinus),
                    _calcButton('=', _pressEquals, color: AppColors.primary, textColor: Colors.white),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _calcButton(
    String label,
    VoidCallback onTap, {
    Color? color,
    Color? textColor,
    int flex = 1,
  }) {
    final bool isOperator = color == AppColors.primary;
    final bool isFunction = color == Colors.grey.shade200;

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(12),
          elevation: isOperator || isFunction ? 0 : 1,
          shadowColor: Colors.black.withOpacity(0.05),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: isOperator ? Colors.white.withOpacity(0.3) : AppColors.primary.withOpacity(0.1),
            highlightColor: isOperator ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isFunction || isOperator ? null : Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isOperator ? FontWeight.bold : FontWeight.w500,
                  color: textColor ?? AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}