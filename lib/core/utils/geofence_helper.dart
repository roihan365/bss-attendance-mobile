import 'dart:math' as math;
import '../../domain/entities/work_location.dart';

class GeofenceEvaluation {
  final bool isFlexible;
  final bool isWithinRadius;
  final WorkLocation? nearestLocation;
  final double? distanceMeters;

  const GeofenceEvaluation({
    required this.isFlexible,
    required this.isWithinRadius,
    this.nearestLocation,
    this.distanceMeters,
  });
}

class GeofenceHelper {
  static const double _earthRadiusMeters = 6371000.0;

  /// Menghitung jarak Haversine dalam meter antara dua koordinat GPS.
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  static double _toRadians(double deg) => deg * (math.pi / 180.0);

  /// Mengevaluasi apakah koordinat user berada dalam radius salah satu lokasi kerja.
  static GeofenceEvaluation evaluate({
    required double latitude,
    required double longitude,
    required bool isFlexibleLocation,
    required List<WorkLocation> workLocations,
  }) {
    if (isFlexibleLocation) {
      return const GeofenceEvaluation(
        isFlexible: true,
        isWithinRadius: true,
      );
    }

    if (workLocations.isEmpty) {
      return const GeofenceEvaluation(
        isFlexible: false,
        isWithinRadius: true,
      );
    }

    WorkLocation? nearest;
    double minDistance = double.infinity;

    for (final loc in workLocations) {
      final dist = calculateDistanceMeters(
        latitude,
        longitude,
        loc.latitude,
        loc.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
      // Jika sudah masuk dalam radius salah satu lokasi, langsung valid
      if (dist <= loc.radiusMeters) {
        return GeofenceEvaluation(
          isFlexible: false,
          isWithinRadius: true,
          nearestLocation: loc,
          distanceMeters: dist,
        );
      }
    }

    return GeofenceEvaluation(
      isFlexible: false,
      isWithinRadius: false,
      nearestLocation: nearest,
      distanceMeters: minDistance.isFinite ? minDistance : null,
    );
  }
}
