import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high, critical }

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String epicId;
  final String? sprintId;
  final String ownerId;
  final TaskStatus status;
  final String? customStatusName; // Nombre personalizado del estado
  final String? assignedTo;
  final DateTime? dueDate;
  final TaskPriority priority;
  final String? timeEstimate;
  final double estimateHours; // horas estimadas
  final double? spentHours; // horas gastadas (opcional)
  final String? teamId; // ID del team asignado
  final List<String> tags; // etiquetas de la tarea
  final List<String>
      favoritedBy; // Lista de usuarios que marcaron como favorito
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.epicId,
    this.sprintId,
    required this.ownerId,
    required this.status,
    this.customStatusName,
    this.assignedTo,
    this.dueDate,
    required this.priority,
    this.timeEstimate,
    this.estimateHours = 0.0,
    this.spentHours,
    this.teamId,
    this.tags = const [],
    this.favoritedBy = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firestore
  factory TaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final now = DateTime.now();
    final statusString = data['status'] ?? 'todo';

    return TaskModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      epicId: data['epicId'] ?? '',
      sprintId: data['sprintId'],
      ownerId: data['ownerId'] ?? '',
      status: _parseStatus(statusString),
      customStatusName: data['customStatusName'] ??
          statusString, // Usar el nombre personalizado si existe
      assignedTo: data['assignedTo'],
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      priority: _parsePriority(data['priority'] ?? 'medium'),
      timeEstimate: data['timeEstimate'],
      estimateHours: (data['estimateHours'] ?? 0.0).toDouble(),
      spentHours: data['spentHours']?.toDouble(),
      teamId: data['teamId'],
      tags: List<String>.from(data['tags'] ?? []),
      favoritedBy: List<String>.from(data['favoritedBy'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : now,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : now,
    );
  }

  // Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    final now = DateTime.now();
    return {
      'title': title,
      'description': description,
      'epicId': epicId,
      'sprintId': sprintId,
      'ownerId': ownerId,
      'status': statusToString(status),
      'customStatusName': customStatusName ??
          statusToString(status), // Guardar nombre personalizado
      'assignedTo': assignedTo,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'priority': _priorityToString(priority),
      'timeEstimate': timeEstimate,
      'estimateHours': estimateHours,
      'spentHours': spentHours,
      'teamId': teamId,
      'tags': tags,
      'favoritedBy': favoritedBy,
      'createdAt': Timestamp.fromDate(
          createdAt.isAfter(DateTime(2020)) ? createdAt : now),
      'updatedAt': Timestamp.fromDate(
          updatedAt.isAfter(DateTime(2020)) ? updatedAt : now),
    };
  }

  // Crear nueva tarea
  factory TaskModel.create({
    required String title,
    required String description,
    required String epicId,
    required String ownerId,
    String? sprintId,
    TaskPriority priority = TaskPriority.medium,
    String? timeEstimate,
  }) {
    final now = DateTime.now();
    return TaskModel(
      id: '',
      title: title,
      description: description,
      epicId: epicId,
      sprintId: sprintId,
      ownerId: ownerId,
      status: TaskStatus.todo,
      priority: priority,
      timeEstimate: timeEstimate,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con modificaciones
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? epicId,
    String? sprintId,
    String? ownerId,
    TaskStatus? status,
    String? customStatusName,
    String? assignedTo,
    DateTime? dueDate,
    TaskPriority? priority,
    String? timeEstimate,
    double? estimateHours,
    double? spentHours,
    String? teamId,
    List<String>? tags,
    List<String>? favoritedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      epicId: epicId ?? this.epicId,
      sprintId: sprintId ?? this.sprintId,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      customStatusName: customStatusName ?? this.customStatusName,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      timeEstimate: timeEstimate ?? this.timeEstimate,
      estimateHours: estimateHours ?? this.estimateHours,
      spentHours: spentHours ?? this.spentHours,
      teamId: teamId ?? this.teamId,
      tags: tags ?? this.tags,
      favoritedBy: favoritedBy ?? this.favoritedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Mover tarea a siguiente estado
  TaskModel moveToNextStatus() {
    TaskStatus nextStatus;
    switch (status) {
      case TaskStatus.todo:
        nextStatus = TaskStatus.inProgress;
        break;
      case TaskStatus.inProgress:
        nextStatus = TaskStatus.done;
        break;
      case TaskStatus.done:
        return this; // Ya está en el estado final
    }
    return copyWith(
      status: nextStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Mover tarea a estado anterior
  TaskModel moveToPreviousStatus() {
    TaskStatus previousStatus;
    switch (status) {
      case TaskStatus.done:
        previousStatus = TaskStatus.inProgress;
        break;
      case TaskStatus.inProgress:
        previousStatus = TaskStatus.todo;
        break;
      case TaskStatus.todo:
        return this; // Ya está en el estado inicial
    }
    return copyWith(
      status: previousStatus,
      updatedAt: DateTime.now(),
    );
  }

  // Asignar tarea a usuario
  TaskModel assignTo(String userId) {
    return copyWith(
      assignedTo: userId,
      updatedAt: DateTime.now(),
    );
  }

  // Desasignar tarea
  TaskModel unassign() {
    return copyWith(
      assignedTo: null,
      updatedAt: DateTime.now(),
    );
  }

  // Verificar si un usuario marcó como favorito
  bool isFavoritedBy(String userId) => favoritedBy.contains(userId);

  // Marcar como favorito
  TaskModel markAsFavorite(String userId) {
    if (!favoritedBy.contains(userId)) {
      return copyWith(
        favoritedBy: [...favoritedBy, userId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Desmarcar como favorito
  TaskModel unmarkAsFavorite(String userId) {
    if (favoritedBy.contains(userId)) {
      return copyWith(
        favoritedBy: favoritedBy.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  // Verificar si la tarea está vencida
  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != TaskStatus.done;
  }

  // Verificar si la tarea está próxima a vencer (3 días)
  bool get isDueSoon {
    if (dueDate == null) return false;
    final threeDaysFromNow = DateTime.now().add(const Duration(days: 3));
    return dueDate!.isBefore(threeDaysFromNow) &&
        dueDate!.isAfter(DateTime.now()) &&
        status != TaskStatus.done;
  }

  // Obtener color de prioridad
  int get priorityColor {
    switch (priority) {
      case TaskPriority.low:
        return 0xFF4CAF50; // Verde
      case TaskPriority.medium:
        return 0xFFFF9800; // Naranja
      case TaskPriority.high:
        return 0xFFFF5722; // Rojo
      case TaskPriority.critical:
        return 0xFF9C27B0; // Púrpura
    }
  }

  // Obtener texto de estado
  String get statusText {
    // Si hay un nombre personalizado, usarlo
    if (customStatusName != null && customStatusName!.isNotEmpty) {
      return customStatusName!;
    }

    // Si no, usar el texto por defecto basado en el enum
    switch (status) {
      case TaskStatus.todo:
        return 'Por hacer';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.done:
        return 'Completada';
    }
  }

  // Obtener texto de prioridad
  String get priorityText {
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

  // Métodos auxiliares para parsing
  static TaskStatus _parseStatus(String status) {
    // Manejar estados estándar
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'in progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      case 'todo':
      case 'to do':
      default:
        return TaskStatus.todo;
    }
  }

  static String statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  static TaskPriority _parsePriority(String priority) {
    switch (priority) {
      case 'high':
        return TaskPriority.high;
      case 'critical':
        return TaskPriority.critical;
      case 'low':
        return TaskPriority.low;
      case 'medium':
      default:
        return TaskPriority.medium;
    }
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.critical:
        return 'critical';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.epicId == epicId &&
        other.status == status &&
        other.assignedTo == assignedTo &&
        other.dueDate == dueDate &&
        other.priority == priority &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      epicId,
      status,
      assignedTo,
      dueDate,
      priority,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, status: $status, priority: $priority)';
  }
}
