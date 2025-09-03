import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_state.dart';

import '../../data/models/task_model.dart';
import '../../data/models/sprint_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';
import '../../data/datasources/boards_remote_datasource.dart';
import '../../data/datasources/users_remote_datasource.dart';
import '../../data/datasources/teams_remote_datasource.dart';
import '../widgets/drop_aware_list_tile.dart';
import '../widgets/sprint_creation_dialog.dart';
import '../widgets/task_edit_sheet.dart';
import '../widgets/sprint_hours_indicator.dart';

class BacklogDualPage extends StatefulWidget {
  final String boardId;

  const BacklogDualPage({
    super.key,
    required this.boardId,
  });

  @override
  State<BacklogDualPage> createState() => _BacklogDualPageState();
}

class _BacklogDualPageState extends State<BacklogDualPage> {
  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();
  final UsersRemoteDataSource _usersDataSource = UsersRemoteDataSource();
  final TeamsRemoteDataSource _teamsDataSource = TeamsRemoteDataSource();

  SprintModel? _activeSprint;
  List<TaskModel> _sprintTasks = [];
  List<TaskModel> _backlogTasks = [];
  List<UserModel> _users = [];
  List<TeamModel> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Cargar sprint activo
      _activeSprint = await _dataSource.getActiveSprint(widget.boardId);

      // Cargar datos en paralelo
      await Future.wait([
        _loadSprintTasks(),
        _loadBacklogTasks(),
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

  Future<void> _loadSprintTasks() async {
    if (_activeSprint != null) {
      final user = context.read<AuthBloc>().state;
      if (user is Authenticated) {
        _dataSource
            .getSprintTasks(_activeSprint!.id, user.user.id)
            .listen((tasks) {
          if (mounted) {
            setState(() => _sprintTasks = tasks);
          }
        });
      }
    }
  }

  Future<void> _loadBacklogTasks() async {
    _dataSource.getBacklogTasks(widget.boardId).listen((tasks) {
      if (mounted) {
        setState(() => _backlogTasks = tasks);
      }
    });
  }

  Future<void> _loadUsers() async {
    _usersDataSource.getUsers().listen((users) {
      if (mounted) {
        setState(() => _users = users);
      }
    });
  }

  Future<void> _loadTeams() async {
    _teamsDataSource.getTeams().listen((teams) {
      if (mounted) {
        setState(() => _teams = teams);
      }
    });
  }

  Future<void> _createSprint() async {
    final result = await showDialog<SprintModel>(
      context: context,
      builder: (context) => SprintCreationDialog(),
    );

    if (result != null) {
      try {
        await _dataSource.createSprint(result);

        // Recargar datos para mostrar el nuevo sprint
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creando sprint: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _moveTaskToSprint(TaskModel task) async {
    if (_activeSprint == null) return;

    try {
      await _dataSource.addTasksToSprint(_activeSprint!.id, [task.id]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moviendo tarea al sprint: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _moveTaskToBacklog(TaskModel task) async {
    try {
      await _dataSource.removeTaskFromSprint(task.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error moviendo tarea al backlog: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEditTaskModal(TaskModel task) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskEditSheet(
        task: task,
        users: _users,
        teams: _teams,
        onTaskUpdated: () {
          // Recargar datos después de actualizar
          _loadData();
        },
      ),
    );
  }

  double _calculateSprintHours() {
    return _sprintTasks.fold(0.0, (sum, task) => sum + task.estimateHours);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

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
        title: const Text('Backlog & Sprint'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_activeSprint != null)
            SprintHoursIndicator(
              totalHours: _calculateSprintHours(),
              isDark: isDark,
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: _activeSprint == null
          ? _buildNoSprintView(isDark)
          : _buildDualListView(isDark),
      floatingActionButton: _activeSprint == null
          ? FloatingActionButton.extended(
              onPressed: _createSprint,
              icon: const Icon(Icons.add),
              label: const Text('Crear Sprint'),
            )
          : null,
    );
  }

  Widget _buildNoSprintView(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.speed,
            size: 80,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(height: 24),
          Text(
            'No hay sprint activo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Crea un sprint para comenzar a organizar tus tareas',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _createSprint,
            icon: const Icon(Icons.add),
            label: const Text('Crear Sprint'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualListView(bool isDark) {
    return Row(
      children: [
        // Panel Sprint
        Expanded(
          child: _buildSprintPanel(isDark),
        ),
        // Divisor
        Container(
          width: 1,
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        // Panel Backlog
        Expanded(
          child: _buildBacklogPanel(isDark),
        ),
      ],
    );
  }

  Widget _buildSprintPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Sprint
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
                Icons.speed,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _activeSprint?.name ?? 'Sprint',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${_sprintTasks.length} tareas',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // Lista de tareas del Sprint
        Expanded(
          child: _sprintTasks.isEmpty
              ? _buildEmptyState(
                  'No hay tareas en el sprint',
                  'Arrastra tareas desde el backlog',
                  Icons.drag_indicator,
                  isDark,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _sprintTasks.length,
                  onReorder: (oldIndex, newIndex) {
                    // TODO: Implementar reordenamiento
                  },
                  itemBuilder: (context, index) {
                    final task = _sprintTasks[index];
                    return DropAwareListTile(
                      key: ValueKey(task.id),
                      task: task,
                      users: _users,
                      teams: _teams,
                      onTaskUpdated: _showEditTaskModal,
                      onMoveToBacklog: _moveTaskToBacklog,
                      isSprint: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBacklogPanel(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Backlog
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
                Icons.list_alt,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Backlog',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                '${_backlogTasks.length} tareas',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // Lista de tareas del Backlog
        Expanded(
          child: _backlogTasks.isEmpty
              ? _buildEmptyState(
                  'No hay tareas en el backlog',
                  'Crea nuevas tareas para comenzar',
                  Icons.add_task,
                  isDark,
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _backlogTasks.length,
                  onReorder: (oldIndex, newIndex) {
                    // TODO: Implementar reordenamiento
                  },
                  itemBuilder: (context, index) {
                    final task = _backlogTasks[index];
                    return DropAwareListTile(
                      key: ValueKey(task.id),
                      task: task,
                      users: _users,
                      teams: _teams,
                      onTaskUpdated: _showEditTaskModal,
                      onMoveToSprint: _moveTaskToSprint,
                      isSprint: false,
                    );
                  },
                ),
        ),
      ],
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
            size: 48,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
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
}
