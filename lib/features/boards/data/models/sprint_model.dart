import 'package:cloud_firestore/cloud_firestore.dart';

class SprintModel {
  final String id;
  final String boardId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String? goal;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SprintModel({
    required this.id,
    required this.boardId,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.goal,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory SprintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SprintModel(
      id: doc.id,
      boardId: data['boardId'] ?? '',
      name: data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      goal: data['goal'],
      isActive: data['isActive'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'boardId': boardId,
      'name': name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'goal': goal,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear nuevo sprint
  factory SprintModel.create({
    required String boardId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    String? goal,
  }) {
    final now = DateTime.now();
    return SprintModel(
      id: '',
      boardId: boardId,
      name: name,
      startDate: startDate,
      endDate: endDate,
      goal: goal,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  SprintModel copyWith({
    String? id,
    String? boardId,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    String? goal,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SprintModel(
      id: id ?? this.id,
      boardId: boardId ?? this.boardId,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      goal: goal ?? this.goal,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Obtener duración del sprint en días
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  // Verificar si el sprint está activo
  bool get isCurrentSprint {
    final now = DateTime.now();
    return now.isAfter(startDate) &&
        now.isBefore(endDate.add(const Duration(days: 1)));
  }

  // Obtener progreso del sprint (0.0 a 1.0)
  double get progress {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 1.0;

    final totalDuration = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    return elapsed / totalDuration;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SprintModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          boardId == other.boardId;

  @override
  int get hashCode => Object.hash(id, boardId);

  @override
  String toString() {
    return 'SprintModel{id: $id, name: $name, boardId: $boardId}';
  }
}
