import '../entities/user.dart';

abstract class IAuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<User?> refreshUserProfile();
  Future<bool> isLoggedIn();
  Future<String?> getToken();
  Future<void> saveUser(User user);
  Future<void> clearUser();
}
