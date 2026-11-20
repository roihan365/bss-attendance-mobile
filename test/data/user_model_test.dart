import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/data/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('fromJson parses nested login API response', () {
      final json = {
        'token': 'mock-token-abc',
        'user': {
          'id': 5,
          'name': 'Roy Field Worker',
          'email': 'roy@bss.co.id',
          'email_verified_at': '2026-11-20T10:00:00.000000Z',
        }
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '5');
      expect(user.name, 'Roy Field Worker');
      expect(user.email, 'roy@bss.co.id');
      expect(user.token, 'mock-token-abc');
      expect(user.emailVerifiedAt, isNotNull);
    });

    test('fromJson parses direct /user endpoint response', () {
      final json = {
        'id': 5,
        'name': 'Roy Field Worker',
        'email': 'roy@bss.co.id',
        'email_verified_at': '2026-11-20T10:00:00.000000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, '5');
      expect(user.name, 'Roy Field Worker');
      expect(user.email, 'roy@bss.co.id');
    });
  });
}
