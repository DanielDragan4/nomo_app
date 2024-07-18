import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('theme_mode');

  if (themeModeIndex == null) {
    // User hasn't set a theme preference before
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final systemThemeMode = brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light;

    // Save the system theme mode to shared preferences
    await prefs.setInt('theme_mode', systemThemeMode.index);

    return systemThemeMode;
  }

  return ThemeMode.values[themeModeIndex];
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(ref.watch(initialThemeModeProvider).value ?? ThemeMode.system),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initialMode) : super(initialMode);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', mode.index);
  }
}
