import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  static const String _userKey = 'user_data';

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<User> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);
    await saveUser(userModel);
    return userModel;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {
      // Abaikan jika token di server gagal di-delete (misal offline), tetap bersihkan lokal
    }
    await clearUser();
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data == null || data.isEmpty) {
      return null;
    }

    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      return UserModel.fromJson(jsonData);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> refreshUserProfile() async {
    try {
      final userProfile = await remoteDataSource.getUserProfile();
      final currentUser = await getCurrentUser();
      // Pertahankan token yang sudah tersimpan
      final updatedUser = userProfile.copyWith(token: currentUser?.token);
      await saveUser(updatedUser);
      return updatedUser;
    } catch (_) {
      return await getCurrentUser();
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
    final model = UserModel(
      id: user.id,
      email: user.email,
      name: user.name,
      token: user.token,
      emailVerifiedAt: user.emailVerifiedAt,
    );
    await prefs.setString(_userKey, json.encode(model.toJson()));
  }

  @override
  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
