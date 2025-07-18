import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../../../features/auth/presentation/pages/login_screen.dart';
import '../../../features/auth/presentation/pages/home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Stream<User?> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // Mostrar loading mientras se verifica el estado de autenticación
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Timeout de 5 segundos para evitar carga infinita
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 5)),
            builder: (context, timeoutSnapshot) {
              if (timeoutSnapshot.connectionState == ConnectionState.done) {
                // Si pasan 5 segundos, mostrar login
                return const LoginScreen();
              }
              return _buildLoadingScreen();
            },
          );
        }

        // Si hay un usuario autenticado, ir a HomeScreen
        if (snapshot.hasData && snapshot.data != null) {
          // Notificar al BLoC sobre el usuario autenticado
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<AuthBloc>().add(AuthCheckRequested());
          });
          return const HomePage();
        }

        // Si no hay usuario autenticado, ir a LoginScreen
        return const LoginScreen();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Verificando autenticación...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
