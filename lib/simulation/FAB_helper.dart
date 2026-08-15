// simulation/FAB_helper.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../data.dart';
import '../firebase/firestore_service.dart';

class SimulasiHelper {
  // ============================================================
  // ================== SHOW SIMULATION DIALOG ==================
  // ============================================================

  static void showSimulationDialog(
    BuildContext parentContext,
    VoidCallback onUpdate,
    VoidCallback? refreshCallback,
  ) {
    if (!parentContext.mounted) return;

    showModalBottomSheet(
      context: parentContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              // ================= HEADER =================
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius:
                        BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Center(
                child: Text(
                  'Mode Simulasi Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const Divider(height: 24),

              // ==================================================
              // TAMBAH 1 SISWA
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.person_add,
                  color: Colors.green,
                ),
                title: const Text(
                  'Tambah 1 Siswa Baru',
                ),
                subtitle: const Text(
                  'Generate 1 siswa random ke Firestore',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _executeWithSnackBar(
                      parentContext,
                      () async {
                        await _addSingleStudent();

                        if (!parentContext.mounted) return;

                        onUpdate();
                        refreshCallback?.call();
                      },
                      '1 siswa berhasil ditambahkan!',
                      Colors.green,
                    );
                  });
                },
              ),

              // ==================================================
              // TAMBAH 5 SISWA
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.group_add,
                  color: Colors.blue,
                ),
                title: const Text(
                  'Tambah 5 Siswa Baru',
                ),
                subtitle: const Text(
                  'Generate 5 siswa random ke Firestore',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _executeWithSnackBar(
                      parentContext,
                      () async {
                        await _addMultipleStudents(5);

                        if (!parentContext.mounted) return;

                        onUpdate();
                        refreshCallback?.call();
                      },
                      '5 siswa berhasil ditambahkan!',
                      Colors.blue,
                    );
                  });
                },
              ),

              const Divider(),

              // ==================================================
              // HAPUS SEMUA
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.delete_sweep,
                  color: Colors.red,
                ),
                title: const Text(
                  'Hapus Semua Siswa',
                ),
                subtitle: const Text(
                  'Kosongkan semua data siswa di Firestore',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _showConfirmDialog(
                      parentContext,
                      'Hapus Semua Siswa',
                      'Yakin ingin menghapus semua data siswa?',
                      () {
                        if (!parentContext.mounted) return;

                        _executeWithSnackBar(
                          parentContext,
                          () async {
                            await _clearAllStudents();

                            if (!parentContext.mounted) {
                              return;
                            }

                            onUpdate();
                            refreshCallback?.call();
                          },
                          'Semua siswa telah dihapus!',
                          Colors.red,
                        );
                      },
                    );
                  });
                },
              ),

              const Divider(),

              // ==================================================
              // GENERATE DUMMY
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.shuffle,
                  color: Colors.purple,
                ),
                title: const Text(
                  'Generate Data Dummy',
                ),
                subtitle: const Text(
                  'Isi Firestore dengan 45 siswa dummy',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _showConfirmDialog(
                      parentContext,
                      'Generate Data Dummy',
                      'Akan menambahkan 45 siswa dummy. Lanjutkan?',
                      () {
                        if (!parentContext.mounted) return;

                        _executeWithSnackBar(
                          parentContext,
                          () async {
                            await _seedDummyStudents();

                            if (!parentContext.mounted) {
                              return;
                            }

                            onUpdate();
                            refreshCallback?.call();
                          },
                          '45 siswa dummy berhasil ditambahkan!',
                          Colors.purple,
                        );
                      },
                    );
                  });
                },
              ),

              const Divider(),

              // ==================================================
              // TANDAI SEMUA LUNAS
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.payment,
                  color: Colors.orange,
                ),
                title: const Text(
                  'Tandai Semua Lunas',
                ),
                subtitle: const Text(
                  'Set semua siswa status lunas',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _showConfirmDialog(
                      parentContext,
                      'Tandai Semua Lunas',
                      'Yakin ingin menandai semua pembayaran lunas?',
                      () {
                        if (!parentContext.mounted) return;

                        _executeWithSnackBar(
                          parentContext,
                          () async {
                            await _markAllPaid();

                            if (!parentContext.mounted) {
                              return;
                            }

                            onUpdate();
                            refreshCallback?.call();
                          },
                          'Semua siswa telah ditandai lunas!',
                          Colors.orange,
                        );
                      },
                    );
                  });
                },
              ),

              const Divider(),

              // ==================================================
              // RESET DATA
              // ==================================================

              ListTile(
                leading: const Icon(
                  Icons.restart_alt,
                  color: Colors.teal,
                ),
                title: const Text(
                  'Reset Data Siswa',
                ),
                subtitle: const Text(
                  'Hapus semua → generate dummy baru',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();

                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (!parentContext.mounted) return;

                    _showConfirmDialog(
                      parentContext,
                      'Reset Data Siswa',
                      'Semua data akan dihapus dan digenerate ulang. Lanjutkan?',
                      () {
                        if (!parentContext.mounted) return;

                        _executeWithSnackBar(
                          parentContext,
                          () async {
                            await _clearAllStudents();
                            await _seedDummyStudents();

                            if (!parentContext.mounted) {
                              return;
                            }

                            onUpdate();
                            refreshCallback?.call();
                          },
                          'Data siswa telah direset!',
                          Colors.teal,
                        );
                      },
                    );
                  });
                },
              ),

              const SizedBox(height: 8),

              // ================= TUTUP =================

              TextButton(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                },
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ================== FUNGSI SIMULASI =========================
  // ============================================================

  static Future<void> _addSingleStudent() async {
    final student = _createRandomStudent();
    await saveStudent(student);
  }

  static Future<void> _addMultipleStudents(
    int count,
  ) async {
    for (int i = 0; i < count; i++) {
      final student = _createRandomStudent();
      await saveStudent(student);
    }
  }

  static Future<void> _clearAllStudents() async {
    final all = await fetchAllStudents();

    for (final student in all) {
      await deleteStudent(student.id);
    }
  }

  static Future<void> _seedDummyStudents() async {
    await seedFirestoreIfEmpty();
  }

  static Future<void> _markAllPaid() async {
    final students = await fetchActiveStudents();

    for (final student in students) {
      for (final payment in student.payments) {
        if (payment.status != PaymentStatus.lunas) {
          payment.status = PaymentStatus.lunas;
          payment.paidAmount = payment.amount;
          payment.lastPaymentDate = DateTime.now();
        }
      }

      await saveStudent(student);
    }
  }

  static Student _createRandomStudent() {
    final random = Random();

    final grade =
        gradeLevels[random.nextInt(gradeLevels.length)];

    final major =
        majors[random.nextInt(majors.length)];

    final number = dummyStudents.length + 1;

    final id =
        'STD${number.toString().padLeft(3, '0')}';

    final nis =
        '2026${number.toString().padLeft(3, '0')}';

    final name =
        'Siswa $grade $major $number';

    return Student(
      id: id,
      name: name,
      nis: nis,
      kelas: '$grade $major',
      alamat: 'Jl. Simulasi No. $number',
      phone:
          '08123456${(700 + number).toString()}',
      payments:
          getDefaultPaymentsForClass('$grade $major'),
      isActive: true,
    );
  }

  // ============================================================
  // ================== CONFIRM DIALOG ==========================
  // ============================================================

  static void _showConfirmDialog(
    BuildContext parentContext,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Batal'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // Jalankan setelah dialog ditutup
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  if (!parentContext.mounted) return;

                  onConfirm();
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Ya, Lanjutkan',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ================== SNACKBAR ================================
  // ============================================================

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
  ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // ================== EXECUTE ================================
  // ============================================================

  static void _executeWithSnackBar(
    BuildContext parentContext,
    Future<void> Function() action,
    String successMessage,
    Color color,
  ) {
    Future<void>(() async {
      try {
        await action();

        if (!parentContext.mounted) return;

        _showSnackBar(
          parentContext,
          successMessage,
          color,
        );
      } catch (e) {
        if (!parentContext.mounted) return;

        _showSnackBar(
          parentContext,
          'Error: $e',
          Colors.red,
        );
      }
    });
  }
}