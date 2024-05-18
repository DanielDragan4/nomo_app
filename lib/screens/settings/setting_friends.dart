import 'package:flutter/material.dart';
import 'package:nomo/widgets/setting_button.dart';

class FriendsSettings extends StatefulWidget {
  const FriendsSettings({super.key});

  @override
  State<FriendsSettings> createState() {
    return _FriendsState();
  }
}

class _FriendsState extends State<FriendsSettings> {
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
          title: "New Event Created",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
        SettingButton(
          title: "New Event Joined",
          onPressed: updateSwitchValue,
          isSwitch: true,
        ),
        SettingButton(
          title: "Availability Changes",
          onPressed: updateSwitchValue,
          isSwitch: true,
        )
      ],
    );
  }
}
