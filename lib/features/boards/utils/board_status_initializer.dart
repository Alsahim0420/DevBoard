import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BoardStatusInitializer {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Inicializar estados por defecto en todos los tableros
  static Future<void> initializeAllBoards() async {
    try {
      final boardsSnapshot = await _firestore.collection('boards').get();

      for (final boardDoc in boardsSnapshot.docs) {
        final boardData = boardDoc.data();

        // Verificar si ya tiene estados personalizados
        if (!boardData.containsKey('customStatuses') ||
            (boardData['customStatuses'] as List).isEmpty) {
          await _initializeBoardStatuses(boardDoc.id);
          debugPrint('Estados inicializados para tablero: ${boardDoc.id}');
        }
      }

      debugPrint(
          'Inicialización de estados completada para ${boardsSnapshot.docs.length} tableros');
    } catch (e) {
      debugPrint('Error inicializando estados: $e');
    }
  }

  // Inicializar estados para un tablero específico
  static Future<void> initializeBoardStatuses(String boardId) async {
    try {
      await _initializeBoardStatuses(boardId);
      debugPrint('Estados inicializados para tablero: $boardId');
    } catch (e) {
      debugPrint('Error inicializando estados para tablero $boardId: $e');
    }
  }

  static Future<void> _initializeBoardStatuses(String boardId) async {
    final defaultStatuses = [
      {
        'id': 'status_0',
        'name': 'To Do',
        'status': 'todo',
        'color': 0xFFE53E3E, // Colors.red
        'order': 0,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'status_1',
        'name': 'In Progress',
        'status': 'in_progress',
        'color': 0xFFDD6B20, // Colors.orange
        'order': 1,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      {
        'id': 'status_2',
        'name': 'Done',
        'status': 'done',
        'color': 0xFF38A169, // Colors.green
        'order': 2,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
    ];

    await _firestore.collection('boards').doc(boardId).update({
      'customStatuses': defaultStatuses,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Agregar estado personalizado adicional
  static Future<void> addCustomStatus(
      String boardId, String name, String status, int color) async {
    try {
      final boardDoc = await _firestore.collection('boards').doc(boardId).get();
      if (boardDoc.exists) {
        final boardData = boardDoc.data();
        final List<dynamic> currentStatuses =
            boardData?['customStatuses'] ?? [];

        final newStatus = {
          'id': 'status_${currentStatuses.length}',
          'name': name,
          'status': status,
          'color': color,
          'order': currentStatuses.length,
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };

        currentStatuses.add(newStatus);

        await _firestore.collection('boards').doc(boardId).update({
          'customStatuses': currentStatuses,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Estado personalizado agregado: $name');
      }
    } catch (e) {
      debugPrint('Error agregando estado personalizado: $e');
    }
  }
}
