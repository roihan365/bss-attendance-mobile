import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/core/network/api_response.dart';

void main() {
  group('ApiResponse Tests', () {
    test('parse successful Laravel API response', () {
      final json = {
        'success': true,
        'message': 'sukses login',
        'data': {
          'token': 'mock_token_123',
          'user': {'id': 1, 'name': 'Roy Ganteng', 'email': 'roy@ganteng.com'}
        },
        'errors': null
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(json);

      expect(response.success, isTrue);
      expect(response.message, 'sukses login');
      expect(response.data?['token'], 'mock_token_123');
      expect(response.errors, isNull);
    });

    test('parse and format Laravel validation errors (Map of Lists)', () {
      final json = {
        'success': false,
        'message': 'Validasi Gagal',
        'data': null,
        'errors': {
          'email': ['Kolom email wajib diisi'],
          'password': ['Password minimal 8 karakter']
        }
      };

      final response = ApiResponse<dynamic>.fromJson(json);

      expect(response.success, isFalse);
      expect(
        response.formattedErrorMessage,
        'Kolom email wajib diisi\nPassword minimal 8 karakter',
      );
    });

    test('fallback to message if errors field is null or empty', () {
      final json = {
        'success': false,
        'message': 'Email tidak ditemukan',
        'data': null,
        'errors': null
      };

      final response = ApiResponse<dynamic>.fromJson(json);

      expect(response.success, isFalse);
      expect(response.formattedErrorMessage, 'Email tidak ditemukan');
    });
  });
}
