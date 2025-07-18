import 'package:cloud_firestore/cloud_firestore.dart';

class EpicModel {
  final String id;
  final String title;
  final String description;
  final String boardId;
  final String ownerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EpicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.boardId,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory EpicModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EpicModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      boardId: data['boardId'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'boardId': boardId,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear nueva épica
  factory EpicModel.create({
    required String title,
    required String description,
    required String boardId,
    required String ownerId,
  }) {
    final now = DateTime.now();
    return EpicModel(
      id: '',
      title: title,
      description: description,
      boardId: boardId,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  EpicModel copyWith({
    String? id,
    String? title,
    String? description,
    String? boardId,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EpicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      boardId: boardId ?? this.boardId,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EpicModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          boardId == other.boardId;

  @override
  int get hashCode => Object.hash(id, title, boardId);

  @override
  String toString() {
    return 'EpicModel{id: $id, title: $title, boardId: $boardId}';
  }
}
