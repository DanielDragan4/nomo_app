import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart' as perm_handler;
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:nomo/screens/settings/setting_template.dart';
import 'package:nomo/widgets/setting_button.dart';
import 'package:nomo/providers/supabase-providers/saved_session_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key, this.isCorp});
  final bool? isCorp;

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  late bool privateSwitch = false;
  late bool cameraSwitch = false;
  late bool locationSwitch = false;
  late bool contactSwitch = false;
  late bool notifSwitch = false;
  late bool newEventSwitch = true;
  late bool joinedEventSwitch = true;
  late bool joinedEventFriendsOnlySwitch = false;
  late bool eventDeletedSwitch = true;
  late bool messageSwitch = true;
  late bool messageFriendsOnlySwitch = false;

  @override
  void initState() {
    loadData();
    super.initState();
  }

  void loadData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      privateSwitch = prefs.getBool('private') ?? false;
      cameraSwitch = prefs.getBool('camera') ?? false;
      locationSwitch = prefs.getBool('location') ?? false;
      contactSwitch = prefs.getBool('contact') ?? false;
      notifSwitch = prefs.getBool('notif') ?? false;
      newEventSwitch = prefs.getBool('newEvent') ?? true;
      joinedEventSwitch = prefs.getBool('joinedEvent') ?? true;
      joinedEventFriendsOnlySwitch = prefs.getBool('joinedEventFriendsOnly') ?? false;
      eventDeletedSwitch = prefs.getBool('eventDeleted') ?? true;
      messageSwitch = prefs.getBool('message') ?? true;
      messageFriendsOnlySwitch = prefs.getBool('messageFriendsOnly') ?? false;
    });

    // Check permissions
    final cameraStatus = await perm_handler.Permission.camera.status;
    final locationStatus = await perm_handler.Permission.location.status;
    final contactsStatus = await perm_handler.Permission.contacts.status;
    final notificationStatus = await perm_handler.Permission.notification.status;

    setState(() {
      cameraSwitch = cameraStatus.isGranted;
      locationSwitch = locationStatus.isGranted;
      contactSwitch = contactsStatus.isGranted;
      notifSwitch = notificationStatus.isGranted;
    });
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
          handlePermissionToggle(perm_handler.Permission.camera, cameraSwitch);
          prefs.setBool('camera', cameraSwitch);
          break;
        case 'location':
          locationSwitch = !locationSwitch;
          handlePermissionToggle(perm_handler.Permission.location, locationSwitch);
          prefs.setBool('location', locationSwitch);
          break;
        case 'contact':
          contactSwitch = !contactSwitch;
          handlePermissionToggle(perm_handler.Permission.contacts, contactSwitch);
          prefs.setBool('contact', contactSwitch);
          break;
        case 'notif':
          notifSwitch = !notifSwitch;
          prefs.setBool('notif', notifSwitch);
          handleNotificationSwitch();
          break;
        case 'newEvent':
          newEventSwitch = !newEventSwitch;
          prefs.setBool('newEvent', newEventSwitch);
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
          break;
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

  Future<void> handlePermissionToggle(perm_handler.Permission permission, bool enabled) async {
    final status = await permission.status;
    if (enabled && !status.isGranted) {
      final result = await permission.request();
      if (!result.isGranted) {
        setState(() {
          switch (permission) {
            case perm_handler.Permission.camera:
              cameraSwitch = false;
              break;
            case perm_handler.Permission.location:
              locationSwitch = false;
              break;
            case perm_handler.Permission.contacts:
              contactSwitch = false;
              break;
            default:
              break;
          }
        });
      }
    } else if (!enabled && status.isGranted) {
      perm_handler.openAppSettings();
    }
  }

  void handleNotificationSwitch() async {
    final perm_handler.PermissionStatus status = await perm_handler.Permission.notification.status;
    print('Notification permission status: $status');

    if (notifSwitch) {
      if (status.isGranted) {
        FirebaseMessaging.instance.subscribeToTopic('notifications');
        print('Subscribed to notifications');
      } else {
        final perm_handler.PermissionStatus requestStatus = await perm_handler.Permission.notification.request();
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
      perm_handler.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.canvasColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          'Settings',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        children: [
          _buildSection('Account', [
            _buildSettingItem('Data Management', onTap: () => redirect("Data")),
            _buildSettingItem('Authentication', onTap: () => redirect("Auth")),
            _buildSettingItem('Security', onTap: () => redirect("Security")),
          ]),
          _buildSection('Privacy', [
            _buildSwitchItem('Make Private', value: privateSwitch, onChanged: (val) => updateSwitchValue('private')),
            _buildSettingItem('Blocked Accounts', onTap: () => redirect("Blocked")),
          ]),
          _buildSection('In-App Notifications', [
            _buildSwitchItem('New Event Created', value: newEventSwitch, onChanged: (val) => updateSwitchValue('newEvent')),
            _buildSwitchItem('New Event Joined', value: joinedEventSwitch, onChanged: (val) => updateSwitchValue('joinedEvent')),
            if (joinedEventSwitch)
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: _buildSwitchItem('Friends Only', value: joinedEventFriendsOnlySwitch, onChanged: (val) => updateSwitchValue('joinedEventFriendsOnly')),
              ),
            _buildSwitchItem('Event Deleted or Updated', value: eventDeletedSwitch, onChanged: (val) => updateSwitchValue('eventDeleted')),
            _buildSwitchItem('Incoming Message', value: messageSwitch, onChanged: (val) => updateSwitchValue('message')),
            if (messageSwitch)
              Padding(
                padding: const EdgeInsets.only(left: 40.0),
                child: _buildSwitchItem('Friends Only', value: messageFriendsOnlySwitch, onChanged: (val) => updateSwitchValue('messageFriendsOnly')),
              ),
          ]),
          _buildSection('Customization', [
            _buildSettingItem('Theme', onTap: () => redirect("Theme")),
          ]),
          _buildSection('Permissions', [
            _buildSwitchItem('Camera', value: cameraSwitch, onChanged: (val) => updateSwitchValue('camera')),
            _buildSwitchItem('Location', value: locationSwitch, onChanged: (val) => updateSwitchValue('location')),
            _buildSwitchItem('Contacts', value: contactSwitch, onChanged: (val) => updateSwitchValue('contact')),
            _buildSwitchItem('Device Notifications', value: notifSwitch, onChanged: (val) => updateSwitchValue('notif')),
          ]),
          if (widget.isCorp == true)
            _buildSection('Corporate Account', [
              _buildSettingItem('Event Analytics', onTap: () => redirect("Analytics")),
              _buildSettingItem('Payment', onTap: () => redirect("Payment")),
              _buildSettingItem('Customer Support', onTap: () => redirect("Support")),
            ]),
          _buildSection('Support', [
            _buildSettingItem('About', onTap: () => redirect("About")),
            _buildSettingItem('Help', onTap: () => redirect("Help")),
            _buildSettingItem('Account Status', onTap: () => redirect("Status")),
          ]),
          _buildLogoutButton(),
          _buildDeleteAccountButton(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingItem(String title, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.onSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem(String title, {required bool value, required ValueChanged<bool> onChanged}) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(
        title,
        style: theme.textTheme.titleMedium,
      ),
      value: value,
      onChanged: onChanged,
      activeColor: theme.primaryColor,
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
        ),
        onPressed: () {
          ref.read(currentUserProvider.notifier).signOut();
          ref.read(savedSessionProvider.notifier).changeSessionDataList();
          Navigator.of(context).push(MaterialPageRoute(builder: ((context) => const LoginScreen())));
        },
        child: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Are you sure you want to delete your account? All data will be deleted.',
                style: TextStyle(
                  color: Theme.of(context).primaryColorLight,
                  fontSize: MediaQuery.of(context).size.width * 0.065,
                  fontWeight: FontWeight.w600,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    ref.watch(currentUserProvider.notifier).signOut();
                    ref.read(savedSessionProvider.notifier).changeSessionDataList();
                    ref.read(currentUserProvider.notifier).deleteAccount();
                    Navigator.of(context).push(MaterialPageRoute(builder: ((context) => const LoginScreen())));
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Account Deleted"),
                      ),
                    );
                  },
                child: Text(
                    'Delete',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: MediaQuery.of(context).size.width * 0.045,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        child: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red, fontSize: MediaQuery.of(context).size.width * 0.039),
        ),
      ),
    );
  }

  void redirect(String screen) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SettingsTemplate(type: screen),
    ));
  }
}