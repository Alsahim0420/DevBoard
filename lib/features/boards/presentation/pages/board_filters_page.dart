import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../data/models/filters_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/team_model.dart';
import '../../data/models/task_model.dart';

class BoardFiltersPage extends StatefulWidget {
  final FiltersModel currentFilters;
  final List<UserModel> users;
  final List<TeamModel> teams;
  final List<TaskModel> allTasks;
  final Function(FiltersModel) onFiltersChanged;

  const BoardFiltersPage({
    super.key,
    required this.currentFilters,
    required this.users,
    required this.teams,
    required this.allTasks,
    required this.onFiltersChanged,
  });

  @override
  State<BoardFiltersPage> createState() => _BoardFiltersPageState();
}

class _BoardFiltersPageState extends State<BoardFiltersPage> {
  late FiltersModel _filters;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
    _searchController.text = _filters.query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    widget.onFiltersChanged(_filters);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _filters = FiltersModel.empty();
      _searchController.clear();
    });
  }

  List<String> _getAvailableTags() {
    final allTags = <String>{};
    for (final task in widget.allTasks) {
      allTags.addAll(task.tags);
    }
    return allTags.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Filtros del Tablero'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_filters.hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: const Text('Limpiar'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda de texto
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar en tareas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _filters = _filters.copyWith(query: '');
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(query: value);
                });
              },
            ),
          ),

          // Lista de filtros
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Filtro por estados
                _buildFilterSection(
                  title: 'Estados',
                  icon: Icons.flag,
                  color: Colors.blue,
                  isDark: isDark,
                  children: [
                    _buildStateFilter('todo', 'To Do', isDark),
                    _buildStateFilter('inProgress', 'En Progreso', isDark),
                    _buildStateFilter('done', 'Completado', isDark),
                    _buildStateFilter('backlog', 'Backlog', isDark),
                    _buildStateFilter('sprint', 'Sprint', isDark),
                  ],
                ),
                const SizedBox(height: 24),

                // Filtro por usuarios
                _buildFilterSection(
                  title: 'Usuarios Asignados',
                  icon: Icons.people,
                  color: Colors.green,
                  isDark: isDark,
                  children: widget.users.map((user) {
                    return _buildUserFilter(user, isDark);
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Filtro por teams
                _buildFilterSection(
                  title: 'Teams',
                  icon: Icons.group,
                  color: Colors.orange,
                  isDark: isDark,
                  children: widget.teams.map((team) {
                    return _buildTeamFilter(team, isDark);
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Filtro por etiquetas
                _buildFilterSection(
                  title: 'Etiquetas',
                  icon: Icons.label,
                  color: Colors.purple,
                  isDark: isDark,
                  children: _getAvailableTags().map((tag) {
                    return _buildTagFilter(tag, isDark);
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Resumen de filtros activos
                if (_filters.hasActiveFilters)
                  _buildActiveFiltersSummary(isDark),
              ],
            ),
          ),

          // Botón aplicar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Aplicar Filtros (${_filters.activeFilterCount})',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateFilter(String state, String label, bool isDark) {
    final isSelected = _filters.states.contains(state);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _filters = _filters.addState(state);
          } else {
            _filters = _filters.removeState(state);
          }
        });
      },
      title: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      activeColor: Colors.blue,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildUserFilter(UserModel user, bool isDark) {
    final isSelected = _filters.userIds.contains(user.id);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _filters = _filters.addUser(user.id);
          } else {
            _filters = _filters.removeUser(user.id);
          }
        });
      },
      title: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.green,
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
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTeamFilter(TeamModel team, bool isDark) {
    final isSelected = _filters.teamIds.contains(team.id);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _filters = _filters.addTeam(team.id);
          } else {
            _filters = _filters.removeTeam(team.id);
          }
        });
      },
      title: Row(
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
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${team.memberCount}',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
      activeColor: Colors.orange,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTagFilter(String tag, bool isDark) {
    final isSelected = _filters.tags.contains(tag);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            _filters = _filters.addTag(tag);
          } else {
            _filters = _filters.removeTag(tag);
          }
        });
      },
      title: Row(
        children: [
          Icon(
            Icons.label,
            size: 16,
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tag,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
      activeColor: Colors.purple,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActiveFiltersSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_list,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros Activos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_filters.states.isNotEmpty)
                _buildFilterChip(
                    'Estados: ${_filters.states.length}', Colors.blue),
              if (_filters.userIds.isNotEmpty)
                _buildFilterChip(
                    'Usuarios: ${_filters.userIds.length}', Colors.green),
              if (_filters.teamIds.isNotEmpty)
                _buildFilterChip(
                    'Teams: ${_filters.teamIds.length}', Colors.orange),
              if (_filters.tags.isNotEmpty)
                _buildFilterChip(
                    'Etiquetas: ${_filters.tags.length}', Colors.purple),
              if (_filters.query.isNotEmpty)
                _buildFilterChip('Búsqueda: "${_filters.query}"', Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}
