import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:bss_attendance_new/core/security/secure_storage_service.dart';

void main() {
  group('SecureStorageService Tests', () {
    test('saveToken and getToken persist encrypted token', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = SecureStorageService();

      await service.saveToken('secure-sanctum-token-12345');
      final retrievedToken = await service.getToken();

      expect(retrievedToken, 'secure-sanctum-token-12345');

      await service.deleteToken();
      final afterDelete = await service.getToken();
      expect(afterDelete, isNull);
    });

    test('saveUserId and getUserId persist user ID', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = SecureStorageService();

      await service.saveUserId('99');
      final retrievedId = await service.getUserId();

      expect(retrievedId, '99');
    });
  });
}
