import '../entities/auth_credentials.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> call(AuthCredentials credentials) async {
    return await repository.signUp(credentials);
  }
}
