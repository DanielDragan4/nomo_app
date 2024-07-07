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

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: initialThemeMode.when(
        data: (_) => ListView(
          children: [
            const ListTile(
                title: Text("Theme Settings:", style: TextStyle(fontSize: 25))),
            ListTile(
              title: const Text("Dark Theme", style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (bool value) {
                  ref.read(themeModeProvider.notifier).setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ),
          ],
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text("Error loading theme"),
      ),
    );
  }
}
