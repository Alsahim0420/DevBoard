import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/register_page.dart';
import 'features/auth/presentation/pages/home_page.dart';
import 'features/boards/presentation/pages/boards_test_page.dart';
import 'features/boards/presentation/pages/firebase_test_page.dart';
import 'features/boards/presentation/pages/boards_page.dart';
import 'features/boards/presentation/pages/backlog_page.dart';
import 'features/boards/presentation/pages/recent_page.dart';
import 'features/boards/presentation/pages/favorites_page.dart';
import 'features/boards/presentation/pages/projects_page.dart';
import 'features/boards/presentation/pages/panels_page.dart';
import 'features/boards/presentation/pages/goals_page.dart';
import 'features/boards/presentation/pages/users_teams_page.dart';
import 'core/presentation/widgets/auth_gate.dart';
import 'core/presentation/widgets/auth_listener.dart';
import 'core/presentation/layouts/main_layout.dart';
import 'core/presentation/bloc/theme_bloc.dart';
import 'core/presentation/bloc/modal_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializar inyección de dependencias
  await di.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => di.sl<AuthBloc>(),
        ),
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc()..add(LoadTheme()),
        ),
        BlocProvider<ModalBloc>(
          create: (context) => ModalBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'DevBoard',
            debugShowCheckedModeBanner: false,
            theme: ThemeData.light(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6750A4),
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6750A4),
                brightness: Brightness.dark,
              ),
            ),
            themeMode: themeState.themeMode,
            home: const AuthListener(
              child: AuthGate(),
            ),
            routes: {
              '/login': (context) => const AuthListener(child: LoginScreen()),
              '/register': (context) =>
                  const AuthListener(child: RegisterPage()),
              // Rutas internas ahora se manejan en el Shell
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/shell' ||
                  settings.name == '/home' ||
                  settings.name == '/boards' ||
                  settings.name == '/backlog' ||
                  settings.name == '/recent' ||
                  settings.name == '/favorites' ||
                  settings.name == '/projects' ||
                  settings.name == '/panels' ||
                  settings.name == '/goals' ||
                  settings.name == '/boards-test' ||
                  settings.name == '/firebase-test') {
                return MaterialPageRoute(
                  builder: (context) => const Shell(),
                  settings: settings,
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

/// Widget Shell con sidebar persistente y Navigator anidado
class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  String _currentRoute = '/home';

  void _onSidebarTap(String route) {
    if (_currentRoute != route) {
      setState(() => _currentRoute = route);
      _navigatorKey.currentState?.pushReplacementNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: context.read<ThemeBloc>(),
      child: MainLayout(
        currentRoute: _currentRoute,
        onSidebarTap: _onSidebarTap,
        child: Navigator(
          key: _navigatorKey,
          initialRoute: _currentRoute,
          onGenerateRoute: (settings) {
            Widget page;
            switch (settings.name) {
              case '/boards':
                page = const BoardsPage();
                break;
              case '/backlog':
                page = const BacklogPage();
                break;
              case '/recent':
                page = const RecentPage();
                break;
              case '/favorites':
                page = const FavoritesPage();
                break;
              case '/projects':
                page = const ProjectsPage();
                break;
              case '/panels':
                page = const PanelsPage();
                break;
              case '/goals':
                page = const GoalsPage();
                break;
              case '/users-teams':
                page = const UsersTeamsPage();
                break;
              case '/boards-test':
                page = const BoardsTestPage();
                break;
              case '/firebase-test':
                page = const FirebaseTestPage();
                break;
              case '/home':
              default:
                page = const HomePage();
            }
            return MaterialPageRoute(
              builder: (context) => page,
              settings: settings,
            );
          },
        ),
      ),
    );
  }
}
