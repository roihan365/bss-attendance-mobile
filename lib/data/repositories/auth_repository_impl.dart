import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/secure_storage_service.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorageService;
  static const String _userKey = 'user_data';

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorageService,
  });

  @override
  Future<User> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);

    // 1. Simpan token secara aman di Android Keystore / iOS Keychain
    if (userModel.token != null) {
      await secureStorageService.saveToken(userModel.token!);
      await secureStorageService.saveUserId(userModel.id);
    }

    // 2. Simpan profil user
    await saveUser(userModel);
    return userModel;
  }

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (_) {}
    await clearUser();
  }

  @override
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    final secureToken = await secureStorageService.getToken();

    if (data == null || data.isEmpty) {
      return null;
    }

    try {
      final jsonData = jsonDecode(data) as Map<String, dynamic>;
      final user = UserModel.fromJson(jsonData);
      // Selalu gunakan token terenkripsi dari Keystore/Keychain
      return user.copyWith(token: secureToken ?? user.token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<User?> refreshUserProfile() async {
    try {
      final userProfile = await remoteDataSource.getUserProfile();
      final secureToken = await secureStorageService.getToken();
      final updatedUser = userProfile.copyWith(token: secureToken);
      await saveUser(updatedUser);
      return updatedUser;
    } catch (_) {
      return await getCurrentUser();
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await secureStorageService.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    return await secureStorageService.getToken();
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
    await secureStorageService.clearAll();
  }
}
