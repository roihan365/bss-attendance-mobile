import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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

class FraudCheckResult {
  final bool isFraud;
  final String? reason;
  final Position? position;

  const FraudCheckResult({
    required this.isFraud,
    this.reason,
    this.position,
  });

  static const safe = FraudCheckResult(isFraud: false);
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

  /// Memeriksa integritas perangkat saat aplikasi pertama kali dibuka
  static Future<FraudCheckResult> checkStartupIntegrity() async {
    try {
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) {
        return const FraudCheckResult(isFraud: false);
      }

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const FraudCheckResult(isFraud: false);
      }

      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );

      if (position.isMocked) {
        return FraudCheckResult(
          isFraud: true,
          reason: 'Aplikasi Fake GPS / Mock Location terdeteksi aktif pada perangkat Anda.',
          position: position,
        );
      }

      if (position.latitude == 0.0 && position.longitude == 0.0) {
        return FraudCheckResult(
          isFraud: true,
          reason: 'Koordinat GPS simulator / tidak wajar terdeteksi (0.0, 0.0).',
          position: position,
        );
      }

      return FraudCheckResult(isFraud: false, position: position);
    } catch (_) {
      return const FraudCheckResult(isFraud: false);
    }
  }

  /// Menampilkan dialog peringatan fraud saat terdeteksi
  static void showFraudWarningDialog(BuildContext context, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.errorRedLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.gpp_bad_rounded,
                color: AppColors.errorRed,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Peringatan Integritas',
                style: AppTextStyles.h3.copyWith(color: AppColors.errorRed),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              reason,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'PT BARITO SAMUDRA SEJAHTERA menerapkan sistem Anti-Fraud ketat. Segala bentuk manipulasi GPS atau penggunaan Fake GPS dilarang dan dapat menyebabkan presensi ditolak serta tercatat di sistem audit HRD.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorRed,
            ),
            child: const Text('Saya Mengerti & Matikan Fake GPS'),
          ),
        ],
      ),
    );
  }
}
