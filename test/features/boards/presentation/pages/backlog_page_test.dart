import 'package:flutter_test/flutter_test.dart';
import 'package:dev_board/features/boards/data/models/task_model.dart';

void main() {
  group('BacklogPage Tests', () {
    test('should handle task reordering', () {
      // Arrange
      final tasks = [
        TaskModel(
          id: 'task1',
          title: 'Task 1',
          description: 'Description 1',
          epicId: 'epic1',
          ownerId: 'user1',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        TaskModel(
          id: 'task2',
          title: 'Task 2',
          description: 'Description 2',
          epicId: 'epic1',
          ownerId: 'user1',
          status: TaskStatus.todo,
          priority: TaskPriority.medium,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act - Simulate reordering
      final reorderedTasks = List<TaskModel>.from(tasks);
      final item = reorderedTasks.removeAt(0);
      reorderedTasks.insert(1, item);

      // Assert
      expect(reorderedTasks.length, equals(2));
      expect(reorderedTasks[0].id, equals('task2'));
      expect(reorderedTasks[1].id, equals('task1'));
    });

    test('should validate task editing form', () {
      // Arrange
      final task = TaskModel(
        id: 'task1',
        title: 'Original Title',
        description: 'Original Description',
        epicId: 'epic1',
        ownerId: 'user1',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(task.title, equals('Original Title'));
      expect(task.description, equals('Original Description'));

      // Test copyWith functionality
      final updatedTask = task.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
        updatedAt: DateTime.now(),
      );

      expect(updatedTask.title, equals('Updated Title'));
      expect(updatedTask.description, equals('Updated Description'));
      expect(updatedTask.id, equals(task.id)); // ID should remain the same
    });

    test('should validate task form fields', () {
      // Arrange
      final task = TaskModel(
        id: 'task1',
        title: 'Test Task',
        description: 'Test Description',
        epicId: 'epic1',
        ownerId: 'user1',
        status: TaskStatus.todo,
        priority: TaskPriority.medium,
        timeEstimate: '2h',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(task.title.isNotEmpty, isTrue);
      expect(task.description.isNotEmpty, isTrue);
      expect(task.timeEstimate, equals('2h'));
      expect(task.priority, equals(TaskPriority.medium));
    });
  });
}
