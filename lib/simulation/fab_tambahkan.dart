import 'package:flutter/material.dart';

import '../data.dart';
import '../firebase/firestore_service.dart';
import '../helpers/sound_helper.dart';

/// ============================================================
/// DATA SIMULASI PEMBAYARAN
/// ============================================================
///
/// Semua DATA CONTOH untuk simulasi pembayaran diletakkan di sini.
///
/// File data.dart hanya berisi MODEL dan DATA APLIKASI.
/// File ini khusus untuk kebutuhan simulasi.
///
/// Simulasi ini BUKAN transaksi pembayaran siswa.
///
/// Fungsinya:
/// 1. Menambahkan contoh jenis pembayaran.
/// 2. Menghapus seluruh konfigurasi pembayaran.
///
/// Konfigurasi berdasarkan tingkat:
/// - X
/// - XI
/// - XII
///
/// Tidak dibedakan berdasarkan jurusan.
/// Jadi X berlaku untuk:
/// - X TKJ
/// - X RPL
/// - X TKR
///
/// Begitu juga XI dan XII.
/// ============================================================

const Map<String, List<Map<String, dynamic>>>
    simulationPaymentData = {
  'X': [
    {
      'type': 'SPP',
      'amount': 200000,
    },
    {
      'type': 'Gedung',
      'amount': 1500000,
    },
    {
      'type': 'Seragam',
      'amount': 750000,
    },
    {
      'type': 'Buku',
      'amount': 300000,
    },
    {
      'type': 'Study Tour',
      'amount': 500000,
    },
    {
      'type': 'Lainnya',
      'amount': 100000,
    },
  ],
  'XI': [
    {
      'type': 'SPP',
      'amount': 200000,
    },
    {
      'type': 'Gedung',
      'amount': 1000000,
    },
    {
      'type': 'Seragam',
      'amount': 500000,
    },
    {
      'type': 'Buku',
      'amount': 250000,
    },
    {
      'type': 'Study Tour',
      'amount': 500000,
    },
    {
      'type': 'Lainnya',
      'amount': 100000,
    },
  ],
  'XII': [
    {
      'type': 'SPP',
      'amount': 200000,
    },
    {
      'type': 'Gedung',
      'amount': 500000,
    },
    {
      'type': 'Seragam',
      'amount': 350000,
    },
    {
      'type': 'Buku',
      'amount': 200000,
    },
    {
      'type': 'Study Tour',
      'amount': 500000,
    },
    {
      'type': 'Lainnya',
      'amount': 100000,
    },
  ],
};

/// ============================================================
/// HELPER MEMBUAT PAYMENT ITEM DARI DATA SIMULASI
/// ============================================================

List<PaymentItem> _buildSimulationItems(
  String grade,
) {
  final rawItems =
      simulationPaymentData[grade] ?? [];

  return rawItems
      .map(
        (item) => PaymentItem(
          type: item['type']?.toString() ?? '',
          amount:
              (item['amount'] as num?)?.toDouble() ?? 0,
          status: PaymentStatus.belumBayar,
          paidAmount: 0,
          lastPaymentDate: null,
        ),
      )
      .toList();
}

/// ============================================================
/// HASIL SIMULASI
/// ============================================================

class SimulationPaymentResult {
  final int added;
  final int skipped;
  final int deleted;

  const SimulationPaymentResult({
    this.added = 0,
    this.skipped = 0,
    this.deleted = 0,
  });
}

/// ============================================================
/// SIMULASI TAMBAH DATA PEMBAYARAN
/// ============================================================
///
/// Data yang sudah ada TIDAK ditimpa.
///
/// Contoh:
///
/// Firebase:
/// X -> SPP
///
/// Simulasi dijalankan.
///
/// Hasil:
/// X -> SPP
///      Gedung
///      Seragam
///      Buku
///      Study Tour
///      Lainnya
///
/// SPP lama tidak diubah.
/// ============================================================

Future<SimulationPaymentResult>
    simulateAddPaymentData() async {
  int added = 0;
  int skipped = 0;

  for (final grade in gradeLevels) {
    final currentItems =
        await fetchPaymentsForClass(grade);

    final updatedItems = currentItems
        .map(
          (item) => item.copyWith(
            status: PaymentStatus.belumBayar,
            paidAmount: 0,
            lastPaymentDate: null,
          ),
        )
        .toList();

    final existingTypes = <String>{
      for (final item in updatedItems)
        item.type.trim().toLowerCase(),
    };

    final simulationItems =
        _buildSimulationItems(grade);

    for (final item in simulationItems) {
      final normalizedType =
          item.type.trim().toLowerCase();

      if (existingTypes.contains(normalizedType)) {
        skipped++;
        continue;
      }

      updatedItems.add(item);
      existingTypes.add(normalizedType);
      added++;
    }

    if (updatedItems.length != currentItems.length) {
      await savePaymentItemsForClass(
        grade,
        updatedItems,
      );
    }
  }

  return SimulationPaymentResult(
    added: added,
    skipped: skipped,
  );
}

/// ============================================================
/// SIMULASI HAPUS DATA PEMBAYARAN
/// ============================================================
///
/// Ini menghapus konfigurasi pembayaran untuk:
/// - X
/// - XI
/// - XII
///
/// Yang dihapus adalah MASTER JENIS PEMBAYARAN.
///
/// BUKAN transaksi pembayaran siswa.
///
/// Contoh:
///
/// X:
///   SPP
///   Gedung
///   Seragam
///
/// Setelah simulasi hapus:
///
/// X:
///   Belum ada jenis pembayaran
///
/// Data di Firebase ikut dihapus.
/// ============================================================

Future<SimulationPaymentResult>
    simulateDeletePaymentData() async {
  int deleted = 0;

  for (final grade in gradeLevels) {
    final currentItems =
        await fetchPaymentsForClass(grade);

    if (currentItems.isEmpty) {
      continue;
    }

    deleted += currentItems.length;

    await savePaymentItemsForClass(
      grade,
      <PaymentItem>[],
    );
  }

  return SimulationPaymentResult(
    deleted: deleted,
  );
}

/// ============================================================
/// FAB SIMULASI PEMBAYARAN
/// ============================================================

class PaymentSimulationFab extends StatefulWidget {
  final Future<void> Function()? onCompleted;

  const PaymentSimulationFab({
    super.key,
    this.onCompleted,
  });

  @override
  State<PaymentSimulationFab> createState() =>
      _PaymentSimulationFabState();
}

class _PaymentSimulationFabState
    extends State<PaymentSimulationFab> {
  bool _isLoading = false;

  /// ==========================================================
  /// DIALOG MENU SIMULASI
  /// ==========================================================

  Future<void> _showSimulationMenu() async {
    if (_isLoading) {
      return;
    }

    await SoundHelper().playClick();

    if (!mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              24,
              16,
              24,
              28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 18),

                const Row(
                  children: [
                    Icon(Icons.science_outlined),
                    SizedBox(width: 10),
                    Text(
                      'Simulasi Data Bayaran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  'Simulasi ini hanya mengatur '
                  'jenis pembayaran pada menu Kelola Pembayaran. '
                  'Tidak melakukan transaksi pembayaran siswa.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 20),

                /// TAMBAH CONTOH
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      await SoundHelper()
                          .playClick();

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                      );

                      await Future<void>.delayed(
                        const Duration(
                          milliseconds: 100,
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await _runAddSimulation();
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                    ),
                    label: const Text(
                      'Tambah Contoh Bayaran',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// HAPUS DATA
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await SoundHelper()
                          .playClick();

                      if (!mounted) {
                        return;
                      }

                      Navigator.pop(
                        sheetContext,
                      );

                      await Future<void>.delayed(
                        const Duration(
                          milliseconds: 100,
                        ),
                      );

                      if (!mounted) {
                        return;
                      }

                      await _runDeleteSimulation();
                    },
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Hapus Data Bayaran',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ==========================================================
  /// TAMBAH SIMULASI
  /// ==========================================================

  Future<void> _runAddSimulation() async {
    if (_isLoading) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tambah Contoh Bayaran',
                ),
              ),
            ],
          ),
          content: const Text(
            'Data contoh akan ditambahkan untuk '
            'kelas X, XI, dan XII.\n\n'
            'Contoh:\n'
            '• SPP\n'
            '• Gedung\n'
            '• Seragam\n'
            '• Buku\n'
            '• Study Tour\n'
            '• Lainnya\n\n'
            'Data yang sudah ada tidak ditimpa.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.pop(ctx, true),
              icon: const Icon(Icons.add),
              label: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await simulateAddPaymentData();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle_outline),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Simulasi Selesai',
                  ),
                ),
              ],
            ),
            content: Text(
              'Data contoh pembayaran berhasil diproses.\n\n'
              'Ditambahkan: ${result.added}\n'
              'Sudah ada: ${result.skipped}\n\n'
              'Data tersimpan di Firebase.',
            ),
            actions: [
              FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      await _notifyCompleted();
    } catch (e) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        'Gagal menambahkan contoh bayaran',
        e,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ==========================================================
  /// HAPUS SIMULASI
  /// ==========================================================

  Future<void> _runDeleteSimulation() async {
    if (_isLoading) {
      return;
    }

    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hapus Data Bayaran',
                ),
              ),
            ],
          ),
          content: const Text(
            'Semua konfigurasi jenis pembayaran '
            'untuk X, XI, dan XII akan dihapus dari Firebase.\n\n'
            'Contoh:\n'
            'SPP, Gedung, Seragam, Buku, dan lainnya.\n\n'
            'Ini TIDAK menghapus siswa dan '
            'TIDAK menghapus transaksi pembayaran.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              style:
                  FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () =>
                  Navigator.pop(ctx, true),
              icon: const Icon(
                Icons.delete_forever,
              ),
              label: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result =
          await simulateDeletePaymentData();

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data Berhasil Dihapus',
                  ),
                ),
              ],
            ),
            content: Text(
              'Konfigurasi pembayaran berhasil dihapus.\n\n'
              'Item terhapus: ${result.deleted}\n\n'
              'Siswa dan transaksi pembayaran '
              'tidak ikut dihapus.',
            ),
            actions: [
              FilledButton(
                onPressed: () =>
                    Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      await _notifyCompleted();
    } catch (e) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        'Gagal menghapus data bayaran',
        e,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ==========================================================
  /// CALLBACK SELESAI
  /// ==========================================================

  Future<void> _notifyCompleted() async {
    if (widget.onCompleted == null) {
      return;
    }

    try {
      await widget.onCompleted!();
    } catch (e) {
      debugPrint(
        'PaymentSimulationFab callback error: $e',
      );
    }
  }

  /// ==========================================================
  /// ERROR DIALOG
  /// ==========================================================

  Future<void> _showErrorDialog(
    String title,
    Object error,
  ) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title),
              ),
            ],
          ),
          content: Text(
            'Terjadi kesalahan:\n\n$error',
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  /// ==========================================================
  /// BUILD
  /// ==========================================================

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'payment_simulation_fab',
      onPressed:
          _isLoading ? null : _showSimulationMenu,
      icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.science_outlined,
            ),
      label: Text(
        _isLoading
            ? 'Memproses...'
            : 'Simulasi Bayaran',
      ),
      tooltip:
          'Simulasi tambah/hapus data bayaran',
    );
  }
}