import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/auth_credentials.dart';
import 'web_storage_helper.dart';
import '../../../boards/data/models/user_model.dart' as board_user_model;

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> signIn(AuthCredentials credentials);
  Future<UserModel> signUp(AuthCredentials credentials);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((user) {
      return user != null ? UserModel.fromFirebaseUser(user) : null;
    });
  }

  @override
  UserModel? get currentUser {
    final user = _auth.currentUser;
    return user != null ? UserModel.fromFirebaseUser(user) : null;
  }

  @override
  Future<UserModel> signIn(AuthCredentials credentials) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (userCredential.user == null) {
        throw Exception('Error al iniciar sesión');
      }

      // Crear el modelo de usuario para auth
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);

      // Crear el modelo de usuario para boards
      final boardUserModel =
          board_user_model.UserModel.fromFirebaseUser(userCredential.user!);

      // Verificar si el usuario existe en Firestore, si no existe, crearlo
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        // El usuario no existe en Firestore, crearlo
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set(boardUserModel.toFirestore());
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> signUp(AuthCredentials credentials) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: credentials.email,
        password: credentials.password,
      );

      if (userCredential.user == null) {
        throw Exception('Error al crear cuenta');
      }

      // Crear el modelo de usuario para auth
      final userModel = UserModel.fromFirebaseUser(userCredential.user!);

      // Validar clave de admin si se intenta crear un admin
      if (credentials.role == board_user_model.UserRole.admin) {
        if (credentials.adminKey != '1401') {
          throw Exception('Clave de administrador incorrecta');
        }
      }

      // Crear el modelo de usuario para boards con información personalizada
      final boardUserModel = board_user_model.UserModel(
        id: userCredential.user!.uid,
        displayName: credentials.displayName ??
            userCredential.user!.displayName ??
            userCredential.user!.email?.split('@').first ??
            'Usuario',
        email: userCredential.user!.email ?? '',
        avatarIcon: credentials.avatarIcon ?? 'person',
        avatarColor: credentials.avatarColor ?? 'blue',
        teamId: null,
        role: credentials.role ?? board_user_model.UserRole.desarrollador,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Guardar el usuario en Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(boardUserModel.toFirestore());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // 1. Cerrar sesión en Firebase
      await _auth.signOut();

      // 2. Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('uid');
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.clear(); // Limpiar todas las preferencias

      // 3. Limpiar localStorage en web
      await WebStorageHelper.clearLocalStorage();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('Enviando email de reset a: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Email de reset enviado exitosamente');
    } on FirebaseAuthException catch (e) {
      print('Error al enviar email de reset: ${e.code} - ${e.message}');
      // Manejar errores específicos de reset de contraseña
      switch (e.code) {
        case 'user-not-found':
          throw 'No se encontró un usuario con este email.';
        case 'invalid-email':
          throw 'El email ingresado no es válido.';
        case 'too-many-requests':
          throw 'Demasiados intentos. Intenta más tarde.';
        case 'operation-not-allowed':
          throw 'Esta operación no está permitida. Verifica la configuración de Firebase.';
        default:
          throw 'Error al enviar email de reset: ${e.message}';
      }
    } catch (e) {
      print('Error inesperado al enviar email de reset: $e');
      rethrow;
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este email ya está registrado.';
      case 'weak-password':
        return 'La contraseña es demasiado débil.';
      case 'invalid-email':
        return 'El email no es válido.';
      case 'user-disabled':
        return 'Este usuario ha sido deshabilitado.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'operation-not-allowed':
        return 'Esta operación no está permitida.';
      case 'invalid-credential':
        return 'Las credenciales son inválidas.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error de autenticación: ${e.message} (Código: ${e.code})';
    }
  }
}
