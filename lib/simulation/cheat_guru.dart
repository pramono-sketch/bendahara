// lib/features/data/cheat.dart
import 'package:flutter/material.dart';
import '../features/gaji_guru.dart';

// Fungsi FAB yang menerima callback dan data
FloatingActionButton FABcheat({
  required BuildContext context,
  required VoidCallback onRefreshUI,
  required VoidCallback onSimulateMonthChange,
  required VoidCallback onGenerateCurrentMonthData,
  required VoidCallback onGenerateRandomData,
  required VoidCallback onAutoLunas,
  required VoidCallback onClearAllData,
  required int currentBulan,
  required int currentTahun,
}) 
{
  return FloatingActionButton(
    onPressed: () {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.skip_next, color: Colors.orange),
                title: const Text('Simulasi Pergantian Bulan'),
                subtitle: const Text('Naikkan bulan & tahun'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSimulateMonthChange();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bulan berubah ke ${getBulanNama(currentBulan)} $currentTahun'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.today, color: Colors.blue),
                title: const Text('Isi Data Gaji Bulan Ini'),
                subtitle: const Text('Generate untuk semua guru (bulan berjalan)'),
                onTap: () {
                  Navigator.pop(ctx);
                  onGenerateCurrentMonthData();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data gaji bulan ini berhasil diisi!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shuffle, color: Colors.green),
                title: const Text('Generate Data Random (6 Bulan)'),
                subtitle: const Text('Isi data gaji untuk 6 bulan terakhir'),
                onTap: () {
                  Navigator.pop(ctx);
                  onGenerateRandomData();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data random 6 bulan berhasil digenerate!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment, color: Colors.purple),
                title: const Text('Auto Lunas'),
                subtitle: const Text('Tandai semua gaji belum lunas menjadi lunas'),
                onTap: () {
                  Navigator.pop(ctx);
                  onAutoLunas();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua gaji telah ditandai lunas!'),
                      backgroundColor: Colors.purple,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.red),
                title: const Text('Hapus Semua Data Gaji'),
                subtitle: const Text('Kosongkan seluruh data'),
                onTap: () {
                  Navigator.pop(ctx);
                  onClearAllData();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Semua data gaji telah dihapus'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
    child: const Icon(Icons.developer_mode),
    tooltip: 'Mode Developer',
  );
}