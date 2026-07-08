import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrCodeService {
  String generateAttendanceQrData(Map<String, dynamic> attendance) {
    final data = {
      'id': attendance['id'],
      'employeeId': attendance['employee_id'],
      'nama': attendance['nama'] ?? '',
      'tanggal': attendance['tanggal'],
      'jamMasuk': attendance['jam_masuk'] ?? '',
      'jamKeluar': attendance['jam_keluar'] ?? '',
      'status': attendance['status'],
      'lokasi': {
        'lat': attendance['latitude_masuk'],
        'lon': attendance['longitude_masuk'],
      },
    };
    return jsonEncode(data);
  }

  String generatePayrollQrData(Map<String, dynamic> payroll) {
    final data = {
      'id': payroll['id'],
      'employeeId': payroll['employee_id'],
      'periode':
          '${payroll['periode_bulan']}/${payroll['periode_tahun']}',
      'gajiBersih':
          (payroll['gaji_bersih'] as num?)?.toDouble() ?? 0,
      'status': payroll['status'],
    };
    return jsonEncode(data);
  }

  Widget generateQrImage(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  Future<String?> scanQrCode(BuildContext context) async {
    try {
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => const _QrScannerPage(),
          fullscreenDialog: true,
        ),
      );
      return result;
    } catch (e) {
      throw Exception('Failed to scan QR code: $e');
    }
  }
}

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();

  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode != null && barcode.rawValue != null) {
            _hasScanned = true;
            Navigator.of(context).pop(barcode.rawValue);
          }
        },
      ),
    );
  }
}
