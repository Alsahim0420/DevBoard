import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import 'avatar_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/domain/entities/auth_credentials.dart';

class UserCreationDialog extends StatefulWidget {
  @override
  State<UserCreationDialog> createState() => _UserCreationDialogState();
}

class _UserCreationDialogState extends State<UserCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adminKeyController = TextEditingController();

  String? _selectedIcon = 'person';
  String? _selectedColor = 'blue';
  UserRole _selectedRole = UserRole.desarrollador;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _adminKeyController.dispose();
    super.dispose();
  }

  void _createUser() {
    if (_formKey.currentState!.validate()) {
      // Validar clave de admin si se intenta crear un admin
      if (_selectedRole == UserRole.admin) {
        if (_adminKeyController.text.trim() != '1401') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clave de administrador incorrecta'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Crear credenciales de autenticación
      final credentials = AuthCredentials(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _displayNameController.text.trim(),
        avatarIcon: _selectedIcon,
        avatarColor: _selectedColor,
        role: _selectedRole,
        adminKey: _selectedRole == UserRole.admin
            ? _adminKeyController.text.trim()
            : null,
      );

      // Usar AuthBloc para crear la cuenta
      context.read<AuthBloc>().add(SignUpRequested(credentials));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Usuario creado exitosamente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          // Error al crear usuario
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Dialog(
        backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.person_add,
                        color: Colors.blue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Crear Usuario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Display Name
                  TextFormField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre de Usuario',
                      hintText: 'Ej: Juan Pérez',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El nombre es requerido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Ej: juan@ejemplo.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El email es requerido';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                          .hasMatch(value.trim())) {
                        return 'Ingresa un email válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contraseña
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Mínimo 6 caracteres',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La contraseña es requerida';
                      }
                      if (value.length < 6) {
                        return 'La contraseña debe tener al menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Selection
                  DropdownButtonFormField<UserRole>(
                    value: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.work),
                    ),
                    items: UserRole.values.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_getRoleDisplayName(role)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecciona un rol';
                      }
                      return null;
                    },
                  ),

                  // Admin Key Field (conditional)
                  if (_selectedRole == UserRole.admin) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _adminKeyController,
                      decoration: InputDecoration(
                        labelText: 'Clave de Administrador',
                        hintText: 'Ingresa la clave especial',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.key),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (_selectedRole == UserRole.admin) {
                          if (value == null || value.trim().isEmpty) {
                            return 'La clave de administrador es requerida';
                          }
                          if (value.trim() != '1401') {
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
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700, size: 16),
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
                    const SizedBox(height: 16),
                  ],

                  // Avatar preview
                  Row(
                    children: [
                      Text(
                        'Avatar:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      AvatarWidget(
                        user: UserModel.create(
                          displayName: _displayNameController.text.isNotEmpty
                              ? _displayNameController.text
                              : 'Usuario',
                          email: '',
                          avatarIcon: _selectedIcon,
                          avatarColor: _selectedColor,
                          role: _selectedRole,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Icon selection
                  Text(
                    'Icono:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'person',
                      'business',
                      'school',
                      'code',
                      'design_services',
                      'engineering',
                      'science',
                      'psychology',
                      'manage_accounts',
                      'admin_panel_settings',
                      'support_agent',
                      'group',
                      'star',
                      'favorite',
                      'thumb_up',
                      'lightbulb',
                      'rocket_launch',
                      'trending_up',
                      'workspace_premium'
                    ].map((icon) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _selectedIcon == icon
                                ? Colors.blue.withOpacity(0.2)
                                : Colors.transparent,
                            border: Border.all(
                              color: _selectedIcon == icon
                                  ? Colors.blue
                                  : Colors.grey.shade300,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getIconData(icon),
                            size: 20,
                            color: _selectedIcon == icon
                                ? Colors.blue
                                : Colors.grey.shade600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color selection
                  Text(
                    'Color:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      'red',
                      'pink',
                      'purple',
                      'indigo',
                      'blue',
                      'cyan',
                      'teal',
                      'green',
                      'lightGreen',
                      'lime',
                      'yellow',
                      'amber',
                      'orange',
                      'deepOrange',
                      'brown',
                      'grey',
                      'blueGrey'
                    ].map((color) {
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _getColorFromName(color),
                            border: Border.all(
                              color: _selectedColor == color
                                  ? Colors.black
                                  : Colors.grey.shade300,
                              width: _selectedColor == color ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            return ElevatedButton(
                              onPressed:
                                  state is AuthLoading ? null : _createUser,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: state is AuthLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Crear Usuario',
                                      style: TextStyle(color: Colors.white),
                                    ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
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
      case 'business':
        return Icons.business;
      case 'school':
        return Icons.school;
      case 'code':
        return Icons.code;
      case 'design_services':
        return Icons.design_services;
      case 'engineering':
        return Icons.engineering;
      case 'science':
        return Icons.science;
      case 'psychology':
        return Icons.psychology;
      case 'manage_accounts':
        return Icons.manage_accounts;
      case 'admin_panel_settings':
        return Icons.admin_panel_settings;
      case 'support_agent':
        return Icons.support_agent;
      case 'group':
        return Icons.group;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'thumb_up':
        return Icons.thumb_up;
      case 'lightbulb':
        return Icons.lightbulb;
      case 'rocket_launch':
        return Icons.rocket_launch;
      case 'trending_up':
        return Icons.trending_up;
      case 'workspace_premium':
        return Icons.workspace_premium;
      default:
        return Icons.person;
    }
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'indigo':
        return Colors.indigo;
      case 'blue':
        return Colors.blue;
      case 'cyan':
        return Colors.cyan;
      case 'teal':
        return Colors.teal;
      case 'green':
        return Colors.green;
      case 'lightGreen':
        return Colors.lightGreen;
      case 'lime':
        return Colors.lime;
      case 'yellow':
        return Colors.yellow;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'deepOrange':
        return Colors.deepOrange;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      case 'blueGrey':
        return Colors.blueGrey;
      default:
        return Colors.blue;
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.lider:
        return 'Líder';
      case UserRole.desarrollador:
        return 'Desarrollador';
      case UserRole.qa:
        return 'QA';
      case UserRole.scrumMaster:
        return 'Scrum Master';
      case UserRole.admin:
        return 'Administrador';
    }
  }
}
