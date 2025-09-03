import 'package:cloud_firestore/cloud_firestore.dart';

class BoardModel {
  final String id;
  final String name;
  final String ownerId;
  final String? teamId; // ID del equipo al que pertenece el tablero
  final List<String> members;
  final List<String>
      favoritedBy; // Lista de usuarios que marcaron como favorito
  final DateTime createdAt;
  final DateTime updatedAt;

  BoardModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.teamId,
    required this.members,
    this.favoritedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory BoardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BoardModel(
      id: doc.id,
      name: data['name'] ?? '',
      ownerId: data['ownerId'] ?? '',
      teamId: data['teamId'],
      members: List<String>.from(data['members'] ?? []),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ownerId': ownerId,
      'teamId': teamId,
      'members': members,
      'favoritedBy': favoritedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear nuevo tablero
  factory BoardModel.create({
    required String name,
    required String ownerId,
    String? teamId,
  }) {
    final now = DateTime.now();
    return BoardModel(
      id: '',
      name: name,
      ownerId: ownerId,
      teamId: teamId,
      members: [ownerId], // El propietario es automáticamente miembro
      favoritedBy: [],
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  BoardModel copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? teamId,
    List<String>? members,
    List<String>? favoritedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoardModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      teamId: teamId ?? this.teamId,
      members: members ?? this.members,
      favoritedBy: favoritedBy ?? this.favoritedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Verificar si un usuario es propietario
  bool isOwner(String userId) => ownerId == userId;

  // Verificar si un usuario es miembro
  bool isMember(String userId) => members.contains(userId);

  // Agregar miembro
  BoardModel addMember(String userId) {
    if (!members.contains(userId)) {
      return copyWith(
        members: [...members, userId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Remover miembro
  BoardModel removeMember(String userId) {
    if (userId != ownerId && members.contains(userId)) {
      return copyWith(
        members: members.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Verificar si un usuario marcó como favorito
  bool isFavoritedBy(String userId) => favoritedBy.contains(userId);

  // Marcar como favorito
  BoardModel markAsFavorite(String userId) {
    if (!favoritedBy.contains(userId)) {
      return copyWith(
        favoritedBy: [...favoritedBy, userId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Desmarcar como favorito
  BoardModel unmarkAsFavorite(String userId) {
    if (favoritedBy.contains(userId)) {
      return copyWith(
        favoritedBy: favoritedBy.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoardModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          ownerId == other.ownerId;

  @override
  int get hashCode => Object.hash(id, name, ownerId);

  @override
  String toString() {
    return 'BoardModel{id: $id, name: $name, ownerId: $ownerId, members: $members}';
  }
}
