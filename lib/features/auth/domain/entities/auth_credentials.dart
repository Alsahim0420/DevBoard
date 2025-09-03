import 'package:equatable/equatable.dart';
import '../../../boards/data/models/user_model.dart';

class AuthCredentials extends Equatable {
  final String email;
  final String password;
  final String? displayName;
  final String? avatarIcon;
  final String? avatarColor;
  final UserRole? role;
  final String? adminKey; // Clave para crear usuarios admin

  const AuthCredentials({
    required this.email,
    required this.password,
    this.displayName,
    this.avatarIcon,
    this.avatarColor,
    this.role,
    this.adminKey,
  });

  @override
  List<Object?> get props =>
      [email, password, displayName, avatarIcon, avatarColor, role, adminKey];
}
