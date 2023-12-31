import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  @override
  Widget build(BuildContext context) {
    final ImagePicker picker = new ImagePicker();
    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 15,
          titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
          title: Center(
            child: Text(
              'Nomo',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            Text("Create New Event+"),
          ],
        ));
  }
}
