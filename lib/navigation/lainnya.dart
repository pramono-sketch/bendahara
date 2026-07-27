// navigation/lainnya.dart
import 'package:flutter/material.dart';
import '../data.dart';
import '../features/settings.dart';
import '../features/tambahkan.dart';
import '../features/ai_assistant.dart';
import '../features/database_akun.dart';
import '../features/log_aktivitas.dart';
import '../features/pemasukan.dart';
import '../features/pengeluaran.dart';
import '../features/statistik.dart';
import '../features/tagihan.dart';
import '../templates/sound_helper.dart'; // 🔥 import helper global

// ================== MORE PAGE (JEMBATAN NAVIGASI) ==================
class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Tagihan', 'icon': Icons.receipt_long, 'page': const TagihanPage()},
      {'title': 'Pemasukan', 'icon': Icons.arrow_downward, 'page': const PemasukanPage()},
      {'title': 'Pengeluaran', 'icon': Icons.arrow_upward, 'page': const PengeluaranPage()},
      {'title': 'Statistik', 'icon': Icons.bar_chart, 'page': const StatistikPage()},
      {'title': 'AI Assistant', 'icon': Icons.auto_awesome, 'page': const AIAssistantPage()},
      {'title': 'Tambah Data', 'icon': Icons.person_add, 'page': const ManageStudentsPage()},
      {'title': 'Akun Digital', 'icon': Icons.vpn_key, 'page': const DatabaseAkunPage()},
      {'title': 'Log Aktivitas', 'icon': Icons.history, 'page': const LogAktivitasPage()},
      {'title': 'Pengaturan', 'icon': Icons.settings, 'page': const SettingsPage()},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Lainnya'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () async {
              // 🔥 Gunakan SoundHelper global
              await SoundHelper().playClick();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => item['page'] as Widget),
                );
              }
            },
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 36,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}