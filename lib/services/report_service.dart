import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ReportService {
  static const _fontFamily = 'Helvetica';

  Future<File> generateAttendanceReportPdf(
    Map<String, dynamic> employee,
    List<Map<String, dynamic>> attendances,
    int month,
    int year,
  ) async {
    try {
      final pdf = pw.Document();
      final monthName = DateFormat('MMMM', 'id_ID').format(DateTime(year, month));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader('LAPORAN ABSENSI'),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildCompanyInfo(),
            pw.SizedBox(height: 8),
            _buildEmployeeInfo(employee),
            pw.SizedBox(height: 8),
            _buildPeriodInfo(monthName, year),
            pw.SizedBox(height: 16),
            _buildSummaryTable(attendances),
            pw.SizedBox(height: 16),
            _buildAttendanceTable(attendances),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/laporan_absen_${employee['nip']}_$month-$year.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw Exception('Failed to generate attendance PDF: $e');
    }
  }

  Future<File> generatePayrollSlipPdf(
    Map<String, dynamic> payroll,
    Map<String, dynamic> employee,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => _buildHeader('SLIP GAJI'),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildCompanyInfo(),
            pw.SizedBox(height: 8),
            _buildEmployeeInfo(employee),
            pw.SizedBox(height: 8),
            _buildPayrollPeriod(payroll),
            pw.SizedBox(height: 16),
            _buildPayrollTable(payroll),
            pw.SizedBox(height: 16),
            _buildPayrollSummary(payroll),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/slip_gaji_${employee['nip']}_${payroll['periode_bulan']}-${payroll['periode_tahun']}.pdf',
      );
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw Exception('Failed to generate payroll PDF: $e');
    }
  }

  Future<File> generatePayrollSummaryExcel(
    List<Map<String, dynamic>> allPayrolls,
    int month,
    int year,
  ) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Payroll $month-$year'];

      final headers = ['No', 'NIP', 'Nama', 'Gaji Pokok', 'Tunjangan Tetap', 'Uang Makan', 'Uang Transport', 'Total Lembur', 'THR', 'BPJS Kesehatan', 'BPJS JHT', 'BPJS JP', 'Potongan Lain', 'Total Pendapatan', 'Total Potongan', 'Gaji Bersih', 'Status'];
      sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

      for (var i = 0; i < allPayrolls.length; i++) {
        final p = allPayrolls[i];
        sheet.appendRow([
          TextCellValue('${i + 1}'),
          TextCellValue('${p['nip'] ?? ''}'),
          TextCellValue('${p['nama_lengkap'] ?? ''}'),
          TextCellValue(_formatNumber(p['gaji_pokok'])),
          TextCellValue(_formatNumber(p['tunjangan_tetap'])),
          TextCellValue(_formatNumber(p['uang_makan'])),
          TextCellValue(_formatNumber(p['uang_transport'])),
          TextCellValue(_formatNumber(p['total_lembur'])),
          TextCellValue(_formatNumber(p['thr'])),
          TextCellValue(_formatNumber(p['bpjs_kesehatan_karyawan'])),
          TextCellValue(_formatNumber(p['bpjs_jht_karyawan'])),
          TextCellValue(_formatNumber(p['bpjs_jp_karyawan'])),
          TextCellValue(_formatNumber(p['potongan_lain'])),
          TextCellValue(_formatNumber(p['total_pendapatan'])),
          TextCellValue(_formatNumber(p['total_potongan'])),
          TextCellValue(_formatNumber(p['gaji_bersih'])),
          TextCellValue('${p['status'] ?? ''}'),
        ]);
      }

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/rekap_gaji_$month-$year.xlsx');
      await file.writeAsBytes(excel.encode()!);
      return file;
    } catch (e) {
      throw Exception('Failed to generate payroll Excel: $e');
    }
  }

  Future<void> shareFile(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'App-Absen Report',
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }

  String formatRupiah(num amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(amount)}';
  }

  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    final num v = (value is num) ? value : double.tryParse(value.toString()) ?? 0;
    return NumberFormat('#,###', 'id_ID').format(v);
  }

  pw.Widget _buildHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Divider(thickness: 1.5),
      ],
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'App-Absen',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
            pw.Text(
              'Halaman ${context.pageNumber}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCompanyInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PT. Contoh',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Text(
            'Jl. Contoh No. 123, Jakarta',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEmployeeInfo(Map<String, dynamic> employee) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Nama', employee['nama_lengkap'] ?? ''),
                _infoRow('NIP', employee['nip'] ?? ''),
                _infoRow('Jabatan', employee['nama_jabatan'] ?? ''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(':  ', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  pw.Widget _buildPeriodInfo(String monthName, int year) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        'Periode: $monthName $year',
        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _buildSummaryTable(List<Map<String, dynamic>> attendances) {
    int hadir = 0, izin = 0, cuti = 0, alpha = 0, telat = 0;

    for (final a in attendances) {
      switch (a['status'] as String? ?? '') {
        case 'hadir':
          hadir++;
          break;
        case 'izin':
          izin++;
          break;
        case 'cuti':
          cuti++;
          break;
        case 'alpha':
          alpha++;
          break;
        case 'telat':
          telat++;
          break;
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _tableCell('Hadir', header: true),
            _tableCell('Izin', header: true),
            _tableCell('Cuti', header: true),
            _tableCell('Alpha', header: true),
            _tableCell('Telat', header: true),
            _tableCell('Total', header: true),
          ],
        ),
        pw.TableRow(
          children: [
            _tableCell('$hadir'),
            _tableCell('$izin'),
            _tableCell('$cuti'),
            _tableCell('$alpha'),
            _tableCell('$telat'),
            _tableCell('${attendances.length}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildAttendanceTable(List<Map<String, dynamic>> attendances) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _tableCell('No', header: true),
            _tableCell('Tanggal', header: true),
            _tableCell('Masuk', header: true),
            _tableCell('Keluar', header: true),
            _tableCell('Status', header: true),
          ],
        ),
        ...attendances.asMap().entries.map(
              (entry) => pw.TableRow(
                children: [
                  _tableCell('${entry.key + 1}'),
                  _tableCell(_formatDate(entry.value['tanggal'])),
                  _tableCell(_formatTime(entry.value['jam_masuk'])),
                  _tableCell(_formatTime(entry.value['jam_keluar'])),
                  _tableCell(entry.value['status'] ?? ''),
                ],
              ),
            ),
      ],
    );
  }

  pw.Widget _buildPayrollPeriod(Map<String, dynamic> payroll) {
    final monthName =
        DateFormat('MMMM', 'id_ID').format(
          DateTime(payroll['periode_tahun'] as int? ?? DateTime.now().year,
              payroll['periode_bulan'] as int? ?? DateTime.now().month),
        );
    return pw.Text(
      'Periode: $monthName ${payroll['periode_tahun']}',
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
      ),
    );
  }

  pw.Widget _buildPayrollTable(Map<String, dynamic> payroll) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rincian Gaji',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.blue50),
              children: [
                _tableCell('Komponen', header: true),
                _tableCell('Jumlah', header: true),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Gaji Pokok'),
                _tableCell(formatRupiah(payroll['gaji_pokok'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Tunjangan Tetap'),
                _tableCell(formatRupiah(payroll['tunjangan_tetap'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Uang Makan'),
                _tableCell(formatRupiah(payroll['uang_makan'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Uang Transport'),
                _tableCell(formatRupiah(payroll['uang_transport'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Lembur'),
                _tableCell(formatRupiah(payroll['total_lembur'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('THR'),
                _tableCell(formatRupiah(payroll['thr'] ?? 0)),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('BPJS Kesehatan (Karyawan)'),
                _tableCell(
                    '-${formatRupiah(payroll['bpjs_kesehatan_karyawan'] ?? 0)}'),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('BPJS JHT (Karyawan)'),
                _tableCell(
                    '-${formatRupiah(payroll['bpjs_jht_karyawan'] ?? 0)}'),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('BPJS JP (Karyawan)'),
                _tableCell(
                    '-${formatRupiah(payroll['bpjs_jp_karyawan'] ?? 0)}'),
              ],
            ),
            pw.TableRow(
              children: [
                _tableCell('Potongan Lain'),
                _tableCell(
                    '-${formatRupiah(payroll['potongan_lain'] ?? 0)}'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildPayrollSummary(Map<String, dynamic> payroll) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800, width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: [
          _summaryRow('Total Pendapatan', payroll['total_pendapatan'] ?? 0),
          pw.SizedBox(height: 4),
          _summaryRow('Total Potongan', payroll['total_potongan'] ?? 0),
          pw.Divider(thickness: 1, color: PdfColors.blue800),
          pw.SizedBox(height: 4),
          _summaryRow(
            'GAJI BERSIH',
            payroll['gaji_bersih'] ?? 0,
            bold: true,
            large: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _summaryRow(String label, dynamic amount,
      {bool bold = false, bool large = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: large ? 14 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          formatRupiah(amount),
          style: pw.TextStyle(
            fontSize: large ? 14 : 11,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: header ? 10 : 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '-';
    try {
      final dt = DateTime.parse(date.toString());
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return date.toString();
    }
  }

  String _formatTime(dynamic time) {
    if (time == null) return '-';
    try {
      final dt = DateTime.parse(time.toString());
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return time.toString();
    }
  }
}
