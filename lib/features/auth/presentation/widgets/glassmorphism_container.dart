import 'package:flutter/material.dart';
import 'dart:ui';

class GlassmorphismContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GlassmorphismContainer({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores dinámicos basados en el tema
    final defaultBackgroundColor = isDark
        ? Colors.grey[850]!.withOpacity(0.8) // Gris oscuro para tema oscuro
        : Colors.white.withOpacity(0.8); // Blanco para tema claro

    final borderColor = isDark
        ? Colors.grey[700]!
            .withOpacity(0.3) // Borde más oscuro para tema oscuro
        : Colors.grey[300]!.withOpacity(0.3); // Borde más claro para tema claro

    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? defaultBackgroundColor,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor,
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
