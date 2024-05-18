import 'package:flutter/material.dart';
import 'package:nomo/widgets/setting_button.dart';

class MessageSettings extends StatefulWidget {
  const MessageSettings({super.key});

  @override
  State<MessageSettings> createState() {
    return _MessageSettingsState();
  }
}

class _MessageSettingsState extends State<MessageSettings> {
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
          title: "Friends",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
        SettingButton(
          title: "Others",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
      ],
    );
  }
}
