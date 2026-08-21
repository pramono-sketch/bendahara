// features/log_aktivitas.dart
import 'package:flutter/material.dart';

import '../constants/appearance.dart'; // 🔥 import warna
import '../data.dart';
import '../simulation/FAB_helper.dart';

/// Halaman untuk menampilkan log aktivitas dengan filter dan pencarian.
class LogAktivitasPage extends StatefulWidget {
  const LogAktivitasPage({super.key});

  @override
  State<LogAktivitasPage> createState() => _LogAktivitasPageState();
}

class _LogAktivitasPageState extends State<LogAktivitasPage> {
  // Filter kategori
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = [
    'Semua',
    'Siswa',
    'Transaksi',
    'Akun Digital',
    'Pembayaran',
    'Login/Logout',
  ];

  // Query pencarian
  String _searchQuery = '';

  // Daftar log yang ditampilkan (setelah filter & search)
  List<ActivityLog> _filteredLogs = [];

  @override
  void initState() {
    super.initState();
    _ensureLocalLogs();
    _applyFilterAndSearch();
  }

  /// Jika localLogs kosong, generate data sample untuk demo.
  void _ensureLocalLogs() {
    if (localLogs.isEmpty) {
      // Menambahkan log untuk berbagai aktivitas
      final now = DateTime.now();

      // Log siswa
      localLogs.addAll([
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.tambah,
          detail: 'Siswa baru: Andi Pratama (X RPL)',
          timestamp: now.subtract(const Duration(days: 2, hours: 1)),
        ),
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.edit,
          detail: 'Edit data siswa: Budi Santoso (XI TKJ)',
          timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        ),
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.hapus,
          detail: 'Hapus siswa: Citra Dewi (XII TKR)',
          timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        ),
      ]);

      // Log transaksi
      localLogs.addAll([
        ActivityLog(
          user: 'Bendahara',
          action: ActivityAction.tambah,
          detail: 'Pemasukan SPP dari 10 siswa (Rp 2.000.000)',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        ActivityLog(
          user: 'Bendahara',
          action: ActivityAction.edit,
          detail: 'Edit transaksi pengeluaran ATK (Rp 500.000)',
          timestamp: now.subtract(const Duration(hours: 4)),
        ),
        ActivityLog(
          user: 'Bendahara',
          action: ActivityAction.hapus,
          detail: 'Hapus transaksi pemasukan duplikat (Rp 1.000.000)',
          timestamp: now.subtract(const Duration(hours: 2)),
        ),
      ]);

      // Log akun digital
      localLogs.addAll([
        ActivityLog(
          user: 'IT Support',
          action: ActivityAction.tambah,
          detail: 'Akun digital baru: Google Workspace (admin@eduvest.sch.id)',
          timestamp: now.subtract(const Duration(days: 3)),
        ),
        ActivityLog(
          user: 'IT Support',
          action: ActivityAction.edit,
          detail: 'Perbarui password akun Zoom Meeting',
          timestamp: now.subtract(const Duration(days: 2, hours: 6)),
        ),
        ActivityLog(
          user: 'IT Support',
          action: ActivityAction.hapus,
          detail: 'Hapus akun lama: Sistem Absensi (v1)',
          timestamp: now.subtract(const Duration(days: 1, hours: 8)),
        ),
      ]);

      // Log pembayaran siswa
      localLogs.addAll([
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.bayar,
          detail: 'Pembayaran SPP siswa: Eko Saputra (XII RPL) - Rp 200.000',
          timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
        ),
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.bayar,
          detail: 'Pembayaran Gedung siswa: Fajar Nugroho (XI TKJ) - Rp 5.000.000',
          timestamp: now.subtract(const Duration(hours: 45)),
        ),
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.edit,
          detail: 'Update status pembayaran SPP siswa: Gita Wulandari (X RPL)',
          timestamp: now.subtract(const Duration(hours: 20)),
        ),
      ]);

      // Log login/logout
      localLogs.addAll([
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.login,
          detail: 'Admin login dari perangkat baru (IP 192.168.1.10)',
          timestamp: now.subtract(const Duration(hours: 3)),
        ),
        ActivityLog(
          user: 'Bendahara',
          action: ActivityAction.login,
          detail: 'Bendahara login (IP 192.168.1.15)',
          timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
        ),
        ActivityLog(
          user: 'Admin',
          action: ActivityAction.logout,
          detail: 'Admin logout',
          timestamp: now.subtract(const Duration(minutes: 10)),
        ),
      ]);
    }
  }

  /// Menerapkan filter kategori dan pencarian ke daftar log.
  void _applyFilterAndSearch() {
    setState(() {
      List<ActivityLog> logs = List.from(localLogs);

      // Filter berdasarkan kategori
      if (_selectedFilter != 'Semua') {
        logs = logs.where((log) {
          final detail = log.detail.toLowerCase();
          final action = log.action;
          switch (_selectedFilter) {
            case 'Siswa':
              return detail.contains('siswa') ||
                  detail.contains('siswa baru') ||
                  detail.contains('edit data siswa') ||
                  detail.contains('hapus siswa');
            case 'Transaksi':
              return detail.contains('pemasukan') ||
                  detail.contains('pengeluaran') ||
                  detail.contains('transaksi');
            case 'Akun Digital':
              return detail.contains('akun digital') ||
                  detail.contains('akun') ||
                  detail.contains('google') ||
                  detail.contains('zoom') ||
                  detail.contains('password');
            case 'Pembayaran':
              return action == ActivityAction.bayar ||
                  detail.contains('pembayaran') ||
                  detail.contains('spp') ||
                  detail.contains('gedung');
            case 'Login/Logout':
              return action == ActivityAction.login ||
                  action == ActivityAction.logout;
            default:
              return true;
          }
        }).toList();
      }

      // Pencarian berdasarkan user, action, atau detail
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        logs = logs.where((log) {
          return log.user.toLowerCase().contains(query) ||
              log.actionText.toLowerCase().contains(query) ||
              log.detail.toLowerCase().contains(query);
        }).toList();
      }

      // Urutkan dari yang terbaru
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      _filteredLogs = logs;
    });
  }

  /// Menentukan warna berdasarkan action.
  Color _logColor(ActivityAction action) {
    switch (action) {
      case ActivityAction.tambah:
        return AppColors.success;
      case ActivityAction.edit:
        return AppColors.warning;
      case ActivityAction.hapus:
        return AppColors.error;
      case ActivityAction.login:
        return AppColors.primary;
      case ActivityAction.logout:
        return AppColors.textSecondary;
      case ActivityAction.bayar:
        return AppColors.primary;
    }
  }

  /// Mendapatkan label kategori untuk sebuah log.
  String _getCategoryLabel(ActivityLog log) {
    final detail = log.detail.toLowerCase();
    final action = log.action;
    if (action == ActivityAction.bayar) return 'Pembayaran';
    if (action == ActivityAction.login || action == ActivityAction.logout) {
      return 'Login/Logout';
    }
    if (detail.contains('siswa') || detail.contains('siswa baru')) {
      return 'Siswa';
    }
    if (detail.contains('pemasukan') || detail.contains('pengeluaran') ||
        detail.contains('transaksi')) {
      return 'Transaksi';
    }
    if (detail.contains('akun digital') || detail.contains('akun') ||
        detail.contains('password')) {
      return 'Akun Digital';
    }
    return 'Lainnya';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _applyFilterAndSearch();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter dan pencarian
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Dropdown filter
                Row(
                  children: [
                    const Text('Kategori: '),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedFilter = newValue;
                            });
                            _applyFilterAndSearch();
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Search field
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari log...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilterAndSearch();
                  },
                ),
              ],
            ),
          ),
          // Jumlah log
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Menampilkan ${_filteredLogs.length} log',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Daftar log
          Expanded(
            child: _filteredLogs.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada log yang sesuai',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _logColor(log.action).withOpacity(0.15),
                            child: Icon(
                              log.actionIcon,
                              color: _logColor(log.action),
                              size: 22,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  log.actionText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Label kategori
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _logColor(log.action).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _logColor(log.action).withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _getCategoryLabel(log),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _logColor(log.action),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(log.detail),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    log.user,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTimestamp(log.timestamp),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
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

  /// Format timestamp menjadi string yang rapi.
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }
}