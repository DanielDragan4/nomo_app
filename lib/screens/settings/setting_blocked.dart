import 'package:flutter/material.dart';

class Blocked extends StatefulWidget {
  const Blocked({super.key});

  @override
  State<Blocked> createState() {
    return _BlockedState();
  }
}

class _BlockedState extends State<Blocked> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
            title: Text("Blocked People Settings:",
                style: TextStyle(fontSize: 25))),
        ListTile(
            title: Text("No Blocked Ppl Yet", style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
