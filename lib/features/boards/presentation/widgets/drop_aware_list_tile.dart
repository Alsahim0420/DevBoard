import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';

class DropAwareListTile extends StatefulWidget {
  final TaskModel task;
  final List<UserModel> users;
  final List<TeamModel> teams;
  final Function(TaskModel) onTaskUpdated;
  final Function(TaskModel)? onMoveToSprint;
  final Function(TaskModel)? onMoveToBacklog;
  final bool isSprint;

  const DropAwareListTile({
    super.key,
    required this.task,
    required this.users,
    required this.teams,
    required this.onTaskUpdated,
    this.onMoveToSprint,
    this.onMoveToBacklog,
    required this.isSprint,
  });

  @override
  State<DropAwareListTile> createState() => _DropAwareListTileState();
}

class _DropAwareListTileState extends State<DropAwareListTile> {
  bool _isOver = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DragTarget<TaskModel>(
      onMove: (details) {
        if (!_isOver) {
          setState(() => _isOver = true);
        }
      },
      onLeave: (data) {
        if (_isOver) {
          setState(() => _isOver = false);
        }
      },
      onAccept: (task) {
        setState(() => _isOver = false);
        _handleTaskDrop(task);
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = _isOver || candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHighlighted
                ? Border.all(
                    color: Colors.blue,
                    width: 2,
                  )
                : null,
            boxShadow: isHighlighted
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => widget.onTaskUpdated(widget.task),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3D3D3D) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con título y prioridad
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.task.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(widget.task.priority),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Descripción
                    if (widget.task.description.isNotEmpty)
                      Text(
                        widget.task.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 8),

                    // Footer con asignado y horas
                    Row(
                      children: [
                        // Avatar del usuario asignado
                        if (widget.task.assignedTo != null)
                          _buildUserAvatar(widget.task.assignedTo!),

                        const Spacer(),

                        // Horas estimadas
                        if (widget.task.estimateHours > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.task.estimateHours}h',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
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
      },
    );
  }

  Widget _buildUserAvatar(String userId) {
    final user = widget.users.firstWhere(
      (u) => u.id == userId,
      orElse: () => UserModel(
        id: userId,
        displayName: 'Usuario',
        email: '',
        role: UserRole.desarrollador,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  void _handleTaskDrop(TaskModel droppedTask) {
    // No mover la tarea a sí misma
    if (droppedTask.id == widget.task.id) return;

    // Si estamos en el panel de sprint y la tarea viene del backlog
    if (widget.isSprint && widget.onMoveToSprint != null) {
      widget.onMoveToSprint!(droppedTask);
    }
    // Si estamos en el panel de backlog y la tarea viene del sprint
    else if (!widget.isSprint && widget.onMoveToBacklog != null) {
      widget.onMoveToBacklog!(droppedTask);
    }
  }
}
