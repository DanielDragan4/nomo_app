import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final initialThemeModeProvider = FutureProvider<ThemeMode>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('theme_mode') ?? ThemeMode.system.index;
  return ThemeMode.values[themeModeIndex];
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(
      ref.watch(initialThemeModeProvider).value ?? ThemeMode.system),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(ThemeMode initialMode) : super(initialMode);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('theme_mode', mode.index);
  }
}
