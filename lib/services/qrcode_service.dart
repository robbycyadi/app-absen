import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app_absen/config/platform_helper.dart';

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
    if (PlatformHelper.isWeb) {
      return _showWebScanDialog(context);
    }
    return _scanQrMobile(context);
  }

  Future<String?> _showWebScanDialog(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan QR Code'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Masukkan kode QR',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<String?> _scanQrMobile(BuildContext context) async {
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: const Center(
        child: Text(
          'QR Scanner tidak tersedia di web',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
