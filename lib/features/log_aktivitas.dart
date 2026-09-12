// features/log_aktivitas.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/appearance.dart';
import '../data.dart';

/// Halaman untuk menampilkan log aktivitas dari Firebase dengan filter dan pencarian.
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

  /// Stream data log aktivitas dari Firestore (diurutkan dari yang terbaru)
  Stream<QuerySnapshot> _getLogStream() {
    return FirebaseFirestore.instance
        .collection('log_aktivitas')
        .orderBy('timestamp', descending: true)
        .limit(500) // Batasi 500 log terakhir agar tidak berat
        .snapshots();
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

  /// Cek apakah log cocok dengan filter kategori yang dipilih
  bool _matchesFilter(ActivityLog log) {
    if (_selectedFilter == 'Semua') return true;

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
  }

  /// Cek apakah log cocok dengan query pencarian
  bool _matchesSearch(ActivityLog log) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    return log.user.toLowerCase().contains(query) ||
        log.actionText.toLowerCase().contains(query) ||
        log.detail.toLowerCase().contains(query);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Aktivitas'),
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
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          // Daftar log dari Firebase
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getLogStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi error: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada log aktivitas',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                // Parse semua dokumen Firestore menjadi list ActivityLog
                List<ActivityLog> allLogs = snapshot.data!.docs.map((doc) {
                  return ActivityLog.fromMap(doc.data() as Map<String, dynamic>);
                }).toList();

                // Terapkan filter dan pencarian secara lokal
                List<ActivityLog> filteredLogs = allLogs.where((log) {
                  return _matchesFilter(log) && _matchesSearch(log);
                }).toList();

                if (filteredLogs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Tidak ada log yang sesuai',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    // Jumlah log
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Menampilkan ${filteredLogs.length} log',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List View
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredLogs.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}