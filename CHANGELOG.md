# Changelog

## [1.1.0] - 2024-01-XX

### Fixed
- **Drag & Drop en Board**: Corregido el sistema de arrastrar y soltar tarjetas entre columnas
  - Mejorado `LongPressDraggable` con mejor feedback visual
  - Agregados indicadores visuales durante el drag (bordes y colores)
  - Mejorada la validación de drop targets
  - Corregida la sincronización de estados entre columnas

- **Backlog - Reordenamiento y Edición**: Implementado sistema completo de gestión de tareas
  - Reemplazada tabla estática con `ReorderableListView` para reordenamiento
  - Agregada funcionalidad de edición inline con modal `BacklogEditSheet`
  - Implementada persistencia del orden de tareas en Firebase
  - Agregados controles de edición para título, descripción, tiempo estimado, épica, prioridad y estado

- **SignOut**: Corregido flujo de cierre de sesión
  - Limpieza completa de `SharedPreferences` al cerrar sesión
  - Agregado soporte para limpiar `localStorage` en web
  - Eliminación de tokens y datos de usuario persistentes
  - Prevención de sesiones zombie al refrescar la página

### Added
- **Nuevos métodos en BoardsRemoteDataSource**:
  - `updateTaskOrder()` para persistir orden de tareas
- **Widget BacklogEditSheet**: Modal completo para edición de tareas
- **WebStorageHelper**: Helper para limpiar localStorage en web
- **Pruebas unitarias**: Tests básicos para drag & drop, reordenamiento y signOut

### Improved
- **UX del Drag & Drop**: Mejor feedback visual y experiencia de usuario
- **Accesibilidad**: Soporte mejorado para navegación por teclado
- **Validaciones**: Validación de formularios en edición de tareas
- **Manejo de errores**: Mejor gestión de errores en operaciones de persistencia

### Technical Details
- **Arquitectura**: Mantenida Clean Architecture con BLoC
- **Persistencia**: Firebase Firestore para datos, SharedPreferences para configuración
- **Compatibilidad**: Flutter 3.32.7, Dart 3.8.1, Material 3
- **Testing**: Agregadas pruebas unitarias y widget tests básicos

---

## [1.0.0] - 2024-01-XX

### Initial Release
- Implementación inicial de DevBoard
- Autenticación con Firebase
- Sistema de tableros Kanban básico
- Gestión de épicas y tareas
- Tema claro/oscuro
- Arquitectura Clean Architecture con BLoC
