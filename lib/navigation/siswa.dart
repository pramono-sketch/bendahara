// navigation/siswa.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../l10n/translations.dart';
import '../templates/sound_helper.dart';

// ========== FUNGSI BANTU UNTUK PROGRES ==========
double _getPaymentProgress(Student student) {
  double totalDue = student.totalDue;
  if (totalDue == 0) return 1.0;
  double totalPaid = student.totalPaid;
  return (totalPaid / totalDue).clamp(0.0, 1.0);
}

Color _getProgressColor(double progress) {
  if (progress >= 1.0) return AppColors.success;
  if (progress >= 0.5) return AppColors.warning;
  return AppColors.error;
}

// ================== HALAMAN UTAMA SISWA ==================
class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _searchQuery = '';
  String _filterKelas = 'Semua';

  Stream<List<Student>> get _studentsStream {
    return studentsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Student.fromMap(doc.data()))
          .toList();
    });
  }

  Future<List<String>> _getKelasOptions() async {
    final t = ref.read(translationsProvider).t;
    final snapshot =
        await studentsCollection.where('isActive', isEqualTo: true).get();
    final set = <String>{};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final kelas = data['kelas'] as String?;
      if (kelas != null) set.add(kelas);
    }
    return [t('all'), ...set.toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('active_students_data')),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {
              SoundHelper().playClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchiveRootPage()),
              );
            },
            tooltip: t('view_archive'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: t('search_name_nis'),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                FutureBuilder<List<String>>(
                  future: _getKelasOptions(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final options = snapshot.data!;
                    final currentVal =
                        options.contains(_filterKelas) ? _filterKelas : options.first;
                    return DropdownButton<String>(
                      value: currentVal,
                      items: options.map((kelas) {
                        return DropdownMenuItem(
                          value: kelas,
                          child: Text(kelas),
                        );
                      }).toList(),
                      onChanged: (val) {
                        SoundHelper().playClick();
                        setState(() => _filterKelas = val!);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Student>>(
              stream: _studentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text(t('no_active_students')));
                }

                final allStudents = snapshot.data!;
                final filtered = allStudents.where((s) {
                  final query = _searchQuery.toLowerCase();
                  bool matchName = s.name.toLowerCase().contains(query);
                  bool matchNis = s.nis.toLowerCase().contains(query);
                  bool matchKelas = s.kelas.toLowerCase().contains(query);
                  bool matchFilter =
                      (_filterKelas == t('all')) || (s.kelas == _filterKelas);
                  return (matchName || matchNis || matchKelas) && matchFilter;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(child: Text(t('no_active_students')));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final majorColor = getMajorColor(student.kelas);
                    final progress = _getPaymentProgress(student);
                    final progressColor = _getProgressColor(progress);
                    final progressText = '${(progress * 100).toInt()}%';

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: majorColor.withOpacity(0.2),
                          child: Text(
                            student.name[0],
                            style: TextStyle(
                              color: majorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(student.name),
                        subtitle: Row(
                          children: [
                            Text('${student.nis} • ${student.kelas}'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: progressColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: progressColor),
                              ),
                              child: Text(
                                progressText,
                                style: TextStyle(
                                  color: progressColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          SoundHelper().playClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  StudentDetailPage(student: student),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ================== HALAMAN ARSIP ROOT ======================
// ============================================================
class ArchiveRootPage extends ConsumerStatefulWidget {
  const ArchiveRootPage({super.key});

  @override
  ConsumerState<ArchiveRootPage> createState() => _ArchiveRootPageState();
}

class _ArchiveRootPageState extends ConsumerState<ArchiveRootPage> {
  List<Map<String, dynamic>> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _folders = await fetchArchiveFolders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('student_archive')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              SoundHelper().playClick();
              _loadFolders();
            },
            tooltip: t('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFolders,
                        child: Text(t('try_again')),
                      ),
                    ],
                  ),
                )
              : _folders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive_outlined,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            t('no_archive_yet'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t('archive_will_appear'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFolders,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _folders.length,
                        itemBuilder: (context, index) {
                          final folder = _folders[index];
                          final name = folder['name'] as String;
                          final count = folder['count'] as int;

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.folder,
                                    color: Colors.amber, size: 32),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text('$count ${t('students_archived')}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                SoundHelper().playClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArchiveMajorsPage(
                                        tahunArsip: name),
                                  ),
                                ).then((_) => _loadFolders());
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ============================================================
// ================== HALAMAN ARSIP PER JURUSAN ===============
// ============================================================
class ArchiveMajorsPage extends ConsumerStatefulWidget {
  final String tahunArsip;
  const ArchiveMajorsPage({super.key, required this.tahunArsip});

  @override
  ConsumerState<ArchiveMajorsPage> createState() => _ArchiveMajorsPageState();
}

class _ArchiveMajorsPageState extends ConsumerState<ArchiveMajorsPage> {
  List<Map<String, dynamic>> _majors = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMajors();
  }

  Future<void> _loadMajors() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _majors = await fetchMajorsInArchive(widget.tahunArsip);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getMajorColor(String major) {
    switch (major) {
      case 'TKJ':
        return Colors.red;
      case 'RPL':
        return Colors.green;
      case 'TKR':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getMajorIcon(String major) {
    switch (major) {
      case 'TKJ':
        return Icons.computer;
      case 'RPL':
        return Icons.code;
      case 'TKR':
        return Icons.build;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    return Scaffold(
      appBar: AppBar(
        title: Text('${t('archive')} ${widget.tahunArsip}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              SoundHelper().playClick();
              _loadMajors();
            },
            tooltip: t('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMajors,
                        child: Text(t('try_again')),
                      ),
                    ],
                  ),
                )
              : _majors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_off,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(t('no_majors_found')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMajors,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _majors.length,
                        itemBuilder: (context, index) {
                          final major = _majors[index];
                          final name = major['name'] as String;
                          final count = major['count'] as int;
                          final color = _getMajorColor(name);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_getMajorIcon(name),
                                    color: color, size: 28),
                              ),
                              title: Text(
                                '${t('major')} $name',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text('$count ${t('students')}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                SoundHelper().playClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ArchiveStudentListPage(
                                      tahunArsip: widget.tahunArsip,
                                      jurusan: name,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ============================================================
// ================== HALAMAN DAFTAR SISWA ARSIP ==============
// ============================================================
class ArchiveStudentListPage extends ConsumerStatefulWidget {
  final String tahunArsip;
  final String jurusan;

  const ArchiveStudentListPage({
    super.key,
    required this.tahunArsip,
    required this.jurusan,
  });

  @override
  ConsumerState<ArchiveStudentListPage> createState() =>
      _ArchiveStudentListPageState();
}

class _ArchiveStudentListPageState
    extends ConsumerState<ArchiveStudentListPage> {
  List<Student> _students = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _students =
          await fetchArchivedStudents(widget.tahunArsip, widget.jurusan);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.jurusan} - ${widget.tahunArsip}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              SoundHelper().playClick();
              _loadStudents();
            },
            tooltip: t('refresh'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStudents,
                        child: Text(t('try_again')),
                      ),
                    ],
                  ),
                )
              : _students.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(t('no_archived_students')),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStudents,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final s = _students[index];

                          return Card(
                            elevation: 1,
                            margin: const EdgeInsets.only(bottom: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.withOpacity(0.3),
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ),
                              title: Text(s.name),
                              subtitle: Text(
                                  '${t('nis_label')}: ${s.nis} • ${s.kelas}'),
                              trailing: const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                              onTap: () {
                                SoundHelper().playClick();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudentDetailPage(
                                      student: s,
                                      isArchived: true,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// ============================================================
// ================== HALAMAN DETAIL SISWA ====================
// ============================================================
class StudentDetailPage extends ConsumerStatefulWidget {
  final Student student;
  final bool isArchived;

  const StudentDetailPage({
    super.key,
    required this.student,
    this.isArchived = false,
  });

  @override
  ConsumerState<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends ConsumerState<StudentDetailPage> {
  late Student student;
  final TextEditingController _quickPayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    student = widget.student;
  }

  // ========== FUNGSI PEMBAYARAN CEPAT ==========
  void _quickPayment() async {
    final t = ref.read(translationsProvider).t;

    if (widget.isArchived) return;

    final input = _quickPayController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('enter_payment_amount'))),
      );
      return;
    }
    double amount = double.tryParse(input) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('amount_must_be_positive'))),
      );
      return;
    }

    setState(() {
      List<PaymentItem> unpaid = student.payments
          .where((p) => p.status != PaymentStatus.lunas && p.type != 'Saldo')
          .toList();

      if (unpaid.isEmpty) {
        PaymentItem? saldo = student.payments.firstWhere(
          (p) => p.type == 'Saldo',
          orElse: () => PaymentItem(
            type: 'Saldo',
            amount: 0,
            status: PaymentStatus.lunas,
            paidAmount: 0,
          ),
        );
        if (saldo.type == 'Saldo') {
          saldo.amount += amount;
          saldo.paidAmount = saldo.amount;
          saldo.lastPaymentDate = DateTime.now();
        } else {
          student.payments.add(
            PaymentItem(
              type: 'Saldo',
              amount: amount,
              status: PaymentStatus.lunas,
              paidAmount: amount,
              lastPaymentDate: DateTime.now(),
            ),
          );
        }
        _addTransaction(
          TransType.pemasukan,
          '${t('savings_payment')} ${student.name}',
          amount,
        );
        _log('${t('savings_payment_log')} Rp ${formatCurrency(amount)}');
        _quickPayController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t('savings_increased')} Rp ${formatCurrency(amount)}',
            ),
          ),
        );
        _saveStudentToFirestore();
        return;
      }

      double totalRemaining = 0;
      for (var p in unpaid) {
        totalRemaining += (p.amount - p.paidAmount);
      }

      if (amount >= totalRemaining) {
        for (var p in unpaid) {
          p.status = PaymentStatus.lunas;
          p.paidAmount = p.amount;
          p.lastPaymentDate = DateTime.now();
        }
        double surplus = amount - totalRemaining;
        if (surplus > 0) {
          PaymentItem? saldo = student.payments.firstWhere(
            (p) => p.type == 'Saldo',
            orElse: () => PaymentItem(
              type: 'Saldo',
              amount: 0,
              status: PaymentStatus.lunas,
              paidAmount: 0,
            ),
          );
          if (saldo.type == 'Saldo') {
            saldo.amount += surplus;
            saldo.paidAmount = saldo.amount;
            saldo.lastPaymentDate = DateTime.now();
          } else {
            student.payments.add(
              PaymentItem(
                type: 'Saldo',
                amount: surplus,
                status: PaymentStatus.lunas,
                paidAmount: surplus,
                lastPaymentDate: DateTime.now(),
              ),
            );
          }
          _addTransaction(
            TransType.pemasukan,
            '${t('full_payment')} ${student.name}',
            amount,
          );
          _log(
            '${t('quick_payment_full_log')}, surplus Rp ${formatCurrency(surplus)} ${t('went_to_savings')}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${t('all_paid_surplus')} Rp ${formatCurrency(surplus)} ${t('went_to_savings')}',
              ),
            ),
          );
        } else {
          _addTransaction(
            TransType.pemasukan,
            '${t('full_payment')} ${student.name}',
            amount,
          );
          _log(t('quick_payment_full_log_exact'));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t('all_payments_paid'))),
          );
        }
      } else {
        double totalUnpaid = totalRemaining;
        for (var p in unpaid) {
          double debt = p.amount - p.paidAmount;
          double portion = debt / totalUnpaid;
          double payment = amount * portion;
          if (payment >= debt) {
            p.status = PaymentStatus.lunas;
            p.paidAmount = p.amount;
          } else {
            p.status = PaymentStatus.sebagian;
            p.paidAmount += payment;
          }
          p.lastPaymentDate = DateTime.now();
        }
        _addTransaction(
          TransType.pemasukan,
          '${t('partial_payment')} ${student.name}',
          amount,
        );
        _log('${t('quick_payment_partial_log')} Rp ${formatCurrency(amount)}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${t('payment_distributed')} Rp ${formatCurrency(amount)} ${t('distributed')}',
            ),
          ),
        );
      }
      _quickPayController.clear();
      _saveStudentToFirestore();
    });
  }

  // ========== FUNGSI BANTU ==========
  void _log(String detail) {
    final log = ActivityLog(
      user: 'Admin',
      action: ActivityAction.bayar,
      detail: '$detail (${student.name})',
      timestamp: DateTime.now(),
    );
    addActivityLog(log);
  }

  void _addTransaction(TransType type, String desc, double amount) {
    final t = ref.read(translationsProvider).t;
    final transactionType = type == TransType.pemasukan ? t('income') : t('expense');

    final trx = Transaction(
      id: 'TRX${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: desc,
      date: DateTime.now(),
      category: transactionType,
    );
    addTransaction(trx);
  }

  Future<void> _saveStudentToFirestore() async {
    if (widget.isArchived) return;
    await saveStudent(student);
  }

  // ========== TOGGLE PEMBAYARAN ==========
  void _togglePayment(int index) async {
    final t = ref.read(translationsProvider).t;

    if (widget.isArchived) return;

    setState(() {
      final item = student.payments[index];
      if (item.type == 'Saldo') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('savings_cannot_be_changed')),
          ),
        );
        return;
      }
      if (item.status != PaymentStatus.lunas) {
        double amountToPay = item.amount - item.paidAmount;
        item.status = PaymentStatus.lunas;
        item.paidAmount = item.amount;
        item.lastPaymentDate = DateTime.now();
        _addTransaction(
          TransType.pemasukan,
          '${item.type} - ${student.name}',
          amountToPay,
        );
        _log('${t('paid_off')} ${item.type}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t('payment_cannot_be_canceled')),
          ),
        );
        return;
      }
    });
    await _saveStudentToFirestore();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    PaymentItem? saldoItem = student.payments.firstWhere(
      (p) => p.type == 'Saldo',
      orElse: () => PaymentItem(
        type: 'Saldo',
        amount: 0,
        status: PaymentStatus.lunas,
        paidAmount: 0,
      ),
    );
    double saldo = saldoItem.amount;

    return Scaffold(
      appBar: AppBar(
        title: Text(student.name),
        backgroundColor: widget.isArchived
            ? Colors.grey
            : getMajorColor(student.kelas),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isArchived)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.archive, color: Colors.grey.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t('archived_student_notice'),
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('student_info'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _infoRow(t('name'), student.name),
                    _infoRow(t('nis_label'), student.nis),
                    _infoRow(t('address'), student.alamat),
                    _infoRow(t('phone_number'), student.phone),
                    _infoRow(
                      t('gender'),
                      getExtraInfo(student.id, 'jenisKelamin'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (!widget.isArchived)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('quick_payment'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quickPayController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: t('enter_amount'),
                                border: const OutlineInputBorder(),
                                prefixText: 'Rp ',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () {
                              SoundHelper().playClick();
                              _quickPayment();
                            },
                            icon: const Icon(Icons.payment),
                            label: Text(t('pay')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t('quick_payment_hint'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!widget.isArchived) const SizedBox(height: 16),
            Text(
              t('payment_history'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...student.payments.map((payment) {
              final idx = student.payments.indexOf(payment);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(
                      payment.status,
                    ).withOpacity(0.1),
                    child: Icon(
                      payment.status == PaymentStatus.lunas
                          ? Icons.check_circle
                          : payment.status == PaymentStatus.sebagian
                              ? Icons.remove_circle_outline
                              : Icons.cancel_outlined,
                      color: _statusColor(payment.status),
                    ),
                  ),
                  title: Text(payment.type),
                  subtitle: Text(
                    'Rp ${formatCurrency(payment.amount)} • ${payment.status == PaymentStatus.lunas ? t('paid') : payment.status == PaymentStatus.sebagian ? t('partial') : t('unpaid')}',
                  ),
                  trailing: payment.type == 'Saldo'
                      ? Text(
                          '${t('balance_label')}: Rp ${formatCurrency(payment.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        )
                      : payment.status == PaymentStatus.lunas
                          ? const Icon(Icons.check_circle,
                              color: AppColors.success)
                          : widget.isArchived
                              ? Text(
                                  payment.status == PaymentStatus.sebagian
                                      ? t('partial')
                                      : t('unpaid'),
                                  style: TextStyle(
                                    color: _statusColor(payment.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : TextButton(
                                  onPressed: () {
                                    SoundHelper().playClick();
                                    _togglePayment(idx);
                                  },
                                  child: Text(t('mark_paid')),
                                ),
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('financial_summary'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      t('total_bills'),
                      'Rp ${formatCurrency(student.totalDue)}',
                    ),
                    _summaryRow(
                      t('total_paid'),
                      'Rp ${formatCurrency(student.totalPaid)}',
                    ),
                    const Divider(),
                    _summaryRow(
                      t('remaining_bills'),
                      'Rp ${formatCurrency(student.remaining)}',
                      color: student.remaining > 0
                          ? AppColors.error
                          : student.remaining < 0
                              ? AppColors.success
                              : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.savings,
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                t('savings_balance'),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Rp ${formatCurrency(saldo)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (saldo > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '✅ ${t('savings_notice')}',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (!widget.isArchived && student.remaining > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ ${t('unpaid_warning')}',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET PEMBANTU ==========
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.lunas:
        return AppColors.success;
      case PaymentStatus.sebagian:
        return AppColors.warning;
      case PaymentStatus.belumBayar:
        return AppColors.error;
    }
  }
}