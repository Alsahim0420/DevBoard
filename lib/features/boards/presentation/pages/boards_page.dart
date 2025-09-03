// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/widgets/glassmorphism_container.dart';
import '../../data/models/board_model.dart';
import '../../data/datasources/boards_remote_datasource.dart';
import 'board_screen.dart';
import '../../../../core/presentation/bloc/theme_bloc.dart';
import '../../../../core/presentation/bloc/modal_bloc.dart';

class BoardsPage extends StatefulWidget {
  const BoardsPage({super.key});

  @override
  State<BoardsPage> createState() => _BoardsPageState();
}

class _BoardsPageState extends State<BoardsPage> {
  final BoardsRemoteDataSource _dataSource = BoardsRemoteDataSource();
  final TextEditingController _boardNameController = TextEditingController();
  final TextEditingController _boardDescriptionController =
      TextEditingController();

  List<BoardModel> _boards = [];
  bool _isLoading = false;
  bool _showCreateModal = false;
  bool _isInitialLoading = true; // Nuevo estado para carga inicial

  @override
  void initState() {
    super.initState();
    _loadBoards();
  }

  void _loadBoards() {
    final user = context.read<AuthBloc>().state;
    if (user is Authenticated) {
      debugPrint('Loading boards for user: ${user.user.id}');
      _dataSource.getUserBoards(user.user.id).listen(
        (boards) {
          debugPrint('Loaded ${boards.length} boards');
          if (mounted) {
            setState(() {
              _boards = boards;
              _isInitialLoading = false; // Marcar como cargado
            });
          }
        },
        onError: (error) {
          debugPrint('Error loading boards: $error');
          // Solo mostrar error si el widget está montado y el contexto es válido
          if (mounted && context.mounted) {
            setState(() {
              _isInitialLoading = false; // Marcar como cargado incluso en error
            });
            try {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error cargando tableros: ${error.toString().split(':').last.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            } catch (e) {
              debugPrint('Error showing snackbar: $e');
            }
          }
        },
      );
    }
  }

  Future<void> _createBoard() async {
    if (_boardNameController.text.trim().isEmpty) return;

    try {
      setState(() => _isLoading = true);

      final user = context.read<AuthBloc>().state;
      if (user is Authenticated) {
        final board = BoardModel.create(
          name: _boardNameController.text.trim(),
          ownerId: user.user.id,
        );

        await _dataSource.createBoard(board);

        if (mounted) {
          _boardNameController.clear();
          _boardDescriptionController.clear();
          setState(() => _showCreateModal = false);
          // Ocultar el modal en el bloc también
          context.read<ModalBloc>().add(HideCreateBoardModal());

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Tablero creado exitosamente'),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error creating board: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Error creando tablero: $e'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCreateBoardModal() {
    setState(() => _showCreateModal = true);
  }

  void _hideCreateBoardModal() {
    setState(() => _showCreateModal = false);
    _boardNameController.clear();
    _boardDescriptionController.clear();
    // Ocultar el modal en el bloc también
    context.read<ModalBloc>().add(HideCreateBoardModal());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return BlocListener<ModalBloc, ModalState>(
                listener: (context, modalState) {
                  if (modalState.showCreateBoardModal && !_showCreateModal) {
                    setState(() {
                      _showCreateModal = true;
                    });
                  }
                },
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(user: state.user),
                            const SizedBox(height: 24),
                            Expanded(
                              child: GlassmorphismContainer(
                                borderRadius: 24,
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Mis Tableros',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const Spacer(),
                                        ElevatedButton.icon(
                                          onPressed: _showCreateBoardModal,
                                          icon: const Icon(Icons.add),
                                          label: const Text('Crear Tablero'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Expanded(
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final isDesktop =
                                              constraints.maxWidth > 900;

                                          // Mostrar indicador de carga durante la carga inicial
                                          if (_isInitialLoading) {
                                            return _buildLoadingState();
                                          }

                                          return _boards.isEmpty
                                              ? _buildEmptyState()
                                              : _buildBoardsGrid(isDesktop);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showCreateModal) _buildCreateBoardModal(),
                    ],
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando tableros...',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Espera mientras cargamos tus tableros',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.dashboard,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No tienes tableros aún',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primer tablero para comenzar a organizar tus proyectos',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showCreateBoardModal,
            icon: const Icon(Icons.add),
            label: const Text('Crear Primer Tablero'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardsGrid(bool isDesktop) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 2,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: 1.2,
      ),
      itemCount: _boards.length,
      itemBuilder: (context, index) {
        final board = _boards[index];
        final user = context.read<AuthBloc>().state;
        final userId = user is Authenticated ? user.user.id : null;

        return _BoardCard(
          board: board,
          currentUserId: userId,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoardScreen(
                  boardId: board.id,
                  boardName: board.name,
                ),
              ),
            );
          },
          onFavoriteToggle: () async {
            try {
              if (user is Authenticated) {
                if (board.isFavoritedBy(user.user.id)) {
                  await _dataSource.unmarkBoardAsFavorite(
                      board.id, user.user.id);
                } else {
                  await _dataSource.markBoardAsFavorite(board.id, user.user.id);
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _boardNameController.dispose();
    _boardDescriptionController.dispose();
    super.dispose();
  }

  Widget _buildCreateBoardModal() {
    final isDark = context.read<ThemeBloc>().state.isDarkMode;
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 500),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.add,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Crear Nuevo Tablero',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade600,
                        ),
                        onPressed: _hideCreateBoardModal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _boardNameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Tablero',
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                      hintText: 'Ej: Proyecto Web',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      prefixIcon: Icon(
                        Icons.dashboard,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _boardDescriptionController,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      labelStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade300
                            : Colors.grey.shade600,
                      ),
                      hintText: 'Describe el propósito del tablero',
                      hintStyle: TextStyle(
                        color: isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      filled: true,
                      fillColor:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade50,
                      prefixIcon: Icon(
                        Icons.description,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _hideCreateBoardModal,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createBoard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('Crear Tablero'),
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
}

class _BoardCard extends StatefulWidget {
  final BoardModel board;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final String? currentUserId;

  const _BoardCard({
    required this.board,
    required this.onTap,
    this.onFavoriteToggle,
    this.currentUserId,
  });

  @override
  State<_BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<_BoardCard>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _scale = 1.04),
      onExit: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: GlassmorphismContainer(
          borderRadius: 18,
          blur: 16,
          backgroundColor: isDark
              ? Colors.blue.withOpacity(0.25) // Más intenso en tema oscuro
              : Colors.blue.withOpacity(0.08),
          padding: const EdgeInsets.all(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: widget.onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.dashboard,
                        size: 32,
                        color: Colors.blue,
                      ),
                      const Spacer(),
                      if (widget.onFavoriteToggle != null)
                        IconButton(
                          icon: Icon(
                            widget.currentUserId != null &&
                                    widget.board
                                        .isFavoritedBy(widget.currentUserId!)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.currentUserId != null &&
                                    widget.board
                                        .isFavoritedBy(widget.currentUserId!)
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: widget.onFavoriteToggle,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.board.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tablero de proyecto',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.board.members.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Creado ${_formatDate(widget.board.createdAt)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade400,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) return 'hoy';
    if (difference == 1) return 'ayer';
    if (difference < 7) return 'hace $difference días';
    if (difference < 30) return 'hace ${(difference / 7).round()} semanas';
    return 'hace ${(difference / 30).round()} meses';
  }
}

class _Header extends StatelessWidget {
  final dynamic user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GlassmorphismContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(28),
      backgroundColor: isDark
          ? Colors.grey[800]!
              .withOpacity(0.8) // Fondo más oscuro para tema oscuro
          : Colors.white.withOpacity(0.8), // Fondo claro para tema claro
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
            child: Text(
              user.email[0].toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Tableros',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  user.email,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
