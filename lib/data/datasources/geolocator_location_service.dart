import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import 'i_location_service.dart';

class GeolocatorLocationService implements ILocationService {
  @override
  Future<LocationData> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission denied');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String locationName = 'Current Location';

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
          place.country,
        ].where((e) => e != null && e.trim().isNotEmpty);

        locationName = parts.join(', ');

        if (locationName.isEmpty) {
          locationName = 'Current Location';
        }
      }
    } catch (e) {
      print('Geocoding error: $e');
    }

    return LocationData(
      latitude: position.latitude.toString(),
      longitude: position.longitude.toString(),
      locationName: locationName,
    );
  }
}
