import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  createState() {
    return _SettingScreenState();
  }
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MainAppBar(),
    );
  }
}
