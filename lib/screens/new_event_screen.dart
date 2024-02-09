import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/event_info.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';
import 'package:nomo/widgets/pick_location.dart';
import 'package:nomo/models/place.dart';
import 'package:intl/intl.dart';

const List<String> list = <String>['Public', 'Private', 'Selective'];

class NewEventScreen extends StatefulWidget {
  const NewEventScreen({super.key});

  @override
  State<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends State<NewEventScreen> {
  TimeOfDay? _selectedStartTime;
  bool stime = false;
  TimeOfDay? _selectedEndTime;
  bool etime = false;
  DateTime? _selectedDate;
  bool date = false;
  String? _formattedDate;
  PlaceLocation? _selectedLocation;
  File? _selectedImage;
  String dropDownValue = list.first;
  bool enableButton = false;
  String? message;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final ThemeData theme = Theme.of(context);
    final TimeOfDay? picked = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.dial,
      context: context,
      initialTime: isStartTime
          ? _selectedStartTime ?? TimeOfDay.now()
          : _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      if (isStartTime) stime = true;
      if (!isStartTime) etime = true;
      _enableButton();
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          stime = true;
        } else {
          _selectedEndTime = picked;
          etime = true;
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
    if (picked != null) {
      date = true;
      _enableButton();
      setState(() {
        _selectedDate = picked;
        _formattedDate = DateFormat.yMd().format(_selectedDate!);
        date = true;
      });
    }
  }

  void _enableButton() {
    if (stime != false &&
        etime != false &&
        date != false &&
        _selectedImage != null) {
      setState(() {
        enableButton = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    options? selectedOption;

    return Scaffold(
      appBar: MainAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Center(
              child: Text("Create New Event +"),
            ),
            const SizedBox(height: 10),
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
        ),
      ),
    );
  }
}
