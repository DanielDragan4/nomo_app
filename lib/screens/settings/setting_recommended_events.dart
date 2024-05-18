import 'package:flutter/material.dart';
import 'package:nomo/widgets/setting_button.dart';

class RecommendedSettings extends StatefulWidget {
  const RecommendedSettings({super.key});

  @override
  State<RecommendedSettings> createState() {
    return _RecommendedSettingsState();
  }
}

class _RecommendedSettingsState extends State<RecommendedSettings> {
  bool _switchVal = false;

  void updateSwitchValue() {
    setState(() {
      _switchVal = !_switchVal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        SettingButton(
          title: "Has Exact Interests",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
        SettingButton(
          title: "Has Similar Interests",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
      ],
    );
  }
}
