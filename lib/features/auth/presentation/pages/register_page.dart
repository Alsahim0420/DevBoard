import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../domain/entities/auth_credentials.dart';
import '../widgets/glassmorphism_container.dart';
import '../../../boards/presentation/widgets/avatar_widget.dart';
import '../../../boards/data/models/user_model.dart' as board_user_model;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Avatar selection
  String _selectedIcon = 'person';
  String _selectedColor = 'blue';

  // Role selection
  board_user_model.UserRole _selectedRole =
      board_user_model.UserRole.desarrollador;
  final _adminKeyController = TextEditingController();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _adminKeyController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      final credentials = AuthCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        avatarIcon: _selectedIcon,
        avatarColor: _selectedColor,
        role: _selectedRole,
        adminKey: _selectedRole == board_user_model.UserRole.admin
            ? _adminKeyController.text.trim()
            : null,
      );
      context.read<AuthBloc>().add(SignUpRequested(credentials));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassmorphismContainer(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_add_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Crear Cuenta',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _displayNameController,
                          decoration: InputDecoration(
                            labelText: 'Nombre de usuario',
                            prefixIcon: const Icon(Icons.person_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu nombre';
                            }
                            if (value.trim().length < 2) {
                              return 'El nombre debe tener al menos 2 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Avatar Selection
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona tu avatar',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              // Avatar Preview
                              Center(
                                child: AvatarWidget(
                                  user: board_user_model.UserModel(
                                    id: '',
                                    displayName:
                                        _displayNameController.text.isNotEmpty
                                            ? _displayNameController.text
                                            : 'Usuario',
                                    email: '',
                                    avatarIcon: _selectedIcon,
                                    avatarColor: _selectedColor,
                                    role: _selectedRole,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  ),
                                  radius: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Icon Selector
                              Text(
                                'Icono:',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  'person',
                                  'work',
                                  'star',
                                  'favorite',
                                  'home',
                                  'school',
                                  'sports',
                                  'music',
                                  'movie',
                                  'gamepad',
                                  'computer',
                                  'phone',
                                  'camera',
                                  'palette',
                                  'book',
                                  'lightbulb',
                                  'rocket',
                                  'pets',
                                  'nature'
                                ]
                                    .map((icon) => GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedIcon = icon),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: _selectedIcon == icon
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getIconData(icon),
                                              color: _selectedIcon == icon
                                                  ? Colors.white
                                                  : Colors.grey.shade600,
                                              size: 20,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 16),
                              // Color Selector
                              Text(
                                'Color:',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  'blue',
                                  'green',
                                  'purple',
                                  'orange',
                                  'red',
                                  'pink',
                                  'teal',
                                  'indigo',
                                  'brown',
                                  'grey',
                                  'cyan',
                                  'lime',
                                  'amber',
                                  'deepOrange',
                                  'deepPurple',
                                  'lightBlue',
                                  'lightGreen'
                                ]
                                    .map((color) => GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedColor = color),
                                          child: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _getColorFromName(color),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: _selectedColor == color
                                                  ? Border.all(
                                                      color: Colors.black,
                                                      width: 2)
                                                  : null,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Role Selection
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selecciona tu rol',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<
                                  board_user_model.UserRole>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Rol',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: board_user_model.UserRole.values
                                    .map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(_getRoleDisplayName(role)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedRole = value;
                                    });
                                  }
                                },
                              ),
                              if (_selectedRole ==
                                  board_user_model.UserRole.admin) ...[
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _adminKeyController,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    labelText: 'Clave de Administrador',
                                    hintText: 'Ingresa la clave de 4 dígitos',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_selectedRole ==
                                        board_user_model.UserRole.admin) {
                                      if (value == null || value.isEmpty) {
                                        return 'La clave de administrador es requerida';
                                      }
                                      if (value != '1401') {
                                        return 'Clave de administrador incorrecta';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.orange.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.orange.shade700,
                                          size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Para crear un usuario Admin necesitas la clave especial',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Por favor ingresa un email válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa una contraseña';
                            }
                            if (value.length < 6) {
                              return 'La contraseña debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          decoration: InputDecoration(
                            labelText: 'Confirmar Contraseña',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isConfirmPasswordVisible =
                                      !_isConfirmPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor confirma tu contraseña';
                            }
                            if (value != _passwordController.text) {
                              return 'Las contraseñas no coinciden';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    state is AuthLoading ? null : _signUp,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: state is AuthLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Crear Cuenta',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'work':
        return Icons.work;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'home':
        return Icons.home;
      case 'school':
        return Icons.school;
      case 'sports':
        return Icons.sports;
      case 'music':
        return Icons.music_note;
      case 'movie':
        return Icons.movie;
      case 'gamepad':
        return Icons.sports_esports;
      case 'computer':
        return Icons.computer;
      case 'phone':
        return Icons.phone;
      case 'camera':
        return Icons.camera_alt;
      case 'palette':
        return Icons.palette;
      case 'book':
        return Icons.book;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'rocket':
        return Icons.rocket_launch;
      case 'pets':
        return Icons.pets;
      case 'nature':
        return Icons.nature;
      default:
        return Icons.person;
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'amber':
        return Colors.amber;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'deepPurple':
        return Colors.deepPurple;
      case 'lightBlue':
        return Colors.lightBlue;
      case 'lightGreen':
        return Colors.lightGreen;
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(board_user_model.UserRole role) {
    switch (role) {
      case board_user_model.UserRole.lider:
        return 'Líder';
      case board_user_model.UserRole.desarrollador:
        return 'Desarrollador';
      case board_user_model.UserRole.qa:
        return 'QA';
      case board_user_model.UserRole.scrumMaster:
        return 'Scrum Master';
      case board_user_model.UserRole.admin:
        return 'Admin';
    }
  }
}
