import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/models/sprint_model.dart';

class BurndownChart extends StatelessWidget {
  final SprintModel sprint;
  final List<TaskModel> tasks;
  final bool isDark;

  const BurndownChart({
    super.key,
    required this.sprint,
    required this.tasks,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final totalHours = tasks.fold(0.0, (sum, task) => sum + task.estimateHours);
    final completedHours = tasks
        .where((task) => task.status == TaskStatus.done)
        .fold(0.0, (sum, task) => sum + task.estimateHours);
    final remainingHours = totalHours - completedHours;

    // Calcular días del sprint
    final sprintDays = sprint.endDate.difference(sprint.startDate).inDays + 1;
    final daysPassed = DateTime.now().difference(sprint.startDate).inDays;
    final daysRemaining = sprintDays - daysPassed;

    // Ideal burndown (línea recta)
    final idealBurndown = totalHours / sprintDays;

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
                Icons.trending_down,
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Burndown Chart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Gráfico simplificado
          Container(
            height: 200,
            child: CustomPaint(
              painter: BurndownChartPainter(
                totalHours: totalHours,
                remainingHours: remainingHours,
                idealBurndown: idealBurndown,
                daysPassed: daysPassed,
                sprintDays: sprintDays,
                isDark: isDark,
              ),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),

          // Leyenda
          Row(
            children: [
              _buildLegendItem('Ideal', Colors.grey, isDark),
              const SizedBox(width: 20),
              _buildLegendItem('Actual', Colors.blue, isDark),
            ],
          ),
          const SizedBox(height: 16),

          // Estadísticas del burndown
          Row(
            children: [
              Expanded(
                child: _buildBurndownStat(
                  'Horas Restantes',
                  '${remainingHours.toStringAsFixed(1)}h',
                  Colors.orange,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBurndownStat(
                  'Días Restantes',
                  '$daysRemaining',
                  Colors.red,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBurndownStat(
                  'Velocidad Ideal',
                  '${idealBurndown.toStringAsFixed(1)}h/día',
                  Colors.blue,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildBurndownStat(
      String title, String value, Color color, bool isDark) {
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

class BurndownChartPainter extends CustomPainter {
  final double totalHours;
  final double remainingHours;
  final double idealBurndown;
  final int daysPassed;
  final int sprintDays;
  final bool isDark;

  BurndownChartPainter({
    required this.totalHours,
    required this.remainingHours,
    required this.idealBurndown,
    required this.daysPassed,
    required this.sprintDays,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Línea ideal (recta desde totalHours hasta 0)
    paint.color = Colors.grey;
    final idealStart = Offset(0, 0);
    final idealEnd = Offset(size.width, size.height);
    canvas.drawLine(idealStart, idealEnd, paint);

    // Línea actual (desde totalHours hasta remainingHours)
    paint.color = Colors.blue;
    final actualStart = Offset(0, 0);
    final actualEnd = Offset(
      size.width * (daysPassed / sprintDays),
      size.height * (remainingHours / totalHours),
    );
    canvas.drawLine(actualStart, actualEnd, paint);

    // Puntos en las líneas
    _drawPoint(canvas, idealEnd, Colors.grey);
    _drawPoint(canvas, actualEnd, Colors.blue);

    // Etiquetas
    _drawLabel(canvas, 'Inicio', Offset(0, size.height + 20), isDark);
    _drawLabel(
        canvas, 'Fin', Offset(size.width - 20, size.height + 20), isDark);
  }

  void _drawPoint(Canvas canvas, Offset point, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 4, paint);
  }

  void _drawLabel(Canvas canvas, String text, Offset position, bool isDark) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
