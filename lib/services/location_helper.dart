import 'package:geolocator/geolocator.dart';

class AttendanceLocationResult {
  final double latitude;
  final double longitude;
  final int distanceMeters;
  final String locationName;
  final bool withinRadius;

  const AttendanceLocationResult({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.locationName,
    required this.withinRadius,
  });
}

class LocationHelper {
  // Ganti dengan koordinat latitude & longitude sekolah kamu
  static const double schoolLat = 30.04042595486019;
  static const double schoolLng = 31.33487530047602;
  static const double maxAllowedRadiusMeters = 100.0;
  static const String schoolLocationLabel = 'Sukari indonesia';

  static Future<AttendanceLocationResult> getAttendanceLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Layanan GPS / Lokasi di perangkat masih mati. Aktifkan dulu ya.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak. Presensi membutuhkan akses GPS.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi diblokir permanen. Aktifkan lewat Pengaturan aplikasi.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    final rawDistance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      schoolLat,
      schoolLng,
    );

    final roundedDistance = rawDistance.round();

    return AttendanceLocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      distanceMeters: roundedDistance,
      locationName: schoolLocationLabel,
      withinRadius: rawDistance <= maxAllowedRadiusMeters,
    );
  }
}