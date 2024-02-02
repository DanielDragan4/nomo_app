import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  TimeOfDay? _selectedTime;

  File? _selectedImage;
  String dropdownValue = "";

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != TimeOfDay.now()) {
      // Update the state with the selected time
      setState(() {
        // Assuming you have a variable to store the selected time
        // _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: MainAppBar(),
        // AppBar(
        //   toolbarHeight: 15,
        //   titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        //   title: Center(
        //     child: Text(
        //       'Nomo',
        //       style: TextStyle(
        //         color: Theme.of(context).primaryColor,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Date ",
                          style: TextStyle(fontSize: 15),
                        ),
                        TextButton(
                          onPressed: () => _selectTime(context),
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
                          onPressed: () => _selectTime(context),
                          child: Text(
                            _selectedTime.toString(),
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                        const Text("-"),
                        TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            _selectedTime.toString(),
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
                          onPressed: () => _selectTime(context),
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
                          onPressed: () => _selectTime(context),
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
                ),
              ],
            )
          ],
        ));
  }
}
