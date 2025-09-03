# Changelog

## [2.0.0] - 2024-01-20

### 🚀 Nuevas Funcionalidades

#### 1. Backlog Dual: Sprint + Backlog
- **Vista dividida**: Panel izquierdo para Sprint actual, panel derecho para Backlog
- **Creación de sprints**: Diálogo para crear sprints con nombre, fechas de inicio y fin
- **Drag & Drop entre listas**: Arrastrar tareas entre Sprint y Backlog
- **Indicador de horas**: Muestra total de horas estimadas del sprint en tiempo real
- **Estados vacíos**: Mensajes informativos cuando no hay sprint activo o tareas

#### 2. Gestión de Usuarios y Teams
- **CRUD de usuarios**: Crear, editar y eliminar usuarios con nombre, email y avatar
- **CRUD de teams**: Crear teams con descripción y asignar miembros
- **Asignación de usuarios**: Asignar usuarios a tareas con selector dropdown
- **Avatares e iniciales**: Mostrar iniciales de usuarios en tareas y equipos
- **Relaciones**: Usuarios pueden pertenecer a teams

#### 3. Filtros Avanzados en el Tablero
- **Filtro por estados**: Multi-select de estados (To Do, En Progreso, Completado, etc.)
- **Filtro por usuarios**: Filtrar tareas por usuario asignado
- **Filtro por teams**: Filtrar tareas por team asignado
- **Filtro por etiquetas**: Filtrar por etiquetas de tareas
- **Búsqueda de texto**: Buscar en títulos y descripciones de tareas
- **Filtros combinables**: AND lógico entre campos, OR dentro del mismo campo
- **Resumen de filtros**: Indicador visual de filtros activos

#### 4. Analytics y Estadísticas
- **Burndown Chart**: Gráfico de burndown del sprint con línea ideal vs actual
- **Carga de trabajo**: Distribución de horas por usuario con gráfico de barras
- **Velocidad del equipo**: Velocidad semanal con tendencias
- **Métricas de rendimiento**: Tasa de completado, total de tareas, etc.
- **Estadísticas del sprint**: Progreso, horas restantes, días restantes

#### 5. Mejoras en Drag & Drop
- **Drop hints visuales**: Borde azul y sombra al arrastrar sobre drop targets
- **Feedback mejorado**: Animaciones suaves y indicadores visuales
- **Tooltip informativo**: "Mantén presionado para arrastrar" en tareas
- **Icono de drag handle**: Indicador visual para arrastrar tareas

### 🔧 Mejoras Técnicas

#### Modelos de Datos Extendidos
- **TaskModel**: Agregadas propiedades `estimateHours`, `spentHours`, `teamId`, `tags`
- **UserModel**: Nuevo modelo con `displayName`, `email`, `avatarUrl`, `teamId`
- **TeamModel**: Nuevo modelo con `name`, `description`, `memberUserIds`, `ownerId`
- **FiltersModel**: Nuevo modelo para manejo de filtros con métodos de manipulación

#### Repositorios y Datasources
- **UsersRemoteDataSource**: CRUD completo para usuarios con Firebase
- **TeamsRemoteDataSource**: CRUD completo para teams con Firebase
- **BoardsRemoteDataSource**: Métodos extendidos para sprints, asignaciones y etiquetas
- **Métodos de sprint**: `addTasksToSprint`, `removeTaskFromSprint`, `getBacklogTasks`
- **Métodos de asignación**: `assignUserToTask`, `assignTeamToTask`, `updateTaskTags`

#### Widgets y UI
- **BacklogDualPage**: Nueva página con vista dividida Sprint/Backlog
- **UsersTeamsPage**: Página de gestión de usuarios y teams con tabs
- **BoardFiltersPage**: Página de filtros avanzados con UI intuitiva
- **AnalyticsPage**: Página de analytics con tabs para diferentes métricas
- **DropAwareListTile**: Widget mejorado con drop hints y drag & drop
- **SprintCreationDialog**: Diálogo para crear sprints
- **TaskEditSheet**: Sheet mejorado para editar tareas con asignaciones
- **Gráficos personalizados**: BurndownChart, UserWorkloadChart, VelocityChart

### 🧪 Testing
- **Tests unitarios**: Tests para UserModel, TeamModel, FiltersModel
- **Tests de widgets**: Tests básicos para DropAwareListTile
- **Cobertura**: Tests para métodos principales de modelos y widgets

### 📱 Mejoras de UX/UI
- **Material 3**: Diseño consistente con Material 3
- **Tema oscuro**: Soporte completo para tema oscuro
- **Responsive**: Diseño adaptativo para diferentes tamaños de pantalla
- **Accesibilidad**: Navegación por teclado y indicadores visuales
- **Animaciones**: Transiciones suaves y feedback visual
- **Estados de carga**: Indicadores de progreso y estados vacíos

### 🔄 Integración
- **Firebase Firestore**: Estructura de datos extendida para nuevas funcionalidades
- **BLoC Pattern**: Mantenimiento del patrón de arquitectura existente
- **Clean Architecture**: Separación clara de capas (Domain, Data, Presentation)
- **Inyección de dependencias**: Uso de GetIt para gestión de dependencias

### 🐛 Correcciones
- **Drag & Drop**: Arreglado problema de actualización de listas después de drag & drop
- **Persistencia**: Mejorada la persistencia de cambios en Firebase
- **Estados**: Sincronización correcta entre estado local y Firebase
- **Errores de linting**: Corregidos todos los errores de análisis estático

### 📋 Estructura de Archivos
```
lib/features/boards/
├── data/
│   ├── models/
│   │   ├── user_model.dart (nuevo)
│   │   ├── team_model.dart (nuevo)
│   │   ├── filters_model.dart (nuevo)
│   │   └── task_model.dart (extendido)
│   └── datasources/
│       ├── users_remote_datasource.dart (nuevo)
│       ├── teams_remote_datasource.dart (nuevo)
│       └── boards_remote_datasource.dart (extendido)
└── presentation/
    ├── pages/
    │   ├── backlog_dual_page.dart (nuevo)
    │   ├── users_teams_page.dart (nuevo)
    │   ├── board_filters_page.dart (nuevo)
    │   └── analytics_page.dart (nuevo)
    └── widgets/
        ├── drop_aware_list_tile.dart (nuevo)
        ├── sprint_creation_dialog.dart (nuevo)
        ├── task_edit_sheet.dart (nuevo)
        ├── burndown_chart.dart (nuevo)
        ├── user_workload_chart.dart (nuevo)
        └── velocity_chart.dart (nuevo)
```

### 🎯 Próximos Pasos
- [ ] Implementar notificaciones push
- [ ] Agregar más tipos de gráficos (pie charts, line charts)
- [ ] Implementar exportación de datos
- [ ] Agregar más filtros (fechas, prioridades)
- [ ] Implementar búsqueda avanzada
- [ ] Agregar más métricas de analytics
- [ ] Implementar roles y permisos
- [ ] Agregar integración con herramientas externas

---

## [1.0.0] - 2024-01-15

### 🎉 Lanzamiento Inicial
- Sistema de autenticación con Firebase
- Tableros Kanban con drag & drop básico
- Gestión de épicas y tareas
- Tema claro/oscuro
- Arquitectura Clean Architecture con BLoC
- Persistencia con Firebase Firestore