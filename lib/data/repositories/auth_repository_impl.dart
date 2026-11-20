import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IAuthRemoteDataSource remoteDataSource;
  final SecureStorageService secureStorageService;
  static const String _userKey = 'user_data';
  static const String _tokenKey = 'auth_bearer_token';
  String? _memoryToken;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorageService,
  });

  @override
  Future<User> login(String email, String password) async {
    final userModel = await remoteDataSource.login(email, password);

    AppLogger.i('AUTH', '🎉 Login sukses dari server untuk user: ${userModel.name} (ID: ${userModel.id})');

    _memoryToken = userModel.token;

    // 1. Simpan token secara permanen di beberapa layer (Memory, SharedPreferences, KeyStore)
    if (userModel.token != null && userModel.token!.isNotEmpty) {
      final token = userModel.token!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await secureStorageService.saveToken(token);
      await secureStorageService.saveUserId(userModel.id);
      final preview = token.length > 12 ? '${token.substring(0, 10)}...' : token;
      AppLogger.i('AUTH', '🔑 Token tersimpan permanen di Memory, SharedPreferences & KeyStore: $preview');
    } else {
      AppLogger.w('AUTH', '⚠️ userModel.token bernilai NULL dari response login!');
    }

    // 2. Simpan profil user
    await saveUser(userModel);
    AppLogger.i('AUTH', '💾 Profil user tersimpan di local cache.');
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
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> getToken() async {
    // 1. Memory cache
    if (_memoryToken != null && _memoryToken!.isNotEmpty) {
      return _memoryToken;
    }

    final prefs = await SharedPreferences.getInstance();

    // 2. Dedicated SharedPreferences key
    final prefToken = prefs.getString(_tokenKey);
    if (prefToken != null && prefToken.isNotEmpty) {
      _memoryToken = prefToken;
      return prefToken;
    }

    // 3. Android KeyStore / Secure Storage
    try {
      final secureToken = await secureStorageService.getToken();
      if (secureToken != null && secureToken.isNotEmpty) {
        _memoryToken = secureToken;
        await prefs.setString(_tokenKey, secureToken);
        return secureToken;
      }
    } catch (_) {}

    // 4. Fallback ke user_data json object
    try {
      final data = prefs.getString(_userKey);
      if (data != null && data.isNotEmpty) {
        final jsonData = jsonDecode(data) as Map<String, dynamic>;
        final token = jsonData['token']?.toString();
        if (token != null && token.isNotEmpty) {
          _memoryToken = token;
          await prefs.setString(_tokenKey, token);
          await secureStorageService.saveToken(token);
          return token;
        }
      }
    } catch (_) {}

    return null;
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
    if (user.token != null && user.token!.isNotEmpty) {
      _memoryToken = user.token;
      await prefs.setString(_tokenKey, user.token!);
    }
  }

  @override
  Future<void> clearUser() async {
    _memoryToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_tokenKey);
    await secureStorageService.clearAll();
    AppLogger.i('AUTH', '🧹 Token dan sesi telah dibersihkan (Logout eksplisit).');
  }
}
