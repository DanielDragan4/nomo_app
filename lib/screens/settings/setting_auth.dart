import 'package:flutter/material.dart';

class AuthSetting extends StatefulWidget {
  const AuthSetting({super.key});

  @override
  State<AuthSetting> createState() {
    return _AuthSettingState();
  }
}

class _AuthSettingState extends State<AuthSetting> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: const [
          ListTile(
              title: Text("Authentication Settings:",
                  style: TextStyle(fontSize: 25))),
          ListTile(
              title: Text("No Auth Stuff Yet", style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
