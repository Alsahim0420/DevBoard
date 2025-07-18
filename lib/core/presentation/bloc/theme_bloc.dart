import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class LoadTheme extends ThemeEvent {}

// States
abstract class ThemeState {
  final bool isDarkMode;
  const ThemeState(this.isDarkMode);
}

class ThemeInitial extends ThemeState {
  const ThemeInitial(super.isDarkMode);
}

class ThemeLoaded extends ThemeState {
  const ThemeLoaded(super.isDarkMode);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String _themeKey = 'theme_mode';

  ThemeBloc() : super(const ThemeInitial(false)) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;
    emit(ThemeLoaded(isDarkMode));
  }

  Future<void> _onToggleTheme(
      ToggleTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final newIsDarkMode = !state.isDarkMode;
    await prefs.setBool(_themeKey, newIsDarkMode);
    emit(ThemeLoaded(newIsDarkMode));
  }
}
