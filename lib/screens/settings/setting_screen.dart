import 'package:flutter/material.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:nomo/screens/settings/setting_about.dart';
import 'package:nomo/screens/settings/setting_template.dart';
import 'package:nomo/widgets/setting_button.dart';

import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingScreen extends ConsumerStatefulWidget {
  SettingScreen({super.key, this.isCorp});
  bool? isCorp;
  @override
  createState() {
    return _SettingScreenState();
  }
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  bool _switchVal = false;

  void updateSwitchValue() {
    setState(() {
      _switchVal = !_switchVal;
    });
  }

  redirect(String screen) {
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsTemplate(type: screen),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        //padding: const EdgeInsets.all(20),
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
          SettingButton(
            title: 'Make Private',
            onPressed: updateSwitchValue,
            isSwitch: true,
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
          //Sub-Toggles: New Event Created, New Event Joined, Availability Changes
          SettingButton(
              title: 'Following Profiles',
              onPressed: () {
                redirect("Following");
              }),
          //Sub-Toggles: New Event Created, New Event Joined, Availability Changes
          SettingButton(
              title: 'Friends',
              onPressed: () {
                redirect("Friends");
              }),
          //Sub-Toggles: Has exact interest, Has similar interest
          SettingButton(
              title: 'Recommended Events',
              onPressed: () {
                redirect("Recommended");
              }),
          //Sub-Toggles: Friends, Not friends
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
          SettingButton(
            title: 'Camera',
            onPressed: updateSwitchValue,
            isSwitch: true,
          ),
          SettingButton(
            title: 'Microphone',
            onPressed: updateSwitchValue,
            isSwitch: true,
          ),
          SettingButton(
            title: 'Contacts',
            onPressed: updateSwitchValue,
            isSwitch: true,
          ),
          SettingButton(
            title: 'Device Notifications',
            onPressed: updateSwitchValue,
            isSwitch: true,
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
          //Included: Helpful Links, Contact Info
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
