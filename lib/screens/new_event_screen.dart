import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';
import 'package:nomo/widgets/pick_location.dart';
import 'package:nomo/models/place.dart';

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  TimeOfDay? _selectedStartTime; // Store start time
  TimeOfDay? _selectedEndTime;
  PlaceLocation? _selectedLocation;
  File? _selectedImage;
  String dropdownValue = "";

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final ThemeData theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? _selectedStartTime ?? TimeOfDay.now()
          : _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2101),
    );
    if (picked != null) print({picked.toString()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Center(
              child: Text("Create New Event +"),
            ),
            const SizedBox(height: 20),
            ImageInput(
              onPickImage: (image) {
                _selectedImage = image;
              },
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text(
                    "Date ",
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () => _selectDate(context),
                    child: const Text(
                      "Calendar Dropdown",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  const Text(
                    "Time",
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () =>
                        _selectTime(context, true), // Select start time
                    child: Text(
                      _selectedStartTime?.format(context) ??
                          "Select Start Time", // Format start time
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                  const Text("-"),
                  TextButton(
                    onPressed: () =>
                        _selectTime(context, false), // Select end time
                    child: Text(
                      _selectedEndTime?.format(context) ??
                          "Select End Time", // Format end time
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
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
            ),
            const Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline, // <--
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Enter Address: '),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        textAlign: TextAlign.start,
                        textAlignVertical: TextAlignVertical.bottom,
                        textCapitalization: TextCapitalization.sentences,
                        maxLength: 50,
                      ),
                    ),
                  ],
                )
                // child: LocationInput(
                //   onSelectedLocation: (location) {
                //     _selectedLocation = location;
                //   },
                // ),
                ),
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline, // <--
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Description: '),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textAlign: TextAlign.start,
                      textAlignVertical: TextAlignVertical.bottom,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 200,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
