import 'package:flutter_test/flutter_test.dart';
import 'package:dev_board/features/boards/data/models/filters_model.dart';

void main() {
  group('FiltersModel', () {
    test('should create empty filters by default', () {
      final filters = FiltersModel.empty();

      expect(filters.states, isEmpty);
      expect(filters.userIds, isEmpty);
      expect(filters.teamIds, isEmpty);
      expect(filters.tags, isEmpty);
      expect(filters.query, isEmpty);
      expect(filters.hasActiveFilters, isFalse);
      expect(filters.activeFilterCount, 0);
    });

    test('should create filters with initial values', () {
      final filters = FiltersModel(
        states: {'todo', 'inProgress'},
        userIds: {'user1', 'user2'},
        teamIds: {'team1'},
        tags: {'bug', 'feature'},
        query: 'search term',
      );

      expect(filters.states, {'todo', 'inProgress'});
      expect(filters.userIds, {'user1', 'user2'});
      expect(filters.teamIds, {'team1'});
      expect(filters.tags, {'bug', 'feature'});
      expect(filters.query, 'search term');
      expect(filters.hasActiveFilters, isTrue);
      expect(filters.activeFilterCount, 5);
    });

    test('should add and remove states', () {
      final filters = FiltersModel.empty();

      final withState = filters.addState('todo');
      expect(withState.states, contains('todo'));

      final withoutState = withState.removeState('todo');
      expect(withoutState.states, isNot(contains('todo')));
    });

    test('should add and remove users', () {
      final filters = FiltersModel.empty();

      final withUser = filters.addUser('user1');
      expect(withUser.userIds, contains('user1'));

      final withoutUser = withUser.removeUser('user1');
      expect(withoutUser.userIds, isNot(contains('user1')));
    });

    test('should add and remove teams', () {
      final filters = FiltersModel.empty();

      final withTeam = filters.addTeam('team1');
      expect(withTeam.teamIds, contains('team1'));

      final withoutTeam = withTeam.removeTeam('team1');
      expect(withoutTeam.teamIds, isNot(contains('team1')));
    });

    test('should add and remove tags', () {
      final filters = FiltersModel.empty();

      final withTag = filters.addTag('bug');
      expect(withTag.tags, contains('bug'));

      final withoutTag = withTag.removeTag('bug');
      expect(withoutTag.tags, isNot(contains('bug')));
    });

    test('should clear all filters', () {
      final filters = FiltersModel(
        states: {'todo'},
        userIds: {'user1'},
        teamIds: {'team1'},
        tags: {'bug'},
        query: 'search',
      );

      final clearedFilters = filters.clear();

      expect(clearedFilters.states, isEmpty);
      expect(clearedFilters.userIds, isEmpty);
      expect(clearedFilters.teamIds, isEmpty);
      expect(clearedFilters.tags, isEmpty);
      expect(clearedFilters.query, isEmpty);
      expect(clearedFilters.hasActiveFilters, isFalse);
    });

    test('should copy with modifications', () {
      final originalFilters = FiltersModel.empty();

      final updatedFilters = originalFilters.copyWith(
        states: {'todo'},
        query: 'new query',
      );

      expect(updatedFilters.states, {'todo'});
      expect(updatedFilters.query, 'new query');
      expect(updatedFilters.userIds, isEmpty);
      expect(updatedFilters.teamIds, isEmpty);
      expect(updatedFilters.tags, isEmpty);
    });

    test('should calculate active filter count correctly', () {
      final filters1 = FiltersModel.empty();
      expect(filters1.activeFilterCount, 0);

      final filters2 = FiltersModel(
        states: {'todo'},
        query: 'search',
      );
      expect(filters2.activeFilterCount, 2);

      final filters3 = FiltersModel(
        states: {'todo', 'inProgress'},
        userIds: {'user1'},
        teamIds: {'team1'},
        tags: {'bug'},
        query: 'search',
      );
      expect(filters3.activeFilterCount, 5);
    });

    test('should implement equality correctly', () {
      final filters1 = FiltersModel(
        states: {'todo'},
        userIds: {'user1'},
        query: 'search',
      );

      final filters2 = FiltersModel(
        states: {'todo'},
        userIds: {'user1'},
        query: 'search',
      );

      final filters3 = FiltersModel(
        states: {'todo'},
        userIds: {'user2'},
        query: 'search',
      );

      expect(filters1, equals(filters2));
      expect(filters1, isNot(equals(filters3)));
    });
  });
}
