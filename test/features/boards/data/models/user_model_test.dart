import 'package:flutter_test/flutter_test.dart';
import 'package:dev_board/features/boards/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('should create user with required fields', () {
      final user = UserModel(
        id: 'user123',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(user.id, 'user123');
      expect(user.displayName, 'Juan Pérez');
      expect(user.email, 'juan@ejemplo.com');
      expect(user.avatarIcon, isNull);
      expect(user.avatarColor, isNull);
      expect(user.teamId, isNull);
    });

    test('should create user with all fields', () {
      final user = UserModel(
        id: 'user123',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        avatarIcon: 'person',
        avatarColor: 'blue',
        teamId: 'team123',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(user.avatarIcon, 'person');
      expect(user.avatarColor, 'blue');
      expect(user.teamId, 'team123');
    });

    test('should generate correct initials', () {
      final user1 = UserModel(
        id: 'user1',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final user2 = UserModel(
        id: 'user2',
        displayName: 'María',
        email: 'maria@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final user3 = UserModel(
        id: 'user3',
        displayName: 'Ana María González López',
        email: 'ana@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(user1.initials, 'JP');
      expect(user2.initials, 'M');
      expect(user3.initials, 'AL');
    });

    test('should create user using factory method', () {
      final user = UserModel.create(
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        avatarIcon: 'person',
        avatarColor: 'blue',
        teamId: 'team123',
      );

      expect(user.displayName, 'Juan Pérez');
      expect(user.email, 'juan@ejemplo.com');
      expect(user.avatarIcon, 'person');
      expect(user.avatarColor, 'blue');
      expect(user.teamId, 'team123');
      expect(user.id, '');
    });

    test('should copy with modifications', () {
      final originalUser = UserModel(
        id: 'user123',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedUser = originalUser.copyWith(
        displayName: 'Juan Carlos Pérez',
        teamId: 'team123',
      );

      expect(updatedUser.id, 'user123');
      expect(updatedUser.displayName, 'Juan Carlos Pérez');
      expect(updatedUser.email, 'juan@ejemplo.com');
      expect(updatedUser.teamId, 'team123');
    });

    test('should implement equality correctly', () {
      final user1 = UserModel(
        id: 'user123',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final user2 = UserModel(
        id: 'user123',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final user3 = UserModel(
        id: 'user456',
        displayName: 'Juan Pérez',
        email: 'juan@ejemplo.com',
        role: UserRole.desarrollador,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });
  });
}
