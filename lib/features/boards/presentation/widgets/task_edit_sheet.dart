import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';
import '../../data/datasources/boards_remote_datasource.dart';

class TaskEditSheet extends StatefulWidget {
  final TaskModel task;
  final List<UserModel> users;
  final List<TeamModel> teams;
  final VoidCallback onTaskUpdated;

  const TaskEditSheet({
    super.key,
    required this.task,
    required this.users,
    required this.teams,
    required this.onTaskUpdated,
  });

  @override
  State<TaskEditSheet> createState() => _TaskEditSheetState();
}

class _TaskEditSheetState extends State<TaskEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimateHoursController = TextEditingController();
  final _spentHoursController = TextEditingController();
  final _tagsController = TextEditingController();

  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();

  TaskPriority _selectedPriority = TaskPriority.medium;
  String? _selectedUserId;
  String? _selectedTeamId;
  List<String> _tags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController.text = widget.task.title;
    _descriptionController.text = widget.task.description;
    _estimateHoursController.text = widget.task.estimateHours.toString();
    _spentHoursController.text = widget.task.spentHours?.toString() ?? '';
    _selectedPriority = widget.task.priority;
    _selectedUserId = widget.task.assignedTo;
    _selectedTeamId = widget.task.teamId;
    _tags = List.from(widget.task.tags);
    _tagsController.text = _tags.join(', ');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimateHoursController.dispose();
    _spentHoursController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Actualizar campos básicos
      final updatedTask = widget.task.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _selectedPriority,
        updatedAt: DateTime.now(),
      );
      await _dataSource.updateTask(updatedTask);

      // Actualizar horas estimadas
      final estimateHours =
          double.tryParse(_estimateHoursController.text) ?? 0.0;
      if (estimateHours != widget.task.estimateHours) {
        await _dataSource.updateTaskEstimateHours(
            widget.task.id, estimateHours);
      }

      // Actualizar horas gastadas
      final spentHours = double.tryParse(_spentHoursController.text);
      if (spentHours != widget.task.spentHours) {
        await _dataSource.updateTaskSpentHours(
            widget.task.id, spentHours ?? 0.0);
      }

      // Actualizar asignación de usuario
      if (_selectedUserId != widget.task.assignedTo) {
        await _dataSource.assignUserToTask(
            widget.task.id, _selectedUserId ?? '');
      }

      // Actualizar asignación de team
      if (_selectedTeamId != widget.task.teamId) {
        await _dataSource.assignTeamToTask(
            widget.task.id, _selectedTeamId ?? '');
      }

      // Actualizar etiquetas
      if (_tags.toString() != widget.task.tags.toString()) {
        await _dataSource.updateTaskTags(widget.task.id, _tags);
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onTaskUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tarea actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando tarea: $e'),
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

  void _parseTags() {
    final tagText = _tagsController.text.trim();
    if (tagText.isEmpty) {
      _tags = [];
    } else {
      _tags = tagText
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.9,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.edit,
                  color: Colors.blue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Editar Tarea',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ],
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El título es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Horas estimadas
                    TextFormField(
                      controller: _estimateHoursController,
                      decoration: InputDecoration(
                        labelText: 'Horas estimadas',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.access_time),
                        suffixText: 'h',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final hours = double.tryParse(value);
                          if (hours == null || hours < 0) {
                            return 'Ingresa un número válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Horas gastadas
                    TextFormField(
                      controller: _spentHoursController,
                      decoration: InputDecoration(
                        labelText: 'Horas gastadas (opcional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.timer),
                        suffixText: 'h',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final hours = double.tryParse(value);
                          if (hours == null || hours < 0) {
                            return 'Ingresa un número válido';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Prioridad
                    DropdownButtonFormField<TaskPriority>(
                      value: _selectedPriority,
                      decoration: InputDecoration(
                        labelText: 'Prioridad',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.flag),
                      ),
                      items: TaskPriority.values.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(_getPriorityName(priority)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedPriority = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Usuario asignado
                    DropdownButtonFormField<String>(
                      value: _selectedUserId,
                      decoration: InputDecoration(
                        labelText: 'Usuario asignado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin asignar'),
                        ),
                        ...widget.users.map((user) {
                          return DropdownMenuItem(
                            value: user.id,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    user.initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    user.displayName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedUserId = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Team asignado
                    DropdownButtonFormField<String>(
                      value: _selectedTeamId,
                      decoration: InputDecoration(
                        labelText: 'Team asignado',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.group),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Sin team'),
                        ),
                        ...widget.teams.map((team) {
                          return DropdownMenuItem(
                            value: team.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    team.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTeamId = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Etiquetas
                    TextFormField(
                      controller: _tagsController,
                      decoration: InputDecoration(
                        labelText: 'Etiquetas (separadas por comas)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.label),
                      ),
                      onChanged: (value) => _parseTags(),
                    ),
                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveTask,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
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
                            : const Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  String _getPriorityName(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.critical:
        return 'Crítica';
    }
  }
}
