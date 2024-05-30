import 'package:flutter/material.dart';
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

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void updateSwitchValue(String switchType) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    switch (switchType) {
      case 'private':
        setState(() {
          privateSwitch = !privateSwitch;
          prefs.setBool('private', privateSwitch);
        });
        break;
      case 'camera':
        setState(() {
          cameraSwitch = !cameraSwitch;
          prefs.setBool('camera', cameraSwitch);
        });
        break;
      case 'mic':
        setState(() {
          micSwitch = !micSwitch;
          prefs.setBool('mic', micSwitch);
        });
        break;
      case 'contact':
        setState(() {
          contactSwitch = !contactSwitch;
          prefs.setBool('contact', contactSwitch);
        });
        break;
      case 'notif':
        setState(() {
          notifSwitch = !notifSwitch;
          prefs.setBool('notif', notifSwitch);
        });
        break;
    }
  }

  redirect(String screen) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsTemplate(type: screen),
    ));
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      privateSwitch = prefs.getBool('private') ?? false;
      cameraSwitch = prefs.getBool('camera') ?? false;
      micSwitch = prefs.getBool('mic') ?? false;
      contactSwitch = prefs.getBool('contact') ?? false;
      notifSwitch = prefs.getBool('notif') ?? false;
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
          SettingButton(
              title: 'Following Profiles',
              onPressed: () {
                redirect("Following");
              }),
          SettingButton(
              title: 'Friends',
              onPressed: () {
                redirect("Friends");
              }),
          SettingButton(
              title: 'Recommended Events',
              onPressed: () {
                redirect("Recommended");
              }),
          SettingButton(
              title: 'Messages',
              onPressed: () {
                redirect("Messages");
              }),
          const ListTile(
            title: Text('Customization', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(
              title: 'Theme',
              onPressed: () {
                redirect("Theme");
              }),
          const ListTile(
            title: Text('Premissions', style: TextStyle(fontSize: 25)),
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
                }),
          if (widget.isCorp != null && true)
            SettingButton(
                title: 'Payment',
                onPressed: () {
                  redirect("Payment");
                }),
          if (widget.isCorp != null && true)
            SettingButton(
                title: 'Customer Support',
                onPressed: () {
                  redirect("Support");
                }),
          const ListTile(
            title: Text('Support', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(
              title: 'About',
              onPressed: () {
                redirect("About");
              }),
          SettingButton(
              title: 'Help',
              onPressed: () {
                redirect("Help");
              }),
          SettingButton(
              title: 'Account Status',
              onPressed: () {
                redirect("Status");
              }),
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
}
