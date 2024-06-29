import 'package:flutter/material.dart';

class Support extends StatefulWidget {
  const Support({super.key});

  @override
  State<Support> createState() {
    return _SupportState();
  }
}

class _SupportState extends State<Support> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ListView(
        children: const [
          ListTile(
              title: Text("Support Settings:", style: TextStyle(fontSize: 25))),
          ListTile(
              title: Text("Give us money, then we'll talk",
                  style: TextStyle(fontSize: 20))),
        ],
      ),
    );
  }
}
