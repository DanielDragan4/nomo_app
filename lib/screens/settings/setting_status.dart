import 'package:flutter/material.dart';

class Status extends StatefulWidget {
  const Status({super.key});

  @override
  State<Status> createState() {
    return _StatusState();
  }
}

class _StatusState extends State<Status> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: const [
          ListTile(
              title: Text("Account Status Settings:",
                  style: TextStyle(fontSize: 25))),
          ListTile(
              title:
                  Text("Idk, account stuff", style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
