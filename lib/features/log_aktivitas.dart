// features/log_aktivitas.dart
import 'package:flutter/material.dart';
import '../data.dart';

class LogAktivitasPage extends StatelessWidget {
  const LogAktivitasPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Gunakan list kosong – TIDAK ADA DATA DUMMY
    final List<ActivityLog> logs = [];

    return Scaffold(
      appBar: AppBar(title: const Text('Log Aktivitas')),
      body: logs.isEmpty
          ? const Center(
              child: Text(
                'Belum ada aktivitas',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
            )
          : ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _logColor(log.action).withOpacity(0.1),
                      child: Icon(
                        log.actionIcon,
                        color: _logColor(log.action),
                        size: 20,
                      ),
                    ),
                    title: Text(log.actionText),
                    subtitle: Text(
                      '${log.detail}\n'
                      '${log.timestamp.day}/${log.timestamp.month}/${log.timestamp.year} '
                      '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }

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
}