import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/datasources/teams_remote_datasource.dart';
import '../widgets/user_creation_dialog.dart';
import '../widgets/team_creation_dialog.dart';
import '../widgets/team_edit_dialog.dart';
import '../widgets/avatar_widget.dart';

class UsersTeamsPage extends StatefulWidget {
  const UsersTeamsPage({super.key});

  @override
  State<UsersTeamsPage> createState() => _UsersTeamsPageState();
}

class _UsersTeamsPageState extends State<UsersTeamsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UsersRemoteDataSource _usersDataSource = UsersRemoteDataSource();
  final TeamsRemoteDataSource _teamsDataSource = TeamsRemoteDataSource();

  List<UserModel> _users = [];
  List<TeamModel> _teams = [];
  bool _isLoading = true;
  UserModel? _currentUser;

  // Stream subscriptions para poder cancelarlas
  StreamSubscription<List<UserModel>>? _usersSubscription;
  StreamSubscription<List<TeamModel>>? _teamsSubscription;
  StreamSubscription<User?>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupAuthListener();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usersSubscription?.cancel();
    _teamsSubscription?.cancel();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    _authStateSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user == null) {
        // Usuario cerró sesión, cancelar todas las suscripciones
        cancelSubscriptions();
      }
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar datos en paralelo
      await Future.wait([
        _loadUsers(),
        _loadTeams(),
      ]);
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUsers() async {
    _usersSubscription?.cancel(); // Cancelar suscripción anterior si existe
    _usersSubscription = _usersDataSource.getUsers().listen((users) {
      if (mounted) {
        setState(() {
          _users = users;
          // Buscar el usuario actual
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId != null) {
            _currentUser = users.firstWhere(
              (user) => user.id == currentUserId,
              orElse: () => UserModel(
                id: currentUserId,
                displayName: 'Usuario Actual',
                email: FirebaseAuth.instance.currentUser?.email ?? '',
                role: UserRole.desarrollador,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
          }
        });
      }
    });
  }

  Future<void> _loadTeams() async {
    _teamsSubscription?.cancel(); // Cancelar suscripción anterior si existe
    _teamsSubscription = _teamsDataSource.getTeams().listen((teams) {
      if (mounted) {
        setState(() => _teams = teams);
      }
    });
  }

  Future<void> _createUser() async {
    // Mostrar el diálogo de creación de usuario
    // El AuthBloc se encarga de crear el usuario y mostrar feedback
    await showDialog(
      context: context,
      builder: (context) => UserCreationDialog(),
    );

    // No necesitamos manejar el resultado aquí porque:
    // 1. El AuthBloc se encarga de crear el usuario en Firebase Auth
    // 2. El AuthBloc también crea el registro en Firestore
    // 3. El BlocListener en UserCreationDialog maneja el feedback
    // 4. La lista de usuarios se actualiza automáticamente via StreamSubscription
  }

  Future<void> _createTeam() async {
    // Usar solo los usuarios de Firestore, que ya incluyen al usuario actual
    // si está registrado correctamente
    final allUsers = _users;

    final result = await showDialog<TeamModel>(
      context: context,
      builder: (context) => TeamCreationDialog(users: allUsers),
    );

    if (result != null) {
      try {
        await _teamsDataSource.createTeam(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creando team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editTeam(TeamModel team) async {
    // Usar solo los usuarios de Firestore, que ya incluyen al usuario actual
    // si está registrado correctamente
    final allUsers = _users;

    final result = await showDialog<TeamModel>(
      context: context,
      builder: (context) => TeamEditDialog(
        team: team,
        allUsers: allUsers,
      ),
    );

    if (result != null) {
      try {
        await _teamsDataSource.updateTeam(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error actualizando team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteTeam(TeamModel team) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Estás seguro de que quieres eliminar el team "${team.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _teamsDataSource.deleteTeam(team.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error eliminando team: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Método público para cancelar suscripciones (útil para logout)
  void cancelSubscriptions() {
    _usersSubscription?.cancel();
    _teamsSubscription?.cancel();
  }

  // Verificar si el usuario actual puede gestionar equipos
  bool get canManageTeams => _currentUser?.canManageTeams ?? false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Usuarios y Teams'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Usuarios',
            ),
            Tab(
              icon: Icon(Icons.group),
              text: 'Teams',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(isDark),
          _buildTeamsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return Column(
      children: [
        // Header con botón agregar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usuarios (${_users.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_currentUser != null)
                      Text(
                        'Rol: ${_currentUser!.roleDisplayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (canManageTeams)
                ElevatedButton.icon(
                  onPressed: _createUser,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        // Lista de usuarios
        Expanded(
          child: _users.isEmpty
              ? _buildEmptyState(
                  'No hay usuarios',
                  'Agrega usuarios para comenzar',
                  Icons.person_add,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return _buildUserCard(user, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTeamsTab(bool isDark) {
    return Column(
      children: [
        // Header con botón agregar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.group,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teams (${_teams.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (_currentUser != null)
                      Text(
                        'Rol: ${_currentUser!.roleDisplayName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (canManageTeams)
                ElevatedButton.icon(
                  onPressed: _createTeam,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
        ),
        // Lista de teams
        Expanded(
          child: _teams.isEmpty
              ? _buildEmptyState(
                  'No hay teams',
                  'Agrega teams para organizar usuarios',
                  Icons.group_add,
                  isDark,
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return _buildTeamCard(team, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(UserModel user, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3D3D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            AvatarWidget(
              user: user,
              radius: 24,
            ),
            const SizedBox(width: 16),
            // Información del usuario
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  if (user.teamId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 14,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTeamName(user.teamId!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Acciones (solo si tiene permisos)
            if (canManageTeams)
              PopupMenuButton<String>(
                onSelected: (value) {
                  // TODO: Implementar acciones (editar, eliminar, etc.)
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3D3D3D) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono del team
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.group,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Información del team
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${team.memberCount} miembros',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Acciones (solo si tiene permisos)
                if (canManageTeams)
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editTeam(team);
                      } else if (value == 'delete') {
                        _deleteTeam(team);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            // Descripción si existe
            if (team.description != null && team.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                team.description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTeamName(String teamId) {
    final team = _teams.firstWhere(
      (t) => t.id == teamId,
      orElse: () => TeamModel(
        id: teamId,
        name: 'Team desconocido',
        ownerId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return team.name;
  }
}
