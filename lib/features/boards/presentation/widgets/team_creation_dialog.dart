import 'package:flutter/material.dart';
import '../../data/models/team_model.dart';
import '../../data/models/user_model.dart';
import 'avatar_widget.dart';

class TeamCreationDialog extends StatefulWidget {
  final List<UserModel> users;

  const TeamCreationDialog({
    super.key,
    required this.users,
  });

  @override
  State<TeamCreationDialog> createState() => _TeamCreationDialogState();
}

class _TeamCreationDialogState extends State<TeamCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  List<String> _selectedMemberIds = [];
  String _selectedOwnerId = '';

  @override
  void initState() {
    super.initState();
    // Seleccionar el primer usuario como propietario por defecto
    if (widget.users.isNotEmpty) {
      _selectedOwnerId = widget.users.first.id;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _createTeam() {
    if (_formKey.currentState!.validate()) {
      final team = TeamModel.create(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        ownerId: _selectedOwnerId,
        memberUserIds: _selectedMemberIds,
      );

      Navigator.of(context).pop(team);
    }
  }

  void _toggleMember(String userId) {
    setState(() {
      // No permitir deseleccionar al propietario como miembro
      if (userId == _selectedOwnerId && _selectedMemberIds.contains(userId)) {
        return; // El propietario siempre debe ser miembro
      }

      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.group_add,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Crear Team',
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
                      color:
                          isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nombre del team
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del team',
                    hintText: 'Ej: Equipo Frontend',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    if (value.trim().length < 2) {
                      return 'El nombre debe tener al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Descripción
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Descripción del equipo...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Propietario del team
                DropdownButtonFormField<String>(
                  value: _selectedOwnerId.isEmpty ? null : _selectedOwnerId,
                  decoration: InputDecoration(
                    labelText: 'Propietario del team',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  items: widget.users.map((user) {
                    return DropdownMenuItem(
                      value: user.id,
                      child: SizedBox(
                        width:
                            200, // Ancho específico para evitar el error de constraints
                        child: Row(
                          children: [
                            AvatarWidget(
                              user: user,
                              radius: 12,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedOwnerId = value;
                        // Agregar automáticamente el propietario como miembro si no está ya seleccionado
                        if (!_selectedMemberIds.contains(value)) {
                          _selectedMemberIds.add(value);
                        }
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona un propietario';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Miembros del team
                Text(
                  'Miembros del team (${_selectedMemberIds.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Lista de usuarios para seleccionar
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: widget.users.isEmpty
                      ? Center(
                          child: Text(
                            'No hay usuarios disponibles',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: widget.users.length,
                          itemBuilder: (context, index) {
                            final user = widget.users[index];
                            final isSelected =
                                _selectedMemberIds.contains(user.id);
                            final isOwner = user.id == _selectedOwnerId;

                            return CheckboxListTile(
                              value: isSelected,
                              onChanged: (value) => _toggleMember(user
                                  .id), // El propietario también puede ser miembro
                              title: SizedBox(
                                width: double
                                    .infinity, // Usar todo el ancho disponible
                                child: Row(
                                  children: [
                                    AvatarWidget(
                                      user: user,
                                      radius: 12,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        user.displayName,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isOwner)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Propietario',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              subtitle: Text(
                                user.email,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // Botones
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
                      child: ElevatedButton(
                        onPressed: _createTeam,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Crear Team',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
