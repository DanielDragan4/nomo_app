import 'package:flutter/material.dart';
import 'package:nomo/widgets/setting_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MessageSettings extends StatefulWidget {
  const MessageSettings({super.key});

  @override
  State<MessageSettings> createState() {
    return _MessageSettingsState();
  }
}

class _MessageSettingsState extends State<MessageSettings> {
  late bool friendSwitch = false;
  late bool otherSwitch = false;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void updateSwitchValue(String switchType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (switchType) {
      case 'friend':
        setState(() {
          friendSwitch = !friendSwitch;
          prefs.setBool('friend', friendSwitch);
        });
        break;
      case 'other':
        setState(() {
          otherSwitch = !otherSwitch;
          prefs.setBool('other', otherSwitch);
        });
        break;
    }
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      friendSwitch = prefs.getBool('friend') ?? false;
      otherSwitch = prefs.getBool('other') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Friends', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: friendSwitch,
            onChanged: (newValue) {
              updateSwitchValue('friend');
            },
          ),
        ),
        ListTile(
          title: const Text('Others', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: otherSwitch,
            onChanged: (newValue) {
              updateSwitchValue('other');
            },
          ),
        ),
      ],
    );
  }
}
