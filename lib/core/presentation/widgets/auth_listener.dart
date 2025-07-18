import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';

class AuthListener extends StatelessWidget {
  final Widget child;

  const AuthListener({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Si el usuario se autentica, navegar a HomeScreen
          Navigator.pushReplacementNamed(context, '/home');
        } else if (state is Unauthenticated) {
          // Si el usuario se desautentica, navegar a LoginScreen
          Navigator.pushReplacementNamed(context, '/login');
        }
      },
      child: child,
    );
  }
}
