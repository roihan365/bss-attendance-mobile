import '../entities/user.dart';
import '../repositories/i_auth_repository.dart';

class RefreshUserProfileUseCase {
  final IAuthRepository repository;

  RefreshUserProfileUseCase(this.repository);

  Future<User?> call() async {
    return await repository.refreshUserProfile();
  }
}
