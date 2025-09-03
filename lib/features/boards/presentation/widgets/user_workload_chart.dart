import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';

class UserWorkloadChart extends StatelessWidget {
  final List<TaskModel> tasks;
  final List<UserModel> users;
  final bool isDark;

  const UserWorkloadChart({
    super.key,
    required this.tasks,
    required this.users,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final userWorkload = <String, double>{};
    for (final task in tasks) {
      if (task.assignedTo != null) {
        userWorkload[task.assignedTo!] =
            (userWorkload[task.assignedTo!] ?? 0) + task.estimateHours;
      }
    }

    if (userWorkload.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No hay tareas asignadas',
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final maxHours = userWorkload.values.isNotEmpty
        ? userWorkload.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Carga de Trabajo por Usuario',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico de barras
          Container(
            height: 200,
            child: CustomPaint(
              painter: UserWorkloadChartPainter(
                userWorkload: userWorkload,
                users: users,
                maxHours: maxHours,
                isDark: isDark,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas
          _buildWorkloadStats(userWorkload, isDark),
        ],
      ),
    );
  }

  Widget _buildWorkloadStats(Map<String, double> userWorkload, bool isDark) {
    final totalHours =
        userWorkload.values.fold(0.0, (sum, hours) => sum + hours);
    final averageHours =
        userWorkload.isNotEmpty ? totalHours / userWorkload.length : 0.0;
    final maxHours = userWorkload.values.isNotEmpty
        ? userWorkload.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Horas',
            '${totalHours.toStringAsFixed(1)}h',
            Colors.green,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Promedio',
            '${averageHours.toStringAsFixed(1)}h',
            Colors.blue,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Máximo',
            '${maxHours.toStringAsFixed(1)}h',
            Colors.orange,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class UserWorkloadChartPainter extends CustomPainter {
  final Map<String, double> userWorkload;
  final List<UserModel> users;
  final double maxHours;
  final bool isDark;

  UserWorkloadChartPainter({
    required this.userWorkload,
    required this.users,
    required this.maxHours,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (userWorkload.isEmpty || maxHours == 0) return;

    final barWidth = size.width / userWorkload.length * 0.8;
    final barSpacing = size.width / userWorkload.length * 0.2;
    final maxBarHeight = size.height - 60; // Espacio para etiquetas

    final paint = Paint()..style = PaintingStyle.fill;

    int index = 0;
    userWorkload.forEach((userId, hours) {
      final barHeight = (hours / maxHours) * maxBarHeight;
      final x = index * (barWidth + barSpacing) + barSpacing / 2;
      final y = size.height - barHeight - 40; // Espacio para etiquetas

      // Color de la barra basado en la carga
      Color barColor;
      if (hours > maxHours * 0.8) {
        barColor = Colors.red;
      } else if (hours > maxHours * 0.6) {
        barColor = Colors.orange;
      } else {
        barColor = Colors.green;
      }

      paint.color = barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Etiqueta del usuario
      final user = users.firstWhere(
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

      final textPainter = TextPainter(
        text: TextSpan(
          text: user.initials,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - textPainter.width / 2, size.height - 30),
      );

      // Etiqueta de horas
      final hoursTextPainter = TextPainter(
        text: TextSpan(
          text: '${hours.toStringAsFixed(1)}h',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      hoursTextPainter.layout();
      hoursTextPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - hoursTextPainter.width / 2, size.height - 15),
      );

      index++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
