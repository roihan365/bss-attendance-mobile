import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_api_data_source.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthApiDataSource remoteDataSource;
  static const String _userKey = 'user_data';

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login(String email, String password) async {
    final user = await remoteDataSource.login(email, password);
    await saveUser(user);
    return user;
  }

  @override
  Future<void> logout() async {
    final user = await getCurrentUser();
    if (user != null && user.token != null) {
      try {
        await remoteDataSource.logout(user.token!);
      } catch (_) {
        // Ignore if logout fails, still clear local data
      }
    }
    await clearUser();
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    print(data);
    if (data == null || data.isEmpty) {
      return null;
    }

    try {
      final jsonData = jsonDecode(data);

      print('Decoded user: $jsonData');

      return User.fromJson(Map<String, dynamic>.from(jsonData));
    } catch (e, stackTrace) {
      print('Error getCurrentUser: $e');
      print(stackTrace);
      return null;
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null && user.token != null && user.token!.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    final user = await getCurrentUser();
    return user?.token;
  }

  @override
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_userKey);
  }
}
