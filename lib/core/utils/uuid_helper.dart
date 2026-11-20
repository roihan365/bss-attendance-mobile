import 'package:uuid/uuid.dart';

class UuidHelper {
  static const _uuid = Uuid();

  /// Menghasilkan UUID v4 standar RFC-4122
  static String generate() {
    return _uuid.v4();
  }

  /// Memvalidasi apakah string merupakan UUID yang sah
  static bool isValid(String uuid) {
    return Uuid.isValidUUID(fromString: uuid);
  }
}
