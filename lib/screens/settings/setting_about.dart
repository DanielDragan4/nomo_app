import 'package:flutter/material.dart';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() {
    return _AboutState();
  }
}

class _AboutState extends State<About> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: const [
          ListTile(title: Text("About Us:", style: TextStyle(fontSize: 25))),
          ListTile(
              title: Text("I have nothing to write about us rn",
                  style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
