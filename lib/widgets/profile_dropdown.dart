import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

enum options {
  itemOne,
}

class ProfileDropdown extends StatefulWidget {
  ProfileDropdown({
    super.key,
    //required this.dropDownFunction(),
  });

  //Function() dropDownFunction;

  @override
  State<StatefulWidget> createState() {
    return _ProfileDropdownState();
  }
}

class _ProfileDropdownState extends State<ProfileDropdown> {
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
          child: Text("Sign Out"),
          //onTap: widget.dropDownFunction(),
        ),
      ],
    );
  }
}
