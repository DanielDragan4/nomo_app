import 'package:flutter/material.dart';

class Analytics extends StatefulWidget {
  const Analytics({super.key});

  @override
  State<Analytics> createState() {
    return _AnalyticsState();
  }
}

class _AnalyticsState extends State<Analytics> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(title: Text("Analytics:", style: TextStyle(fontSize: 25))),
        ListTile(
            title: Text("No Analytics Yet", style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
