import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_credentials.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final AuthCredentials credentials;

  const SignInRequested(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class SignUpRequested extends AuthEvent {
  final AuthCredentials credentials;

  const SignUpRequested(this.credentials);

  @override
  List<Object?> get props => [credentials];
}

class SignOutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}
