import '../repositories/i_auth_repository.dart';
import '../entities/user.dart';

class LoginUseCase {
  final IAuthRepository repository;

  LoginUseCase(this.repository);

  Future<User> call(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('email dan password harus diisi');
    }
    return await repository.login(email, password);
  }
}