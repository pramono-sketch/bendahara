// features/database_akun.dart
import 'package:flutter/material.dart';
import '../data.dart';
import '../templates/sound_helper.dart'; // 🔥 import suara

class DatabaseAkunPage extends StatelessWidget {
  const DatabaseAkunPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Akun Digital')),
      body: ListView.builder(
        itemCount: dummyAccounts.length,
        itemBuilder: (context, index) {
          final acc = dummyAccounts[index];
          return Card(
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.lock_outline, color: Colors.white),
              ),
              title: Text(acc.name),
              subtitle: Text(acc.email),
              onExpansionChanged: (expanded) {
                SoundHelper().playClick(); // 🔥 suara
              },
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Email', acc.email),
                      _infoRow('Penanggung Jawab', acc.penanggungJawab),
                      _infoRow('Keterangan', acc.keterangan),
                      _infoRow('Password', acc.passwordMasked),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
              width: 120,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}