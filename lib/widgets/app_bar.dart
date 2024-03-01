import 'package:flutter/material.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
  });
  //TODO: implement a way to add more widgets (like profile screen user info) optionally

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AppBar(
      //toolbarHeight: 15,
      titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
      title: Center(
        child: Column(
          children: [
            Text(
              'Nomo',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
