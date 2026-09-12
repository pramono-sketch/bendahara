// features/tagihan.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/sound_helper.dart';
import '../constants/appearance.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  // ============================================================
  // STATE & FIREBASE REFS
  // ============================================================
  String _searchQuery = '';
  String _filterStatus = 'all'; // all | kritis | sebagian
  final _searchCtrl = TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final CollectionReference<Map<String, dynamic>> _attentionRef;
  late final CollectionReference<Map<String, dynamic>> _studentsRef;

  @override
  void initState() {
    super.initState();
    _attentionRef = _db.collection('tagihan_attention');
    _studentsRef = _db.collection('students');
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _fmt(double v) => v.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Klasifikasi level perhatian untuk sebuah pembayaran.
  /// - 'kritis'    : belum bayar sama sekali
  /// - 'sebagian'  : sudah bayar sebagian
  /// - 'lunas'     : sudah lunas
  String _level(PaymentItem p) {
    if (p.status == PaymentStatus.belumBayar) return 'kritis';
    if (p.status == PaymentStatus.sebagian) return 'sebagian';
    return 'lunas';
  }

  Color _levelColor(String lvl) {
    switch (lvl) {
      case 'kritis':
        return AppColors.error;
      case 'sebagian':
        return Colors.orange.shade700;
      default:
        return Colors.green;
    }
  }

  /// Upload/menandai tunggakan ke Firebase (collection: tagihan_attention)
  Future<void> _flagPayment(Student s, PaymentItem p, String reason) async {
    SoundHelper().playClick();
    final docId =
        '${s.id}_${p.type.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}';

    try {
      await _attentionRef.doc(docId).set({
        'studentId': s.id,
        'studentName': s.name,
        'nis': s.nis,
        'kelas': s.kelas,
        'phone': s.phone,
        'paymentType': p.type,
        'totalAmount': p.amount,
        'paidAmount': p.paidAmount,
        'remaining': p.amount - p.paidAmount,
        'statusIndex': p.status.index,
        'reason': reason,
        'flaggedAt': FieldValue.serverTimestamp(),
        'resolved': false,
      }, SetOptions(merge: true));

      // Catat ke activity log
      await addActivityLog(ActivityLog(
        user: 'admin',
        action: ActivityAction.edit,
        detail: 'Menandai tunggakan ${s.name} - ${p.type} (${reason})',
        timestamp: DateTime.now(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${p.type} - ${s.name} ditandai untuk perhatian'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  /// Tandai sebagai sudah ditindaklanjuti (resolved=true) di Firebase
  Future<void> _resolveFlag(String docId, String studentName) async {
    SoundHelper().playClick();
    await _attentionRef.doc(docId).update({
      'resolved': true,
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    await addActivityLog(ActivityLog(
      user: 'admin',
      action: ActivityAction.edit,
      detail: 'Menyelesaikan tunggakan $studentName',
      timestamp: DateTime.now(),
    ));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Tunggakan $studentName ditandai selesai'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Tunggakan Tagihan'),
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: _attentionRef.where('resolved', isEqualTo: false).snapshots(),
            builder: (context, snap) {
              final count = snap.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    tooltip: 'Daftar Perlu Perhatian',
                    icon: const Icon(Icons.flag_outlined),
                    onPressed: () => _showAttentionSheet(context),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                            minWidth: 18, minHeight: 18),
                        child: Text(
                          '$count',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _studentsRef.where('isActive', isEqualTo: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: Icons.people_outline,
              text: 'Belum ada data siswa aktif',
            );
          }

          final students = snapshot.data!.docs
              .map((d) => Student.fromMap(d.data() as Map<String, dynamic>))
              .toList();

          // Hanya siswa yang punya tunggakan
          final outstanding = students.where((s) => s.hasOutstanding).toList();

          // Statistik
          double totalOutstanding = outstanding.fold<double>(
              0, (sum, s) => sum + s.remaining);
          int kritis = 0, sebagian = 0;
          for (var s in outstanding) {
            for (var p in s.payments) {
              if (p.status == PaymentStatus.belumBayar) kritis++;
              if (p.status == PaymentStatus.sebagian) sebagian++;
            }
          }

          // Filter pencarian
          var filtered = outstanding.where((s) {
            if (_searchQuery.isEmpty) return true;
            return s.name.toLowerCase().contains(_searchQuery) ||
                s.nis.toLowerCase().contains(_searchQuery) ||
                s.kelas.toLowerCase().contains(_searchQuery);
          }).toList();

          // Filter level
          if (_filterStatus != 'all') {
            filtered = filtered.where((s) {
              return s.payments.any((p) => _level(p) == _filterStatus);
            }).toList();
          }

          // Sort: paling besar sisa tunggakan di atas
          filtered.sort((a, b) => b.remaining.compareTo(a.remaining));

          return Column(
            children: [
              _buildSummaryHeader(
                outstanding.length,
                totalOutstanding,
                kritis,
                sebagian,
              ),
              _buildToolbar(),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.check_circle_outline,
                        text: 'Semua siswa sudah lunas 🎉',
                        color: Colors.green,
                      )
                    : RefreshIndicator(
                        onRefresh: () async => setState(() {}),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildStudentCard(filtered[index]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER SUMMARY
  // ============================================================
  Widget _buildSummaryHeader(
      int studentCount, double total, int kritis, int sebagian) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.error, AppColors.error.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Total Tunggakan Aktif',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$studentCount siswa',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Rp ${_fmt(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStat('Kritis', kritis, Icons.priority_high),
              const SizedBox(width: 10),
              _miniStat('Sebagian', sebagian, Icons.pending_actions),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, int count, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOOLBAR: SEARCH + FILTER
  // ============================================================
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari nama / NIS / kelas...',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.error, width: 1.5),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                icon: const Icon(Icons.filter_list, size: 20),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Semua')),
                  DropdownMenuItem(value: 'kritis', child: Text('Kritis')),
                  DropdownMenuItem(value: 'sebagian', child: Text('Sebagian')),
                ],
                onChanged: (v) =>
                    setState(() => _filterStatus = v ?? 'all'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STUDENT CARD
  // ============================================================
  Widget _buildStudentCard(Student s) {
    final unpaid = s.payments
        .where((p) => p.status != PaymentStatus.lunas)
        .toList();
    unpaid.sort((a, b) =>
        (b.amount - b.paidAmount).compareTo(a.amount - a.paidAmount));

    final hasKritis =
        unpaid.any((p) => p.status == PaymentStatus.belumBayar);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        onExpansionChanged: (_) => SoundHelper().playClick(),
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: (hasKritis ? AppColors.error : Colors.orange)
              .withOpacity(0.12),
          child: Text(
            s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: hasKritis ? AppColors.error : Colors.orange.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (hasKritis)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'KRITIS',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blueGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                s.kelas,
                style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text('${unpaid.length} tunggakan',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Icon(Icons.account_balance_wallet_outlined,
                  size: 14, color: AppColors.error),
              const SizedBox(width: 4),
              Text(
                'Rp ${_fmt(s.remaining)}',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        childrenPadding:
            const EdgeInsets.only(left: 8, right: 8, bottom: 8, top: 4),
        children: unpaid.map((p) => _buildPaymentTile(s, p)).toList(),
      ),
    );
  }

  // ============================================================
  // PAYMENT TILE
  // ============================================================
  Widget _buildPaymentTile(Student s, PaymentItem p) {
    final remaining = p.amount - p.paidAmount;
    final lvl = _level(p);
    final color = _levelColor(lvl);
    final progress = p.amount > 0 ? p.paidAmount / p.amount : 0.0;

    // Auto-detect "perlu perhatian" ekstra
    final bool isLargeAmount = p.amount >= 1000000;
    final bool isSppOverdue =
        p.type.toLowerCase().contains('spp') &&
            p.status == PaymentStatus.belumBayar;
    final bool isStale = p.lastPaymentDate != null &&
        DateTime.now().difference(p.lastPaymentDate!).inDays > 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header baris 1
          Row(
            children: [
              Expanded(
                child: Text(
                  p.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  lvl == 'kritis'
                      ? 'Belum Bayar'
                      : lvl == 'sebagian'
                          ? 'Sebagian'
                          : 'Lunas',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 6),

          // Detail nominal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${_fmt(p.paidAmount)} / ${_fmt(p.amount)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                'Sisa: Rp ${_fmt(remaining)}',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          if (p.lastPaymentDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Terakhir bayar: ${_fmtDate(p.lastPaymentDate!)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Auto badge "perlu perhatian"
          if (isLargeAmount || isSppOverdue || isStale) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (isLargeAmount)
                  _badge('Nominal Besar', Colors.red.shade700),
                if (isSppOverdue)
                  _badge('SPP Overdue', Colors.red.shade700),
                if (isStale)
                  _badge('Lama Menunggak', Colors.deepOrange),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Aksi
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showRemindDialog(s, p),
                icon: const Icon(Icons.notifications_active_outlined, size: 16),
                label: const Text('Ingatkan'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              ElevatedButton.icon(
                onPressed: () => _showFlagDialog(s, p),
                icon: const Icon(Icons.flag_outlined, size: 16),
                label: const Text('Tandai'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // DIALOGS
  // ============================================================
  void _showFlagDialog(Student s, PaymentItem p) {
    final reasons = [
      'Sudah jatuh tempo',
      'Nominal besar & belum dibayar',
      'Sudah lama menunggak',
      'SPP bulan ini belum dibayar',
      'Perlu tindak lanjut wali kelas',
      'Akan dihubungi orang tua',
    ];
    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.flag, color: AppColors.error),
              const SizedBox(width: 8),
              const Text('Tandai Tunggakan'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Siswa', s.name),
                _infoRow('Kelas', s.kelas),
                _infoRow('Jenis', p.type),
                _infoRow(
                    'Sisa', 'Rp ${_fmt(p.amount - p.paidAmount)}'),
                const SizedBox(height: 12),
                const Text('Alasan / Tindak Lanjut:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...reasons.map(
                  (r) => RadioListTile<String>(
                    value: r,
                    groupValue: selectedReason,
                    onChanged: (v) =>
                        setState(() => selectedReason = v ?? r),
                    title: Text(r, style: const TextStyle(fontSize: 13)),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _flagPayment(s, p, selectedReason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Tandai'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showRemindDialog(Student s, PaymentItem p) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Kirim Pengingat'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Siswa: ${s.name}'),
            Text('Tunggakan: ${p.type}'),
            Text('Sisa: Rp ${_fmt(p.amount - p.paidAmount)}'),
            const SizedBox(height: 8),
            Text(
              'Pengingat akan dikirim via WhatsApp ke nomor ${s.phone}. '
              'Pastikan nomor orang tua/wali sudah terdaftar.',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Simulate send + log
              await addActivityLog(ActivityLog(
                user: 'admin',
                action: ActivityAction.bayar,
                detail: 'Mengirim pengingat ${p.type} ke ${s.name}',
                timestamp: DateTime.now(),
              ));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('📨 Pengingat dikirim ke ${s.name}'),
                    backgroundColor: Colors.orange,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTTOM SHEET: DAFTAR TUNGGAKAN DITANDAI
  // ============================================================
  void _showAttentionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (context, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.flag, color: AppColors.error),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Daftar Tunggakan Ditandai',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _attentionRef
                      .orderBy('flaggedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada tunggakan ditandai',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }
                    final docs = snapshot.data!.docs;
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final isResolved = data['resolved'] == true;
                        final ts = data['flaggedAt'] as Timestamp?;
                        final date =
                            ts != null ? ts.toDate() : DateTime.now();

                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isResolved
                                  ? Colors.green.withOpacity(0.3)
                                  : AppColors.error.withOpacity(0.3),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: isResolved
                                  ? Colors.green.withOpacity(0.12)
                                  : AppColors.error.withOpacity(0.12),
                              child: Icon(
                                isResolved
                                    ? Icons.check_circle
                                    : Icons.flag,
                                color: isResolved
                                    ? Colors.green
                                    : AppColors.error,
                              ),
                            ),
                            title: Text(
                              data['studentName'] ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: isResolved
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isResolved
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.blueGrey
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${data['kelas'] ?? '-'}',
                                        style: const TextStyle(
                                            fontSize: 10),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      data['paymentType'] ?? '-',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  data['reason'] ?? '-',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      'Sisa: Rp ${_fmt((data['remaining'] ?? 0).toDouble())}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isResolved
                                            ? Colors.green
                                            : AppColors.error,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '• ${_fmtDate(date)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: isResolved
                                ? const Text('Selesai',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold))
                                : IconButton(
                                    tooltip: 'Tandai selesai',
                                    icon: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    onPressed: () => _resolveFlag(
                                      docs[index].id,
                                      data['studentName'] ?? '',
                                    ),
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
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================
  Widget _buildEmptyState({
    required IconData icon,
    required String text,
    Color color = Colors.grey,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}