import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/theme_provider.dart';

class ThemeSettings extends ConsumerStatefulWidget {
  const ThemeSettings({super.key});

  @override
  ConsumerState<ThemeSettings> createState() {
    return _ThemeSettingsState();
  }
}

class _ThemeSettingsState extends ConsumerState<ThemeSettings> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final initialThemeMode = ref.watch(initialThemeModeProvider);

    ref.listen<AsyncValue<ThemeMode>>(initialThemeModeProvider, (previous, next) {
      next.whenData((themeMode) {
        ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
      });
    });

    final isDarkMode = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    print('_________________________________themeMode: $themeMode');
    print('_________________________________initialThemeMode: $initialThemeMode');

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: initialThemeMode.when(
        data: (_) => ListView(
          children: [
            const ListTile(title: Text("Theme Settings:", style: TextStyle(fontSize: 25))),
            ListTile(
              title: const Text("Dark Theme", style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (bool value) {
                  ref.read(themeModeProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Error loading theme")),
      ),
    );
  }
}
