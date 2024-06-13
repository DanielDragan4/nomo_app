import 'package:flutter/material.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:nomo/screens/settings/setting_about.dart';
import 'package:nomo/screens/settings/setting_template.dart';
import 'package:nomo/widgets/setting_button.dart';

import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends ConsumerStatefulWidget {
  SettingScreen({super.key, this.isCorp});
  bool? isCorp;
  @override
  createState() {
    return _SettingScreenState();
  }
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late bool privateSwitch = false;
  late bool cameraSwitch = false;
  late bool micSwitch = false;
  late bool contactSwitch = false;
  late bool notifSwitch = false;

  late bool newEventSwitch = false;
  late bool newEventFriendsOnlySwitch = false;
  late bool joinedEventSwitch = false;
  late bool joinedEventFriendsOnlySwitch = false;
  late bool eventDeletedSwitch = false;
  late bool eventDeletedFriendsOnlySwitch = false;
  late bool availabilitySwitch = false;
  late bool availabilityFriendsOnlySwitch = false;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void updateSwitchValue(String switchType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      switch (switchType) {
        case 'private':
          privateSwitch = !privateSwitch;
          prefs.setBool('private', privateSwitch);
          ref.read(profileProvider.notifier).updatePrivacy(privateSwitch);
          break;
        case 'camera':
          cameraSwitch = !cameraSwitch;
          prefs.setBool('camera', cameraSwitch);
          break;
        case 'mic':
          micSwitch = !micSwitch;
          prefs.setBool('mic', micSwitch);
          break;
        case 'contact':
          contactSwitch = !contactSwitch;
          prefs.setBool('contact', contactSwitch);
          break;
        case 'notif':
          notifSwitch = !notifSwitch;
          prefs.setBool('notif', notifSwitch);
          break;
        case 'newEvent':
          newEventSwitch = !newEventSwitch;
          prefs.setBool('newEvent', newEventSwitch);
          if (!newEventSwitch) {
            newEventFriendsOnlySwitch = false;
            prefs.setBool('newEventFriendsOnly', false);
          }
          break;
        case 'newEventFriendsOnly':
          newEventFriendsOnlySwitch = !newEventFriendsOnlySwitch;
          prefs.setBool('newEventFriendsOnly', newEventFriendsOnlySwitch);
          break;
        case 'joinedEvent':
          joinedEventSwitch = !joinedEventSwitch;
          prefs.setBool('joinedEvent', joinedEventSwitch);
          if (!joinedEventSwitch) {
            joinedEventFriendsOnlySwitch = false;
            prefs.setBool('joinedEventFriendsOnly', false);
          }
          break;
        case 'joinedEventFriendsOnly':
          joinedEventFriendsOnlySwitch = !joinedEventFriendsOnlySwitch;
          prefs.setBool('joinedEventFriendsOnly', joinedEventFriendsOnlySwitch);
          break;
        case 'eventDeleted':
          eventDeletedSwitch = !eventDeletedSwitch;
          prefs.setBool('eventDeleted', eventDeletedSwitch);
          if (!eventDeletedSwitch) {
            eventDeletedFriendsOnlySwitch = false;
            prefs.setBool('eventDeletedFriendsOnly', false);
          }
          break;
        case 'eventDeletedFriendsOnly':
          eventDeletedFriendsOnlySwitch = !eventDeletedFriendsOnlySwitch;
          prefs.setBool(
              'eventDeletedFriendsOnly', eventDeletedFriendsOnlySwitch);
          break;
        case 'availability':
          availabilitySwitch = !availabilitySwitch;
          prefs.setBool('availability', availabilitySwitch);
          if (!availabilitySwitch) {
            availabilityFriendsOnlySwitch = false;
            prefs.setBool('availabilityFriendsOnly', false);
          }
          break;
        case 'availabilityFriendsOnly':
          availabilityFriendsOnlySwitch = !availabilityFriendsOnlySwitch;
          prefs.setBool(
              'availabilityFriendsOnly', availabilityFriendsOnlySwitch);
          break;
      }
    });
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      privateSwitch = prefs.getBool('private') ?? false;
      cameraSwitch = prefs.getBool('camera') ?? false;
      micSwitch = prefs.getBool('mic') ?? false;
      contactSwitch = prefs.getBool('contact') ?? false;
      notifSwitch = prefs.getBool('notif') ?? false;

      newEventSwitch = prefs.getBool('newEvent') ?? false;
      newEventFriendsOnlySwitch = prefs.getBool('newEventFriendsOnly') ?? false;
      joinedEventSwitch = prefs.getBool('joinedEvent') ?? false;
      joinedEventFriendsOnlySwitch =
          prefs.getBool('joinedEventFriendsOnly') ?? false;
      eventDeletedSwitch = prefs.getBool('eventDeleted') ?? false;
      eventDeletedFriendsOnlySwitch =
          prefs.getBool('eventDeletedFriendsOnly') ?? false;
      availabilitySwitch = prefs.getBool('availability') ?? false;
      availabilityFriendsOnlySwitch =
          prefs.getBool('availabilityFriendsOnly') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text('Settings',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                )),
          ),
        ),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Account', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(
            title: 'Data Management',
            onPressed: () {
              redirect("Data");
            },
          ),
          SettingButton(
            title: 'Authentication',
            onPressed: () {
              redirect("Auth");
            },
          ),
          SettingButton(
            title: 'Security',
            onPressed: () {
              redirect("Security");
            },
          ),
          const ListTile(
            title: Text('Privacy', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          ListTile(
            title: Text('Make Private', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: privateSwitch,
              onChanged: (newValue) {
                updateSwitchValue('private');
              },
            ),
          ),
          SettingButton(
            title: 'Blocked Accounts',
            onPressed: () {
              redirect("Blocked");
            },
          ),
          const ListTile(
            title: Text('In-App Notifications', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          ListTile(
            title: Text('New Event Created', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: newEventSwitch,
              onChanged: (newValue) {
                updateSwitchValue('newEvent');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: ListTile(
              title: Text('Friends Only', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: newEventSwitch ? newEventFriendsOnlySwitch : false,
                onChanged: newEventSwitch
                    ? (newValue) {
                        updateSwitchValue('newEventFriendsOnly');
                      }
                    : null,
                activeColor: newEventSwitch
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: Text('New Event Joined', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: joinedEventSwitch,
              onChanged: (newValue) {
                updateSwitchValue('joinedEvent');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: ListTile(
              title: Text('Friends Only', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: joinedEventSwitch ? joinedEventFriendsOnlySwitch : false,
                onChanged: joinedEventSwitch
                    ? (newValue) {
                        updateSwitchValue('joinedEventFriendsOnly');
                      }
                    : null,
                activeColor: joinedEventSwitch
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: Text('Event Deleted', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: eventDeletedSwitch,
              onChanged: (newValue) {
                updateSwitchValue('eventDeleted');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: ListTile(
              title: Text('Friends Only', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value:
                    eventDeletedSwitch ? eventDeletedFriendsOnlySwitch : false,
                onChanged: eventDeletedSwitch
                    ? (newValue) {
                        updateSwitchValue('eventDeletedFriendsOnly');
                      }
                    : null,
                activeColor: eventDeletedSwitch
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: Text('Availability Changes', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: availabilitySwitch,
              onChanged: (newValue) {
                updateSwitchValue('availability');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: ListTile(
              title: Text('Friends Only', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value:
                    availabilitySwitch ? availabilityFriendsOnlySwitch : false,
                onChanged: availabilitySwitch
                    ? (newValue) {
                        updateSwitchValue('availabilityFriendsOnly');
                      }
                    : null,
                activeColor: availabilitySwitch
                    ? Theme.of(context).primaryColor
                    : Colors.grey,
              ),
            ),
          ),
          const ListTile(
            title: Text('Customization', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(
            title: 'Theme',
            onPressed: () {
              redirect("Theme");
            },
          ),
          const ListTile(
            title: Text('Permissions', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          ListTile(
            title: Text('Camera', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: cameraSwitch,
              onChanged: (newValue) {
                updateSwitchValue('camera');
              },
            ),
          ),
          ListTile(
            title: Text('Microphone', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: micSwitch,
              onChanged: (newValue) {
                updateSwitchValue('mic');
              },
            ),
          ),
          ListTile(
            title: Text('Contacts', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: contactSwitch,
              onChanged: (newValue) {
                updateSwitchValue('contact');
              },
            ),
          ),
          ListTile(
            title: Text('Device Notifications', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: notifSwitch,
              onChanged: (newValue) {
                updateSwitchValue('notif');
              },
            ),
          ),
          if (widget.isCorp != null && true)
            const ListTile(
              title: Row(
                children: [
                  Text('Corporate Account', style: TextStyle(fontSize: 25)),
                  Icon(Icons.workspace_premium_outlined)
                ],
              ),
            ),
          if (widget.isCorp != null && true) const Divider(),
          if (widget.isCorp != null && true)
            SettingButton(
              title: 'Event Analytics',
              onPressed: () {
                redirect("Analytics");
              },
            ),
          if (widget.isCorp != null && true)
            SettingButton(
              title: 'Payment',
              onPressed: () {
                redirect("Payment");
              },
            ),
          if (widget.isCorp != null && true)
            SettingButton(
              title: 'Customer Support',
              onPressed: () {
                redirect("Support");
              },
            ),
          const ListTile(
            title: Text('Support', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(
            title: 'About',
            onPressed: () {
              redirect("About");
            },
          ),
          SettingButton(
            title: 'Help',
            onPressed: () {
              redirect("Help");
            },
          ),
          SettingButton(
            title: 'Account Status',
            onPressed: () {
              redirect("Status");
            },
          ),
          TextButton(
            onPressed: () {
              ref.watch(currentUserProvider.notifier).signOut();
              ref.read(savedSessionProvider.notifier).changeSessionDataList();
              Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => const LoginScreen())));
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  redirect(String screen) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsTemplate(type: screen),
    ));
  }
}
