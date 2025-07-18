import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/board_model.dart';
import '../models/epic_model.dart';
import '../models/task_model.dart';
import '../models/sprint_model.dart';

class BoardsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo tablero
  Future<void> createBoard(BoardModel board) async {
    try {
      final docRef =
          await _firestore.collection('boards').add(board.toFirestore());

      // Actualizar el ID del tablero
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Error al crear el tablero: $e');
    }
  }

  // Obtener tableros de un usuario
  Stream<List<BoardModel>> getUserBoards(String userId) {
    debugPrint('Getting boards for user: $userId');
    return _firestore
        .collection('boards')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      debugPrint('Found ${snapshot.docs.length} boards in Firestore');
      final boards =
          snapshot.docs.map((doc) => BoardModel.fromFirestore(doc)).toList();
      // Ordenar localmente por fecha de creación
      boards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('Returning ${boards.length} boards');
      return boards;
    });
  }

  // Obtener un tablero específico
  Future<BoardModel?> getBoard(String boardId) async {
    try {
      final doc = await _firestore.collection('boards').doc(boardId).get();
      if (doc.exists) {
        return BoardModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener el tablero: $e');
    }
  }

  // Actualizar un tablero
  Future<void> updateBoard(BoardModel board) async {
    try {
      await _firestore
          .collection('boards')
          .doc(board.id)
          .update(board.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar el tablero: $e');
    }
  }

  // Eliminar un tablero
  Future<void> deleteBoard(String boardId) async {
    try {
      await _firestore.collection('boards').doc(boardId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el tablero: $e');
    }
  }

  // Agregar miembro a un tablero
  Future<void> addMemberToBoard(String boardId, String userId) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'members': FieldValue.arrayUnion([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al agregar miembro: $e');
    }
  }

  // Remover miembro de un tablero
  Future<void> removeMemberFromBoard(String boardId, String userId) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'members': FieldValue.arrayRemove([userId]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error al remover miembro: $e');
    }
  }

  // ===== OPERACIONES DE ÉPICAS =====

  // Crear nueva épica
  Future<String> createEpic(EpicModel epic) async {
    final docRef = await _firestore.collection('epics').add(epic.toFirestore());
    return docRef.id;
  }

  // Obtener épicas de un tablero
  Stream<List<EpicModel>> getBoardEpics(String boardId, String userId) {
    return _firestore
        .collection('epics')
        .where('boardId', isEqualTo: boardId)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => EpicModel.fromFirestore(doc)).toList());
  }

  // Obtener una épica específica
  Future<EpicModel?> getEpic(String epicId) async {
    final doc = await _firestore.collection('epics').doc(epicId).get();
    if (doc.exists) {
      return EpicModel.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar épica
  Future<void> updateEpic(EpicModel epic) async {
    await _firestore
        .collection('epics')
        .doc(epic.id)
        .update(epic.toFirestore());
  }

  // Eliminar épica
  Future<void> deleteEpic(String epicId) async {
    // Primero eliminar todas las tareas de la épica
    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('epicId', isEqualTo: epicId)
        .get();

    final batch = _firestore.batch();
    for (final doc in tasksSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_firestore.collection('epics').doc(epicId));
    await batch.commit();
  }

  // Obtener todas las épicas (temporal para debugging)
  Stream<List<EpicModel>> getAllEpics() {
    return _firestore.collection('epics').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => EpicModel.fromFirestore(doc)).toList());
  }

  // Obtener todas las épicas una vez (temporal para debugging)
  Future<List<EpicModel>> getAllEpicsOnce() async {
    final snapshot = await _firestore.collection('epics').get();
    return snapshot.docs.map((doc) => EpicModel.fromFirestore(doc)).toList();
  }

  // ===== OPERACIONES DE TAREAS =====

  // Crear nueva tarea
  Future<String> createTask(TaskModel task) async {
    final docRef = await _firestore.collection('tasks').add(task.toFirestore());
    return docRef.id;
  }

  // Obtener tareas de una épica
  Stream<List<TaskModel>> getEpicTasks(String epicId, String userId) {
    return _firestore
        .collection('tasks')
        .where('epicId', isEqualTo: epicId)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Obtener tareas por estado
  Stream<List<TaskModel>> getTasksByStatus(
      String epicId, TaskStatus status, String userId) {
    return _firestore
        .collection('tasks')
        .where('epicId', isEqualTo: epicId)
        .where('status', isEqualTo: TaskModel.statusToString(status))
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      // Ordenar localmente por prioridad y fecha
      tasks.sort((a, b) {
        final priorityComparison = b.priority.index.compareTo(a.priority.index);
        if (priorityComparison != 0) return priorityComparison;
        return b.createdAt.compareTo(a.createdAt);
      });
      return tasks;
    });
  }

  // Obtener tareas asignadas a un usuario
  Stream<List<TaskModel>> getAssignedTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('ownerId', isEqualTo: userId)
        .where('assignedTo', isEqualTo: userId)
        .where('status', whereIn: ['todo', 'in_progress'])
        .snapshots()
        .map((snapshot) {
          final tasks =
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
          // Ordenar localmente por fecha de vencimiento
          tasks.sort((a, b) {
            if (a.dueDate == null && b.dueDate == null) return 0;
            if (a.dueDate == null) return 1;
            if (b.dueDate == null) return -1;
            return a.dueDate!.compareTo(b.dueDate!);
          });
          return tasks;
        });
  }

  // Obtener todas las tareas de un usuario (para la página de recientes)
  Stream<List<TaskModel>> getUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      // Ordenar por fecha de actualización (más recientes primero)
      tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tasks;
    });
  }

  // ===== OPERACIONES DE FAVORITOS =====

  // Obtener tableros favoritos de un usuario
  Stream<List<BoardModel>> getUserFavoriteBoards(String userId) {
    return _firestore
        .collection('boards')
        .where('ownerId', isEqualTo: userId)
        .where('favoritedBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final boards =
          snapshot.docs.map((doc) => BoardModel.fromFirestore(doc)).toList();
      // Ordenar por fecha de actualización (más recientes primero)
      boards.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return boards;
    });
  }

  // Obtener tareas favoritas de un usuario
  Stream<List<TaskModel>> getUserFavoriteTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('ownerId', isEqualTo: userId)
        .where('favoritedBy', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final tasks =
          snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
      // Ordenar por fecha de actualización (más recientes primero)
      tasks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return tasks;
    });
  }

  // Marcar tablero como favorito
  Future<void> markBoardAsFavorite(String boardId, String userId) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'favoritedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar tablero como favorito: $e');
    }
  }

  // Desmarcar tablero como favorito
  Future<void> unmarkBoardAsFavorite(String boardId, String userId) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'favoritedBy': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al desmarcar tablero como favorito: $e');
    }
  }

  // Marcar tarea como favorita
  Future<void> markTaskAsFavorite(String taskId, String userId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'favoritedBy': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al marcar tarea como favorita: $e');
    }
  }

  // Desmarcar tarea como favorita
  Future<void> unmarkTaskAsFavorite(String taskId, String userId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).update({
        'favoritedBy': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al desmarcar tarea como favorita: $e');
    }
  }

  // Obtener una tarea específica
  Future<TaskModel?> getTask(String taskId) async {
    final doc = await _firestore.collection('tasks').doc(taskId).get();
    if (doc.exists) {
      return TaskModel.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar tarea
  Future<void> updateTask(TaskModel task) async {
    await _firestore
        .collection('tasks')
        .doc(task.id)
        .update(task.toFirestore());
  }

  // Actualizar estado de tarea
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': TaskModel.statusToString(newStatus),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Actualizar estado de tarea con nombre personalizado
  Future<void> updateTaskStatusWithCustomName(
      String taskId, String customStatusName) async {
    await _firestore.collection('tasks').doc(taskId).update({
      'status': customStatusName,
      'customStatusName':
          customStatusName, // Guardar también el nombre personalizado
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Eliminar tarea
  Future<void> deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  // Mover tarea a siguiente estado
  Future<void> moveTaskToNextStatus(String taskId) async {
    final task = await getTask(taskId);
    if (task != null) {
      final updatedTask = task.moveToNextStatus();
      await updateTask(updatedTask);
    }
  }

  // Mover tarea a estado anterior
  Future<void> moveTaskToPreviousStatus(String taskId) async {
    final task = await getTask(taskId);
    if (task != null) {
      final updatedTask = task.moveToPreviousStatus();
      await updateTask(updatedTask);
    }
  }

  // Asignar tarea a usuario
  Future<void> assignTask(String taskId, String userId) async {
    final task = await getTask(taskId);
    if (task != null) {
      final updatedTask = task.assignTo(userId);
      await updateTask(updatedTask);
    }
  }

  // Desasignar tarea
  Future<void> unassignTask(String taskId) async {
    final task = await getTask(taskId);
    if (task != null) {
      final updatedTask = task.unassign();
      await updateTask(updatedTask);
    }
  }

  // ===== CONSULTAS AVANZADAS =====

  // Obtener estadísticas del tablero
  Future<Map<String, int>> getBoardStats(String boardId) async {
    final epicsSnapshot = await _firestore
        .collection('epics')
        .where('boardId', isEqualTo: boardId)
        .get();

    final epicIds = epicsSnapshot.docs.map((doc) => doc.id).toList();

    if (epicIds.isEmpty) {
      return {
        'totalEpics': 0,
        'totalTasks': 0,
        'todoTasks': 0,
        'inProgressTasks': 0,
        'doneTasks': 0,
      };
    }

    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('epicId', whereIn: epicIds)
        .get();

    final tasks =
        tasksSnapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

    return {
      'totalEpics': epicIds.length,
      'totalTasks': tasks.length,
      'todoTasks': tasks.where((t) => t.status == TaskStatus.todo).length,
      'inProgressTasks':
          tasks.where((t) => t.status == TaskStatus.inProgress).length,
      'doneTasks': tasks.where((t) => t.status == TaskStatus.done).length,
    };
  }

  // Obtener tareas vencidas
  Stream<List<TaskModel>> getOverdueTasks(String userId) {
    final now = DateTime.now();
    return _firestore
        .collection('tasks')
        .where('assignedTo', isEqualTo: userId)
        .where('status', whereIn: ['todo', 'in_progress'])
        .snapshots()
        .map((snapshot) {
          final tasks =
              snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
          // Filtrar tareas vencidas localmente
          final overdueTasks = tasks
              .where(
                  (task) => task.dueDate != null && task.dueDate!.isBefore(now))
              .toList();
          // Ordenar por fecha de vencimiento
          overdueTasks.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
          return overdueTasks;
        });
  }

  // Buscar tareas por texto
  Future<List<TaskModel>> searchTasks(String boardId, String searchText) async {
    final epicsSnapshot = await _firestore
        .collection('epics')
        .where('boardId', isEqualTo: boardId)
        .get();

    final epicIds = epicsSnapshot.docs.map((doc) => doc.id).toList();

    if (epicIds.isEmpty) return [];

    final tasksSnapshot = await _firestore
        .collection('tasks')
        .where('epicId', whereIn: epicIds)
        .get();

    final tasks =
        tasksSnapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();

    return tasks
        .where((task) =>
            task.title.toLowerCase().contains(searchText.toLowerCase()) ||
            task.description.toLowerCase().contains(searchText.toLowerCase()))
        .toList();
  }

  // ===== OPERACIONES DE ESTADOS PERSONALIZADOS =====

  // Guardar estados personalizados del tablero
  Future<void> saveBoardStatuses(
      String boardId, List<Map<String, dynamic>> statuses) async {
    try {
      await _firestore.collection('boards').doc(boardId).update({
        'customStatuses': statuses,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al guardar los estados personalizados: $e');
    }
  }

  // Obtener estados personalizados del tablero
  Future<List<Map<String, dynamic>>> getBoardStatuses(String boardId) async {
    try {
      final doc = await _firestore.collection('boards').doc(boardId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('customStatuses')) {
          final List<dynamic> statusesList = data['customStatuses'] ?? [];
          return statusesList
              .map((status) => Map<String, dynamic>.from(status))
              .toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Error al obtener los estados personalizados: $e');
    }
  }

  // Stream para escuchar cambios en los estados personalizados
  Stream<List<Map<String, dynamic>>> watchBoardStatuses(String boardId) {
    return _firestore.collection('boards').doc(boardId).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data.containsKey('customStatuses')) {
          final List<dynamic> statusesList = data['customStatuses'] ?? [];
          return statusesList
              .map((status) => Map<String, dynamic>.from(status))
              .toList();
        }
      }
      return [];
    });
  }

  // ===== OPERACIONES DE SPRINTS =====

  // Crear nuevo sprint
  Future<String> createSprint(SprintModel sprint) async {
    final docRef =
        await _firestore.collection('sprints').add(sprint.toFirestore());
    return docRef.id;
  }

  // Obtener sprints de un tablero
  Stream<List<SprintModel>> getBoardSprints(String boardId) {
    return _firestore
        .collection('sprints')
        .where('boardId', isEqualTo: boardId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SprintModel.fromFirestore(doc))
            .toList());
  }

  // Obtener sprint activo de un tablero
  Future<SprintModel?> getActiveSprint(String boardId) async {
    final snapshot = await _firestore
        .collection('sprints')
        .where('boardId', isEqualTo: boardId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return SprintModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // Obtener un sprint específico
  Future<SprintModel?> getSprint(String sprintId) async {
    final doc = await _firestore.collection('sprints').doc(sprintId).get();
    if (doc.exists) {
      return SprintModel.fromFirestore(doc);
    }
    return null;
  }

  // Actualizar sprint
  Future<void> updateSprint(SprintModel sprint) async {
    await _firestore
        .collection('sprints')
        .doc(sprint.id)
        .update(sprint.toFirestore());
  }

  // Eliminar sprint
  Future<void> deleteSprint(String sprintId) async {
    await _firestore.collection('sprints').doc(sprintId).delete();
  }

  // Completar sprint (marcar como inactivo)
  Future<void> completeSprint(String sprintId) async {
    await _firestore.collection('sprints').doc(sprintId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Obtener tareas de un sprint
  Stream<List<TaskModel>> getSprintTasks(String sprintId, String userId) {
    return _firestore
        .collection('tasks')
        .where('sprintId', isEqualTo: sprintId)
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Obtener tareas de un tablero (incluyendo las del sprint activo)
  Stream<List<TaskModel>> getBoardTasks(String boardId, String userId) async* {
    try {
      debugPrint(
          '🔍 getBoardTasks - Iniciando para boardId: $boardId, userId: $userId');

      // Obtener todas las tareas del usuario para este tablero
      final allTasksSnapshot = await _firestore
          .collection('tasks')
          .where('ownerId', isEqualTo: userId)
          .get();

      final allTasks = allTasksSnapshot.docs
          .map((doc) => TaskModel.fromFirestore(doc))
          .toList();
      debugPrint(
          '🔍 getBoardTasks - Total tareas del usuario: ${allTasks.length}');

      // Mostrar todas las tareas para debugging
      for (final task in allTasks) {
        debugPrint(
            '   - Tarea: ${task.title}, EpicId: ${task.epicId}, SprintId: ${task.sprintId}');
      }

      // Obtener todas las épicas del tablero
      final epicsSnapshot = await _firestore
          .collection('epics')
          .where('boardId', isEqualTo: boardId)
          .where('ownerId', isEqualTo: userId)
          .get();

      final epicIds = epicsSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('🔍 getBoardTasks - Épicas encontradas: ${epicIds.length}');
      debugPrint('🔍 getBoardTasks - IDs de épicas: $epicIds');

      // Obtener todos los sprints del tablero
      final sprintsSnapshot = await _firestore
          .collection('sprints')
          .where('boardId', isEqualTo: boardId)
          .get();

      final sprintIds = sprintsSnapshot.docs.map((doc) => doc.id).toList();
      debugPrint('🔍 getBoardTasks - Sprints encontrados: ${sprintIds.length}');
      debugPrint('🔍 getBoardTasks - IDs de sprints: $sprintIds');

      // Filtrar tareas que pertenecen a este tablero
      final boardTasks = allTasks.where((task) {
        debugPrint('🔍 Analizando tarea: ${task.title}');
        debugPrint('   - epicId: ${task.epicId}');
        debugPrint('   - sprintId: ${task.sprintId}');

        // Tarea pertenece a una épica del tablero
        if (epicIds.contains(task.epicId)) {
          debugPrint('   ✅ Tarea pertenece a épica del tablero');
          return true;
        }

        // Tarea pertenece a un sprint del tablero
        if (task.sprintId != null && sprintIds.contains(task.sprintId)) {
          debugPrint('   ✅ Tarea pertenece a sprint del tablero');
          return true;
        }

        debugPrint('   ❌ Tarea NO pertenece al tablero');
        return false;
      }).toList();

      debugPrint('🔍 getBoardTasks - Tareas filtradas: ${boardTasks.length}');
      yield boardTasks;
    } catch (e) {
      debugPrint('❌ Error in getBoardTasks: $e');
      yield [];
    }
  }

  // Obtener todas las tareas (temporal para debugging)
  Stream<List<TaskModel>> getAllTasks() {
    return _firestore.collection('tasks').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Obtener todas las tareas una vez (temporal para debugging)
  Future<List<TaskModel>> getAllTasksOnce() async {
    final snapshot = await _firestore.collection('tasks').get();
    return snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList();
  }

  // Método temporal para debuggear - obtener todas las tareas del usuario
  Stream<List<TaskModel>> getAllUserTasks(String userId) {
    return _firestore
        .collection('tasks')
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => TaskModel.fromFirestore(doc)).toList());
  }

  // Método temporal para debuggear - obtener todas las épicas del usuario
  Future<List<Map<String, dynamic>>> getAllUserEpics(String userId) async {
    final snapshot = await _firestore
        .collection('epics')
        .where('ownerId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'title': doc.data()['title'] ?? 'Sin título',
              'boardId': doc.data()['boardId'] ?? 'Sin boardId',
              ...doc.data(),
            })
        .toList();
  }

  // Método temporal para arreglar tareas con estados incorrectos
  Future<void> fixTaskStatuses(String userId) async {
    try {
      debugPrint('🔧 Arreglando estados de tareas para usuario: $userId');

      final tasksSnapshot = await _firestore
          .collection('tasks')
          .where('ownerId', isEqualTo: userId)
          .get();

      int fixedCount = 0;
      for (final doc in tasksSnapshot.docs) {
        final data = doc.data();
        final customStatusName = data['customStatusName'] as String?;

        if (customStatusName == 'todo') {
          debugPrint(
              '🔧 Arreglando tarea: ${data['title']} - Estado: $customStatusName -> To Do');
          await _firestore.collection('tasks').doc(doc.id).update({
            'customStatusName': 'To Do',
            'updatedAt': FieldValue.serverTimestamp(),
          });
          fixedCount++;
        }
      }

      debugPrint('✅ Se arreglaron $fixedCount tareas');
    } catch (e) {
      debugPrint('❌ Error arreglando tareas: $e');
    }
  }
}
