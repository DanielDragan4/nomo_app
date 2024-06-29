import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/login_screen.dart';
import 'package:nomo/screens/settings/setting_template.dart';
import 'package:nomo/widgets/setting_button.dart';
import 'package:nomo/providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';

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
  late bool locationSwitch = false;
  late bool contactSwitch = false;
  late bool notifSwitch = false;
  late bool newEventSwitch = true;
  //late bool newEventFriendsOnlySwitch = false;
  late bool joinedEventSwitch = true;
  late bool joinedEventFriendsOnlySwitch = false;
  late bool eventDeletedSwitch = true;
  //late bool eventDeletedFriendsOnlySwitch = false;
  late bool messageSwitch = true;
  late bool messageFriendsOnlySwitch = false;

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
        case 'location':
          locationSwitch = !locationSwitch;
          prefs.setBool('location', locationSwitch);
          break;
        case 'contact':
          contactSwitch = !contactSwitch;
          prefs.setBool('contact', contactSwitch);
          break;
        case 'notif':
          notifSwitch = !notifSwitch;
          prefs.setBool('notif', notifSwitch); // Save notification switch state
          handleNotificationSwitch();
          break;
        case 'newEvent':
          newEventSwitch = !newEventSwitch;
          prefs.setBool('newEvent', newEventSwitch);
          //   if (!newEventSwitch) {
          //     newEventFriendsOnlySwitch = false;
          //     prefs.setBool('newEventFriendsOnly', false);
          //   }
          break;
        // case 'newEventFriendsOnly':
        //   newEventFriendsOnlySwitch = !newEventFriendsOnlySwitch;
        //   prefs.setBool('newEventFriendsOnly', newEventFriendsOnlySwitch);
        //  break;
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
          // if (!eventDeletedSwitch) {
          //   eventDeletedFriendsOnlySwitch = false;
          //   prefs.setBool('eventDeletedFriendsOnly', false);
          // }
          break;
        // case 'eventDeletedFriendsOnly':
        //   eventDeletedFriendsOnlySwitch = !eventDeletedFriendsOnlySwitch;
        //   prefs.setBool(
        //       'eventDeletedFriendsOnly', eventDeletedFriendsOnlySwitch);
        //   break;
        case 'message':
          messageSwitch = !messageSwitch;
          prefs.setBool('message', messageSwitch);
          if (!messageSwitch) {
            messageFriendsOnlySwitch = false;
            prefs.setBool('messageFriendsOnly', false);
          }
          break;
        case 'messageFriendsOnly':
          messageFriendsOnlySwitch = !messageFriendsOnlySwitch;
          prefs.setBool('messageFriendsOnly', messageFriendsOnlySwitch);
          break;
      }
    });
  }

  void handleNotificationSwitch() async {
    final perm_handler.PermissionStatus status =
        await perm_handler.Permission.notification.status;
    print('Notification permission status: $status');
    if (notifSwitch) {
      if (status.isGranted) {
        FirebaseMessaging.instance.subscribeToTopic('notifications');
        print('Subscribed to notifications');
      } else {
        final perm_handler.PermissionStatus requestStatus =
            await perm_handler.Permission.notification.request();
        print('Notification permission requested: $requestStatus');
        if (requestStatus.isGranted) {
          FirebaseMessaging.instance.subscribeToTopic('notifications');
          print('Subscribed to notifications after request');
        } else {
          setState(() {
            notifSwitch = false;
          });
          print('Notification permission denied');
        }
      }
    } else {
      FirebaseMessaging.instance.unsubscribeFromTopic('notifications');
      print('Unsubscribed from notifications');
    }
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      privateSwitch = prefs.getBool('private') ?? false;
      cameraSwitch = prefs.getBool('camera') ?? false;
      locationSwitch = prefs.getBool('location') ?? false;
      contactSwitch = prefs.getBool('contact') ?? false;
      notifSwitch = prefs.getBool('notif') ?? false;

      newEventSwitch = prefs.getBool('newEvent') ?? false;
      //newEventFriendsOnlySwitch = prefs.getBool('newEventFriendsOnly') ?? false;
      joinedEventSwitch = prefs.getBool('joinedEvent') ?? false;
      joinedEventFriendsOnlySwitch =
          prefs.getBool('joinedEventFriendsOnly') ?? false;
      eventDeletedSwitch = prefs.getBool('eventDeleted') ?? false;
      //eventDeletedFriendsOnlySwitch =
      //    prefs.getBool('eventDeletedFriendsOnly') ?? false;
      messageSwitch = prefs.getBool('message') ?? false;
      messageFriendsOnlySwitch = prefs.getBool('messageFriendsOnly') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
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
            title: const Text('Make Private', style: TextStyle(fontSize: 20)),
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
          // Padding(
          //   padding: const EdgeInsets.only(left: 40.0),
          //   child: ListTile(
          //     title: const Text('Friends Only', style: TextStyle(fontSize: 20)),
          //     trailing: Switch(
          //       value: newEventSwitch ? newEventFriendsOnlySwitch : false,
          //       onChanged: newEventSwitch
          //           ? (newValue) {
          //               updateSwitchValue('newEventFriendsOnly');
          //             }
          //           : null,
          //       activeColor: newEventSwitch
          //           ? Theme.of(context).primaryColor
          //           : Colors.grey,
          //     ),
          //   ),
          // ),
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
              title: const Text('Friends Only', style: TextStyle(fontSize: 20)),
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
            title: const Text('Event Deleted or Updated',
                style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: eventDeletedSwitch,
              onChanged: (newValue) {
                updateSwitchValue('eventDeleted');
              },
            ),
          ),
          // Padding(
          //   padding: const EdgeInsets.only(left: 40.0),
          //   child: ListTile(
          //     title: const Text('Friends Only', style: TextStyle(fontSize: 20)),
          //     trailing: Switch(
          //       value:
          //           eventDeletedSwitch ? eventDeletedFriendsOnlySwitch : false,
          //       onChanged: eventDeletedSwitch
          //           ? (newValue) {
          //               updateSwitchValue('eventDeletedFriendsOnly');
          //             }
          //           : null,
          //       activeColor: eventDeletedSwitch
          //           ? Theme.of(context).primaryColor
          //           : Colors.grey,
          //     ),
          //   ),
          // ),
          ListTile(
            title: Text('Incoming Message', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: messageSwitch,
              onChanged: (newValue) {
                updateSwitchValue('message');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: ListTile(
              title: const Text('Friends Only', style: TextStyle(fontSize: 20)),
              trailing: Switch(
                value: messageSwitch ? messageFriendsOnlySwitch : false,
                onChanged: messageSwitch
                    ? (newValue) {
                        updateSwitchValue('messageFriendsOnly');
                      }
                    : null,
                activeColor: messageSwitch
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
            title: const Text('Camera', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: cameraSwitch,
              onChanged: (newValue) {
                updateSwitchValue('camera');
              },
            ),
          ),
          ListTile(
            title: Text('Location', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: locationSwitch,
              onChanged: (newValue) {
                updateSwitchValue('location');
              },
            ),
          ),
          ListTile(
            title: const Text('Contacts', style: TextStyle(fontSize: 20)),
            trailing: Switch(
              value: contactSwitch,
              onChanged: (newValue) {
                updateSwitchValue('contact');
              },
            ),
          ),
          ListTile(
            title: const Text('Device Notifications',
                style: TextStyle(fontSize: 20)),
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
