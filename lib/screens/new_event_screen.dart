import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo/widgets/app_bar.dart';
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
                    child: Text(
                      _formattedDate ?? "Select Event Date",
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
                    "Invitation Type: ",
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 10),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropDownValue,
                      elevation: 16,
                      icon: SizedBox.shrink(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                      onChanged: (String? value) {
                        // This is called when the user selects an item.
                        setState(() {
                          dropDownValue = value!;
                        });
                      },
                      items: list.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter Your Event Address",
                    contentPadding: EdgeInsets.all(5),
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  maxLines: null,
                  textAlign: TextAlign.start,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 50,
                ),
              ),
            ),
            // child: LocationInput(
            //   onSelectedLocation: (location) {
            //     _selectedLocation = location;
            //   },
            // ),

            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Enter Your Event Description",
                    contentPadding: EdgeInsets.all(5),
                  ),
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.done,
                  maxLines: null,
                  textAlign: TextAlign.start,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 200,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                if (_selectedImage == null) {
                  const snackbar =
                      SnackBar(content: Text('Select an image for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (date == false) {
                  const snackbar =
                      SnackBar(content: Text('Select a date for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (stime == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a start time for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (etime == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a end time for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                }
              },
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
                onPressed: enableButton ? () {} : null,
                child: const Text('Create Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}