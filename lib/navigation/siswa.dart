// lib/navigation/siswa.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/appearance.dart';
import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/scroll_reveal.dart';
import '../helpers/theme_helper.dart';
import '../l10n/translations.dart';
import '../helpers/custom_animation.dart';
import '../helpers/sound_helper.dart';

// ============================================================
// FUNGSI BANTU UNTUK PROGRES
// ============================================================

double _getPaymentProgress(Student student) {
  final double totalDue = student.totalDue;

  if (totalDue == 0) {
    return 0.0;
  }

  final double totalPaid = student.totalPaid;

  return (totalPaid / totalDue).clamp(0.0, 1.0);
}

Color _getProgressColor(double progress) {
  if (progress >= 1.0) {
    return AppColors.success;
  }

  if (progress >= 0.5) {
    return AppColors.warning;
  }

  return AppColors.error;
}

// ============================================================
// HALAMAN UTAMA SISWA
// ============================================================

class StudentsPage extends ConsumerStatefulWidget {
  const StudentsPage({super.key});

  @override
  ConsumerState<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends ConsumerState<StudentsPage> {
  String _searchQuery = '';

  static const String _allClassFilter = '__ALL_CLASSES__';

  String _filterKelas = _allClassFilter;

  Stream<List<Student>> get _studentsStream {
    return studentsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final paymentConfigs = await fetchPaymentManagement();

          return snapshot.docs.map((doc) {
            final student = Student.fromMap(doc.data());

            final grade = paymentGradeFromClass(student.kelas);
            final config = paymentConfigs[grade] ?? [];

            student.payments = syncStudentPaymentsWithConfig(
              student.payments,
              config,
            );

            return student;
          }).toList();
        });
  }

  Future<List<String>> _getKelasOptions() async {
    final snapshot = await studentsCollection
        .where('isActive', isEqualTo: true)
        .get();

    final set = <String>{};

    for (var doc in snapshot.docs) {
      final data = doc.data();

      final kelas = data['kelas'] as String?;

      if (kelas != null) {
        set.add(kelas);
      }
    }

    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    final themeMode = ref.watch(themeModeProvider);

    final allText = t('all');

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        appBar: AppBar(
          title: Text(t('active_students_data')),
          actions: [
            IconButton(
              icon: const Icon(Icons.archive),
              onPressed: () {
                SoundHelper().playClick();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ArchiveRootPage(),
                  ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<List<String>>(
                    future: _getKelasOptions(),
                    builder: (context, snapshot) {
                      final classes = snapshot.data ?? [];

                      final items = [
                        DropdownMenuItem<String>(
                          value: _allClassFilter,
                          child: Text(allText),
                        ),
                        ...classes.map((kelas) {
                          return DropdownMenuItem<String>(
                            value: kelas,
                            child: Text(kelas),
                          );
                        }),
                      ];

                      final currentValue = _filterKelas == _allClassFilter ||
                              classes.contains(_filterKelas)
                          ? _filterKelas
                          : _allClassFilter;

                      return DropdownButton<String>(
                        value: currentValue,
                        dropdownColor:
                            Theme.of(context).colorScheme.surface,
                        items: items,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          SoundHelper().playClick();

                          setState(() {
                            _filterKelas = value;
                          });
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
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const LottieLoading();
                  }

                  if (snapshot.hasError) {
                    return _FirebaseErrorView(
                      message: snapshot.error.toString(),
                    );
                  }

                  if (!snapshot.hasData) {
                    return LottieError(
                      message: t('no_active_students'),
                    );
                  }

                  final allStudents = snapshot.data!;

                  if (allStudents.isEmpty) {
                    return LottieError(
                      message: t('no_active_students'),
                    );
                  }

                  final query =
                      _searchQuery.toLowerCase().trim();

                  final filtered = allStudents.where((student) {
                    final matchName =
                        student.name.toLowerCase().contains(query);

                    final matchNis =
                        student.nis.toLowerCase().contains(query);

                    final matchKelas =
                        student.kelas.toLowerCase().contains(query);

                    final matchFilter = _filterKelas == _allClassFilter ||
                        student.kelas == _filterKelas;

                    return (matchName || matchNis || matchKelas) &&
                        matchFilter;
                  }).toList();

                  if (filtered.isEmpty) {
                    return LottieError(
                      message: t('no_active_students'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final student = filtered[index];

                      final majorColor =
                          getMajorColor(student.kelas);

                      final progress = _getPaymentProgress(student);

                      final progressColor =
                          _getProgressColor(progress);

                      final progressText =
                          '${(progress * 100).toInt()}%';

                      final delayMs =
                          (index * 35).clamp(0, 280).toInt();

                      return ScrollReveal(
                        delay: Duration(milliseconds: delayMs),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  majorColor.withOpacity(0.2),
                              child: Text(
                                student.name.isNotEmpty
                                    ? student.name[0]
                                    : '?',
                                style: TextStyle(
                                  color: majorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(student.name),
                            subtitle: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${student.nis} • ${student.kelas}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        progressColor.withOpacity(0.2),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    border: Border.all(
                                      color: progressColor,
                                    ),
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
                                  builder: (_) => StudentDetailPage(
                                    student: student,
                                  ),
                                ),
                              ).then((_) {
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ERROR FIREBASE
// ============================================================

class _FirebaseErrorView extends ConsumerWidget {
  const _FirebaseErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).t;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              t('firebase_data_error'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ARSIP ROOT
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      _folders = await fetchArchiveFolders();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    final themeMode = ref.watch(themeModeProvider);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
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
            ? const LottieLoading()
            : _errorMessage != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('archive_data_error'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadFolders,
                            child: Text(t('try_again')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _folders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              t('no_archive_yet'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t('archive_will_appear'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
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

                            final delayMs =
                                (index * 45).clamp(0, 300).toInt();

                            return ScrollReveal(
                              delay: Duration(milliseconds: delayMs),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.warning.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.folder,
                                      color: AppColors.warning,
                                      size: 32,
                                    ),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle:
                                      Text('$count ${t('students_archived')}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    SoundHelper().playClick();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ArchiveMajorsPage(
                                          tahunArsip: name,
                                        ),
                                      ),
                                    ).then((_) {
                                      _loadFolders();
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

// ============================================================
// ARSIP PER JURUSAN
// ============================================================

class ArchiveMajorsPage extends ConsumerStatefulWidget {
  final String tahunArsip;

  const ArchiveMajorsPage({
    super.key,
    required this.tahunArsip,
  });

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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      _majors = await fetchMajorsInArchive(widget.tahunArsip);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

    final themeMode = ref.watch(themeModeProvider);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
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
            ? const LottieLoading()
            : _errorMessage != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('archive_major_error'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMajors,
                            child: Text(t('try_again')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _majors.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
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

                            final delayMs =
                                (index * 45).clamp(0, 300).toInt();

                            return ScrollReveal(
                              delay: Duration(milliseconds: delayMs),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getMajorIcon(name),
                                      color: color,
                                      size: 28,
                                    ),
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
                                        builder: (_) =>
                                            ArchiveStudentListPage(
                                          tahunArsip: widget.tahunArsip,
                                          jurusan: name,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

// ============================================================
// DAFTAR SISWA ARSIP
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
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      _students = await fetchArchivedStudents(
        widget.tahunArsip,
        widget.jurusan,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    final themeMode = ref.watch(themeModeProvider);

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
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
            ? const LottieLoading()
            : _errorMessage != null
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            t('archive_student_error'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadStudents,
                            child: Text(t('try_again')),
                          ),
                        ],
                      ),
                    ),
                  )
                : _students.isEmpty
                    ? LottieError(message: t('no_archived_students'))
                    : RefreshIndicator(
                        onRefresh: _loadStudents,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _students.length,
                          itemBuilder: (context, index) {
                            final student = _students[index];

                            final delayMs =
                                (index * 35).clamp(0, 280).toInt();

                            return ScrollReveal(
                              delay: Duration(milliseconds: delayMs),
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withOpacity(0.5),
                                    child: Text(
                                      student.name.isNotEmpty
                                          ? student.name[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  title: Text(student.name),
                                  subtitle: Text(
                                    '${t('nis_label')}: ${student.nis} • ${student.kelas}',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    SoundHelper().playClick();

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentDetailPage(
                                          student: student,
                                          isArchived: true,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

// ============================================================
// DETAIL SISWA
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

  Future<void> _quickPayment() async {
    final t = ref.read(translationsProvider).t;

    if (widget.isArchived) {
      return;
    }

    final input = _quickPayController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('enter_payment_amount'))),
      );
      return;
    }

    final double amount = double.tryParse(input) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('amount_must_be_positive'))),
      );
      return;
    }

    final unpaid = student.payments
        .where(
          (p) =>
              p.status != PaymentStatus.lunas && p.type != 'Saldo',
        )
        .toList();

    if (unpaid.isEmpty) {
      PaymentItem saldo = student.payments.firstWhere(
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
      }

      _addTransaction(
        TransType.pemasukan,
        '${t('savings_payment')} ${student.name}',
        amount,
      );

      _log('${t('savings_payment_log')} Rp ${formatCurrency(amount)}');

      _quickPayController.clear();

      await _saveStudentToFirestore();

      if (!mounted) return;

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t('savings_increased')} Rp ${formatCurrency(amount)}',
          ),
        ),
      );

      return;
    }

    double totalRemaining = 0;

    for (final payment in unpaid) {
      totalRemaining += payment.amount - payment.paidAmount;
    }

    if (amount >= totalRemaining) {
      for (final payment in unpaid) {
        payment.status = PaymentStatus.lunas;
        payment.paidAmount = payment.amount;
        payment.lastPaymentDate = DateTime.now();
      }

      final double surplus = amount - totalRemaining;

      if (surplus > 0) {
        PaymentItem saldo = student.payments.firstWhere(
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
        }

        _addTransaction(
          TransType.pemasukan,
          '${t('full_payment')} ${student.name}',
          amount,
        );

        _log(
          '${t('quick_payment_full_log')}, '
          'surplus Rp ${formatCurrency(surplus)} ${t('went_to_savings')}',
        );
      } else {
        _addTransaction(
          TransType.pemasukan,
          '${t('full_payment')} ${student.name}',
          amount,
        );

        _log(t('quick_payment_full_log_exact'));
      }
    } else {
      final double totalUnpaid = totalRemaining;

      for (final payment in unpaid) {
        final double debt = payment.amount - payment.paidAmount;
        final double portion = debt / totalUnpaid;
        final double paymentAmount = amount * portion;

        if (paymentAmount >= debt) {
          payment.status = PaymentStatus.lunas;
          payment.paidAmount = payment.amount;
        } else {
          payment.status = PaymentStatus.sebagian;
          payment.paidAmount += paymentAmount;
        }

        payment.lastPaymentDate = DateTime.now();
      }

      _addTransaction(
        TransType.pemasukan,
        '${t('partial_payment')} ${student.name}',
        amount,
      );

      _log('${t('quick_payment_partial_log')} Rp ${formatCurrency(amount)}');
    }

    _quickPayController.clear();

    await _saveStudentToFirestore();

    if (!mounted) return;

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${t('payment_distributed')} Rp ${formatCurrency(amount)} ${t('distributed')}',
        ),
      ),
    );
  }

  void _log(String detail) {
    final log = ActivityLog(
      user: 'Admin',
      action: ActivityAction.bayar,
      detail: '$detail (${student.name})',
      timestamp: DateTime.now(),
    );

    addActivityLog(log);
  }

  void _addTransaction(
    TransType type,
    String description,
    double amount,
  ) {
    final t = ref.read(translationsProvider).t;

    final transactionType =
        type == TransType.pemasukan ? t('income') : t('expense');

    final transaction = Transaction(
      id: 'TRX${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      amount: amount,
      description: description,
      date: DateTime.now(),
      category: transactionType,
    );

    addTransaction(transaction);
  }

  Future<void> _saveStudentToFirestore() async {
    if (widget.isArchived) {
      return;
    }

    // Set logActivity to false agar tidak mendouble log siswa
    // karena transaksi dan pembayaran sudah dicatat secara spesifik.
    await saveStudent(student, logActivity: false);
  }

  Future<void> _togglePayment(int index) async {
    final t = ref.read(translationsProvider).t;

    if (widget.isArchived) {
      return;
    }

    final item = student.payments[index];

    if (item.type == 'Saldo') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('savings_cannot_be_changed'))),
      );
      return;
    }

    if (item.status == PaymentStatus.lunas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('payment_cannot_be_canceled'))),
      );
      return;
    }

    final double amountToPay = item.amount - item.paidAmount;

    setState(() {
      item.status = PaymentStatus.lunas;
      item.paidAmount = item.amount;
      item.lastPaymentDate = DateTime.now();
    });

    _addTransaction(
      TransType.pemasukan,
      '${item.type} - ${student.name}',
      amountToPay,
    );

    _log('${t('paid_off')} ${item.type}');

    await _saveStudentToFirestore();
  }

  String _getPaymentTypeLabel(
    String type,
    String Function(String) t,
  ) {
    if (type == 'Saldo') {
      return t('balance_payment_type');
    }

    return type;
  }

  String _getGenderLabel(
    String gender,
    String Function(String) t,
  ) {
    switch (gender.trim().toLowerCase()) {
      case 'laki-laki':
      case 'laki laki':
      case 'male':
        return t('male');
      case 'perempuan':
      case 'female':
        return t('female');
      default:
        return gender;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(translationsProvider).t;

    final themeMode = ref.watch(themeModeProvider);

    final PaymentItem saldoItem = student.payments.firstWhere(
      (p) => p.type == 'Saldo',
      orElse: () => PaymentItem(
        type: 'Saldo',
        amount: 0,
        status: PaymentStatus.lunas,
        paidAmount: 0,
      ),
    );

    final double saldo = saldoItem.amount;

    final theme = Theme.of(context);

    final colors = theme.colorScheme;

    final gender = getExtraInfo(student.id, 'jenisKelamin');

    return ThemeHelper.buildThemedBackground(
      themeMode,
      Scaffold(
        appBar: AppBar(
          title: Text(student.name),
          backgroundColor: widget.isArchived
              ? colors.surfaceContainerHighest
              : getMajorColor(student.kelas),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isArchived)
                ScrollReveal(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.archive, color: colors.onSurface),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t('archived_student_notice'),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ScrollReveal(
                delay: const Duration(milliseconds: 60),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('student_info'),
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(t('name'), student.name),
                        _infoRow(t('nis_label'), student.nis),
                        _infoRow(t('address'), student.alamat),
                        _infoRow(t('phone_number'), student.phone),
                        _infoRow(
                          t('gender'),
                          _getGenderLabel(gender, t),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              if (!widget.isArchived)
                ScrollReveal(
                  delay: const Duration(milliseconds: 120),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('quick_payment'),
                            style: theme.textTheme.titleMedium,
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
                                  backgroundColor: AppColors.success,
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
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              ScrollReveal(
                delay: const Duration(milliseconds: 180),
                child: Text(
                  t('payment_history'),
                  style: theme.textTheme.titleMedium,
                ),
              ),

              const SizedBox(height: 8),

              ...student.payments.asMap().entries.map((entry) {
                final idx = entry.key;
                final payment = entry.value;

                final delayMs = (idx * 35).clamp(210, 420).toInt();

                return ScrollReveal(
                  delay: Duration(milliseconds: delayMs),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            _statusColor(payment.status).withOpacity(0.1),
                        child: Icon(
                          payment.status == PaymentStatus.lunas
                              ? Icons.check_circle
                              : payment.status == PaymentStatus.sebagian
                                  ? Icons.remove_circle_outline
                                  : Icons.cancel_outlined,
                          color: _statusColor(payment.status),
                        ),
                      ),
                      title: Text(
                        _getPaymentTypeLabel(payment.type, t),
                      ),
                      subtitle: Text(
                        'Rp ${formatCurrency(payment.amount)} • '
                        '${payment.status == PaymentStatus.lunas ? t('paid') : payment.status == PaymentStatus.sebagian ? t('partial') : t('unpaid')}',
                      ),
                      trailing: payment.type == 'Saldo'
                          ? Text(
                              '${t('balance_label')}: Rp ${formatCurrency(payment.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.warning,
                              ),
                            )
                          : payment.status == PaymentStatus.lunas
                              ? const Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                )
                              : widget.isArchived
                                  ? Text(
                                      payment.status ==
                                              PaymentStatus.sebagian
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
                  ),
                );
              }),

              const SizedBox(height: 16),

              ScrollReveal(
                delay: const Duration(milliseconds: 260),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t('financial_summary'),
                          style: theme.textTheme.titleMedium,
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
                                  : colors.onSurface,
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.savings,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    t('savings_balance'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.warning,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Rp ${formatCurrency(saldo)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.warning,
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
                              style: const TextStyle(
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
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    Color? color,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color ?? colors.onSurface,
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

  @override
  void dispose() {
    _quickPayController.dispose();
    super.dispose();
  }
}