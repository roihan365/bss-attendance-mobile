import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/security/anti_mock_location_service.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import 'i_location_service.dart';

class GeolocatorLocationService implements ILocationService {
  @override
  Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Layanan GPS / Lokasi pada perangkat nonaktif. Mohon aktifkan GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Izin akses lokasi ditolak oleh pengguna.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi ditolak permanen. Buka Pengaturan untuk mengaktifkan.');
    }

    // Ambil koordinat GPS dengan akurasi tinggi
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // SECURITY CHECK: Validasi Anti-Mock Location (Fake GPS)
    AntiMockLocationService.validatePosition(position);

    String locationName = 'Lokasi Terdeteksi';

    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final parts = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty);

        locationName = parts.join(', ');

        if (locationName.isEmpty) {
          locationName = 'Koordinat: ${position.latitude}, ${position.longitude}';
        }
      }
    } catch (_) {
      locationName = 'Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }

    return LocationData(
      latitude: position.latitude.toString(),
      longitude: position.longitude.toString(),
      locationName: locationName,
    );
  }
}
