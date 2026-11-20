import 'package:geolocator/geolocator.dart';

class MockLocationDetectedException implements Exception {
  final String message;
  MockLocationDetectedException([
    this.message = 'Terdeteksi manipulasi GPS / Fake GPS. Presensi ditolak demi integritas data.',
  ]);

  @override
  String toString() => message;
}

class InaccurateGpsException implements Exception {
  final double accuracy;
  InaccurateGpsException(this.accuracy);

  @override
  String toString() =>
      'Akurasi sinyal GPS terlalu rendah (${accuracy.toStringAsFixed(1)}m). Cari ruang terbuka untuk melanjutkan presensi.';
}

class AntiMockLocationService {
  static const double maxAcceptableAccuracyMeters = 100.0;

  /// Memvalidasi integritas posisi GPS
  static void validatePosition(Position position) {
    // 1. Cek flag isMocked (deteksi aplikasi Mock Location / Fake GPS Android & iOS)
    if (position.isMocked) {
      throw MockLocationDetectedException();
    }

    // 2. Cek apakah akurasi GPS terlalu buruk
    if (position.accuracy > maxAcceptableAccuracyMeters) {
      throw InaccurateGpsException(position.accuracy);
    }

    // 3. Cek apakah koordinat valid (tidak 0.0, 0.0)
    if (position.latitude == 0.0 && position.longitude == 0.0) {
      throw MockLocationDetectedException('Koordinat GPS tidak valid (0, 0).');
    }
  }
}
