import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../data/models/task_model.dart';
import '../../data/models/sprint_model.dart';
import '../../data/models/user_model.dart';
import '../widgets/burndown_chart.dart';
import '../widgets/user_workload_chart.dart';
import '../widgets/velocity_chart.dart';

class AnalyticsPage extends StatefulWidget {
  final List<TaskModel> tasks;
  final SprintModel? activeSprint;
  final List<UserModel> users;

  const AnalyticsPage({
    super.key,
    required this.tasks,
    this.activeSprint,
    required this.users,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.trending_down),
              text: 'Burndown',
            ),
            Tab(
              icon: Icon(Icons.people),
              text: 'Carga de Trabajo',
            ),
            Tab(
              icon: Icon(Icons.speed),
              text: 'Velocidad',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBurndownTab(isDark),
          _buildWorkloadTab(isDark),
          _buildVelocityTab(isDark),
        ],
      ),
    );
  }

  Widget _buildBurndownTab(bool isDark) {
    if (widget.activeSprint == null) {
      return _buildNoSprintState(isDark);
    }

    final sprintTasks = widget.tasks
        .where((task) => task.sprintId == widget.activeSprint!.id)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen del sprint
          _buildSprintSummary(sprintTasks, isDark),
          const SizedBox(height: 24),

          // Gráfico de burndown
          BurndownChart(
            sprint: widget.activeSprint!,
            tasks: sprintTasks,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Estadísticas del sprint
          _buildSprintStats(sprintTasks, isDark),
        ],
      ),
    );
  }

  Widget _buildWorkloadTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de carga de trabajo
          _buildWorkloadSummary(isDark),
          const SizedBox(height: 24),

          // Gráfico de carga por usuario
          UserWorkloadChart(
            tasks: widget.tasks,
            users: widget.users,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Lista detallada de usuarios
          _buildUserWorkloadList(isDark),
        ],
      ),
    );
  }

  Widget _buildVelocityTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resumen de velocidad
          _buildVelocitySummary(isDark),
          const SizedBox(height: 24),

          // Gráfico de velocidad
          VelocityChart(
            tasks: widget.tasks,
            isDark: isDark,
          ),
          const SizedBox(height: 24),

          // Métricas de rendimiento
          _buildPerformanceMetrics(isDark),
        ],
      ),
    );
  }

  Widget _buildNoSprintState(bool isDark) {
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
            'Crea un sprint para ver el análisis de burndown',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSprintSummary(List<TaskModel> sprintTasks, bool isDark) {
    final totalHours =
        sprintTasks.fold(0.0, (sum, task) => sum + task.estimateHours);
    final completedHours = sprintTasks
        .where((task) => task.status == TaskStatus.done)
        .fold(0.0, (sum, task) => sum + task.estimateHours);
    final remainingHours = totalHours - completedHours;
    final progress = totalHours > 0 ? (completedHours / totalHours) : 0.0;

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
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.activeSprint!.name,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Horas',
                  '${totalHours.toStringAsFixed(1)}h',
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Completadas',
                  '${completedHours.toStringAsFixed(1)}h',
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Restantes',
                  '${remainingHours.toStringAsFixed(1)}h',
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de progreso
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progreso del Sprint',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                minHeight: 8,
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkloadSummary(bool isDark) {
    final userWorkload = <String, double>{};
    for (final task in widget.tasks) {
      if (task.assignedTo != null) {
        userWorkload[task.assignedTo!] =
            (userWorkload[task.assignedTo!] ?? 0) + task.estimateHours;
      }
    }

    final totalWorkload =
        userWorkload.values.fold(0.0, (sum, hours) => sum + hours);
    final averageWorkload =
        userWorkload.isNotEmpty ? totalWorkload / userWorkload.length : 0.0;

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
                'Carga de Trabajo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Horas',
                  '${totalWorkload.toStringAsFixed(1)}h',
                  Colors.green,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Promedio',
                  '${averageWorkload.toStringAsFixed(1)}h',
                  Colors.blue,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Usuarios',
                  '${userWorkload.length}',
                  Colors.orange,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocitySummary(bool isDark) {
    final completedTasks =
        widget.tasks.where((task) => task.status == TaskStatus.done).toList();
    final completedHours =
        completedTasks.fold(0.0, (sum, task) => sum + task.estimateHours);

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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tareas Completadas',
                  '${completedTasks.length}',
                  Colors.purple,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Horas Completadas',
                  '${completedHours.toStringAsFixed(1)}h',
                  Colors.green,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSprintStats(List<TaskModel> sprintTasks, bool isDark) {
    final todoTasks =
        sprintTasks.where((t) => t.status == TaskStatus.todo).length;
    final inProgressTasks =
        sprintTasks.where((t) => t.status == TaskStatus.inProgress).length;
    final doneTasks =
        sprintTasks.where((t) => t.status == TaskStatus.done).length;

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
          Text(
            'Distribución de Tareas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child:
                    _buildStatCard('To Do', '$todoTasks', Colors.grey, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'En Progreso', '$inProgressTasks', Colors.orange, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                    'Completadas', '$doneTasks', Colors.green, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserWorkloadList(bool isDark) {
    final userWorkload = <String, double>{};
    for (final task in widget.tasks) {
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
          child: Text(
            'No hay tareas asignadas a usuarios',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

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
          Text(
            'Carga por Usuario',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...userWorkload.entries.map((entry) {
            final user = widget.users.firstWhere(
              (u) => u.id == entry.key,
              orElse: () => UserModel(
                id: entry.key,
                displayName: 'Usuario desconocido',
                email: '',
                role: UserRole.desarrollador,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3D3D3D) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.green,
                    child: Text(
                      user.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${entry.value.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetrics(bool isDark) {
    final completedTasks =
        widget.tasks.where((task) => task.status == TaskStatus.done).toList();
    final totalTasks = widget.tasks.length;
    final completionRate =
        totalTasks > 0 ? (completedTasks.length / totalTasks) : 0.0;

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
          Text(
            'Métricas de Rendimiento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tasa de Completado',
                  '${(completionRate * 100).toStringAsFixed(1)}%',
                  Colors.purple,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Tareas',
                  '$totalTasks',
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
}
