// features/pengeluaran.dart
import 'package:flutter/material.dart';
import '../data.dart';

class PengeluaranPage extends StatelessWidget {
  const PengeluaranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenses = dummyTransactions
        .where((t) => t.type == TransType.pengeluaran)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      body: ListView.builder(
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final trx = expenses[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.error,
                child: Icon(Icons.arrow_upward, color: Colors.white),
              ),
              title: Text(trx.description),
              subtitle: Text(
                  '${trx.date.day}/${trx.date.month}/${trx.date.year}'),
              trailing: Text(
                'Rp ${formatCurrency(trx.amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.error),
              ),
            ),
          );
        },
      ),
    );
  }
}