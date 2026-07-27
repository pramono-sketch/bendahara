// features/pemasukan.dart
import 'package:flutter/material.dart';
import '../data.dart';
class PemasukanPage extends StatelessWidget {
  const PemasukanPage({super.key});

  @override
  Widget build(BuildContext context) {
    final incomes = dummyTransactions
        .where((t) => t.type == TransType.pemasukan)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pemasukan')),
      body: ListView.builder(
        itemCount: incomes.length,
        itemBuilder: (context, index) {
          final trx = incomes[index];
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.success,
                child: Icon(Icons.arrow_downward, color: Colors.white),
              ),
              title: Text(trx.description),
              subtitle: Text(
                  '${trx.date.day}/${trx.date.month}/${trx.date.year}'),
              trailing: Text(
                'Rp ${formatCurrency(trx.amount)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success),
              ),
            ),
          );
        },
      ),
    );
  }
}