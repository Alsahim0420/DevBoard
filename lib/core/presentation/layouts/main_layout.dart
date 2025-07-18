import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';
import '../bloc/theme_bloc.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final void Function(String route)? onSidebarTap;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onSidebarTap,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (isDesktop) {
          return Row(
            children: [
              _Sidebar(
                  currentRoute: widget.currentRoute,
                  onSidebarTap: widget.onSidebarTap),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(
                            0xFF121212) // Fondo oscuro para tema oscuro
                        : const Color(
                            0xFFF5F5F5), // Fondo claro para tema claro
                  ),
                  child: widget.child,
                ),
              ),
            ],
          );
        } else {
          return Scaffold(
            drawer: _Sidebar(
                currentRoute: widget.currentRoute,
                onSidebarTap: widget.onSidebarTap),
            body: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF121212) // Fondo oscuro para tema oscuro
                    : const Color(0xFFF5F5F5), // Fondo claro para tema claro
              ),
              child: widget.child,
            ),
          );
        }
      },
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentRoute;
  final void Function(String route)? onSidebarTap;

  const _Sidebar({required this.currentRoute, this.onSidebarTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E1E) // Gris muy oscuro para tema oscuro
            : const Color(0xFFF8F9FA), // Gris muy claro para tema claro
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              // Logo y nombre
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.dashboard,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'DevBoard',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[900],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),

              // // Botón Crear
              // Padding(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              //   child: SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton.icon(
              //       onPressed: () {
              //         // Navegar a la página de tableros y mostrar modal de creación
              //         Navigator.pushNamed(context, '/boards').then((_) {
              //           if (context.mounted) {
              //             context.read<ModalBloc>().add(ShowCreateBoardModal());
              //           }
              //         });
              //       },
              //       icon: Icon(Icons.add, color: theme.colorScheme.primary),
              //       label: Text('Crear',
              //           style: TextStyle(color: theme.colorScheme.primary)),
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor:
              //             theme.colorScheme.primary.withOpacity(0.12),
              //         padding: const EdgeInsets.symmetric(vertical: 12),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(8),
              //         ),
              //         elevation: 0,
              //       ),
              //     ),
              //   ),
              // ),

              const SizedBox(height: 16),

              // Navegación principal
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarSection(
                        title: 'Para ti',
                        items: [
                          _SidebarItem(
                            icon: Icons.star,
                            label: 'Recientes',
                            isSelected: currentRoute == '/recent',
                            onTap: () => onSidebarTap?.call('/recent'),
                          ),
                          _SidebarItem(
                            icon: Icons.favorite,
                            label: 'Marcados como favoritos',
                            isSelected: currentRoute == '/favorites',
                            onTap: () => onSidebarTap?.call('/favorites'),
                          ),
                        ],
                      ),
                      _SidebarSection(
                        title: 'Aplicaciones',
                        items: [
                          _SidebarItem(
                            icon: Icons.dashboard,
                            label: 'Proyectos',
                            isSelected: currentRoute == '/projects',
                            onTap: () => onSidebarTap?.call('/projects'),
                          ),
                        ],
                      ),
                      _SidebarSection(
                        title: 'Marcados como favoritas',
                        items: [
                          _SidebarItem(
                            icon: Icons.folder,
                            label: 'Mis Tableros',
                            isSelected: currentRoute == '/boards',
                            onTap: () => onSidebarTap?.call('/boards'),
                          ),
                          _SidebarItem(
                            icon: Icons.list_alt,
                            label: 'Backlog',
                            isSelected: currentRoute == '/backlog',
                            onTap: () => onSidebarTap?.call('/backlog'),
                          ),
                          _SidebarItem(
                            icon: Icons.dashboard,
                            label: 'Dashboard',
                            isSelected: currentRoute == '/home',
                            onTap: () => onSidebarTap?.call('/home'),
                          ),
                        ],
                      ),
                      _SidebarSection(
                        title: 'Herramientas',
                        items: [
                          _SidebarItem(
                            icon: Icons.view_kanban,
                            label: 'Paneles',
                            isSelected: currentRoute == '/panels',
                            onTap: () => onSidebarTap?.call('/panels'),
                          ),
                          // _SidebarItem(
                          //   icon: Icons.people,
                          //   label: 'Equipos',
                          //   isSelected: false,
                          //   onTap: () {},
                          // ),
                          _SidebarItem(
                            icon: Icons.track_changes,
                            label: 'Metas',
                            isSelected: currentRoute == '/goals',
                            onTap: () => onSidebarTap?.call('/goals'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),

              // Configuración y cerrar sesión
              Column(
                children: [
                  // Switch de tema personalizado
                  _ThemeSwitchItem(),
                  // _SidebarItem(
                  //   icon: Icons.settings,
                  //   label: 'Configuración',
                  //   isSelected: false,
                  //   onTap: () {},
                  // ),
                  _SidebarItem(
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    isSelected: false,
                    onTap: () {
                      context.read<AuthBloc>().add(SignOutRequested());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String title;
  final List<_SidebarItem> items;

  const _SidebarSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          size: 20,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (isDark ? Colors.white : Colors.black),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        hoverColor:
            isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

class _ThemeSwitchItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, themeState) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            leading: Icon(
              themeState.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              size: 20,
            ),
            title: Text(
              'Tema ${themeState.isDarkMode ? 'Oscuro' : 'Claro'}',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
            ),
            trailing: Container(
              width: 48,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: themeState.isDarkMode
                      ? [
                          Colors.purple.shade400,
                          Colors.purple.shade600,
                        ]
                      : [
                          Colors.orange.shade300,
                          Colors.orange.shade500,
                        ],
                ),
              ),
              child: Stack(
                children: [
                  // Switch track
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                  // Switch thumb
                  AnimatedAlign(
                    alignment: themeState.isDarkMode
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              context.read<ThemeBloc>().add(ToggleTheme());
            },
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            selected: false,
            selectedTileColor: Colors.transparent,
            hoverColor:
                isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
            dense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
        );
      },
    );
  }
}
