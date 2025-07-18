# DevBoard - Flutter Firebase Authentication

Una aplicación Flutter moderna con Firebase Authentication implementada usando Clean Architecture y BLoC como gestor de estado.

## 🏗️ Arquitectura

La aplicación sigue los principios de **Clean Architecture** con las siguientes capas:

- **Domain Layer**: Entidades, repositorios abstractos y casos de uso
- **Data Layer**: Implementaciones de repositorios, modelos y fuentes de datos
- **Presentation Layer**: BLoC, páginas y widgets

## 📦 Dependencias

- `firebase_core: ^2.24.2` - Inicialización de Firebase
- `firebase_auth: ^4.15.3` - Autenticación con Firebase
- `flutter_bloc: ^8.1.3` - Gestión de estado con BLoC
- `equatable: ^2.0.5` - Comparación de objetos
- `get_it: ^7.6.4` - Inyección de dependencias

## 🚀 Configuración de Firebase

### 1. Crear proyecto en Firebase Console

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita Authentication con Email/Password

### 2. Configurar Android

1. En Firebase Console, ve a Project Settings > General
2. Descarga el archivo `google-services.json`
3. Colócalo en `android/app/google-services.json`

4. Actualiza `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

5. Actualiza `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

### 3. Configurar iOS

1. En Firebase Console, descarga `GoogleService-Info.plist`
2. Colócalo en `ios/Runner/GoogleService-Info.plist`
3. Agrega el archivo a Xcode (arrastra y suelta en Runner)

### 4. Configurar Web

1. En Firebase Console, ve a Project Settings > General
2. En la sección "Your apps", agrega una app web
3. Copia la configuración y agrégalo a `web/index.html`:

```html
<script type="module">
  import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-app.js'
  import { getAuth } from 'https://www.gstatic.com/firebasejs/10.7.1/firebase-auth.js'

  const firebaseConfig = {
    // Tu configuración aquí
  };

  const app = initializeApp(firebaseConfig);
  const auth = getAuth(app);
</script>
```

## 🎨 Características

### Autenticación
- ✅ Registro con email y contraseña
- ✅ Inicio de sesión con email y contraseña
- ✅ Cerrar sesión
- ✅ Verificación de estado de autenticación
- ✅ Manejo de errores en español

### UI/UX
- ✅ Diseño moderno con Material 3
- ✅ Efectos de glassmorphism
- ✅ Gradientes y transparencias
- ✅ Responsive design
- ✅ Loading states
- ✅ Validación de formularios

### Arquitectura
- ✅ Clean Architecture completa
- ✅ Separación de responsabilidades
- ✅ Inyección de dependencias
- ✅ BLoC para gestión de estado
- ✅ Manejo de errores centralizado

## 📁 Estructura del Proyecto

```
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart
│   ├── errors/
│   └── utils/
├── features/
│   └── auth/
│       ├── data/
│       │   ├── datasources/
│       │   │   └── auth_remote_datasource.dart
│       │   ├── models/
│       │   │   └── user_model.dart
│       │   └── repositories/
│       │       └── auth_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── auth_credentials.dart
│       │   │   └── user_entity.dart
│       │   ├── repositories/
│       │   │   └── auth_repository.dart
│       │   └── usecases/
│       │       ├── get_current_user_usecase.dart
│       │       ├── sign_in_usecase.dart
│       │       ├── sign_out_usecase.dart
│       │       └── sign_up_usecase.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── auth_bloc.dart
│           │   ├── auth_event.dart
│           │   └── auth_state.dart
│           ├── pages/
│           │   ├── home_page.dart
│           │   ├── login_page.dart
│           │   └── register_page.dart
│           └── widgets/
│               └── glassmorphism_container.dart
└── main.dart
```

## 🏃‍♂️ Ejecutar el Proyecto

1. Instala las dependencias:
```bash
flutter pub get
```

2. Configura Firebase (ver sección de configuración)

3. Ejecuta la aplicación:
```bash
flutter run
```

## 🔧 Funcionalidades Implementadas

### AuthService (implementado como AuthRepository)
- ✅ `signIn(String email, String password)`
- ✅ `signUp(String email, String password)`
- ✅ `signOut()`
- ✅ `currentUser()`

### Características Adicionales
- ✅ Stream de cambios de estado de autenticación
- ✅ Manejo de errores en español
- ✅ Validación de formularios
- ✅ UI moderna con glassmorphism
- ✅ Navegación automática basada en estado de auth

## 🎯 Próximos Pasos

- [ ] Agregar más métodos de autenticación (Google, Apple, etc.)
- [ ] Implementar recuperación de contraseña
- [ ] Agregar verificación de email
- [ ] Implementar persistencia local
- [ ] Agregar tests unitarios y de widgets
- [ ] Implementar tema oscuro
- [ ] Agregar animaciones de transición

## 📝 Notas

- La aplicación usa las últimas versiones de Firebase y Flutter
- Implementa Clean Architecture completa con separación clara de capas
- Usa BLoC para gestión de estado de forma reactiva
- Incluye efectos visuales modernos con glassmorphism
- Manejo de errores en español para mejor UX
