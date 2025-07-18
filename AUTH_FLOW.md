# Flujo de Autenticación - DevBoard

## Arquitectura de Autenticación

La aplicación implementa un flujo de autenticación limpio y bien estructurado usando Clean Architecture y BLoC, con los siguientes componentes:

### 1. AuthGate (`lib/core/presentation/widgets/auth_gate.dart`)

**Propósito**: Verifica el estado inicial de autenticación al abrir la app.

**Funcionalidad**:
- Usa `FirebaseAuth.instance.authStateChanges()` para detectar cambios en tiempo real
- Muestra una pantalla de loading mientras verifica el estado
- Redirige automáticamente:
  - Si hay usuario autenticado → `HomeScreen`
  - Si no hay usuario → `LoginScreen`

**Características**:
- ✅ Verificación inicial al abrir la app
- ✅ Loading state mientras verifica
- ✅ Navegación automática basada en estado
- ✅ Integración con BLoC para notificar cambios

### 2. AuthListener (`lib/core/presentation/widgets/auth_listener.dart`)

**Propósito**: Maneja la navegación automática cuando cambia el estado de autenticación.

**Funcionalidad**:
- Escucha cambios en el estado del BLoC
- Navega automáticamente:
  - `Authenticated` → `HomeScreen`
  - `Unauthenticated` → `LoginScreen`

**Características**:
- ✅ Navegación automática en tiempo real
- ✅ Separación de responsabilidades
- ✅ Integración con BLoC

### 3. Flujo Completo

```
App Inicia
    ↓
AuthGate verifica estado inicial
    ↓
┌─────────────────┬─────────────────┐
│ Usuario existe  │ No hay usuario  │
│     ↓           │       ↓         │
│ HomeScreen      │  LoginScreen    │
└─────────────────┴─────────────────┘
    ↓
AuthListener escucha cambios
    ↓
┌─────────────────┬─────────────────┐
│ Login/Register  │   Logout        │
│     ↓           │       ↓         │
│ HomeScreen      │  LoginScreen    │
└─────────────────┴─────────────────┘
```

### 4. Integración en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
      ],
      child: AuthListener(
        child: MaterialApp(
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomePage(),
          },
        ),
      ),
    );
  }
}
```

### 5. Ventajas de esta Implementación

#### ✅ **Separación de Responsabilidades**
- `AuthGate`: Verificación inicial
- `AuthListener`: Navegación automática
- `BLoC`: Gestión de estado
- `FirebaseAuth`: Fuente de verdad

#### ✅ **Clean Architecture**
- Presentación: AuthGate, AuthListener
- Dominio: BLoC, Estados, Eventos
- Datos: FirebaseAuth, Repositorio

#### ✅ **Experiencia de Usuario**
- Verificación instantánea al abrir la app
- Navegación automática sin interrupciones
- Loading states apropiados
- Manejo de errores centralizado

#### ✅ **Mantenibilidad**
- Código modular y reutilizable
- Fácil de testear
- Fácil de extender

### 6. Casos de Uso

#### **Usuario Nuevo**
1. Abre la app → `AuthGate` detecta no autenticado
2. Redirige a `LoginScreen`
3. Usuario se registra → `AuthListener` detecta cambio
4. Redirige automáticamente a `HomeScreen`

#### **Usuario Existente**
1. Abre la app → `AuthGate` detecta autenticado
2. Redirige directamente a `HomeScreen`
3. Usuario hace logout → `AuthListener` detecta cambio
4. Redirige automáticamente a `LoginScreen`

#### **Cambio de Estado en Tiempo Real**
- Si el token expira → Navegación automática a login
- Si se autentica en otra pestaña → Navegación automática a home
- Si hay errores de red → Manejo centralizado

### 7. Configuración Requerida

Para que funcione correctamente, asegúrate de:

1. **Firebase configurado** en `main.dart`
2. **Inyección de dependencias** inicializada
3. **BLoC registrado** en el contenedor de DI
4. **Rutas definidas** en MaterialApp

### 8. Próximos Pasos

- [ ] Agregar persistencia local para estado offline
- [ ] Implementar refresh tokens
- [ ] Agregar biometría
- [ ] Implementar multi-factor authentication
- [ ] Agregar analytics de autenticación 