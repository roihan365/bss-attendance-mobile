import 'dart:io';

class DeviceSecurityService {
  /// Memeriksa indikator perangkat yang sudah di-root (Android)
  static Future<bool> isRooted() async {
    if (!Platform.isAndroid) return false;

    // Daftar lokasi binary su yang umum digunakan pada perangkat rooted
    final paths = [
      '/system/app/Superuser.apk',
      '/sbin/su',
      '/system/bin/su',
      '/system/xbin/su',
      '/data/local/xbin/su',
      '/data/local/bin/su',
      '/system/sd/xbin/su',
      '/system/bin/failsafe/su',
      '/data/local/su',
      '/su/bin/su',
    ];

    for (final path in paths) {
      if (File(path).existsSync()) {
        return true;
      }
    }

    return false;
  }
}
