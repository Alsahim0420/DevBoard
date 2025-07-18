import '../entities/auth_credentials.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<UserEntity> call(AuthCredentials credentials) async {
    return await repository.signIn(credentials);
  }
}
