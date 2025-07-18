// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/models/task_model.dart';
import '../../data/models/epic_model.dart';
import '../../data/models/sprint_model.dart';
import '../../data/models/board_model.dart';
import '../../data/datasources/boards_remote_datasource.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';

class BacklogPage extends StatefulWidget {
  final String? boardId;
  final String? boardName;

  const BacklogPage({
    super.key,
    this.boardId,
    this.boardName,
  });

  @override
  State<BacklogPage> createState() => _BacklogPageState();
}

class _BacklogPageState extends State<BacklogPage> {
  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _timeEstimateController = TextEditingController();
  final TextEditingController _epicTitleController = TextEditingController();
  final TextEditingController _epicDescriptionController =
      TextEditingController();
  final TextEditingController _sprintNameController = TextEditingController();
  final TextEditingController _sprintGoalController = TextEditingController();

  final List<TaskModel> _tasks = [];
  List<EpicModel> _epics = [];
  List<BoardModel> _boards = [];
  SprintModel? _currentSprint;
  bool _isLoading = false;
  bool _showCreateModal = false;
  bool _showEpicModal = false;
  bool _showSprintModal = false;
  TaskPriority _selectedPriority = TaskPriority.medium;
  String _selectedEpicId = '';
  final String _selectedStatus = 'todo';
  String _selectedBoardId = '';
  String _selectedBoardName = '';
  DateTime _sprintStartDate = DateTime.now();
  DateTime _sprintEndDate = DateTime.now().add(const Duration(days: 14));

  // Estados disponibles

  @override
  void initState() {
    super.initState();
    // Inicializar con el tablero proporcionado o vacío
    _selectedBoardId = widget.boardId ?? '';
    _selectedBoardName = widget.boardName ?? 'Seleccionar Tablero';

    if (_selectedBoardId.isNotEmpty) {
      _loadData();
    } else {
      _loadBoards();
    }
  }

  Future<void> _loadBoards() async {
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthBloc>().state;
      if (user is Authenticated) {
        _dataSource.getUserBoards(user.user.id).listen((boards) {
          if (mounted) {
            setState(() {
              _boards = boards;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading boards: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _selectBoard(String boardId, String boardName) {
    setState(() {
      _selectedBoardId = boardId;
      _selectedBoardName = boardName;
      _tasks.clear(); // Limpiar tareas al cambiar de tablero
    });
    _loadData();
  }

  Future<void> _loadData() async {
    if (_selectedBoardId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Primero actualizar las épicas existentes con el boardId correcto
      await _updateExistingEpics();

      // Luego actualizar las tareas existentes con el boardId correcto
      await _updateExistingTasks();

      // Luego cargar épicas del tablero
      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;
      final userId = user.user.id;

      _dataSource.getBoardEpics(_selectedBoardId, userId).listen((epics) {
        debugPrint(
            'Received ${epics.length} epics for board: $_selectedBoardId');
        if (mounted) {
          setState(() {
            _epics = epics;
            // Si no hay épica seleccionada y hay épicas disponibles, seleccionar la primera
            if (_selectedEpicId.isEmpty && epics.isNotEmpty) {
              _selectedEpicId = epics.first.id;
            }
          });
          // Cargar tareas después de que las épicas estén disponibles
          _loadTasks();
        }
      });

      // Cargar sprint
      _loadSprint();
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error cargando datos: $e'),
              ],
            ),
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

  // Método para actualizar épicas existentes con el boardId correcto
  Future<void> _updateExistingEpics() async {
    try {
      final allEpics = await _dataSource.getAllEpicsOnce();
      int updatedCount = 0;

      for (final epic in allEpics) {
        if (epic.boardId.isEmpty) {
          final updatedEpic = epic.copyWith(
            boardId: _selectedBoardId,
            updatedAt: DateTime.now(),
          );
          await _dataSource.updateEpic(updatedEpic);
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        debugPrint(
            'Se actualizaron $updatedCount épicas con boardId: $_selectedBoardId');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Se agregaron $updatedCount épicas al tablero'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating epics: $e');
    }
  }

  // Método para actualizar tareas existentes con el boardId correcto
  Future<void> _updateExistingTasks() async {
    try {
      final allTasks = await _dataSource.getAllTasksOnce();
      int updatedCount = 0;

      for (final task in allTasks) {
        // Buscar la épica de la tarea para obtener el boardId
        final epic = await _dataSource.getEpic(task.epicId);
        if (epic != null && epic.boardId == _selectedBoardId) {
          // La tarea ya pertenece a este tablero, no necesita actualización
          continue;
        }

        // Si la tarea no tiene sprintId y hay un sprint activo, asignarlo
        if (task.sprintId == null && _currentSprint != null) {
          final updatedTask = task.copyWith(
            sprintId: _currentSprint!.id,
            updatedAt: DateTime.now(),
          );
          await _dataSource.updateTask(updatedTask);
          updatedCount++;
        }
      }

      if (updatedCount > 0) {
        debugPrint(
            'Se actualizaron $updatedCount tareas con sprintId: ${_currentSprint?.id}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('Se agregaron $updatedCount tareas al sprint'),
                ],
              ),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating tasks: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      debugPrint('Loading tasks for board: $_selectedBoardId');

      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;
      final userId = user.user.id;

      // Usar el mismo método que el tablero para consistencia
      _dataSource.getBoardTasks(_selectedBoardId, userId).listen((tasks) {
        debugPrint(
            'Received ${tasks.length} tasks for board: $_selectedBoardId');
        if (mounted) {
          setState(() {
            _tasks.clear();
            _tasks.addAll(tasks);
          });
          debugPrint('Total tasks in backlog: ${_tasks.length}');
        }
      });
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<void> _loadSprint() async {
    try {
      final activeSprint = await _dataSource.getActiveSprint(_selectedBoardId);
      if (mounted) {
        setState(() {
          _currentSprint = activeSprint;
          if (activeSprint != null) {
            _sprintNameController.text = activeSprint.name;
            _sprintGoalController.text = activeSprint.goal ?? '';
            _sprintStartDate = activeSprint.startDate;
            _sprintEndDate = activeSprint.endDate;
          } else {
            // Crear un sprint por defecto si no existe
            _sprintNameController.text =
                'Sprint ${DateTime.now().month}-${DateTime.now().day}';
            _sprintGoalController.text = '';
            _sprintStartDate = DateTime.now();
            _sprintEndDate = DateTime.now().add(const Duration(days: 14));
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading sprint: $e');
    }
  }

  Future<void> _saveSprint() async {
    if (_sprintNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('El nombre del sprint es obligatorio'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      SprintModel sprint;
      if (_currentSprint != null) {
        // Actualizar sprint existente
        sprint = _currentSprint!.copyWith(
          name: _sprintNameController.text.trim(),
          goal: _sprintGoalController.text.trim().isEmpty
              ? null
              : _sprintGoalController.text.trim(),
          startDate: _sprintStartDate,
          endDate: _sprintEndDate,
          updatedAt: DateTime.now(),
        );
        await _dataSource.updateSprint(sprint);
      } else {
        // Crear nuevo sprint
        sprint = SprintModel.create(
          boardId: _selectedBoardId,
          name: _sprintNameController.text.trim(),
          startDate: _sprintStartDate,
          endDate: _sprintEndDate,
          goal: _sprintGoalController.text.trim().isEmpty
              ? null
              : _sprintGoalController.text.trim(),
        );
        final sprintId = await _dataSource.createSprint(sprint);
        sprint = sprint.copyWith(id: sprintId);
      }

      if (mounted) {
        setState(() {
          _currentSprint = sprint;
          _showSprintModal = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_currentSprint != null
                    ? 'Sprint actualizado exitosamente'
                    : 'Sprint creado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving sprint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error guardando sprint: $e'),
              ],
            ),
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

  Future<void> _completeSprint() async {
    if (_currentSprint == null) return;

    try {
      setState(() => _isLoading = true);
      await _dataSource.completeSprint(_currentSprint!.id);

      if (mounted) {
        setState(() {
          _currentSprint = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Sprint completado exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing sprint: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error completando sprint: $e'),
              ],
            ),
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

  void _showEditSprintModal() {
    setState(() => _showSprintModal = true);
  }

  void _hideEditSprintModal() {
    setState(() => _showSprintModal = false);
  }

  String _formatDate(DateTime date) {
    final months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  Future<void> _createTask() async {
    if (_taskTitleController.text.trim().isEmpty || _selectedEpicId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Título y épica son obligatorios'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;
      final userId = user.user.id;

      final task = TaskModel.create(
        title: _taskTitleController.text.trim(),
        description: _taskDescriptionController.text.trim(),
        epicId: _selectedEpicId,
        ownerId: userId,
        sprintId: _currentSprint?.id,
        priority: _selectedPriority,
        timeEstimate: _timeEstimateController.text.trim().isNotEmpty
            ? _timeEstimateController.text.trim()
            : null,
      );

      // Crear la tarea
      final taskId = await _dataSource.createTask(task);

      // Siempre asignar el estado correcto para consistencia con el tablero
      await _dataSource.updateTaskStatusWithCustomName(taskId, _selectedStatus);
      debugPrint('✅ Tarea creada con estado: $_selectedStatus');

      if (mounted) {
        _taskTitleController.clear();
        _taskDescriptionController.clear();
        _timeEstimateController.clear();
        setState(() => _showCreateModal = false);

        // Recargar tareas después de crear una nueva
        await _loadTasks();

        // TEMPORAL: Arreglar tareas con estados incorrectos
        await _dataSource.fixTaskStatuses(userId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Tarea creada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error creando tarea: $e'),
              ],
            ),
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

  Future<void> _deleteTask(String taskId) async {
    try {
      setState(() => _isLoading = true);

      await _dataSource.deleteTask(taskId);

      if (mounted) {
        // Recargar la lista de tareas después de eliminar
        await _loadTasks();

        // TEMPORAL: Arreglar tareas con estados incorrectos después de eliminar
        final user = context.read<AuthBloc>().state;
        if (user is Authenticated) {
          await _dataSource.fixTaskStatuses(user.user.id);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Tarea eliminada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error deleting task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error eliminando tarea: $e'),
              ],
            ),
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

  Future<void> _createEpic() async {
    if (_epicTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('El título de la épica es obligatorio'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;

      final epic = EpicModel.create(
        title: _epicTitleController.text.trim(),
        description: _epicDescriptionController.text.trim(),
        boardId: _selectedBoardId,
        ownerId: user.user.id,
      );

      await _dataSource.createEpic(epic);

      if (mounted) {
        _epicTitleController.clear();
        _epicDescriptionController.clear();
        setState(() => _showEpicModal = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Épica creada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error creating epic: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error creando épica: $e'),
              ],
            ),
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

  void _showCreateEpicModal() {
    setState(() => _showEpicModal = true);
  }

  void _hideCreateEpicModal() {
    setState(() => _showEpicModal = false);
    _epicTitleController.clear();
    _epicDescriptionController.clear();
  }

  void _showCreateTaskModal() {
    if (_epics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Primero debes crear una épica'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _showCreateModal = true);
  }

  void _hideCreateTaskModal() {
    setState(() => _showCreateModal = false);
    _taskTitleController.clear();
    _taskDescriptionController.clear();
    _timeEstimateController.clear();
  }

  String _generateTaskId() {
    // Generar ID único para la tarea (formato: MOV-XXXX)
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return 'MOV-$random';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'todo':
        return 'POR DESARROLLAR';
      case 'in_progress':
        return 'EN DESARROLLO';
      case 'in_review':
        return 'EN REVISIÓN';
      case 'testing':
        return 'EN TESTING';
      case 'done':
        return 'FINALIZADO';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'todo':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'in_review':
        return Colors.orange;
      case 'testing':
        return Colors.purple;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.isDarkMode;

        return Scaffold(
          backgroundColor:
              isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Backlog - $_selectedBoardName',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E)
                : Theme.of(context).colorScheme.inversePrimary,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : Colors.black87,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  if (_selectedBoardId.isNotEmpty) {
                    _loadData();
                  }
                },
                tooltip: 'Recargar',
              ),
              IconButton(
                icon: Icon(
                  Icons.star,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () => _showCreateEpicModal(),
                tooltip: 'Crear Épica',
              ),
              IconButton(
                icon: Icon(
                  Icons.add,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _showCreateTaskModal,
                tooltip: 'Crear Tarea',
              ),
            ],
          ),
          body: Stack(
            children: [
              _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDark
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Cargando backlog...',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildBacklogContent(),
              if (_showCreateModal) _buildCreateTaskModal(),
              if (_showEpicModal) _buildCreateEpicModal(),
              if (_showSprintModal) _buildEditSprintModal(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBacklogContent() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    // Si no hay tablero seleccionado, mostrar selector
    if (_selectedBoardId.isEmpty) {
      return _buildBoardSelector();
    }

    return Column(
      children: [
        // Header del sprint
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showEditSprintModal,
                  child: Row(
                    children: [
                      Text(
                        _currentSprint?.name ??
                            'Sprint ${DateTime.now().month}-${DateTime.now().day}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
              ),
              if (_currentSprint != null) ...[
                Text(
                  '${_formatDate(_currentSprint!.startDate)} - ${_formatDate(_currentSprint!.endDate)}',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '(${_tasks.length} actividades)',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
              const Spacer(),
              if (_currentSprint != null) ...[
                Text(
                  '${_currentSprint!.durationInDays}d',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(_currentSprint!.durationInDays / 7).ceil()}sem',
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              ElevatedButton(
                onPressed: _currentSprint != null ? _completeSprint : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Completar sprint'),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: _showEditSprintModal,
              ),
            ],
          ),
        ),

        // Tabla de tareas
        Expanded(
          child: _tasks.isEmpty ? _buildEmptyState() : _buildTasksTable(),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
              ),
            ),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _showCreateTaskModal,
                icon: const Icon(Icons.add),
                label: const Text('Crear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTable() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return SingleChildScrollView(
      child: DataTable(
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
        dataTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
        columns: const [
          DataColumn(label: Text('')),
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Título')),
          DataColumn(label: Text('Categoría')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Tiempo')),
          DataColumn(label: Text('Asignado')),
          DataColumn(label: Text('')),
        ],
        rows: _tasks.map((task) {
          final taskId = _generateTaskId();
          final statusText = _getStatusText(task.status.toString());
          final statusColor = _getStatusColor(task.status.toString());
          final epic = _epics.firstWhere(
            (epic) => epic.id == task.epicId,
            orElse: () => _epics.first,
          );

          return DataRow(
            cells: [
              const DataCell(
                Icon(
                  Icons.check_box_outline_blank,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              DataCell(Text(taskId)),
              DataCell(
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    task.title,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Text(
                    epic.title,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: statusColor,
                      size: 16,
                    ),
                  ],
                ),
              ),
              DataCell(Text(task.timeEstimate ?? '-')),
              DataCell(
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    'U',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
              DataCell(
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 16),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      // Mostrar diálogo de confirmación
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirmar eliminación'),
                          content: Text(
                              '¿Estás seguro de que quieres eliminar la tarea "${task.title}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed == true) {
                        await _deleteTask(task.id);
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Eliminar tarea'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBoardSelector() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard,
              size: 64,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Selecciona un Tablero',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Elige un tablero para ver su backlog',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            if (_boards.isEmpty)
              Text(
                'No tienes tableros creados',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              )
            else
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: _boards
                      .map((board) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              onPressed: () =>
                                  _selectBoard(board.id, board.name),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.white,
                                foregroundColor:
                                    isDark ? Colors.white : Colors.black87,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.dashboard, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      board.name,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, size: 16),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt,
            size: 64,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay tareas en el backlog',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea tu primera tarea para comenzar',
            style: TextStyle(
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateTaskModal,
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTaskModal() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.green.shade900
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.task,
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crear Nueva Tarea',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: _hideCreateTaskModal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (_epics.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedEpicId.isNotEmpty ? _selectedEpicId : null,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Épica',
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.green.shade300
                              : Colors.green.shade600,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      prefixIcon: const Icon(Icons.star),
                    ),
                    items: _epics.map((epic) {
                      return DropdownMenuItem<String>(
                        value: epic.id,
                        child: Text(
                          epic.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedEpicId = value ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _taskTitleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título de la Tarea',
                    hintText: 'Ej: Configurar Firebase Auth',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade600,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _taskDescriptionController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Descripción detallada de la tarea...',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    hintStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.green.shade300
                            : Colors.green.shade600,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TaskPriority>(
                        value: _selectedPriority,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Prioridad',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade600,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.priority_high),
                        ),
                        items: TaskPriority.values.map((priority) {
                          // Crear una tarea temporal para acceder a los getters
                          final tempTask = TaskModel.create(
                            title: '',
                            description: '',
                            epicId: '',
                            ownerId: '',
                            priority: priority,
                          );

                          return DropdownMenuItem<TaskPriority>(
                            value: priority,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(tempTask.priorityColor),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tempTask.priorityText,
                                  style: TextStyle(
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedPriority = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _timeEstimateController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Tiempo Estimado',
                          hintText: 'Ej: 2h, 1d, 3d',
                          labelStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                          ),
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.green.shade300
                                  : Colors.green.shade600,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          prefixIcon: const Icon(Icons.schedule),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _hideCreateTaskModal,
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_isLoading || _selectedEpicId.isEmpty)
                            ? null
                            : _createTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Crear Tarea'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateEpicModal() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.orange.shade900
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.star,
                        color: isDark
                            ? Colors.orange.shade300
                            : Colors.orange.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crear Nueva Épica',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: _hideCreateEpicModal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Título
                TextField(
                  controller: _epicTitleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título de la Épica',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Descripción
                TextField(
                  controller: _epicDescriptionController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _hideCreateEpicModal,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createEpic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.orange.shade700
                              : Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Crear Épica'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditSprintModal() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.purple.shade900
                            : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.schedule,
                        color: isDark
                            ? Colors.purple.shade300
                            : Colors.purple.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentSprint != null ? 'Editar Sprint' : 'Crear Sprint',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: _hideEditSprintModal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre del sprint
                TextField(
                  controller: _sprintNameController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nombre del Sprint',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Objetivo del sprint
                TextField(
                  controller: _sprintGoalController,
                  maxLines: 3,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Objetivo del Sprint (opcional)',
                    labelStyle: TextStyle(
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Fechas
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de inicio',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _sprintStartDate,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate: DateTime.now()
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _sprintStartDate = date;
                                  if (_sprintEndDate.isBefore(date)) {
                                    _sprintEndDate =
                                        date.add(const Duration(days: 14));
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_sprintStartDate.day}/${_sprintStartDate.month}/${_sprintStartDate.year}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fecha de fin',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _sprintEndDate,
                                firstDate: _sprintStartDate,
                                lastDate: _sprintStartDate
                                    .add(const Duration(days: 365)),
                              );
                              if (date != null) {
                                setState(() {
                                  _sprintEndDate = date;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey.shade300,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_sprintEndDate.day}/${_sprintEndDate.month}/${_sprintEndDate.year}',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _hideEditSprintModal,
                        style: TextButton.styleFrom(
                          foregroundColor: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveSprint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.purple.shade700
                              : Colors.purple.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(_currentSprint != null
                                ? 'Actualizar Sprint'
                                : 'Crear Sprint'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescriptionController.dispose();
    _timeEstimateController.dispose();
    _epicTitleController.dispose();
    _epicDescriptionController.dispose();
    _sprintNameController.dispose();
    _sprintGoalController.dispose();
    super.dispose();
  }
}
