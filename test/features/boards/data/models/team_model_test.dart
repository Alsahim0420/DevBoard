import 'package:flutter_test/flutter_test.dart';
import 'package:dev_board/features/boards/data/models/team_model.dart';

void main() {
  group('TeamModel', () {
    test('should create team with required fields', () {
      final team = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(team.id, 'team123');
      expect(team.name, 'Equipo Frontend');
      expect(team.ownerId, 'user123');
      expect(team.description, isNull);
      expect(team.memberUserIds, isEmpty);
    });

    test('should create team with all fields', () {
      final team = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        description: 'Equipo encargado del desarrollo frontend',
        memberUserIds: ['user1', 'user2', 'user3'],
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(team.description, 'Equipo encargado del desarrollo frontend');
      expect(team.memberUserIds, ['user1', 'user2', 'user3']);
      expect(team.memberCount, 3);
    });

    test('should create team using factory method', () {
      final team = TeamModel.create(
        name: 'Equipo Backend',
        description: 'Equipo encargado del desarrollo backend',
        ownerId: 'user123',
        memberUserIds: ['user1', 'user2'],
      );

      expect(team.name, 'Equipo Backend');
      expect(team.description, 'Equipo encargado del desarrollo backend');
      expect(team.ownerId, 'user123');
      expect(team.memberUserIds, ['user1', 'user2']);
      expect(team.id, '');
    });

    test('should add member to team', () {
      final team = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTeam = team.addMember('user456');

      expect(updatedTeam.memberUserIds, contains('user456'));
      expect(updatedTeam.memberCount, 1);
    });

    test('should remove member from team', () {
      final team = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        memberUserIds: ['user1', 'user2', 'user3'],
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTeam = team.removeMember('user2');

      expect(updatedTeam.memberUserIds, isNot(contains('user2')));
      expect(updatedTeam.memberUserIds, contains('user1'));
      expect(updatedTeam.memberUserIds, contains('user3'));
      expect(updatedTeam.memberCount, 2);
    });

    test('should check if user is member', () {
      final team = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        memberUserIds: ['user1', 'user2'],
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(team.isMember('user1'), isTrue);
      expect(team.isMember('user2'), isTrue);
      expect(team.isMember('user3'), isFalse);
    });

    test('should copy with modifications', () {
      final originalTeam = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final updatedTeam = originalTeam.copyWith(
        name: 'Equipo Frontend Actualizado',
        description: 'Nueva descripción',
        memberUserIds: ['user1', 'user2'],
      );

      expect(updatedTeam.id, 'team123');
      expect(updatedTeam.name, 'Equipo Frontend Actualizado');
      expect(updatedTeam.description, 'Nueva descripción');
      expect(updatedTeam.memberUserIds, ['user1', 'user2']);
      expect(updatedTeam.ownerId, 'user123');
    });

    test('should implement equality correctly', () {
      final team1 = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final team2 = TeamModel(
        id: 'team123',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final team3 = TeamModel(
        id: 'team456',
        name: 'Equipo Frontend',
        ownerId: 'user123',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      expect(team1, equals(team2));
      expect(team1, isNot(equals(team3)));
    });
  });
}
