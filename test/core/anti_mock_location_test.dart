import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bss_attendance_new/core/security/anti_mock_location_service.dart';

void main() {
  group('AntiMockLocationService Security Tests', () {
    test('throws MockLocationDetectedException when isMocked is true', () {
      final mockedPosition = Position(
        latitude: -6.2145,
        longitude: 106.8451,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 20.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: true, // FAKE GPS ACTIVE
      );

      expect(
        () => AntiMockLocationService.validatePosition(mockedPosition),
        throwsA(isA<MockLocationDetectedException>()),
      );
    });

    test('throws InaccurateGpsException when accuracy exceeds threshold (e.g. 150m)', () {
      final badAccuracyPosition = Position(
        latitude: -6.2145,
        longitude: 106.8451,
        timestamp: DateTime.now(),
        accuracy: 150.0, // TOO INACCURATE
        altitude: 20.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      expect(
        () => AntiMockLocationService.validatePosition(badAccuracyPosition),
        throwsA(isA<InaccurateGpsException>()),
      );
    });

    test('throws MockLocationDetectedException when coordinates are 0,0', () {
      final zeroPosition = Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 20.0,
        altitudeAccuracy: 5.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      expect(
        () => AntiMockLocationService.validatePosition(zeroPosition),
        throwsA(isA<MockLocationDetectedException>()),
      );
    });

    test('passes validation when position is genuine and accurate', () {
      final validPosition = Position(
        latitude: -6.2145,
        longitude: 106.8451,
        timestamp: DateTime.now(),
        accuracy: 12.5,
        altitude: 25.0,
        altitudeAccuracy: 3.0,
        heading: 90.0,
        headingAccuracy: 2.0,
        speed: 1.2,
        speedAccuracy: 0.5,
        isMocked: false,
      );

      expect(
        () => AntiMockLocationService.validatePosition(validPosition),
        returnsNormally,
      );
    });
  });
}
