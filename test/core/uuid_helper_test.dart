import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/core/utils/uuid_helper.dart';

void main() {
  group('UuidHelper Tests', () {
    test('generate() returns valid RFC-4122 v4 UUID string', () {
      final uuid = UuidHelper.generate();
      expect(uuid, isNotEmpty);
      expect(UuidHelper.isValid(uuid), isTrue);

      // Regex for UUID v4
      final uuidV4Pattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      );
      expect(uuidV4Pattern.hasMatch(uuid), isTrue);
    });

    test('generate() generates unique IDs on successive calls', () {
      final id1 = UuidHelper.generate();
      final id2 = UuidHelper.generate();
      expect(id1, isNot(equals(id2)));
    });

    test('isValid() rejects invalid string formats', () {
      expect(UuidHelper.isValid(''), isFalse);
      expect(UuidHelper.isValid('12345'), isFalse);
      expect(UuidHelper.isValid('1700000000_1'), isFalse);
    });
  });
}
