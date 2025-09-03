import '../repositories/auth_repository.dart';

class SendPasswordResetEmailUseCase {
  final AuthRepository authRepository;

  SendPasswordResetEmailUseCase(this.authRepository);

  Future<void> call(String email) async {
    return await authRepository.sendPasswordResetEmail(email);
  }
}
