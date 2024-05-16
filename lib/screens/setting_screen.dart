import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
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
            onPressed: () {},
          ),
          SettingButton(
            title: 'Authentication',
            onPressed: () {},
          ),
          SettingButton(
            title: 'Security',
            onPressed: () {},
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
            onPressed: () {},
          ),
          const ListTile(
            title: Text('In-App Notifications', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          //Sub-Toggles: New Event Created, New Event Joined, Availability Changes
          SettingButton(title: 'Following Profiles', onPressed: () {}),
          //Sub-Toggles: New Event Created, New Event Joined, Availability Changes
          SettingButton(title: 'Friends', onPressed: () {}),
          //Sub-Toggles: Has exact interest, Has similar interest
          SettingButton(title: 'Recommended Events', onPressed: () {}),
          //Sub-Toggles: Friends, Not friends
          SettingButton(title: 'Messages', onPressed: () {}),
          const ListTile(
            title: Text('Customization', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(title: 'Theme', onPressed: () {}),
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
            SettingButton(title: 'Event Analytics', onPressed: () {}),
          if (widget.isCorp != null && true)
            SettingButton(title: 'Payment', onPressed: () {}),
          if (widget.isCorp != null && true)
            SettingButton(title: 'Customer Support', onPressed: () {}),
          const ListTile(
            title: Text('Support', style: TextStyle(fontSize: 25)),
          ),
          const Divider(),
          SettingButton(title: 'About', onPressed: () {}),
          //Included: Helpful Links, Contact Info
          SettingButton(title: 'Help', onPressed: () {}),
          SettingButton(title: 'Account Status', onPressed: () {}),
          TextButton(
            onPressed: () {
              ref.watch(currentUserProvider.notifier).signOut();
              ref.read(savedSessionProvider.notifier).changeSessionDataList();
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
