import 'package:flutter/material.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  File? _selectedImage;
  String dropdownValue = "";

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 20),
            const Center(
              child: Text("Create New Event+"),
            ),
            const SizedBox(height: 20),
            ImageInput(
              onPickImage: (image) {
                _selectedImage = image;
              },
            ),
            const SizedBox(height: 10),
            Column(
              children: [
                Row(
                  children: [
                    const Text(
                      "Date ",
                      style: TextStyle(fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Calendar Dropdown",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "Time",
                      style: TextStyle(fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "10:00pm",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                    const Text("-"),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "12:30am",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "Location",
                      style: TextStyle(fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Location Picker Here",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      "Invitation Type",
                      style: TextStyle(fontSize: 15),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Type Dropdown Here",
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      "Description",
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ],
            )
          ],
        ));
  }
}
