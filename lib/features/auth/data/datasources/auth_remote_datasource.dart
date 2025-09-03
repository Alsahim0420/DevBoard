import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../domain/entities/auth_credentials.dart';
import 'web_storage_helper.dart';

abstract class AuthRemoteDataSource {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;

  Future<UserModel> signIn(AuthCredentials credentials);
  Future<UserModel> signUp(AuthCredentials credentials);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      return UserModel.fromFirebaseUser(userCredential.user!);
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

      return UserModel.fromFirebaseUser(userCredential.user!);
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
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}
