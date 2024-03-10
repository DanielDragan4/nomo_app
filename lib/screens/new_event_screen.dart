import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';
import 'package:nomo/models/place.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/providers/saved_session_provider.dart';

const List<String> list = <String>['Public', 'Private', 'Selective'];

class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key});

  @override
  ConsumerState<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends ConsumerState<NewEventScreen> {
  TimeOfDay? _selectedStartTime;
  bool stime = false;
  TimeOfDay? _selectedEndTime;
  bool etime = false;
  DateTime? _selectedDate;
  bool date = false;
  String? _formattedDate;
  //PlaceLocation? _selectedLocation;
  File? _selectedImage;
  String dropDownValue = list.first;
  bool enableButton = false;
  int? _inviteType = 1;
  final _selectedLocation = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _selectedLocation.dispose();
    _description.dispose();
    super.dispose();
  }

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

  //TO-DO: generate unique image name to replace '/anotherimage' otherwise error occurs
  Future<void> uploadImage(File imageFile) async {
    final supabase = ref.watch(supabaseInstance);
    final userId = (await supabase).client.auth.currentUser!.id.toString();
    final response = await (await supabase)
        .client
        .storage
        .from('Images')
        .upload('${userId}/images/image12', imageFile);

    // if (response.error == null) {
    //   print('Image uploaded successfully');
    // } else {
    //   print('Upload error: ${response.error!.message}');
    // }
  }

  Future<void> createEvent(
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedDate,
      File selectedImage,
      int inviteType,
      String location,
      String description) async {
    uploadImage(selectedImage);
    print('Location: $_selectedLocation');
    print('Description: $_description');
    final supabase = (await ref.read(supabaseInstance)).client;

    final newEventRowMap = {
      'time_start': selectedStart,
      'time_end': selectedEnd,
      'location': location,
      'description': description,
      'host': supabase.auth.currentUser!.id,
      'invitationtype': inviteType
    };

    await supabase.from('Event').insert(newEventRowMap);
  }

  int _getInvite(String type) {
    switch (type) {
      case 'Public':
        return 0;
      case 'Private':
        return 1;
      case 'Selective':
        return 2;
    }
    return -1;
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
      appBar: const MainAppBar(),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Expanded(
                child: TextField(
                  controller: _selectedLocation,
                  decoration: const InputDecoration(
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Expanded(
                child: TextField(
                  controller: _description,
                  decoration: const InputDecoration(
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
                onPressed: enableButton
                    ? () {
                        createEvent(
                          _selectedStartTime!,
                          _selectedEndTime!,
                          _selectedDate!,
                          _selectedImage!,
                          _getInvite(dropDownValue),
                          _selectedLocation.text,
                          _description.text,
                        );
                      }
                    : null,
                child: const Text('Create Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
