import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FriendsSettings extends StatefulWidget {
  const FriendsSettings({super.key});

  @override
  State<FriendsSettings> createState() {
    return _FriendsState();
  }
}

class _FriendsState extends State<FriendsSettings> {
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
      case 'newEventFriend':
        setState(() {
          newEventSwitch = !newEventSwitch;
          prefs.setBool('newEventFriend', newEventSwitch);
        });
        break;
      case 'joinedEventFriend':
        setState(() {
          joinedEventSwitch = !joinedEventSwitch;
          prefs.setBool('joinedEventFriend', joinedEventSwitch);
        });
        break;
      case 'availabilityFriend':
        setState(() {
          availabilitySwitch = !availabilitySwitch;
          prefs.setBool('availabilityFriend', availabilitySwitch);
        });
        break;
    }
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      newEventSwitch = prefs.getBool('newEventFriend') ?? false;
      joinedEventSwitch = prefs.getBool('joinedEventFriend') ?? false;
      availabilitySwitch = prefs.getBool('availabilityFriend') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('New Event Created', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: newEventSwitch,
            onChanged: (newValue) {
              updateSwitchValue('newEventFriend');
            },
          ),
        ),
        ListTile(
          title: const Text('New Event Joined', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: joinedEventSwitch,
            onChanged: (newValue) {
              updateSwitchValue('joinedEventFriend');
            },
          ),
        ),
        ListTile(
          title: const Text('Availability Changes', style: TextStyle(fontSize: 20)),
          trailing: Switch(
            value: availabilitySwitch,
            onChanged: (newValue) {
              updateSwitchValue('availabilityFriend');
            },
          ),
        ),
      ],
    );
  }
}
