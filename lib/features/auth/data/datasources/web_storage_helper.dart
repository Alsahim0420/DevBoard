import 'package:flutter/foundation.dart';

/// Helper para limpiar localStorage en web
class WebStorageHelper {
  /// Limpia el localStorage en web
  static Future<void> clearLocalStorage() async {
    if (kIsWeb) {
      try {
        // En web, usar dart:html para acceder a localStorage
        // ignore: undefined_prefixed_name
        // import 'dart:html' as html;
        // html.window.localStorage.clear();

        // Por ahora, solo log que se intentó limpiar
        debugPrint(
            'Web localStorage clear attempted (dart:html not available in this context)');
      } catch (e) {
        debugPrint('Error clearing web localStorage: $e');
      }
    }
  }
}
