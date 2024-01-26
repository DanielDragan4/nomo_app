import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/auth_service.dart';

enum options {
  itemOne,
  itemTwo,
}

class ProfileDropdown extends StatefulWidget {
  ProfileDropdown({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _ProfileDropdownState();
  }
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  final AuthService authService = AuthService();

  @override
  Widget build(BuildContext context) {
    options? selectedOption;

    return PopupMenuButton<options>(
      onSelected: (options item) {
        setState(
          () {
            selectedOption = item;
          },
        );
      },
      itemBuilder: (context) => <PopupMenuEntry<options>>[
        PopupMenuItem(
          value: options.itemOne,
          child: Text("Settings"),
          onTap: () {},
        ),
        PopupMenuItem(
          value: options.itemTwo,
          child: Text("Sign Out"),
          onTap: () {
            authService.signOut();
          },
        ),
      ],
    );
  }
}
