import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/core/utils/geofence_helper.dart';
import 'package:bss_attendance_new/domain/entities/work_location.dart';

void main() {
  const office = WorkLocation(
    id: 1,
    name: 'Kantor Pusat BSS',
    latitude: -6.224694,
    longitude: 106.807785,
    radiusMeters: 150,
  );

  const branch = WorkLocation(
    id: 2,
    name: 'Site Balikpapan',
    latitude: -1.269160,
    longitude: 116.825264,
    radiusMeters: 200,
  );

  group('GeofenceHelper Tests', () {
    test('allows attendance anywhere when isFlexibleLocation is true', () {
      final eval = GeofenceHelper.evaluate(
        latitude: -7.0,
        longitude: 110.0,
        isFlexibleLocation: true,
        workLocations: const [office],
      );

      expect(eval.isFlexible, isTrue);
      expect(eval.isWithinRadius, isTrue);
    });

    test('allows attendance when inside work location radius', () {
      // ~30m away from Kantor Pusat BSS
      final eval = GeofenceHelper.evaluate(
        latitude: -6.224900,
        longitude: 106.807800,
        isFlexibleLocation: false,
        workLocations: const [office],
      );

      expect(eval.isFlexible, isFalse);
      expect(eval.isWithinRadius, isTrue);
      expect(eval.nearestLocation?.name, 'Kantor Pusat BSS');
      expect(eval.distanceMeters, lessThan(150));
    });

    test('blocks attendance when outside all work location radii', () {
      // ~1.1km away from Kantor Pusat BSS
      final eval = GeofenceHelper.evaluate(
        latitude: -6.235000,
        longitude: 106.807785,
        isFlexibleLocation: false,
        workLocations: const [office, branch],
      );

      expect(eval.isFlexible, isFalse);
      expect(eval.isWithinRadius, isFalse);
      expect(eval.nearestLocation?.name, 'Kantor Pusat BSS');
      expect(eval.distanceMeters, greaterThan(150));
    });

    test('allows attendance if user is inside second assigned work location', () {
      final eval = GeofenceHelper.evaluate(
        latitude: -1.269200,
        longitude: 116.825264,
        isFlexibleLocation: false,
        workLocations: const [office, branch],
      );

      expect(eval.isWithinRadius, isTrue);
      expect(eval.nearestLocation?.name, 'Site Balikpapan');
    });
  });
}
