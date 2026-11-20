import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';

class AuthApiDataSource {
  final String baseUrl;

  AuthApiDataSource({required this.baseUrl});

  Future<User> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode({'email': email, 'password': password}),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return User.fromJson(data['data']);
    }

    // Ambil errors
    final errors = data['errors'];

    if (errors != null && errors is Map && errors.isNotEmpty) {
      final messages = <String>[];

      errors.forEach((field, value) {
        if (value is List) {
          messages.addAll(value.map((e) => e.toString()));
        } else if (value != null) {
          messages.add(value.toString());
        }
      });

      if (messages.isNotEmpty) {
        throw Exception(messages.join('\n'));
      }
    }

    // Jika errors null / [] / kosong
    throw Exception(
      data['message']?.toString() ?? 'Login gagal: ${response.statusCode}',
    );
  }

  Future<void> logout(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Logout gagal: ${response.statusCode}');
    }
  }
}
