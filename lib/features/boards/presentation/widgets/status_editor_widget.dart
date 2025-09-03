import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

class StatusEditorWidget extends StatefulWidget {
  final List<BoardStatus> currentStatuses;
  final Function(List<BoardStatus>) onStatusesChanged;

  const StatusEditorWidget({
    super.key,
    required this.currentStatuses,
    required this.onStatusesChanged,
  });

  @override
  State<StatusEditorWidget> createState() => _StatusEditorWidgetState();
}

class _StatusEditorWidgetState extends State<StatusEditorWidget> {
  final TextEditingController _newStatusController = TextEditingController();
  late List<BoardStatus> _currentStatuses;
  final List<Color> _availableColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _currentStatuses = List<BoardStatus>.from(widget.currentStatuses);
  }

  @override
  void didUpdateWidget(StatusEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentStatuses != widget.currentStatuses) {
      setState(() {
        _currentStatuses = List<BoardStatus>.from(widget.currentStatuses);
      });
    }
  }

  @override
  void dispose() {
    _newStatusController.dispose();
    super.dispose();
  }

  void _addNewStatus() {
    if (_newStatusController.text.trim().isEmpty) return;

    final newStatus = BoardStatus(
      _newStatusController.text.trim(),
      _newStatusController.text
          .trim()
          .toLowerCase()
          .replaceAll(' ', '_'), // Usar el nombre como estado
      _availableColors.first,
    );

    setState(() {
      _currentStatuses.add(newStatus);
    });

    widget.onStatusesChanged(_currentStatuses);
    _newStatusController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('Estado "${newStatus.name}" agregado'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _removeStatus(int index) {
    if (_currentStatuses.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Text('Debe mantener al menos 3 estados'),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final statusToRemove = _currentStatuses[index];
    setState(() {
      _currentStatuses.removeAt(index);
    });

    widget.onStatusesChanged(_currentStatuses);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: Colors.white),
              const SizedBox(width: 8),
              Text('Estado "${statusToRemove.name}" eliminado'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _changeStatusColor(int index, Color newColor) {
    final status = _currentStatuses[index];
    final updatedStatus = BoardStatus(status.name, status.status, newColor);

    setState(() {
      _currentStatuses[index] = updatedStatus;
    });

    widget.onStatusesChanged(_currentStatuses);
  }

  void _reorderStatus(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _currentStatuses.removeAt(oldIndex);
      _currentStatuses.insert(newIndex, item);
    });

    widget.onStatusesChanged(_currentStatuses);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.swap_horiz, color: Colors.white),
              SizedBox(width: 8),
              Text('Orden de estados actualizado'),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        // Usar el tema actual del contexto para detectar si es oscuro
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.purple.shade900
                            : Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.settings,
                        color: isDark
                            ? Colors.purple.shade300
                            : Colors.purple.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Configurar Estados',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.grey.shade800,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Estados actuales
                Text(
                  'Estados actuales:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 300, // Altura fija para el área de drag & drop
                  child: DragAndDropLists(
                    children: _currentStatuses.asMap().entries.map((entry) {
                      final index = entry.key;
                      final status = entry.value;

                      return DragAndDropList(
                        header: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? status.color.withOpacity(0.2)
                                : status.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: isDark
                                    ? status.color.withOpacity(0.5)
                                    : status.color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              // Icono de arrastre
                              Icon(
                                Icons.drag_handle,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: status.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  status.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: status.color,
                                  ),
                                ),
                              ),
                              // Selector de color
                              PopupMenuButton<Color>(
                                icon: Icon(
                                  Icons.palette,
                                  color: status.color,
                                  size: 20,
                                ),
                                itemBuilder: (context) => _availableColors
                                    .map((color) => PopupMenuItem<Color>(
                                          value: color,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 16,
                                                height: 16,
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.grey.shade600
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Color',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onSelected: (color) =>
                                    _changeStatusColor(index, color),
                              ),
                              // Botón eliminar
                              if (_currentStatuses.length > 3)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: Colors.red.shade400,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeStatus(index),
                                ),
                            ],
                          ),
                        ),
                        children: const [], // No hay elementos hijos, solo el header
                      );
                    }).toList(),
                    onItemReorder: (int oldItemIndex, int oldListIndex,
                        int newItemIndex, int newListIndex) {
                      _reorderStatus(oldItemIndex, newItemIndex);
                    },
                    onListReorder: (int oldListIndex, int newListIndex) {
                      _reorderStatus(oldListIndex, newListIndex);
                    },
                    axis: Axis.vertical,
                    listWidth: double.infinity,
                    listPadding: EdgeInsets.zero,
                    itemDivider: const SizedBox(height: 8),
                  ),
                ),

                const SizedBox(height: 20),

                // Agregar nuevo estado
                Text(
                  'Agregar nuevo estado:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newStatusController,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nombre del nuevo estado',
                          hintStyle: TextStyle(
                            color: isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isDark
                                  ? Colors.purple.shade300
                                  : Colors.purple.shade600,
                            ),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _addNewStatus,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Agregar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.blue.shade900.withOpacity(0.3)
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isDark
                            ? Colors.blue.shade600
                            : Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark
                            ? Colors.blue.shade300
                            : Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Arrastra los estados para cambiar su orden en el tablero. También puedes arrastrar tareas entre columnas para cambiar su estado.',
                          style: TextStyle(
                            color: isDark
                                ? Colors.blue.shade200
                                : Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class BoardStatus {
  final String name;
  final String
      status; // Cambiado de TaskStatus a String para soportar estados personalizados
  final Color color;

  BoardStatus(this.name, this.status, this.color);
}
