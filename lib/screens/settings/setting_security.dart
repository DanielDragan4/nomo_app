import 'package:flutter/material.dart';

class Security extends StatefulWidget {
  const Security({super.key});

  @override
  State<Security> createState() {
    return _SecurityState();
  }
}

class _SecurityState extends State<Security> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
            title: Text("Security Settings:", style: TextStyle(fontSize: 25))),
        ListTile(
            title: Text(
                "We definetely won't not consider possibly thinking about the prospects of selling all of your data, maybe",
                style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
