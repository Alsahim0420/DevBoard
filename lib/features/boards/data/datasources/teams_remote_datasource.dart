import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/team_model.dart';

class TeamsRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Crear un nuevo team
  Future<String> createTeam(TeamModel team) async {
    try {
      final docRef =
          await _firestore.collection('teams').add(team.toFirestore());

      // Actualizar el ID del team
      await docRef.update({'id': docRef.id});

      return docRef.id;
    } catch (e) {
      throw Exception('Error al crear el team: $e');
    }
  }

  // Obtener todos los teams
  Stream<List<TeamModel>> getTeams() {
    return _firestore
        .collection('teams')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList();
    });
  }

  // Obtener team por ID
  Future<TeamModel?> getTeamById(String teamId) async {
    try {
      final doc = await _firestore.collection('teams').doc(teamId).get();
      if (doc.exists) {
        return TeamModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error al obtener el team: $e');
    }
  }

  // Actualizar team
  Future<void> updateTeam(TeamModel team) async {
    try {
      await _firestore
          .collection('teams')
          .doc(team.id)
          .update(team.toFirestore());
    } catch (e) {
      throw Exception('Error al actualizar el team: $e');
    }
  }

  // Eliminar team
  Future<void> deleteTeam(String teamId) async {
    try {
      await _firestore.collection('teams').doc(teamId).delete();
    } catch (e) {
      throw Exception('Error al eliminar el team: $e');
    }
  }

  // Agregar miembro al team
  Future<void> addMemberToTeam(String teamId, String userId) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'memberUserIds': FieldValue.arrayUnion([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar miembro al team: $e');
    }
  }

  // Remover miembro del team
  Future<void> removeMemberFromTeam(String teamId, String userId) async {
    try {
      await _firestore.collection('teams').doc(teamId).update({
        'memberUserIds': FieldValue.arrayRemove([userId]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al remover miembro del team: $e');
    }
  }

  // Obtener teams de un usuario
  Stream<List<TeamModel>> getTeamsByUser(String userId) {
    return _firestore
        .collection('teams')
        .where('memberUserIds', arrayContains: userId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList();
    });
  }

  // Buscar teams por nombre
  Stream<List<TeamModel>> searchTeams(String query) {
    if (query.isEmpty) {
      return getTeams();
    }

    return _firestore
        .collection('teams')
        .orderBy('name')
        .startAt([query])
        .endAt(['$query\uf8ff'])
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TeamModel.fromFirestore(doc))
              .toList();
        });
  }

  // Obtener teams por propietario
  Stream<List<TeamModel>> getTeamsByOwner(String ownerId) {
    return _firestore
        .collection('teams')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TeamModel.fromFirestore(doc)).toList();
    });
  }
}
