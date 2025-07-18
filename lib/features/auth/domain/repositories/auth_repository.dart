import '../entities/user_entity.dart';
import '../entities/auth_credentials.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  UserEntity? get currentUser;

  Future<UserEntity> signIn(AuthCredentials credentials);
  Future<UserEntity> signUp(AuthCredentials credentials);
  Future<void> signOut();
}
