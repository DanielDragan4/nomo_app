import 'package:flutter/material.dart';

class ThemeSettings extends StatefulWidget {
  const ThemeSettings({super.key});

  @override
  State<ThemeSettings> createState() {
    return _ThemeSettingsState();
  }
}

class _ThemeSettingsState extends State<ThemeSettings> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
            title: Text("Theme Settings:", style: TextStyle(fontSize: 25))),
        ListTile(
            title: Text(
                "You get shiny customizations here (give us your money)",
                style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
