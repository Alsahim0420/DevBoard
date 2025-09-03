class FiltersModel {
  final Set<String> states;
  final Set<String> userIds;
  final Set<String> teamIds;
  final Set<String> tags;
  final String query;

  const FiltersModel({
    this.states = const {},
    this.userIds = const {},
    this.teamIds = const {},
    this.tags = const {},
    this.query = '',
  });

  // Crear filtros vacíos
  factory FiltersModel.empty() => const FiltersModel();

  // Copiar con modificaciones
  FiltersModel copyWith({
    Set<String>? states,
    Set<String>? userIds,
    Set<String>? teamIds,
    Set<String>? tags,
    String? query,
  }) {
    return FiltersModel(
      states: states ?? this.states,
      userIds: userIds ?? this.userIds,
      teamIds: teamIds ?? this.teamIds,
      tags: tags ?? this.tags,
      query: query ?? this.query,
    );
  }

  // Agregar estado al filtro
  FiltersModel addState(String state) {
    return copyWith(states: {...states, state});
  }

  // Remover estado del filtro
  FiltersModel removeState(String state) {
    return copyWith(states: states.where((s) => s != state).toSet());
  }

  // Agregar usuario al filtro
  FiltersModel addUser(String userId) {
    return copyWith(userIds: {...userIds, userId});
  }

  // Remover usuario del filtro
  FiltersModel removeUser(String userId) {
    return copyWith(userIds: userIds.where((id) => id != userId).toSet());
  }

  // Agregar team al filtro
  FiltersModel addTeam(String teamId) {
    return copyWith(teamIds: {...teamIds, teamId});
  }

  // Remover team del filtro
  FiltersModel removeTeam(String teamId) {
    return copyWith(teamIds: teamIds.where((id) => id != teamId).toSet());
  }

  // Agregar etiqueta al filtro
  FiltersModel addTag(String tag) {
    return copyWith(tags: {...tags, tag});
  }

  // Remover etiqueta del filtro
  FiltersModel removeTag(String tag) {
    return copyWith(tags: tags.where((t) => t != tag).toSet());
  }

  // Limpiar todos los filtros
  FiltersModel clear() {
    return const FiltersModel();
  }

  // Verificar si hay filtros activos
  bool get hasActiveFilters {
    return states.isNotEmpty ||
        userIds.isNotEmpty ||
        teamIds.isNotEmpty ||
        tags.isNotEmpty ||
        query.isNotEmpty;
  }

  // Obtener número de filtros activos
  int get activeFilterCount {
    int count = 0;
    if (states.isNotEmpty) count++;
    if (userIds.isNotEmpty) count++;
    if (teamIds.isNotEmpty) count++;
    if (tags.isNotEmpty) count++;
    if (query.isNotEmpty) count++;
    return count;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FiltersModel &&
        other.states.toString() == states.toString() &&
        other.userIds.toString() == userIds.toString() &&
        other.teamIds.toString() == teamIds.toString() &&
        other.tags.toString() == tags.toString() &&
        other.query == query;
  }

  @override
  int get hashCode {
    return Object.hash(states, userIds, teamIds, tags, query);
  }

  @override
  String toString() {
    return 'FiltersModel(states: $states, userIds: $userIds, teamIds: $teamIds, tags: $tags, query: $query)';
  }
}
