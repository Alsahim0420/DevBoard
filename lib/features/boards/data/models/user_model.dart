import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

enum UserRole {
  lider,
  desarrollador,
  qa,
  scrumMaster,
  admin,
}

class UserModel {
  final String id;
  final String displayName;
  final String email;
  final String? avatarIcon; // Icono del avatar (ej: 'person', 'work', 'star')
  final String? avatarColor; // Color del avatar (ej: 'blue', 'green', 'purple')
  final String? teamId; // ID del team al que pertenece
  final UserRole role; // Rol del usuario
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.displayName,
    required this.email,
    this.avatarIcon,
    this.avatarColor,
    this.teamId,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();

    return UserModel(
      id: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      avatarIcon: data['avatarIcon'],
      avatarColor: data['avatarColor'],
      teamId: data['teamId'],
      role: _parseRole(data['role']),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : now,
    );
  }

  // Crear desde Firebase User
  factory UserModel.fromFirebaseUser(User firebaseUser) {
    final now = DateTime.now();

    return UserModel(
      id: firebaseUser.uid,
      displayName: firebaseUser.displayName ??
          firebaseUser.email?.split('@').first ??
          'Usuario',
      email: firebaseUser.email ?? '',
      avatarIcon: 'person', // Default icon
      avatarColor: 'blue', // Default color
      teamId: null,
      role: UserRole.desarrollador, // Default role
      createdAt: now,
      updatedAt: now,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    final now = DateTime.now();
    return {
      'displayName': displayName,
      'email': email,
      'avatarIcon': avatarIcon,
      'avatarColor': avatarColor,
      'teamId': teamId,
      'role': role.name,
      'createdAt': Timestamp.fromDate(
          createdAt.isAfter(DateTime(2020)) ? createdAt : now),
      'updatedAt': Timestamp.fromDate(
          updatedAt.isAfter(DateTime(2020)) ? updatedAt : now),
    };
  }

  // Crear nuevo usuario
  factory UserModel.create({
    required String displayName,
    required String email,
    String? avatarIcon,
    String? avatarColor,
    String? teamId,
    UserRole role = UserRole.desarrollador,
  }) {
    final now = DateTime.now();
    return UserModel(
      id: '', // Se asignará al crear en Firestore
      displayName: displayName,
      email: email,
      avatarIcon: avatarIcon,
      avatarColor: avatarColor,
      teamId: teamId,
      role: role,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  UserModel copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarIcon,
    String? avatarColor,
    String? teamId,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      avatarColor: avatarColor ?? this.avatarColor,
      teamId: teamId ?? this.teamId,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Obtener iniciales del nombre
  String get initials {
    final names = displayName.split(' ');
    if (names.isEmpty) return 'U';
    if (names.length == 1) return names[0][0].toUpperCase();
    return '${names[0][0]}${names[names.length - 1][0]}'.toUpperCase();
  }

  // Obtener icono del avatar (con fallback)
  String get avatarIconName => avatarIcon ?? 'person';

  // Obtener color del avatar (con fallback)
  String get avatarColorName => avatarColor ?? 'blue';

  // Obtener nombre del rol en español
  String get roleDisplayName {
    switch (role) {
      case UserRole.lider:
        return 'Líder';
      case UserRole.desarrollador:
        return 'Desarrollador';
      case UserRole.qa:
        return 'QA';
      case UserRole.scrumMaster:
        return 'Scrum Master';
      case UserRole.admin:
        return 'Admin';
    }
  }

  // Verificar si es admin
  bool get isAdmin => role == UserRole.admin;

  // Verificar si puede crear tableros
  bool get canCreateBoards =>
      role == UserRole.admin ||
      role == UserRole.lider ||
      role == UserRole.scrumMaster;

  // Verificar si puede gestionar equipos
  bool get canManageTeams => role == UserRole.admin || role == UserRole.lider;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserModel(id: $id, displayName: $displayName, email: $email, role: $role)';
  }
}

// Función auxiliar para parsear el rol desde string
UserRole _parseRole(String? roleString) {
  switch (roleString) {
    case 'lider':
      return UserRole.lider;
    case 'desarrollador':
      return UserRole.desarrollador;
    case 'qa':
      return UserRole.qa;
    case 'scrumMaster':
      return UserRole.scrumMaster;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.desarrollador; // Default role
  }
}
