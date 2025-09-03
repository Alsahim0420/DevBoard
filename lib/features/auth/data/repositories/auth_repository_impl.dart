import '../datasources/auth_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/auth_credentials.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Stream<UserEntity?> get authStateChanges {
    return remoteDataSource.authStateChanges;
  }

  @override
  UserEntity? get currentUser {
    return remoteDataSource.currentUser;
  }

  @override
  Future<UserEntity> signIn(AuthCredentials credentials) async {
    return await remoteDataSource.signIn(credentials);
  }

  @override
  Future<UserEntity> signUp(AuthCredentials credentials) async {
    return await remoteDataSource.signUp(credentials);
  }

  @override
  Future<void> signOut() async {
    return await remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return await remoteDataSource.sendPasswordResetEmail(email);
  }
}
