import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class BoardStatusModel {
  final String id;
  final String name;
  final TaskStatus status;
  final Color color;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  BoardStatusModel({
    required this.id,
    required this.name,
    required this.status,
    required this.color,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  // Crear desde Firebase
  factory BoardStatusModel.fromFirestore(Map<String, dynamic> data) {
    return BoardStatusModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      status: _stringToTaskStatus(data['status'] ?? 'todo'),
      color: Color(data['color'] ?? Colors.grey.value),
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a Firebase
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'status': _taskStatusToString(status),
      'color': color.value,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Crear nuevo estado
  factory BoardStatusModel.create({
    required String name,
    required TaskStatus status,
    required Color color,
    required int order,
  }) {
    final now = DateTime.now();
    return BoardStatusModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      status: status,
      color: color,
      order: order,
      createdAt: now,
      updatedAt: now,
    );
  }

  // Copiar con cambios
  BoardStatusModel copyWith({
    String? id,
    String? name,
    TaskStatus? status,
    Color? color,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoardStatusModel(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      color: color ?? this.color,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir TaskStatus a string
  static String _taskStatusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  // Convertir string a TaskStatus
  static TaskStatus _stringToTaskStatus(String status) {
    switch (status) {
      case 'todo':
        return TaskStatus.todo;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BoardStatusModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BoardStatusModel(id: $id, name: $name, status: $status, color: $color, order: $order)';
  }
}
