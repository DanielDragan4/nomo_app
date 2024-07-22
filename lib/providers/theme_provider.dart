import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('theme_mode');

  if (themeModeIndex == null) {
    const systemThemeMode = ThemeMode.system;

    await prefs.setInt('theme_mode', systemThemeMode.index);

    return systemThemeMode;
  }

  return ThemeMode.values[themeModeIndex];
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) {
    final initialThemeMode = ref.watch(initialThemeModeProvider).maybeWhen(
          data: (themeMode) => themeMode,
          orElse: () => ThemeMode.system,
        );
    return ThemeModeNotifier(initialThemeMode);
  },
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initialMode) : super(initialMode);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', mode.index);
  }
}
