import 'package:cloud_firestore/cloud_firestore.dart';

class TeamModel {
  final String id;
  final String name;
  final String? description;
  final List<String> memberUserIds; // IDs de usuarios miembros
  final String ownerId; // ID del usuario propietario del team
  final DateTime createdAt;
  final DateTime updatedAt;

  const TeamModel({
    required this.id,
    required this.name,
    this.description,
    this.memberUserIds = const [],
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory TeamModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();

    return TeamModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      memberUserIds: List<String>.from(data['memberUserIds'] ?? []),
      ownerId: data['ownerId'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : now,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    final now = DateTime.now();
    return {
      'name': name,
      'description': description,
      'memberUserIds': memberUserIds,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(
          createdAt.isAfter(DateTime(2020)) ? createdAt : now),
      'updatedAt': Timestamp.fromDate(
          updatedAt.isAfter(DateTime(2020)) ? updatedAt : now),
    };
  }

  // Crear nuevo team
  factory TeamModel.create({
    required String name,
    String? description,
    required String ownerId,
    List<String> memberUserIds = const [],
  }) {
    final now = DateTime.now();
    return TeamModel(
      id: '', // Se asignará al crear en Firestore
      name: name,
      description: description,
      memberUserIds: memberUserIds,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  TeamModel copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? memberUserIds,
    String? ownerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      memberUserIds: memberUserIds ?? this.memberUserIds,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Agregar miembro al team
  TeamModel addMember(String userId) {
    if (memberUserIds.contains(userId)) return this;
    return copyWith(
      memberUserIds: [...memberUserIds, userId],
      updatedAt: DateTime.now(),
    );
  }

  // Remover miembro del team
  TeamModel removeMember(String userId) {
    return copyWith(
      memberUserIds: memberUserIds.where((id) => id != userId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  // Verificar si un usuario es miembro
  bool isMember(String userId) => memberUserIds.contains(userId);

  // Obtener número de miembros
  int get memberCount => memberUserIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TeamModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TeamModel(id: $id, name: $name, memberCount: $memberCount)';
  }
}
