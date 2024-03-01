import 'package:flutter/material.dart';

enum options {
  itemOne,
  itemTwo,
}

class ProfileDropdown extends StatefulWidget {
  const ProfileDropdown({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return _ProfileDropdownState();
  }
}

class _ProfileDropdownState extends State<ProfileDropdown> {
  //final AuthService authService = AuthService();

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
          child: const Text("Settings"),
          onTap: () {},
        ),
        PopupMenuItem(
          value: options.itemTwo,
          child: const Text("Sign Out"),
          onTap: () {
            //authService.signOut();
          },
        ),
      ],
    );
  }
}
