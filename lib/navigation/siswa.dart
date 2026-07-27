// navigation/siswa.dart
import 'package:flutter/material.dart';
import '../data.dart';
import '../templates/sound_helper.dart'; // 🔥 import

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
class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  String _searchQuery = '';
  String _filterKelas = 'Semua';

  List<String> get _kelasOptions {
    final set = <String>{};
    for (var s in dummyStudents.where((s) => s.isActive)) {
      set.add(s.kelas);
    }
    return ['Semua', ...set.toList()..sort()];
  }

  @override
  Widget build(BuildContext context) {
    final activeStudents = dummyStudents.where((s) => s.isActive).toList();
    final filtered = activeStudents.where((s) {
      final query = _searchQuery.toLowerCase();
      bool matchName = s.name.toLowerCase().contains(query);
      bool matchNis = s.nis.toLowerCase().contains(query);
      bool matchKelas = s.kelas.toLowerCase().contains(query);
      bool matchFilter = (_filterKelas == 'Semua') || (s.kelas == _filterKelas);
      return (matchName || matchNis || matchKelas) && matchFilter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Siswa Aktif'),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: () {
              SoundHelper().playClick(); // 🔥
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ArchiveRootPage()),
              );
            },
            tooltip: 'Lihat Arsip',
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
                      hintText: 'Cari nama, NIS...',
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
                DropdownButton<String>(
                  value: _filterKelas,
                  items: _kelasOptions.map((kelas) {
                    return DropdownMenuItem(value: kelas, child: Text(kelas));
                  }).toList(),
                  onChanged: (val) {
                    SoundHelper().playClick(); // 🔥
                    setState(() => _filterKelas = val!);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Tidak ada siswa aktif'))
                : ListView.builder(
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
                            SoundHelper().playClick(); // 🔥
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
                  ),
          ),
        ],
      ),
    );
  }
}

// ================== HALAMAN ARSIP ROOT ==================
class ArchiveRootPage extends StatelessWidget {
  const ArchiveRootPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tahunKeys = arsipSiswa.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: const Text('Arsip Siswa')),
      body: tahunKeys.isEmpty
          ? const Center(child: Text('Belum ada arsip'))
          : ListView.builder(
              itemCount: tahunKeys.length,
              itemBuilder: (context, index) {
                final tahun = tahunKeys[index];
                final kelasMap = arsipSiswa[tahun]!;
                final totalSiswa = kelasMap.values.fold(
                  0,
                  (sum, list) => sum + list.length,
                );

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.folder, color: Colors.amber),
                    title: Text(tahun),
                    subtitle: Text(
                      '$totalSiswa siswa • ${kelasMap.length} kelas',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      SoundHelper().playClick(); // 🔥
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveClassPage(tahun: tahun),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ================== HALAMAN ARSIP PER KELAS ==================
class ArchiveClassPage extends StatelessWidget {
  final String tahun;
  const ArchiveClassPage({super.key, required this.tahun});

  @override
  Widget build(BuildContext context) {
    final kelasMap = arsipSiswa[tahun] ?? {};
    final kelasKeys = kelasMap.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text('Arsip $tahun')),
      body: kelasKeys.isEmpty
          ? const Center(child: Text('Kosong'))
          : ListView.builder(
              itemCount: kelasKeys.length,
              itemBuilder: (context, index) {
                final kelas = kelasKeys[index];
                final siswaList = kelasMap[kelas]!;

                return Card(
                  child: ListTile(
                    leading: Icon(
                      Icons.folder_open,
                      color: getMajorColor(kelas),
                    ),
                    title: Text(kelas),
                    subtitle: Text('${siswaList.length} siswa'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      SoundHelper().playClick(); // 🔥
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArchiveStudentListPage(
                            tahun: tahun,
                            kelas: kelas,
                            siswaList: siswaList,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

// ================== HALAMAN DAFTAR SISWA DALAM ARSIP ==================
class ArchiveStudentListPage extends StatelessWidget {
  final String tahun;
  final String kelas;
  final List<Student> siswaList;

  const ArchiveStudentListPage({
    super.key,
    required this.tahun,
    required this.kelas,
    required this.siswaList,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$kelas - $tahun')),
      body: ListView.builder(
        itemCount: siswaList.length,
        itemBuilder: (context, index) {
          final s = siswaList[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.withOpacity(0.3),
                child: Text(
                  s.name[0],
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              title: Text(s.name),
              subtitle: Text('NIS: ${s.nis} • ${s.alamat}'),
              trailing: IconButton(
                icon: const Icon(Icons.remove_red_eye, color: Colors.grey),
                onPressed: () {
                  SoundHelper().playClick(); // 🔥
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Siswa sudah lulus (arsip)')),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

// ================== HALAMAN DETAIL SISWA ==================
class StudentDetailPage extends StatefulWidget {
  final Student student;
  const StudentDetailPage({super.key, required this.student});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Student student;
  final TextEditingController _quickPayController = TextEditingController();

  @override
  void initState() {
    super.initState();
    student = widget.student;
  }

  // ========== FUNGSI PEMBAYARAN CEPAT ==========
  void _quickPayment() {
    final input = _quickPayController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal pembayaran')),
      );
      return;
    }
    double amount = double.tryParse(input) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0')),
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
        addIncomeTransaction('Saldo tabungan - ${student.name}', amount);
        _log('Pembayaran saldo tabungan sebesar Rp ${formatCurrency(amount)}');
        _quickPayController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saldo tabungan bertambah Rp ${formatCurrency(amount)}',
            ),
          ),
        );
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
          addIncomeTransaction(
            'Pembayaran lunas semua - ${student.name}',
            amount,
          );
          _log(
            'Pembayaran cepat lunas semua, surplus Rp ${formatCurrency(surplus)} masuk saldo',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Semua lunas! Surplus Rp ${formatCurrency(surplus)} masuk saldo',
              ),
            ),
          );
        } else {
          addIncomeTransaction(
            'Pembayaran lunas semua - ${student.name}',
            amount,
          );
          _log('Pembayaran cepat lunas semua (pas)');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Semua pembayaran lunas!')),
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
        addIncomeTransaction('Pembayaran parsial - ${student.name}', amount);
        _log('Pembayaran cepat parsial sebesar Rp ${formatCurrency(amount)}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembayaran Rp ${formatCurrency(amount)} didistribusikan',
            ),
          ),
        );
      }
      _quickPayController.clear();
    });
  }

  void _log(String detail) {
    dummyLogs.insert(
      0,
      ActivityLog(
        user: 'Admin',
        action: ActivityAction.bayar,
        detail: '$detail (${student.name})',
        timestamp: DateTime.now(),
      ),
    );
  }

  // ========== TOGGLE PEMBAYARAN ==========
  void _togglePayment(int index) {
    setState(() {
      final item = student.payments[index];
      if (item.type == 'Saldo') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saldo tabungan tidak dapat diubah secara manual'),
          ),
        );
        return;
      }
      if (item.status != PaymentStatus.lunas) {
        double amountToPay = item.amount - item.paidAmount;
        item.status = PaymentStatus.lunas;
        item.paidAmount = item.amount;
        item.lastPaymentDate = DateTime.now();
        addIncomeTransaction('${item.type} - ${student.name}', amountToPay);
        _log('Melunasi ${item.type}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran sudah lunas dan tidak dapat dibatalkan'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: getMajorColor(student.kelas),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Siswa',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _infoRow('Nama', student.name),
                    _infoRow('NIS', student.nis),
                    _infoRow('Alamat', student.alamat),
                    _infoRow('No. Telepon', student.phone),
                    _infoRow(
                      'Jenis Kelamin',
                      getExtraInfo(student.id, 'jenisKelamin'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pembayaran Cepat',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quickPayController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: 'Masukkan nominal',
                              border: OutlineInputBorder(),
                              prefixText: 'Rp ',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            SoundHelper().playClick(); // 🔥
                            _quickPayment();
                          },
                          icon: const Icon(Icons.payment),
                          label: const Text('Bayar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nominal akan dialokasikan ke semua tagihan yang belum lunas. Kelebihan akan menjadi saldo tabungan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Riwayat Pembayaran',
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
                    'Rp ${formatCurrency(payment.amount)} • ${payment.status == PaymentStatus.lunas
                        ? 'Lunas'
                        : payment.status == PaymentStatus.sebagian
                        ? 'Sebagian'
                        : 'Belum Bayar'}',
                  ),
                  trailing: payment.type == 'Saldo'
                      ? Text(
                          'Saldo: Rp ${formatCurrency(payment.amount)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        )
                      : payment.status == PaymentStatus.lunas
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : TextButton(
                          onPressed: () {
                            SoundHelper().playClick(); // 🔥
                            _togglePayment(idx);
                          },
                          child: const Text('Lunas'),
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
                      'Ringkasan Keuangan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      'Total Tagihan',
                      'Rp ${formatCurrency(student.totalDue)}',
                    ),
                    _summaryRow(
                      'Total Dibayar',
                      'Rp ${formatCurrency(student.totalPaid)}',
                    ),
                    const Divider(),
                    _summaryRow(
                      'Sisa Tagihan',
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
                                'Saldo Tabungan',
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
                          '✅ Saldo ini dapat digunakan untuk pembayaran di tahun ajaran berikutnya (naik kelas).',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    if (student.remaining > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '⚠️ Masih ada tagihan yang belum lunas. Gunakan pembayaran cepat atau lunasi per item.',
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