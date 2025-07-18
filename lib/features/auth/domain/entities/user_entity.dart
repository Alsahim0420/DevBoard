import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final bool isEmailVerified;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, isEmailVerified, createdAt];
}
