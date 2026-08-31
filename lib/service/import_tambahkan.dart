// service/import_tambahkan.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:permission_handler/permission_handler.dart';

import '../data.dart';
import '../firebase/firestore_service.dart'; // Import Firestore

// ============================================================
// ================== EXCEL IMPORT MANAGER ====================
// ============================================================

class ExcelImportManager {
  static const String _importFolderPath =
      '/storage/emulated/0/Download/bendaharaku/import';
  static const String _exportFolderPath =
      '/storage/emulated/0/Download/bendaharaku/export';

  /// Meminta izin akses penyimpanan
  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    if (await Permission.manageExternalStorage.status.isGranted) {
      return true;
    }

    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;

    var storageStatus = await Permission.storage.request();
    return storageStatus.isGranted;
  }

  /// Mengambil daftar file Excel (.xlsx / .xls) dari folder import
  Future<List<File>> getExcelFilesFromFolder() async {
    List<File> excelFiles = [];

    try {
      List<String> possiblePaths = [
        _importFolderPath,
        '/sdcard/Download/bendaharaku/import',
      ];

      Directory? dir;
      for (String path in possiblePaths) {
        Directory d = Directory(path);
        if (await d.exists()) {
          dir = d;
          break;
        }
      }

      if (dir == null) {
        try {
          dir = Directory(_importFolderPath);
          await dir.create(recursive: true);
        } catch (e) {
          debugPrint('Tidak bisa membuat folder: $e');
          return excelFiles;
        }
      }

      List<FileSystemEntity> entities = dir.listSync();

      for (var entity in entities) {
        if (entity is File) {
          String ext = entity.path.split('.').last.toLowerCase();
          if (ext == 'xlsx' || ext == 'xls') {
            excelFiles.add(entity);
          }
        }
      }

      excelFiles.sort((a, b) {
        return b.statSync().modified.compareTo(a.statSync().modified);
      });
    } catch (e) {
      debugPrint('Error listing files: $e');
    }

    return excelFiles;
  }

  /// Menampilkan dialog popup berisi daftar file Excel dari folder import
  Future<void> showImportFileDialog(BuildContext context) async {
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Memuat file Excel...'),
          ],
        ),
      ),
    );

    bool hasPermission = await _requestStoragePermission();

    if (!navigator.mounted) return;
    navigator.pop(); // Tutup loading

    if (!hasPermission) {
      if (!navigator.mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Izin Diperlukan'),
            ],
          ),
          content: const Text(
            'Aplikasi memerlukan izin akses penyimpanan untuk '
            'membaca file Excel dari folder import.\n\n'
            'Silakan berikan izin "Kelola semua file" di pengaturan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      return;
    }

    List<File> excelFiles = await getExcelFilesFromFolder();

    if (!navigator.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => ImportFileDialog(
        excelFiles: excelFiles,
        folderPath: _importFolderPath,
        onFileSelected: (File file) {
          Navigator.pop(ctx);
          importFromFile(context, file);
        },
        onPickOtherFile: () {
          Navigator.pop(ctx);
          importFromExcelPicker(context);
        },
        onShowGuide: () {
          Navigator.pop(ctx); 
          showDialog(
            context: context,
            builder: (_) => GuideDialog(
              onExport: () => exportGuideFile(context),
            ),
          );
        },
      ),
    );
  }

  /// Import data siswa dari file Excel yang dipilih
  Future<void> importFromFile(BuildContext context, File file) async {
    String fileName = file.path.split('/').last;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text('Mengimport data dari:\n$fileName...')),
          ],
        ),
      ),
    );

    try {
      final bytes = await file.readAsBytes();

      if (!navigator.mounted) return;
      navigator.pop(); // Tutup loading

      await processExcelBytes(context, bytes, fileName);
    } catch (e) {
      if (!navigator.mounted) return;
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan saat membaca file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Fallback: Pilih file menggunakan FilePicker (sistem)
  Future<void> importFromExcelPicker(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (result == null) return;

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Gagal membaca file.')),
        );
        return;
      }

      await processExcelBytes(context, bytes, result.files.first.name);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  /// Proses bytes Excel dan tambahkan siswa
  Future<void> processExcelBytes(
      BuildContext context, Uint8List bytes, String fileName) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      var excel = Excel.decodeBytes(bytes);
      var sheet = excel.tables[excel.tables.keys.first];
      if (sheet == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Tidak ada sheet yang ditemukan.')),
        );
        return;
      }

      int addedCount = 0;
      int errorCount = 0;
      List<String> errorDetails = [];

      for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
        var row = sheet.rows[rowIndex];
        if (row.isEmpty) continue;

        String? name = row.length > 0 ? row[0]?.value?.toString().trim() : null;
        String? nis = row.length > 1 ? row[1]?.value?.toString().trim() : null;
        String? kelas = row.length > 2 ? row[2]?.value?.toString().trim() : null;
        String? alamat = row.length > 3 ? row[3]?.value?.toString().trim() : null;
        String? phone = row.length > 4 ? row[4]?.value?.toString().trim() : null;

        if (name == null || name.isEmpty || nis == null || nis.isEmpty || kelas == null || kelas.isEmpty) {
          errorCount++;
          errorDetails.add('Baris ${rowIndex + 1}: data tidak lengkap');
          continue;
        }

        String id = 'STD${DateTime.now().millisecondsSinceEpoch}_$rowIndex';
        Student newStudent = createStudentWithPayments(
          id: id,
          name: name,
          nis: nis,
          kelas: kelas,
          alamat: alamat ?? '-',
          phone: phone ?? '-',
        );

        try {
          // FIX: Simpan ke Firestore, bukan list lokal
          await saveStudent(newStudent);
          addedCount++;
        } catch (e) {
          errorCount++;
          errorDetails.add('Baris ${rowIndex + 1}: Gagal simpan (NIS mungkin duplikat)');
        }
      }

      if (addedCount > 0) {
        await addActivityLog(ActivityLog(
          user: 'Admin',
          action: ActivityAction.tambah,
          detail: 'Import $addedCount siswa dari Excel ($fileName)',
          timestamp: DateTime.now(),
        ));
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            addedCount > 0
                ? '✅ Import selesai: $addedCount siswa berhasil ditambahkan'
                    '${errorCount > 0 ? ', $errorCount gagal' : ''}'
                : '❌ Tidak ada siswa yang ditambahkan ($errorCount error)',
          ),
          backgroundColor: addedCount > 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );

      if (errorDetails.isNotEmpty && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Detail Import'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: errorDetails.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorDetails[index], style: const TextStyle(fontSize: 13))),
                      ],
                    ),
                  );
                },
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  /// Export Template Petunjuk ke Folder Export
  Future<void> exportGuideFile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        if (!context.mounted) return;
        messenger.showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak!'), backgroundColor: Colors.red),
        );
        return;
      }

      Directory exportDir = Directory(_exportFolderPath);
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      String filePath = '${exportDir.path}/format_import_siswa.csv';
      File file = File(filePath);

      String csvContent = "Nama,NIS,Kelas,Alamat,Telepon\n";
      csvContent += "Budi Santoso,12345,X TKJ,Jl. Mawar No.1,081234567890\n";
      csvContent += "Siti Aminah,12346,XI RPL,Jl. Melati No.2,081234567891\n";

      await file.writeAsString(csvContent);

      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Petunjuk berhasil diexport ke:\n$filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal export petunjuk: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ============================================================
// ================== WIDGET DIALOG IMPORT =====================
// ============================================================

class ImportFileDialog extends StatelessWidget {
  final List<File> excelFiles;
  final String folderPath;
  final Function(File) onFileSelected;
  final VoidCallback onPickOtherFile;
  final VoidCallback onShowGuide;

  const ImportFileDialog({
    super.key,
    required this.excelFiles,
    required this.folderPath,
    required this.onFileSelected,
    required this.onPickOtherFile,
    required this.onShowGuide,
  });

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.blue),
            onPressed: onShowGuide,
            tooltip: 'Petunjuk Format',
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Pilih File Excel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Folder:\n$folderPath', style: TextStyle(fontSize: 11, color: Colors.blue.shade700)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (excelFiles.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.folder_off, size: 56, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Tidak ada file Excel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Letakkan file Excel (.xlsx / .xls) di folder:\nDownload/bendaharaku/import/\n\nAtau gunakan tombol "Pilih File Lain".',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: excelFiles.length,
                  itemBuilder: (context, index) {
                    final file = excelFiles[index];
                    final fileName = file.path.split('/').last;
                    final fileStat = file.statSync();
                    final fileSize = _formatFileSize(fileStat.size);
                    final modified = _formatDate(fileStat.modified);

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.file_present, color: Colors.green, size: 28),
                        ),
                        title: Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('$fileSize • $modified', style: const TextStyle(fontSize: 11)),
                        trailing: const Icon(Icons.download_rounded, color: Colors.blue),
                        onTap: () => onFileSelected(file),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: onPickOtherFile,
          icon: const Icon(Icons.search, size: 18),
          label: const Text('Pilih File Lain'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    );
  }
}

// ============================================================
// ================== WIDGET DIALOG PETUNJUK ===================
// ============================================================

class GuideDialog extends StatelessWidget {
  final VoidCallback onExport;

  const GuideDialog({super.key, required this.onExport});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.menu_book, color: Colors.blue),
          SizedBox(width: 8),
          Text('Petunjuk Import'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pastikan file Excel (.xlsx / .xls) Anda memiliki format kolom dengan urutan sebagai berikut:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _buildFormatTable(),
            const SizedBox(height: 12),
            const Text(
              'Catatan:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Baris pertama (Header) tidak akan diproses.\n'
              '• NIS tidak boleh sama (duplikat).\n'
              '• Pastikan format Kelas sesuai (contoh: X TKJ).',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            onExport();
          },
          icon: const Icon(Icons.download),
          label: const Text('Export Petunjuk'),
        ),
      ],
    );
  }

  Widget _buildFormatTable() {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(3),
      },
      children: const [
        TableRow(
          decoration: BoxDecoration(color: Color(0xFFE3F2FD)),
          children: [
            Padding(padding: EdgeInsets.all(8), child: Text('Kolom', style: TextStyle(fontWeight: FontWeight.bold))),
            Padding(padding: EdgeInsets.all(8), child: Text('Deskripsi', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text('A (1)')),
          Padding(padding: EdgeInsets.all(8), child: Text('Nama Lengkap Siswa')),
        ]),
        TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text('B (2)')),
          Padding(padding: EdgeInsets.all(8), child: Text('NIS (Nomor Induk Siswa)')),
        ]),
        TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text('C (3)')),
          Padding(padding: EdgeInsets.all(8), child: Text('Kelas (Contoh: X TKJ)')),
        ]),
        TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text('D (4)')),
          Padding(padding: EdgeInsets.all(8), child: Text('Alamat')),
        ]),
        TableRow(children: [
          Padding(padding: EdgeInsets.all(8), child: Text('E (5)')),
          Padding(padding: EdgeInsets.all(8), child: Text('No. Telepon')),
        ]),
      ],
    );
  }
}