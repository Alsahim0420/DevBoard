import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';

class VelocityChart extends StatelessWidget {
  final List<TaskModel> tasks;
  final bool isDark;

  const VelocityChart({
    super.key,
    required this.tasks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular velocidad por semana (simulado)
    final weeklyVelocity = _calculateWeeklyVelocity();
    final averageVelocity = weeklyVelocity.isNotEmpty
        ? weeklyVelocity.values.reduce((a, b) => a + b) / weeklyVelocity.length
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
                Icons.speed,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Velocidad del Equipo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico de velocidad
          Container(
            height: 200,
            child: CustomPaint(
              painter: VelocityChartPainter(
                weeklyVelocity: weeklyVelocity,
                averageVelocity: averageVelocity,
                isDark: isDark,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),

          // Estadísticas de velocidad
          _buildVelocityStats(weeklyVelocity, averageVelocity, isDark),
        ],
      ),
    );
  }

  Map<String, double> _calculateWeeklyVelocity() {
    // Simular datos de velocidad por semana
    // En una implementación real, esto vendría de datos históricos
    final now = DateTime.now();
    final velocity = <String, double>{};

    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: i * 7));
      final weekKey = 'Sem ${weekStart.day}/${weekStart.month}';

      // Simular velocidad basada en tareas completadas
      final completedTasks = tasks.where((task) {
        if (task.status != TaskStatus.done) return false;
        final taskDate = task.updatedAt;
        return taskDate.isAfter(weekStart) &&
            taskDate.isBefore(weekStart.add(const Duration(days: 7)));
      }).toList();

      final weekHours =
          completedTasks.fold(0.0, (sum, task) => sum + task.estimateHours);
      velocity[weekKey] = weekHours;
    }

    return velocity;
  }

  Widget _buildVelocityStats(
      Map<String, double> weeklyVelocity, double averageVelocity, bool isDark) {
    final maxVelocity = weeklyVelocity.values.isNotEmpty
        ? weeklyVelocity.values.reduce((a, b) => a > b ? a : b)
        : 0.0;
    final minVelocity = weeklyVelocity.values.isNotEmpty
        ? weeklyVelocity.values.reduce((a, b) => a < b ? a : b)
        : 0.0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Promedio',
            '${averageVelocity.toStringAsFixed(1)}h/sem',
            Colors.purple,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Máximo',
            '${maxVelocity.toStringAsFixed(1)}h/sem',
            Colors.green,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Mínimo',
            '${minVelocity.toStringAsFixed(1)}h/sem',
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

class VelocityChartPainter extends CustomPainter {
  final Map<String, double> weeklyVelocity;
  final double averageVelocity;
  final bool isDark;

  VelocityChartPainter({
    required this.weeklyVelocity,
    required this.averageVelocity,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyVelocity.isEmpty) return;

    final maxVelocity = weeklyVelocity.values.isNotEmpty
        ? weeklyVelocity.values.reduce((a, b) => a > b ? a : b)
        : 0.0;

    if (maxVelocity == 0) return;

    final barWidth = size.width / weeklyVelocity.length * 0.8;
    final barSpacing = size.width / weeklyVelocity.length * 0.2;
    final maxBarHeight = size.height - 60;

    final paint = Paint()..style = PaintingStyle.fill;

    // Línea de promedio
    final averageY =
        size.height - (averageVelocity / maxVelocity) * maxBarHeight - 40;
    paint.color = Colors.grey.withOpacity(0.5);
    paint.strokeWidth = 1;
    canvas.drawLine(
      Offset(0, averageY),
      Offset(size.width, averageY),
      paint,
    );

    // Etiqueta de promedio
    final avgTextPainter = TextPainter(
      text: TextSpan(
        text: 'Promedio: ${averageVelocity.toStringAsFixed(1)}h',
        style: TextStyle(
          fontSize: 10,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    avgTextPainter.layout();
    avgTextPainter.paint(canvas, Offset(5, averageY - 15));

    // Barras de velocidad
    paint.style = PaintingStyle.fill;
    int index = 0;
    weeklyVelocity.forEach((week, velocity) {
      final barHeight = (velocity / maxVelocity) * maxBarHeight;
      final x = index * (barWidth + barSpacing) + barSpacing / 2;
      final y = size.height - barHeight - 40;

      // Color basado en si está por encima o debajo del promedio
      paint.color = velocity >= averageVelocity ? Colors.green : Colors.orange;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // Etiqueta de la semana
      final weekTextPainter = TextPainter(
        text: TextSpan(
          text: week,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      weekTextPainter.layout();
      weekTextPainter.paint(
        canvas,
        Offset(x + barWidth / 2 - weekTextPainter.width / 2, size.height - 30),
      );

      // Etiqueta de velocidad
      final velocityTextPainter = TextPainter(
        text: TextSpan(
          text: '${velocity.toStringAsFixed(1)}h',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      velocityTextPainter.layout();
      velocityTextPainter.paint(
        canvas,
        Offset(
            x + barWidth / 2 - velocityTextPainter.width / 2, size.height - 15),
      );

      index++;
    });
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
