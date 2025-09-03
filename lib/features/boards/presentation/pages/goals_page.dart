import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../data/datasources/boards_remote_datasource.dart';
import '../../data/models/task_model.dart';
import '../../data/models/sprint_model.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();
  List<TaskModel> _allTasks = [];
  SprintModel? _activeSprint;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = context.read<AuthBloc>().state;
      if (user is Authenticated) {
        // Cargar tableros
        _dataSource.getUserBoards(user.user.id).listen((boards) {
          if (mounted) {
            setState(() {});
          }
        });

        // Cargar todas las tareas
        _dataSource.getUserTasks(user.user.id).listen((tasks) {
          if (mounted) {
            setState(() {
              _allTasks = tasks;
            });
          }
        });

        // Cargar sprint activo del primer tablero (si existe)
        _dataSource.getUserBoards(user.user.id).listen((boards) async {
          if (mounted && boards.isNotEmpty) {
            try {
              final activeSprint =
                  await _dataSource.getActiveSprint(boards.first.id);
              if (mounted) {
                setState(() {
                  _activeSprint = activeSprint;
                  _isLoading = false;
                });
              }
            } catch (e) {
              debugPrint('No active sprint found: $e');
              if (mounted) {
                setState(() {
                  _activeSprint = null;
                  _isLoading = false;
                });
              }
            }
          } else if (mounted) {
            setState(() {
              _activeSprint = null;
              _isLoading = false;
            });
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        final isDark = themeState.isDarkMode;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 32),
                      _buildMetricsGrid(isDark),
                      const SizedBox(height: 32),
                      _buildChartsSection(isDark),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metas y Métricas',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Seguimiento de progreso y métricas Scrum',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(bool isDark) {
    final totalTasks = _allTasks.length;
    final completedTasks =
        _allTasks.where((task) => task.status == TaskStatus.done).length;
    final inProgressTasks =
        _allTasks.where((task) => task.status == TaskStatus.inProgress).length;
    final pendingTasks =
        _allTasks.where((task) => task.status == TaskStatus.todo).length;
    final completionRate =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Generales',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Total Tareas',
              totalTasks.toString(),
              Icons.task,
              Colors.blue,
              isDark,
            ),
            _buildMetricCard(
              'Completadas',
              completedTasks.toString(),
              Icons.check_circle,
              Colors.green,
              isDark,
            ),
            _buildMetricCard(
              'En Progreso',
              inProgressTasks.toString(),
              Icons.pending,
              Colors.orange,
              isDark,
            ),
            _buildMetricCard(
              'Pendientes',
              pendingTasks.toString(),
              Icons.schedule,
              Colors.red,
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildCompletionRateCard(completionRate, isDark),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 20,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionRateCard(int completionRate, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Tasa de Completación',
                style: TextStyle(
                  fontSize: 18,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completionRate%',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'de tareas completadas',
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
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: completionRate / 100,
                  strokeWidth: 8,
                  backgroundColor:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gráficas de Progreso',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatusDistributionChart(isDark),
        const SizedBox(height: 24),
        _buildSprintProgressChart(isDark),
      ],
    );
  }

  Widget _buildStatusDistributionChart(bool isDark) {
    final todoCount =
        _allTasks.where((task) => task.status == TaskStatus.todo).length;
    final inProgressCount =
        _allTasks.where((task) => task.status == TaskStatus.inProgress).length;
    final doneCount =
        _allTasks.where((task) => task.status == TaskStatus.done).length;
    final total = _allTasks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución por Estado',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusBar(
                    'Pendiente', todoCount, total, Colors.grey, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusBar('En Progreso', inProgressCount, total,
                    Colors.orange, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusBar(
                    'Completada', doneCount, total, Colors.green, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(
      String label, int count, int total, Color color, bool isDark) {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: total > 0 ? (count / total * 80) : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSprintProgressChart(bool isDark) {
    // Si no hay sprint activo, mostrar mensaje
    if (_activeSprint == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso del Sprint',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.speed,
                    size: 48,
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No hay sprint activo',
                    style: TextStyle(
                      fontSize: 16,
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea un sprint para ver el progreso',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Calcular días transcurridos basado en fechas reales
    final now = DateTime.now();
    final startDate = _activeSprint!.startDate;
    final endDate = _activeSprint!.endDate;

    final totalDays = endDate.difference(startDate).inDays + 1;
    final currentDay = now.difference(startDate).inDays + 1;
    final daysRemaining = endDate.difference(now).inDays;

    // Asegurar que currentDay esté dentro del rango del sprint
    final actualCurrentDay = currentDay.clamp(1, totalDays);
    final sprintProgress = (actualCurrentDay / totalDays * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progreso del Sprint',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Día $actualCurrentDay de $totalDays',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      daysRemaining > 0
                          ? '$daysRemaining días restantes'
                          : 'Sprint finalizado',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysRemaining > 0
                            ? (isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade500)
                            : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$sprintProgress% completado',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: sprintProgress / 100,
                  strokeWidth: 6,
                  backgroundColor:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: sprintProgress / 100,
            backgroundColor:
                isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            minHeight: 8,
          ),
        ],
      ),
    );
  }
}
