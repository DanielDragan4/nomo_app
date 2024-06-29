import 'package:flutter/material.dart';
import 'package:nomo/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    return ListView(
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
    );
  }
}
