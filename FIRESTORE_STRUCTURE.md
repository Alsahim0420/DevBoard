# Estructura de Firestore - Sistema de Tableros Tipo Jira

## Descripción General

Esta estructura de Firestore está diseñada para un sistema de gestión de proyectos tipo Jira, donde los usuarios pueden crear tableros, organizar trabajo en épicas y gestionar tareas individuales.

## Colecciones

### 1. `boards` - Tableros

**Descripción**: Representa un tablero de proyecto donde se organizan las épicas y tareas.

**Estructura del documento**:
```json
{
  "name": "string (1-100 caracteres)",
  "ownerId": "string (UID del usuario propietario)",
  "members": ["array de UIDs de usuarios"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Ejemplo**:
```json
{
  "name": "Sprint Q1 2024",
  "ownerId": "user123",
  "members": ["user123", "user456", "user789"],
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T14:45:00Z"
}
```

**Validaciones**:
- `name`: Requerido, 1-100 caracteres
- `ownerId`: Requerido, debe ser un UID válido
- `members`: Opcional, array de UIDs
- `createdAt`: Automático, timestamp de creación
- `updatedAt`: Automático, timestamp de última actualización

### 2. `epics` - Épicas

**Descripción**: Agrupaciones lógicas de tareas relacionadas dentro de un tablero.

**Estructura del documento**:
```json
{
  "title": "string (1-200 caracteres)",
  "description": "string (máximo 1000 caracteres)",
  "boardId": "string (ID del tablero)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Ejemplo**:
```json
{
  "title": "Implementar Sistema de Autenticación",
  "description": "Desarrollar un sistema completo de autenticación con Firebase Auth, incluyendo login, registro y recuperación de contraseñas.",
  "boardId": "board123",
  "createdAt": "2024-01-15T11:00:00Z",
  "updatedAt": "2024-01-18T16:20:00Z"
}
```

**Validaciones**:
- `title`: Requerido, 1-200 caracteres
- `description`: Opcional, máximo 1000 caracteres
- `boardId`: Requerido, debe existir en colección `boards`
- `createdAt`: Automático, timestamp de creación
- `updatedAt`: Automático, timestamp de última actualización

### 3. `tasks` - Tareas

**Descripción**: Tareas individuales que pertenecen a una épica y tienen un estado específico.

**Estructura del documento**:
```json
{
  "title": "string (1-200 caracteres)",
  "description": "string (máximo 1000 caracteres)",
  "epicId": "string (ID de la épica)",
  "status": "string (todo | in_progress | done)",
  "assignedTo": "string (UID del usuario asignado) | null",
  "dueDate": "timestamp | null",
  "priority": "string (low | medium | high | critical)",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

**Ejemplo**:
```json
{
  "title": "Configurar Firebase Auth",
  "description": "Configurar Firebase Authentication en el proyecto Flutter, incluyendo las dependencias necesarias y la inicialización.",
  "epicId": "epic123",
  "status": "in_progress",
  "assignedTo": "user456",
  "dueDate": "2024-01-25T17:00:00Z",
  "priority": "high",
  "createdAt": "2024-01-15T12:00:00Z",
  "updatedAt": "2024-01-19T09:15:00Z"
}
```

**Validaciones**:
- `title`: Requerido, 1-200 caracteres
- `description`: Opcional, máximo 1000 caracteres
- `epicId`: Requerido, debe existir en colección `epics`
- `status`: Requerido, uno de: `todo`, `in_progress`, `done`
- `assignedTo`: Opcional, UID válido o null
- `dueDate`: Opcional, timestamp válido o null
- `priority`: Opcional, uno de: `low`, `medium`, `high`, `critical`
- `createdAt`: Automático, timestamp de creación
- `updatedAt`: Automático, timestamp de última actualización

### 4. `board_members` - Miembros del Tablero

**Descripción**: Gestión de permisos y miembros de cada tablero.

**Estructura del documento**:
```json
{
  "members": {
    "user123": {
      "role": "string (owner | admin | member)",
      "joinedAt": "timestamp"
    }
  },
  "invitations": {
    "invite123": {
      "email": "string",
      "role": "string (admin | member)",
      "invitedBy": "string (UID)",
      "invitedAt": "timestamp",
      "expiresAt": "timestamp"
    }
  }
}
```

## Índices Recomendados

### Índices Compuestos

1. **Para consultas de épicas por tablero**:
   - Collection: `epics`
   - Fields: `boardId` (Ascending), `createdAt` (Descending)

2. **Para consultas de tareas por épica**:
   - Collection: `tasks`
   - Fields: `epicId` (Ascending), `status` (Ascending), `createdAt` (Descending)

3. **Para consultas de tareas por asignado**:
   - Collection: `tasks`
   - Fields: `assignedTo` (Ascending), `status` (Ascending), `dueDate` (Ascending)

4. **Para consultas de tareas por fecha de vencimiento**:
   - Collection: `tasks`
   - Fields: `dueDate` (Ascending), `priority` (Descending)

## Consultas Comunes

### Obtener todos los tableros de un usuario
```javascript
// Como propietario
const userBoards = await firebase.firestore()
  .collection('boards')
  .where('ownerId', '==', userId)
  .orderBy('createdAt', 'desc')
  .get();

// Como miembro
const memberBoards = await firebase.firestore()
  .collection('boards')
  .where('members', 'array-contains', userId)
  .orderBy('createdAt', 'desc')
  .get();
```

### Obtener épicas de un tablero
```javascript
const epics = await firebase.firestore()
  .collection('epics')
  .where('boardId', '==', boardId)
  .orderBy('createdAt', 'desc')
  .get();
```

### Obtener tareas de una épica
```javascript
const tasks = await firebase.firestore()
  .collection('tasks')
  .where('epicId', '==', epicId)
  .orderBy('status', 'asc')
  .orderBy('createdAt', 'desc')
  .get();
```

### Obtener tareas por estado
```javascript
const todoTasks = await firebase.firestore()
  .collection('tasks')
  .where('epicId', '==', epicId)
  .where('status', '==', 'todo')
  .orderBy('priority', 'desc')
  .orderBy('createdAt', 'asc')
  .get();
```

### Obtener tareas asignadas a un usuario
```javascript
const assignedTasks = await firebase.firestore()
  .collection('tasks')
  .where('assignedTo', '==', userId)
  .where('status', 'in', ['todo', 'in_progress'])
  .orderBy('dueDate', 'asc')
  .get();
```

## Consideraciones de Seguridad

1. **Autenticación**: Todas las operaciones requieren autenticación
2. **Propiedad**: Solo el propietario puede eliminar tableros
3. **Membresía**: Solo miembros pueden acceder a tableros
4. **Validación**: Todas las entradas se validan en las reglas de Firestore
5. **Integridad referencial**: Las reglas verifican la existencia de documentos padre

## Optimizaciones

1. **Índices**: Usar índices compuestos para consultas frecuentes
2. **Paginación**: Implementar paginación para grandes conjuntos de datos
3. **Caché**: Usar Firestore offline persistence para mejor UX
4. **Subcolecciones**: Considerar subcolecciones para datos muy relacionados
5. **Batch operations**: Usar operaciones en lote para múltiples actualizaciones

## Migración y Mantenimiento

1. **Backup**: Configurar backups automáticos
2. **Monitoreo**: Usar Firebase Analytics para monitorear uso
3. **Escalabilidad**: La estructura permite escalar horizontalmente
4. **Versionado**: Mantener versiones de esquemas para migraciones 