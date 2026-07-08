import 'package:flutter/material.dart';

enum TipeShift {
  pagi,
  siang,
  malam;

  static TipeShift fromString(String value) {
    switch (value) {
      case 'pagi':
        return TipeShift.pagi;
      case 'siang':
        return TipeShift.siang;
      case 'malam':
        return TipeShift.malam;
      default:
        throw ArgumentError('Invalid TipeShift: $value');
    }
  }

  @override
  String toString() => name;
}

class ShiftModel {
  final String id;
  final String namaShift;
  final TipeShift tipeShift;
  final TimeOfDay jamMasuk;
  final TimeOfDay jamKeluar;
  final int toleransiTerlambat;

  const ShiftModel({
    required this.id,
    required this.namaShift,
    required this.tipeShift,
    required this.jamMasuk,
    required this.jamKeluar,
    required this.toleransiTerlambat,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      namaShift: json['nama_shift'] as String,
      tipeShift: TipeShift.fromString(json['tipe_shift'] as String),
      jamMasuk: TimeOfDay(
        hour: int.parse(json['jam_masuk'].toString().split(':')[0]),
        minute: int.parse(json['jam_masuk'].toString().split(':')[1]),
      ),
      jamKeluar: TimeOfDay(
        hour: int.parse(json['jam_keluar'].toString().split(':')[0]),
        minute: int.parse(json['jam_keluar'].toString().split(':')[1]),
      ),
      toleransiTerlambat: json['toleransi_terlambat'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_shift': namaShift,
      'tipe_shift': tipeShift.toString(),
      'jam_masuk':
          '${jamMasuk.hour.toString().padLeft(2, '0')}:${jamMasuk.minute.toString().padLeft(2, '0')}',
      'jam_keluar':
          '${jamKeluar.hour.toString().padLeft(2, '0')}:${jamKeluar.minute.toString().padLeft(2, '0')}',
      'toleransi_terlambat': toleransiTerlambat,
    };
  }

  ShiftModel copyWith({
    String? id,
    String? namaShift,
    TipeShift? tipeShift,
    TimeOfDay? jamMasuk,
    TimeOfDay? jamKeluar,
    int? toleransiTerlambat,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      namaShift: namaShift ?? this.namaShift,
      tipeShift: tipeShift ?? this.tipeShift,
      jamMasuk: jamMasuk ?? this.jamMasuk,
      jamKeluar: jamKeluar ?? this.jamKeluar,
      toleransiTerlambat: toleransiTerlambat ?? this.toleransiTerlambat,
    );
  }

  @override
  String toString() {
    return 'ShiftModel(id: $id, namaShift: $namaShift, tipeShift: $tipeShift)';
  }
}
