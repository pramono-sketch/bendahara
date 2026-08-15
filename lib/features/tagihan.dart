// features/tagihan.dart
import 'package:flutter/material.dart';

import '../data.dart';
import '../templates/sound_helper.dart'; // 🔥 import suara
import '../constants/appearance.dart'; // 🔥 import warna

class TagihanPage extends StatelessWidget {
  const TagihanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final outstanding = dummyStudents.where((s) => s.hasOutstanding && s.isActive).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Tunggakan Tagihan')),
      body: outstanding.isEmpty
          ? const Center(child: Text('Semua siswa sudah lunas 🎉'))
          : ListView.builder(
              itemCount: outstanding.length,
              itemBuilder: (context, index) {
                final s = outstanding[index];
                final unpaid = s.payments
                    .where((p) => p.status != PaymentStatus.lunas)
                    .toList();
                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.error.withOpacity(0.1),
                      child: const Icon(Icons.warning_amber,
                          color: AppColors.error),
                    ),
                    title: Text(s.name),
                    subtitle: Text(
                        '${unpaid.length} jenis pembayaran menunggak'),
                    onExpansionChanged: (expanded) {
                      SoundHelper().playClick(); // 🔥 suara
                    },
                    children: unpaid
                        .map((p) => ListTile(
                              title: Text(p.type),
                              trailing: Text(
                                'Rp ${formatCurrency(p.amount - p.paidAmount)}',
                                style: const TextStyle(color: AppColors.error),
                              ),
                            ))
                        .toList(),
                  ),
                );
              },
            ),
    );
  }
}