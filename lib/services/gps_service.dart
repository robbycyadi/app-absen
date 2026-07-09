import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class GpsService {
  Future<Position> getCurrentLocation() async {
    try {
      final permission = await requestLocationPermission();
      if (!permission) {
        throw Exception('Location permission denied');
      }

      final position = await Geolocator.getCurrentPosition();
      return position;
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radius = 6371000;

    final double phi1 = lat1 * pi / 180;
    final double phi2 = lat2 * pi / 180;
    final double deltaPhi = (lat2 - lat1) * pi / 180;
    final double deltaLambda = (lon2 - lon1) * pi / 180;

    final double a = sin(deltaPhi / 2) * sin(deltaPhi / 2) +
        cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radius * c;
  }

  bool isWithinRadius(
    double empLat,
    double empLon,
    double officeLat,
    double officeLon,
    double radiusMeters,
  ) {
    final distance = calculateDistance(empLat, empLon, officeLat, officeLon);
    return distance <= radiusMeters;
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty)
            place.administrativeArea!,
          if (place.country != null && place.country!.isNotEmpty)
            place.country!,
        ];
        return parts.join(', ');
      }
      return '$lat, $lng';
    } catch (e) {
      return '$lat, $lng';
    }
  }

  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }
}
