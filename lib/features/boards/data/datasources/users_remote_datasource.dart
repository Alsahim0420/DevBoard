import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UsersRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo usuario
  Future<String> createUser(UserModel user) async {
    try {
      final docRef =
          await _firestore.collection('users').add(user.toFirestore());

      // Actualizar el ID del usuario
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear el usuario: $e');
    }
  }

  // Obtener todos los usuarios
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Obtener usuario por ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener el usuario: $e');
    }
  }

  // Actualizar usuario
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar el usuario: $e');
    }
  }

  // Eliminar usuario
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el usuario: $e');
    }
  }

  // Obtener usuarios por team
  Stream<List<UserModel>> getUsersByTeam(String teamId) {
    return _firestore
        .collection('users')
        .where('teamId', isEqualTo: teamId)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }

  // Buscar usuarios por nombre o email
  Stream<List<UserModel>> searchUsers(String query) {
    if (query.isEmpty) {
      return getUsers();
    }

    return _firestore
        .collection('users')
        .orderBy('displayName')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
        });
  }

  // Asignar usuario a team
  Future<void> assignUserToTeam(String userId, String teamId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'teamId': teamId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al asignar usuario al team: $e');
    }
  }

  // Remover usuario de team
  Future<void> removeUserFromTeam(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'teamId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al remover usuario del team: $e');
    }
  }
}
