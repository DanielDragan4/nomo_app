import 'package:flutter/material.dart';

//(Currently) useless garbage
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  MainAppBar({
    super.key,
    this.child,
  });
  var child;
  //TODO: implement a way to add more widgets (like profile screen user info) optionally

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return PreferredSize(
      preferredSize: preferredSize,
      child: AppBar(
        centerTitle: true,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        title: Text(
          'Nomo',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: child != null
            ? PreferredSize(
                preferredSize: Size.fromHeight(getHeightOfWidget(context, child)),
                child: child,
              )
            : null,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  double getHeightOfWidget(BuildContext context, Widget widget) {
    return MediaQuery.of(context).size.height;
  }
}
