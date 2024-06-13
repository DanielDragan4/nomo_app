import 'package:flutter/material.dart';
import 'package:nomo/screens/settings/setting_about.dart';
import 'package:nomo/screens/settings/setting_analytics.dart';
import 'package:nomo/screens/settings/setting_auth.dart';
import 'package:nomo/screens/settings/setting_blocked.dart';
import 'package:nomo/screens/settings/setting_data_management.dart';
import 'package:nomo/screens/settings/setting_following.dart';
import 'package:nomo/screens/settings/setting_friends.dart';
import 'package:nomo/screens/settings/setting_help.dart';
import 'package:nomo/screens/settings/setting_messages.dart';
import 'package:nomo/screens/settings/setting_payment.dart';
import 'package:nomo/screens/settings/setting_recommended_events.dart';
import 'package:nomo/screens/settings/setting_security.dart';
import 'package:nomo/screens/settings/setting_status.dart';
import 'package:nomo/screens/settings/setting_support.dart';
import 'package:nomo/screens/settings/setting_theme.dart';

class SettingsTemplate extends StatefulWidget {
  SettingsTemplate({super.key, required this.type});

  String type;

  @override
  State<SettingsTemplate> createState() {
    return _SettingsTemplateState();
  }
}

class _SettingsTemplateState extends State<SettingsTemplate> {
  @override
  Widget build(BuildContext context) {
    Widget content;

    if (widget.type == "About") {
      content = const About();
    } else if (widget.type == "Analytics")
      content = const Analytics();
    else if (widget.type == "Auth")
      content = const AuthSetting();
    else if (widget.type == "Blocked")
      content = const Blocked();
    else if (widget.type == "Data")
      content = const DataManagement();
    else if (widget.type == "Following")
      content = const Following();
    else if (widget.type == "Friends")
      content = const FriendsSettings();
    else if (widget.type == "Help")
      content = const Help();
    else if (widget.type == "Messages") {
      content = const MessageSettings();
      widget.type = "Message Notifications";
    } else if (widget.type == "Payment")
      content = const Payment();
    else if (widget.type == "Recommended") {
      content = const RecommendedSettings();
      widget.type = "Recommended Events";
    } else if (widget.type == "Security")
      content = const Security();
    else if (widget.type == "Status") {
      content = const Status();
      widget.type = "Account Status";
    } else if (widget.type == "Support")
      content = const Support();
    else if (widget.type == "Theme")
      content = const ThemeSettings();
    else
      content = Container();

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
            child: Text(widget.type,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                )),
          ),
        ),
      ),
      body: content,
    );
  }
}
