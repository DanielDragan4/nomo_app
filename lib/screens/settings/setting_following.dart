import 'package:flutter/material.dart';
import 'package:nomo/widgets/setting_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Following extends StatefulWidget {
  const Following({super.key});

  @override
  State<Following> createState() {
    return _FollowingState();
  }
}

class _FollowingState extends State<Following> {
  late bool newEventSwitch = false;
  late bool joinedEventSwitch = false;
  late bool availabilitySwitch = false;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void updateSwitchValue(String switchType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (switchType) {
      case 'newEventFollowing':
        setState(() {
          newEventSwitch = !newEventSwitch;
          prefs.setBool('newEventFollowing', newEventSwitch);
        });
        break;
      case 'joinedEventFollowing':
        setState(() {
          joinedEventSwitch = !joinedEventSwitch;
          prefs.setBool('joinedEventFollowing', joinedEventSwitch);
        });
        break;
      case 'availabilityFollowing':
        setState(() {
          availabilitySwitch = !availabilitySwitch;
          prefs.setBool('availabilityFollowing', availabilitySwitch);
        });
        break;
    }
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      newEventSwitch = prefs.getBool('newEventFollowing') ?? false;
      joinedEventSwitch = prefs.getBool('joinedEventFollowing') ?? false;
      availabilitySwitch = prefs.getBool('availabilityFollowing') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('New Event Created', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: newEventSwitch,
            onChanged: (newValue) {
              updateSwitchValue('newEventFollowing');
            },
          ),
        ),
        ListTile(
          title: Text('New Event Joined', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: joinedEventSwitch,
            onChanged: (newValue) {
              updateSwitchValue('joinedEventFollowing');
            },
          ),
        ),
        ListTile(
          title: Text('Availability Changes', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: availabilitySwitch,
            onChanged: (newValue) {
              updateSwitchValue('availabilityFollowing');
            },
          ),
        ),
      ],
    );
  }
}
