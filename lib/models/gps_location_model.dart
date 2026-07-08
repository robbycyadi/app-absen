import 'dart:math';

class GpsLocationModel {
  final String id;
  final String namaLokasi;
  final double latitude;
  final double longitude;
  final int radius;
  final bool isActive;

  const GpsLocationModel({
    required this.id,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.isActive,
  });

  bool isWithinRadius(double empLatitude, double empLongitude) {
    const double earthRadius = 6371000.0;

    final double lat1 = latitude * pi / 180;
    final double lat2 = empLatitude * pi / 180;
    final double lon1 = longitude * pi / 180;
    final double lon2 = empLongitude * pi / 180;

    final double dlat = lat2 - lat1;
    final double dlon = lon2 - lon1;

    final double a = sin(dlat / 2) * sin(dlat / 2) +
        cos(lat1) * cos(lat2) * sin(dlon / 2) * sin(dlon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final double distance = earthRadius * c;

    return distance <= radius;
  }

  factory GpsLocationModel.fromJson(Map<String, dynamic> json) {
    return GpsLocationModel(
      id: json['id'] as String,
      namaLokasi: json['nama_lokasi'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radius: json['radius'] as int,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lokasi': namaLokasi,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_active': isActive,
    };
  }

  GpsLocationModel copyWith({
    String? id,
    String? namaLokasi,
    double? latitude,
    double? longitude,
    int? radius,
    bool? isActive,
  }) {
    return GpsLocationModel(
      id: id ?? this.id,
      namaLokasi: namaLokasi ?? this.namaLokasi,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'GpsLocationModel(id: $id, namaLokasi: $namaLokasi, lat: $latitude, lon: $longitude, radius: $radius)';
  }
}
