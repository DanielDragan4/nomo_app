import 'package:flutter/material.dart';

class DataManagement extends StatefulWidget {
  const DataManagement({super.key});

  @override
  State<DataManagement> createState() {
    return _DataManagementState();
  }
}

class _DataManagementState extends State<DataManagement> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(
            title: Text("Data Management Settings:",
                style: TextStyle(fontSize: 25))),
        ListTile(
            title:
                Text("No Data to Manage Yet", style: TextStyle(fontSize: 20))),
      ],
    );
  }
}
