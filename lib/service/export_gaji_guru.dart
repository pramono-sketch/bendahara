// service/export_gaji_guru.dart
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../features/gaji_guru.dart';

class DownloadService {
  // ============= TULIS FILE KE DOWNLOAD FOLDER / BENDARAHAKU =============
  static Future<Directory> _getDownloadsDirectory() async {
    // Tujuan: storage/emulated/0/Download/bendaharaku/
    if (Platform.isAndroid) {
      try {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) {
          final parts = extDir.path.split('/');
          if (parts.length >= 4) {
            // Ambil base path seperti /storage/emulated/0
            var base = '/${parts[1]}/${parts[2]}/${parts[3]}';
            var downloadDir = Directory('$base/Download');
            if (!await downloadDir.exists()) {
              await downloadDir.create(recursive: true);
            }
            // Buat subfolder bendaharaku
            var appDir = Directory('$base/Download/bendaharaku');
            if (!await appDir.exists()) {
              await appDir.create(recursive: true);
            }
            return appDir;
          }
        }
      } catch (e) {
        print('Error getting download directory: $e');
      }
    }
    // Fallback: temporary
    final tempDir = await getTemporaryDirectory();
    final fallbackDir = Directory('${tempDir.path}/bendaharaku');
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }
    return fallbackDir;
  }

  static Future<void> _saveFile(String fileName, String content) async {
    final dir = await _getDownloadsDirectory();
    final filePath = '${dir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);
    print('File saved to: $filePath');
  }

  // ============= EXPORT WORD (.doc) =============
  static Future<void> exportYearToWord(int tahun, List<GajiGuru> data) async {
    try {
      StringBuffer html = StringBuffer();
      html.writeln(_getWordHeader('LAPORAN GAJI GURU TAHUN $tahun'));

      Map<int, List<GajiGuru>> groupedByMonth = {};
      for (var g in data) {
        groupedByMonth.putIfAbsent(g.bulan, () => []).add(g);
      }
      var bulanKeys = groupedByMonth.keys.toList()..sort();

      for (var bulan in bulanKeys) {
        var items = groupedByMonth[bulan]!;
        double totalBulan = items.fold(0.0, (sum, g) => sum + g.totalGaji);
        int lunas = items.where((g) => g.isPaid).length;
        int totalGuru = items.length;

        html.writeln('<h2>${getBulanNama(bulan)} $tahun</h2>');
        html.writeln('<p><b>Total gaji:</b> Rp ${formatCurrency(totalBulan)} &nbsp;|&nbsp; <b>Lunas:</b> $lunas / $totalGuru guru</p>');
        html.writeln(_buildTable(items));
      }

      html.writeln(_getWordFooter(data, tahun));

      String fileName = 'Laporan_Gaji_$tahun.doc';
      await _saveFile(fileName, html.toString());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportMonthToWord(int tahun, int bulan, List<GajiGuru> data) async {
    try {
      StringBuffer html = StringBuffer();
      html.writeln(_getWordHeader('LAPORAN GAJI GURU ${getBulanNama(bulan)} $tahun'));
      html.writeln(_buildTable(data));

      double totalAll = data.fold(0.0, (sum, g) => sum + g.totalGaji);
      html.writeln('''
      <p style="font-size:14pt; margin-top:20px;"><b>TOTAL KESELURUHAN:</b> Rp ${formatCurrency(totalAll)}</p>
      <p><b>Total guru:</b> ${data.length}</p>
      ''');
      html.writeln(_getSimpleFooter());

      String fileName = 'Laporan_Gaji_${getBulanNama(bulan)}_$tahun.doc';
      await _saveFile(fileName, html.toString());
    } catch (e) {
      rethrow;
    }
  }

  // ============= EXPORT EXCEL (.xls) =============
  static Future<void> exportYearToExcel(int tahun, List<GajiGuru> data) async {
    try {
      StringBuffer html = StringBuffer();
      html.writeln(_getExcelHeader('LAPORAN GAJI GURU TAHUN $tahun'));

      Map<int, List<GajiGuru>> groupedByMonth = {};
      for (var g in data) {
        groupedByMonth.putIfAbsent(g.bulan, () => []).add(g);
      }
      var bulanKeys = groupedByMonth.keys.toList()..sort();

      for (var bulan in bulanKeys) {
        var items = groupedByMonth[bulan]!;
        double totalBulan = items.fold(0.0, (sum, g) => sum + g.totalGaji);
        int lunas = items.where((g) => g.isPaid).length;

        html.writeln('<h3>${getBulanNama(bulan)} $tahun</h3>');
        html.writeln('<p><b>Total gaji:</b> Rp ${formatCurrency(totalBulan)} &nbsp;|&nbsp; <b>Lunas:</b> $lunas / ${items.length} guru</p>');
        html.writeln(_buildExcelTable(items));
      }

      double grandTotal = data.fold(0.0, (sum, g) => sum + g.totalGaji);
      int totalLunas = data.where((g) => g.isPaid).length;
      html.writeln('<hr/>');
      html.writeln('<p style="font-size:14pt;"><b>GRAND TOTAL:</b> Rp ${formatCurrency(grandTotal)}</p>');
      html.writeln('<p><b>Total guru:</b> ${data.map((g) => g.namaGuru).toSet().length} &nbsp;|&nbsp; <b>Lunas:</b> $totalLunas / ${data.length}</p>');
      html.writeln('</body></html>');

      String fileName = 'Laporan_Gaji_$tahun.xls';
      await _saveFile(fileName, html.toString());
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> exportMonthToExcel(int tahun, int bulan, List<GajiGuru> data) async {
    try {
      StringBuffer html = StringBuffer();
      html.writeln(_getExcelHeader('LAPORAN GAJI GURU ${getBulanNama(bulan)} $tahun'));
      html.writeln(_buildExcelTable(data));

      double totalAll = data.fold(0.0, (sum, g) => sum + g.totalGaji);
      html.writeln('<p style="font-size:14pt; margin-top:20px;"><b>TOTAL:</b> Rp ${formatCurrency(totalAll)}</p>');
      html.writeln('</body></html>');

      String fileName = 'Laporan_Gaji_${getBulanNama(bulan)}_$tahun.xls';
      await _saveFile(fileName, html.toString());
    } catch (e) {
      rethrow;
    }
  }

  // ============= HELPERS =============
  static String _getWordHeader(String title) {
    return '''
    <html xmlns:o='urn:schemas-microsoft-com:office:office'
          xmlns:w='urn:schemas-microsoft-com:office:word'
          xmlns='http://www.w3.org/TR/REC-html40'>
    <head><meta charset='utf-8'>
    <style>
      body { font-family: 'Times New Roman', serif; margin: 40px; }
      h1 { text-align: center; font-size: 22pt; }
      h2 { font-size: 16pt; margin-top: 20px; border-bottom: 1px solid #000; }
      table { border-collapse: collapse; width: 100%; margin-top: 10px; }
      th { background-color: #4472C4; color: white; font-weight: bold; padding: 6px 8px; border: 1px solid #000; text-align: center; }
      td { padding: 4px 8px; border: 1px solid #000; word-wrap: break-word; white-space: normal; }
      .total-row { font-weight: bold; background-color: #e0e0e0; }
      .footer { margin-top: 30px; font-style: italic; font-size: 10pt; text-align: center; }
    </style>
    </head>
    <body>
    <h1>$title</h1>
    <p><b>Tanggal cetak:</b> ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
    ''';
  }

  static String _getExcelHeader(String title) {
    return '''
    <html xmlns:o='urn:schemas-microsoft-com:office:office'
          xmlns:x='urn:schemas-microsoft-com:office:excel'
          xmlns='http://www.w3.org/TR/REC-html40'>
    <head><meta charset='utf-8'>
    <!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet>
    <x:Name>Laporan</x:Name>
    <x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>
    </x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->
    <style>
      table { border-collapse: collapse; width: 100%; font-family: 'Calibri', sans-serif; font-size: 11pt; }
      th { background-color: #4472C4; color: white; font-weight: bold; padding: 6px 8px; border: 1px solid #000; text-align: center; }
      td { padding: 4px 8px; border: 1px solid #000; white-space: normal; word-wrap: break-word; }
      .total-row { font-weight: bold; background-color: #e0e0e0; }
      .header-title { font-size: 18pt; font-weight: bold; text-align: center; margin: 10px 0; }
      .sub-header { font-size: 12pt; text-align: center; margin-bottom: 10px; }
    </style>
    </head>
    <body>
    <div class="header-title">$title</div>
    <div class="sub-header">Tanggal cetak: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</div>
    ''';
  }

  static String _buildTable(List<GajiGuru> items) {
    StringBuffer html = StringBuffer();
    html.writeln('<table>');
    html.writeln('<tr><th>No</th><th>Nama Guru</th><th>Total Gaji</th><th>Status</th><th>Tanggal Bayar</th></tr>');
    int no = 1;
    for (var g in items) {
      html.writeln('''
      <tr>
        <td>$no</td>
        <td style="white-space: normal; word-wrap: break-word;">${g.namaGuru}</td>
        <td style="text-align:right;">Rp ${formatCurrency(g.totalGaji)}</td>
        <td>${g.isPaid ? 'Lunas' : 'Belum'}</td>
        <td>${g.isPaid && g.tanggalBayar != null ? '${g.tanggalBayar!.day}/${g.tanggalBayar!.month}/${g.tanggalBayar!.year}' : '-'}</td>
      </tr>
      ''');
      no++;
    }
    double total = items.fold(0.0, (sum, g) => sum + g.totalGaji);
    html.writeln('<tr class="total-row"><td colspan="2" style="text-align:right;">TOTAL</td>');
    html.writeln('<td style="text-align:right;">Rp ${formatCurrency(total)}</td>');
    html.writeln('<td colspan="2"></td></tr>');
    html.writeln('</table>');
    return html.toString();
  }

  static String _buildExcelTable(List<GajiGuru> items) {
    StringBuffer html = StringBuffer();
    html.writeln('<table>');
    html.writeln('<tr><th>No</th><th>Nama Guru</th><th>Total Gaji</th><th>Status</th><th>Tanggal Bayar</th></tr>');
    int no = 1;
    for (var g in items) {
      html.writeln('''
      <tr>
        <td>$no</td>
        <td>${g.namaGuru}</td>
        <td style="text-align:right;">Rp ${formatCurrency(g.totalGaji)}</td>
        <td>${g.isPaid ? 'Lunas' : 'Belum'}</td>
        <td>${g.isPaid && g.tanggalBayar != null ? '${g.tanggalBayar!.day}/${g.tanggalBayar!.month}/${g.tanggalBayar!.year}' : '-'}</td>
      </tr>
      ''');
      no++;
    }
    double total = items.fold(0.0, (sum, g) => sum + g.totalGaji);
    html.writeln('<tr class="total-row"><td colspan="2" style="text-align:right;">TOTAL</td>');
    html.writeln('<td style="text-align:right;">Rp ${formatCurrency(total)}</td>');
    html.writeln('<td colspan="2"></td></tr>');
    html.writeln('</table>');
    return html.toString();
  }

  static String _getWordFooter(List<GajiGuru> data, int tahun) {
    double grandTotal = data.fold(0.0, (sum, g) => sum + g.totalGaji);
    int totalLunas = data.where((g) => g.isPaid).length;
    return '''
    <hr/>
    <p style="font-size:14pt;"><b>GRAND TOTAL SELURUH TAHUN:</b> Rp ${formatCurrency(grandTotal)}</p>
    <p><b>Total guru:</b> ${data.map((g) => g.namaGuru).toSet().length} &nbsp;|&nbsp; <b>Lunas:</b> $totalLunas / ${data.length}</p>
    <div class="footer">
      Laporan ini dibuat secara otomatis oleh Aplikasi Manajemen Gaji Guru<br/>
      &copy; ${DateTime.now().year} - All Rights Reserved
    </div>
    </body></html>
    ''';
  }

  static String _getSimpleFooter() {
    return '''
    <div class="footer" style="margin-top:30px; font-style:italic; font-size:10pt; text-align:center;">
      Laporan ini dibuat secara otomatis oleh Aplikasi Manajemen Gaji Guru<br/>
      &copy; ${DateTime.now().year} - All Rights Reserved
    </div>
    </body></html>
    ''';
  }
}