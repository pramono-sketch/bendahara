// lib/simulation/cheat_guru.dart
import 'package:flutter/material.dart';
import '../features/gaji_guru.dart';

// Data dummy guru default - hanya ditambahkan ke Firebase via tombol developer FAB
const List<String> defaultTeachers = [
  'Ali Faesol, S.Pd.I.', 'Susi Wulandari, S.Pd', 'Kris Setyowati, S.Pd',
  'Eko Ardhiyanto, S. Kom.', 'Aris Khoirun Ma\'dum, S.E', 'Khoirul Ihsan Z. R, S. Sos.',
  'Didin Arif Setiawan, S. Pd. I', 'Ust. Ahmad Sholeh, S.Pd.I', 'Farid Fahmi, S. T.',
  'Rizki Safitri, S. Pd.', 'Shyecha Syaidatun Nisa\', S. E.', 'Ali Muhlisin, S. Pd.',
  'Windi Kusumowardani, S. Pd.', 'Wiendha Kurnia Pranata, S. Pd.',
  'Ustz. Afivatun Nadliyah, Al Hafidzah, M.Pd', 'Nike Izza Elfana, S.Pd',
  'Novita Nur Farida, S. Pd.', 'Dwi Luvi Nur Ahmad, S. Kom.', 'Vera Artanti, S. Kom.',
  'Hikmah Lailatul Kamalia, S. Pd.', 'Niken Octevani Army, S. T.', 'Imam Syibawech, S. Kom',
  'Alfida Zumaroh, S. Kom.', 'Nur Khamim', 'Mustagfirrin',
];

// Fungsi FAB yang menerima callback dan data (Diperbarui)
FloatingActionButton FABcheat({
  required BuildContext context,
  required VoidCallback onRefreshUI,
  required VoidCallback onSimulateMonthChange,
  required VoidCallback onGenerateCurrentMonthData,
  required VoidCallback onGenerateRandomData,
  required VoidCallback onAutoLunas,
  required VoidCallback onClearAllData,
  required VoidCallback onSeedDefaultTeachers,
  required VoidCallback onDeleteAllTeachers, // <--- Parameter Baru Ditambahkan
  required int currentBulan,
  required int currentTahun,
}) {
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
              // === TAMBAH DATA GURU DEFAULT KE FIREBASE ===
              ListTile(
                leading: const Icon(Icons.people_alt, color: Colors.indigo),
                title: const Text('Tambah Data Guru Default'),
                subtitle: const Text('Masukkan 25 data guru dummy ke Firebase'),
                onTap: () {
                  Navigator.pop(ctx);
                  onSeedDefaultTeachers();
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Data guru default berhasil ditambahkan ke Firebase!'),
                      backgroundColor: Colors.indigo,
                    ),
                  );
                },
              ),
              // === HAPUS SEMUA GURU & GAJI DARI FIREBASE ===
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.deepOrange),
                title: const Text('Hapus Semua Data Guru'),
                subtitle: const Text('Hapus seluruh guru beserta data gajinya'),
                onTap: () {
                  Navigator.pop(ctx);
                  onDeleteAllTeachers(); // Memanggil fungsi hapus semua guru
                  onRefreshUI();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Proses penghapusan semua guru dimulai...'),
                      backgroundColor: Colors.deepOrange,
                    ),
                  );
                },
              ),
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
                subtitle: const Text('Kosongkan seluruh riwayat gaji (Data guru tetap)'),
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