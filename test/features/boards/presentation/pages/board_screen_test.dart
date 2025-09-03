import 'package:flutter_test/flutter_test.dart';
import 'package:dev_board/features/boards/data/models/task_model.dart';
import 'package:dev_board/features/boards/data/models/epic_model.dart';

void main() {
  group('BoardScreen Drag & Drop Tests', () {
    test('should create task model correctly', () {
      // Arrange & Act
      final mockTask = TaskModel(
        id: 'task1',
        title: 'Test Task 1',
        description: 'Test Description',
        epicId: 'epic1',
        ownerId: 'user1',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(mockTask.id, equals('task1'));
      expect(mockTask.title, equals('Test Task 1'));
      expect(mockTask.status, equals(TaskStatus.todo));
      expect(mockTask.priority, equals(TaskPriority.medium));
    });

    test('should create epic model correctly', () {
      // Arrange & Act
      final mockEpic = EpicModel(
        id: 'epic1',
        title: 'Test Epic',
        description: 'Test Epic Description',
        boardId: 'board1',
        ownerId: 'user1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(mockEpic.id, equals('epic1'));
      expect(mockEpic.title, equals('Test Epic'));
      expect(mockEpic.boardId, equals('board1'));
    });

    test('should handle task status changes', () {
      // Arrange
      final task = TaskModel(
        id: 'task1',
        title: 'Test Task',
        description: 'Test Description',
        epicId: 'epic1',
        ownerId: 'user1',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updatedTask = task.copyWith(
        status: TaskStatus.inProgress,
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(updatedTask.status, equals(TaskStatus.inProgress));
      expect(updatedTask.id, equals(task.id)); // ID should remain the same
    });
  });
}
