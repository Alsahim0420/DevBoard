// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../data/models/epic_model.dart';
import '../../data/models/task_model.dart';
import '../../data/datasources/boards_remote_datasource.dart';
import '../widgets/status_editor_widget.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class BoardScreen extends StatefulWidget {
  final String boardId;
  final String boardName;

  const BoardScreen({
    super.key,
    required this.boardId,
    required this.boardName,
  });

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _epicTitleController = TextEditingController();
  final TextEditingController _taskDescriptionController =
      TextEditingController();
  final TextEditingController _taskTimeEstimateController =
      TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  List<EpicModel> _epics = [];
  List<TaskModel> _tasks = [];
  String? _selectedEpicId;
  bool _isLoading = false;
  bool _showCreateTask = false;
  bool _showCreateEpic = false;
  bool _showEditTask = false;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;
  TaskModel? _editingTask;
  String? _editingTaskStatus; // Estado actual de la tarea que se está editando
  TaskPriority _selectedPriority = TaskPriority.medium;

  // Stream subscriptions para gestionar el ciclo de vida
  StreamSubscription<List<EpicModel>>? _epicsSubscription;
  final List<StreamSubscription<List<TaskModel>>> _taskSubscriptions = [];

  // Estados personalizados del tablero
  List<BoardStatus> _boardStatuses = [
    BoardStatus('To Do', 'todo', Colors.red),
    BoardStatus('In Progress', 'in_progress', Colors.orange),
    BoardStatus('Done', 'done', Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _loadEpics();
    _loadBoardStatuses();
    _horizontalScrollController.addListener(_onScrollChanged);

    // Forzar reconstrucción de iconos después de un breve delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onScrollChanged() {
    if (mounted && _horizontalScrollController.hasClients) {
      try {
        setState(() {
          _canScrollLeft = _horizontalScrollController.offset > 0;
          _canScrollRight = _horizontalScrollController.offset <
              _horizontalScrollController.position.maxScrollExtent;
        });
      } catch (e) {
        debugPrint('Error in scroll listener: $e');
      }
    }
  }

  void _scrollLeft() {
    if (mounted && _horizontalScrollController.hasClients) {
      try {
        final newOffset = _horizontalScrollController.offset - 320;
        _horizontalScrollController.animateTo(
          newOffset.clamp(
              0.0, _horizontalScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('Error scrolling left: $e');
      }
    }
  }

  void _scrollRight() {
    if (mounted && _horizontalScrollController.hasClients) {
      try {
        final newOffset = _horizontalScrollController.offset + 320;
        _horizontalScrollController.animateTo(
          newOffset.clamp(
              0.0, _horizontalScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } catch (e) {
        debugPrint('Error scrolling right: $e');
      }
    }
  }

  void _loadEpics() {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;

      // Cancelar suscripción anterior si existe
      _epicsSubscription?.cancel();

      _epicsSubscription =
          _dataSource.getBoardEpics(widget.boardId, user.user.id).listen(
        (epics) {
          if (mounted) {
            setState(() {
              _epics = epics;
            });
            if (epics.isNotEmpty && _selectedEpicId == null) {
              _selectedEpicId = epics.first.id;
            }
            // Cargar todas las tareas del tablero
            _loadAllBoardTasks();
          }
        },
        onError: (error) {
          debugPrint('Error loading epics: $error');
          if (mounted && context.mounted) {
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error cargando épicas: ${error.toString().split(':').last.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (e) {
              debugPrint('Error showing snackbar: $e');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _loadEpics: $e');
    }
  }

  void _loadTasks(String epicId) {
    // Ahora cargamos todas las tareas del tablero
    _loadAllBoardTasks();
  }

  void _loadAllBoardTasks() {
    try {
      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;

      // Cancelar suscripciones anteriores
      for (final subscription in _taskSubscriptions) {
        subscription.cancel();
      }
      _taskSubscriptions.clear();

      // Limpiar tareas existentes
      if (mounted) {
        setState(() {
          _tasks.clear();
        });
      }

      // Usar el método unificado que incluye tareas de épicas y sprint activo
      final subscription =
          _dataSource.getBoardTasks(widget.boardId, user.user.id).listen(
        (tasks) {
          if (mounted) {
            setState(() {
              _tasks = tasks;
            });
            debugPrint(
                '✅ Cargadas ${tasks.length} tareas del tablero (incluyendo sprint)');
          }
        },
        onError: (error) {
          debugPrint('Error loading board tasks: $error');
        },
      );
      _taskSubscriptions.add(subscription);
    } catch (e) {
      debugPrint('Error in _loadAllBoardTasks: $e');
    }
  }

  Future<void> _createEpic() async {
    if (_epicTitleController.text.isEmpty) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;

      final epic = EpicModel.create(
        title: _epicTitleController.text,
        description: 'Descripción de la épica',
        boardId: widget.boardId,
        ownerId: user.user.id,
      );

      await _dataSource.createEpic(epic);
      _epicTitleController.clear();

      if (mounted) {
        setState(() {
          _showCreateEpic = false;
        });
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createTask() async {
    if (_selectedEpicId == null || _taskTitleController.text.trim().isEmpty) {
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
      setState(() {
        _isLoading = true;
      });

      final user = context.read<AuthBloc>().state;
      if (user is! Authenticated) return;

      final task = TaskModel.create(
        title: _taskTitleController.text.trim(),
        description: _taskDescriptionController.text.trim().isNotEmpty
            ? _taskDescriptionController.text.trim()
            : 'Descripción de la tarea',
        epicId: _selectedEpicId!,
        ownerId: user.user.id,
        priority: _selectedPriority,
        timeEstimate: _taskTimeEstimateController.text.trim().isNotEmpty
            ? _taskTimeEstimateController.text.trim()
            : null,
      );

      debugPrint('🔧 Creando tarea:');
      debugPrint('   - Título: ${task.title}');
      debugPrint('   - EpicId: ${task.epicId}');
      debugPrint('   - OwnerId: ${task.ownerId}');
      debugPrint('   - SprintId: ${task.sprintId}');

      // Crear la tarea primero
      final taskId = await _dataSource.createTask(task);

      // Luego asignar el estado por defecto (To Do)
      if (_boardStatuses.isNotEmpty) {
        final defaultStatus =
            _boardStatuses.first; // El primer estado es "To Do"
        await _dataSource.updateTaskStatusWithCustomName(
            taskId, defaultStatus.name);
        debugPrint(
            '✅ Tarea creada con estado por defecto: ${defaultStatus.name}');
      }

      _taskTitleController.clear();
      _taskDescriptionController.clear();
      _taskTimeEstimateController.clear();

      if (mounted) {
        setState(() {
          _showCreateTask = false;
        });

        // Recargar tareas después de crear una nueva
        _loadAllBoardTasks();

        // TEMPORAL: Arreglar tareas con estados incorrectos
        await _dataSource.fixTaskStatuses(user.user.id);

        // Recargar tareas después del arreglo
        _loadAllBoardTasks();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateTaskStatusWithCustomStatus(
      String taskId, BoardStatus boardStatus) async {
    try {
      debugPrint(
          'Actualizando tarea $taskId a estado personalizado: ${boardStatus.name}');
      debugPrint('Color del estado: ${boardStatus.color}');
      debugPrint('Status string: ${boardStatus.status}');

      // Para estados completamente personalizados, solo actualizar el customStatusName
      // Esto permite cualquier nombre de estado sin limitaciones del enum
      await _dataSource.updateTaskStatusWithCustomName(
          taskId, boardStatus.name);

      debugPrint('✅ Tarea actualizada exitosamente en Firebase');
      debugPrint('   - Custom status name: ${boardStatus.name}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('Tarea movida a ${boardStatus.name}'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error updating task status with custom name: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error actualizando tarea: ${e.toString().split(':').last.trim()}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _loadBoardStatuses() {
    try {
      _dataSource.watchBoardStatuses(widget.boardId).listen(
        (statusesData) {
          if (mounted) {
            if (statusesData.isNotEmpty) {
              setState(() {
                // Ordenar por el campo 'order' para mantener el orden personalizado
                final sortedData =
                    List<Map<String, dynamic>>.from(statusesData);
                sortedData.sort(
                    (a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));

                _boardStatuses = sortedData.map((data) {
                  return BoardStatus(
                    data['name'] ?? 'Estado',
                    data['status'] ?? 'todo', // Usar string directamente
                    Color(data['color'] ?? Colors.grey.value),
                  );
                }).toList();
              });
            } else {
              // Si no hay estados guardados, guardar los estados por defecto
              _saveDefaultStatuses();
            }
          }
        },
        onError: (error) {
          debugPrint('Error loading board statuses: $error');
          // En caso de error, usar estados por defecto
          if (mounted) {
            _saveDefaultStatuses();
          }
        },
      );
    } catch (e) {
      debugPrint('Error in _loadBoardStatuses: $e');
      _saveDefaultStatuses();
    }
  }

  void _saveDefaultStatuses() {
    final defaultStatuses = [
      BoardStatus('To Do', 'todo', Colors.red),
      BoardStatus('In Progress', 'in_progress', Colors.orange),
      BoardStatus('Done', 'done', Colors.green),
    ];
    _saveBoardStatuses(defaultStatuses);
  }

  Future<void> _saveBoardStatuses(List<BoardStatus> statuses) async {
    try {
      final statusesData = statuses.asMap().entries.map((entry) {
        final index = entry.key;
        final status = entry.value;
        return {
          'id': 'status_$index',
          'name': status.name,
          'status': status.status, // Usar string directamente
          'color': status.color.value,
          'order': index, // El orden se mantiene según la posición en la lista
          'createdAt': DateTime.now().millisecondsSinceEpoch,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        };
      }).toList();

      await _dataSource.saveBoardStatuses(widget.boardId, statusesData);

      if (mounted && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Estados guardados exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } catch (e) {
          debugPrint('Error showing success snackbar: $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving board statuses: $e');
      if (mounted && context.mounted) {
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Error guardando estados: ${e.toString().split(':').last.trim()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (snackbarError) {
          debugPrint('Error showing error snackbar: $snackbarError');
        }
      }
    }
  }

  void _showStatusEditorDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: StatusEditorWidget(
          currentStatuses: _boardStatuses,
          onStatusesChanged: (newStatuses) {
            setState(() {
              _boardStatuses = newStatuses;
            });
            _saveBoardStatuses(newStatuses);
          },
        ),
      ),
    );
  }

  void _showCreateEpicModal() {
    setState(() {
      _showCreateEpic = true;
      _showCreateTask = false;
    });
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
    setState(() {
      _showCreateTask = true;
      _showCreateEpic = false;
    });
  }

  void _hideCreateEpicModal() {
    setState(() {
      _showCreateEpic = false;
    });
    _epicTitleController.clear();
  }

  void _hideCreateTaskModal() {
    setState(() {
      _showCreateTask = false;
    });
    _taskTitleController.clear();
  }

  void _showEditTaskModal(TaskModel task) {
    setState(() {
      _editingTask = task;
      _selectedPriority = task.priority;
      _taskTitleController.text = task.title;
      _taskDescriptionController.text = task.description;
      _taskTimeEstimateController.text = task.timeEstimate ?? '';
      _editingTaskStatus = task.customStatusName ??
          task.statusText; // Usar el nombre personalizado o el texto del estado
      _showEditTask = true;
    });
  }

  void _hideEditTaskModal() {
    setState(() {
      _showEditTask = false;
      _editingTask = null;
      _editingTaskStatus = null;
      _taskTitleController.clear();
      _taskDescriptionController.clear();
      _taskTimeEstimateController.clear();
    });

    // Recargar las tareas para asegurar que estén en las columnas correctas
    if (_selectedEpicId != null) {
      _loadTasks(_selectedEpicId!);
    }
  }

  Future<void> _saveEditedTask() async {
    if (_editingTask == null || _taskTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('El título es obligatorio'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final updatedTask = _editingTask!.copyWith(
        title: _taskTitleController.text.trim(),
        description: _taskDescriptionController.text.trim().isEmpty
            ? null
            : _taskDescriptionController.text.trim(),
        priority: _selectedPriority,
        timeEstimate: _taskTimeEstimateController.text.trim().isEmpty
            ? null
            : _taskTimeEstimateController.text.trim(),
        customStatusName: _editingTaskStatus, // Guardar el estado personalizado
        updatedAt: DateTime.now(),
      );

      await _dataSource.updateTask(updatedTask);

      if (mounted) {
        _hideEditTaskModal();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Tarea actualizada exitosamente'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error actualizando tarea: $e'),
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

  List<TaskModel> _getTasksByStatusFromString(String statusString) {
    debugPrint('🔍 Buscando tareas para estado: "$statusString"');
    debugPrint('📊 Total de tareas disponibles: ${_tasks.length}');

    // Log especial para "En Qa"
    if (statusString.toLowerCase() == 'en qa') {
      debugPrint('🎯 Búsqueda específica para "En Qa"');
      debugPrint('📋 Estados disponibles en el tablero:');
      for (var status in _boardStatuses) {
        debugPrint('   - "${status.name}" (color: ${status.color})');
      }
    }

    // Buscar tareas que coincidan con el string del estado
    final filteredTasks = _tasks.where((task) {
      debugPrint(
          '📝 Tarea "${task.title}": customStatusName="${task.customStatusName}", status=${task.status}, buscando="$statusString"');

      // SOLO comparar con el nombre personalizado del estado (exacto)
      if (task.customStatusName != null &&
          task.customStatusName!.toLowerCase() == statusString.toLowerCase()) {
        debugPrint('✅ Coincidencia EXACTA para tarea "${task.title}"');
        return true;
      }

      // Si la tarea NO tiene customStatusName, solo asignar a "To Do"
      if ((task.customStatusName == null || task.customStatusName!.isEmpty) &&
          (statusString.toLowerCase() == 'to do' ||
              statusString.toLowerCase() == 'todo')) {
        debugPrint('✅ Tarea sin customStatusName asignada a "To Do"');
        return true;
      }

      debugPrint('❌ No hay coincidencia para tarea "${task.title}"');
      return false;
    }).toList();

    debugPrint(
        '📈 Tareas encontradas para estado "$statusString": ${filteredTasks.length}');
    return filteredTasks;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.isDarkMode;

        return Scaffold(
          backgroundColor: isDark
              ? const Color(0xFF121212) // Fondo oscuro para tema oscuro
              : const Color(0xFFF8FAFC), // Fondo claro para tema claro
          appBar: AppBar(
            title: Text(
              widget.boardName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1E1E1E) // AppBar oscuro
                : Theme.of(context).colorScheme.inversePrimary,
            elevation: 0,
            iconTheme: IconThemeData(
              color: isDark ? Colors.white : Colors.black87,
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  _showStatusEditorDialog();
                },
                tooltip: 'Configurar Estados y Orden',
              ),
              IconButton(
                icon: Icon(
                  Icons.star,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  _showCreateEpicModal();
                },
                tooltip: 'Crear Épica',
              ),
              IconButton(
                icon: Icon(
                  Icons.task,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  _showCreateTaskModal();
                },
                tooltip: 'Crear Tarea',
              ),
              // TEMPORAL: Botón para arreglar tareas
              IconButton(
                icon: Icon(
                  Icons.build,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () async {
                  final user = context.read<AuthBloc>().state;
                  if (user is Authenticated) {
                    await _dataSource.fixTaskStatuses(user.user.id);
                    _loadAllBoardTasks();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tareas arregladas'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'Arreglar Estados de Tareas',
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
                            'Cargando tablero...',
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _epics.isEmpty
                      ? _buildEmptyState()
                      : _buildKanbanBoard(),
              if (_showCreateEpic) _buildCreateEpicModal(),
              if (_showCreateTask) _buildCreateTaskModal(),
              if (_showEditTask) _buildEditTaskModal(),
            ],
          ),
        );
      },
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
                TextField(
                  controller: _epicTitleController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Título de la Épica',
                    hintText: 'Ej: Implementar Sistema de Autenticación',
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
                            ? Colors.orange.shade300
                            : Colors.orange.shade600,
                      ),
                    ),
                    filled: true,
                    fillColor:
                        isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.edit),
                  ),
                ),
                const SizedBox(height: 24),
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

  Widget _buildEditTaskModal() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Container(
      color: Colors.black.withOpacity(0.6),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header con diseño tipo Jira
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // ID de la tarea (simulado)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.blue.shade900
                            : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TASK-${_editingTask?.id.substring(0, 4).toUpperCase() ?? '0000'}',
                        style: TextStyle(
                          color: isDark
                              ? Colors.blue.shade300
                              : Colors.blue.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Título de la tarea
                    Expanded(
                      child: Text(
                        _editingTask?.title ?? 'Editar Tarea',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    // Botones de acción
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {},
                          tooltip: 'Compartir',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: () {},
                          tooltip: 'Más opciones',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                            size: 20,
                          ),
                          onPressed: _hideEditTaskModal,
                          tooltip: 'Cerrar',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Panel izquierdo - Descripción y actividad
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo de título
                            Text(
                              'Título',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _taskTitleController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Ingresa el título de la tarea',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade600,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Campo de descripción
                            Text(
                              'Descripción',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _taskDescriptionController,
                              maxLines: 6,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Describe los detalles de la tarea...',
                                hintStyle: TextStyle(
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey.shade600
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.blue.shade400
                                        : Colors.blue.shade600,
                                  ),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                contentPadding: const EdgeInsets.all(12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 24),

                      // Panel derecho - Detalles y metadatos
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sección de detalles
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.settings,
                                        size: 16,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Detalles',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.keyboard_arrow_down,
                                        size: 16,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Estado de la tarea
                                  _buildDetailRow(
                                    'Estado',
                                    _buildStatusDropdown(),
                                    isDark: isDark,
                                  ),

                                  const SizedBox(height: 16),

                                  // Prioridad
                                  _buildDetailRow(
                                    'Prioridad',
                                    _buildPriorityDropdown(isDark),
                                    isDark: isDark,
                                  ),

                                  const SizedBox(height: 16),

                                  // Tiempo estimado
                                  _buildDetailRow(
                                    'Tiempo Estimado',
                                    _buildTimeEstimateField(isDark),
                                    isDark: isDark,
                                  ),

                                  const SizedBox(height: 16),

                                  // Fecha de creación
                                  _buildDetailRow(
                                    'Creada',
                                    Text(
                                      _formatDate(_editingTask?.createdAt ??
                                          DateTime.now()),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer con botones de acción
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D2D2D) : Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(
                      color:
                          isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _hideEditTaskModal,
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveEditedTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? Colors.blue.shade600
                            : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Guardar Cambios'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Método auxiliar para construir filas de detalles
  Widget _buildDetailRow(String label, Widget child, {required bool isDark}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  // Dropdown para seleccionar estado
  Widget _buildStatusDropdown() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _editingTaskStatus,
          isExpanded: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          items: _boardStatuses.map((status) {
            return DropdownMenuItem<String>(
              value: status.name,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(status.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _editingTaskStatus = value;
              });
            }
          },
        ),
      ),
    );
  }

  // Dropdown para seleccionar prioridad
  Widget _buildPriorityDropdown(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade700 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority>(
          value: _selectedPriority,
          isExpanded: true,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          items: TaskPriority.values.map((priority) {
            return DropdownMenuItem<TaskPriority>(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    Icons.priority_high,
                    size: 16,
                    color: _getPriorityColor(priority),
                  ),
                  const SizedBox(width: 8),
                  Text(priority.toString().split('.').last),
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
    );
  }

  // Campo para tiempo estimado
  Widget _buildTimeEstimateField(bool isDark) {
    return TextField(
      controller: _taskTimeEstimateController,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Ej: 1d, 2h, 30m',
        hintStyle: TextStyle(
          color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
          fontSize: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: isDark ? Colors.blue.shade400 : Colors.blue.shade600,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade700 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),
    );
  }

  // Obtener color de prioridad
  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.critical:
        return Colors.purple;
    }
  }

  // Método para debuggear problemas con estados

  // Método para arreglar tareas con estados inconsistentes

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
                    value: _selectedEpicId,
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
                        _selectedEpicId = value;
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
                        controller: _taskTimeEstimateController,
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
                        onPressed: (_isLoading || _selectedEpicId == null)
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
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.dashboard,
                size: 64,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay épicas en este tablero',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Crea tu primera épica para comenzar a organizar las tareas',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showCreateEpic = true;
                  _showCreateTask = false;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Primera Épica'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _boardStatuses.asMap().entries.map((entry) {
                final columnIndex = entry.key;
                final boardStatus = entry.value;
                final tasks = _getTasksByStatusFromString(boardStatus.name);

                return Container(
                  width: 320, // Ancho fijo para cada columna
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: _buildKanbanColumn(boardStatus, tasks, columnIndex),
                );
              }).toList(),
            ),
          ),
        ),

        // Botones de navegación
        Positioned(
          left: 8,
          top: MediaQuery.of(context).size.height * 0.5 - 20,
          child: AnimatedOpacity(
            opacity: _canScrollLeft ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _buildIconWithFallback(
                  Icons.chevron_left,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _canScrollLeft ? _scrollLeft : null,
                tooltip: 'Desplazarse a la izquierda',
              ),
            ),
          ),
        ),

        Positioned(
          right: 8,
          top: MediaQuery.of(context).size.height * 0.5 - 20,
          child: AnimatedOpacity(
            opacity: _canScrollRight ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withOpacity(0.7)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: _buildIconWithFallback(
                  Icons.chevron_right,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: _canScrollRight ? _scrollRight : null,
                tooltip: 'Desplazarse a la derecha',
              ),
            ),
          ),
        ),

        // // Indicador de scroll
        // Positioned(
        //   bottom: 16,
        //   left: 0,
        //   right: 0,
        //   child: Center(
        //     child: Container(
        //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //       decoration: BoxDecoration(
        //         color: isDark
        //             ? Colors.black.withOpacity(0.7)
        //             : Colors.white.withOpacity(0.9),
        //         borderRadius: BorderRadius.circular(20),
        //         boxShadow: [
        //           BoxShadow(
        //             color: Colors.black.withOpacity(0.2),
        //             blurRadius: 8,
        //             offset: const Offset(0, 2),
        //           ),
        //         ],
        //       ),
        //       child: Row(
        //         mainAxisSize: MainAxisSize.min,
        //         children: [
        //           _buildIconWithFallback(
        //             Icons.swap_horiz,
        //             size: 16,
        //             color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
        //           ),
        //           const SizedBox(width: 8),
        //           Text(
        //             'Desliza horizontalmente para ver más columnas',
        //             style: TextStyle(
        //               fontSize: 12,
        //               color:
        //                   isDark ? Colors.grey.shade300 : Colors.grey.shade600,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }

  Widget _buildKanbanColumn(
      BoardStatus boardStatus, List<TaskModel> tasks, int columnIndex) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Container(
      height: MediaQuery.of(context).size.height - 200, // Altura fija
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildKanbanColumnHeader(boardStatus, tasks.length),
          Expanded(
            child: DragTarget<TaskModel>(
              onWillAcceptWithDetails: (details) => true,
              onAcceptWithDetails: (details) {
                // Actualizar el estado de la tarea cuando se arrastra a esta columna
                // Para estados personalizados, usar el nombre del estado en lugar del enum
                _updateTaskStatusWithCustomStatus(details.data.id, boardStatus);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...tasks.map((task) =>
                            _buildDraggableTaskCard(task, columnIndex)),
                        if (tasks.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Sin tareas',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumnHeader(BoardStatus boardStatus, int taskCount) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? boardStatus.color.withOpacity(0.2)
            : boardStatus.color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? boardStatus.color.withOpacity(0.3)
                : boardStatus.color.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: boardStatus.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            boardStatus.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : boardStatus.color,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? boardStatus.color.withOpacity(0.3)
                  : boardStatus.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$taskCount',
              style: TextStyle(
                color: isDark ? Colors.white : boardStatus.color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTaskCard(TaskModel task, int columnIndex) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade200),
          ),
          child: Text(
            task.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
              style: BorderStyle.solid),
        ),
        child: Text(
          'Arrastrando...',
          style: TextStyle(
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade500,
            fontSize: 14,
          ),
        ),
      ),
      child: _buildTaskCard(task, columnIndex),
    );
  }

  Widget _buildTaskCard(TaskModel task, int columnIndex) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditTaskModal(task),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3D3D3D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade200),
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
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color(task.priorityColor),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(task.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.customStatusName ?? task.statusText,
                        style: TextStyle(
                          color: _getStatusColor(task.status),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      task.priorityText,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                ...[
                  const SizedBox(height: 8),
                  Text(
                    'Creada: ${_formatDate(task.createdAt)}',
                    style: TextStyle(
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    // Buscar el estado personalizado correspondiente basado en el customStatusName
    // de las tareas actuales
    for (var task in _tasks) {
      if (task.customStatusName != null && task.customStatusName!.isNotEmpty) {
        final customStatus = _boardStatuses.firstWhere(
          (boardStatus) =>
              boardStatus.name.toLowerCase() ==
              task.customStatusName!.toLowerCase(),
          orElse: () => BoardStatus('', 'todo', Colors.grey),
        );

        if (customStatus.name.isNotEmpty) {
          return customStatus.color;
        }
      }
    }

    // Si no se encontró, usar colores por defecto
    switch (status) {
      case TaskStatus.todo:
        return Colors.red.shade600;
      case TaskStatus.inProgress:
        return Colors.orange.shade600;
      case TaskStatus.done:
        return Colors.green.shade600;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildIconWithFallback(IconData icon, {Color? color, double? size}) {
    return Icon(
      icon,
      color: color,
      size: size,
    );
  }

  @override
  void dispose() {
    // Cancelar todas las suscripciones de streams
    _epicsSubscription?.cancel();
    for (final subscription in _taskSubscriptions) {
      subscription.cancel();
    }
    _taskSubscriptions.clear();

    // Dispose de los controllers
    _taskTitleController.dispose();
    _epicTitleController.dispose();
    _taskDescriptionController.dispose();
    _taskTimeEstimateController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }
}
