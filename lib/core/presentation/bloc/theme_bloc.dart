import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class LoadTheme extends ThemeEvent {}

// States
abstract class ThemeState {
  final ThemeMode themeMode;
  const ThemeState(this.themeMode);

  bool get isDarkMode => themeMode == ThemeMode.dark;
  bool get isSystemMode => themeMode == ThemeMode.system;
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.themeMode);
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(super.themeMode);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeBloc() : super(const ThemeInitial(ThemeMode.system)) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values[themeModeIndex];
    emit(ThemeLoaded(themeMode));
  }

  Future<void> _onToggleTheme(
      ToggleTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();

    // Cycle through: system -> light -> dark -> system
    ThemeMode newThemeMode;
    switch (state.themeMode) {
      case ThemeMode.system:
        newThemeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        newThemeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newThemeMode = ThemeMode.system;
        break;
    }

    await prefs.setInt(_themeKey, newThemeMode.index);
    emit(ThemeLoaded(newThemeMode));
  }
}
