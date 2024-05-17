import 'package:flutter/material.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/pick_image.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:uuid/uuid.dart';

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
  DateTime? _selectedStartDate;
  bool sdate = false;
  DateTime? _selectedEndDate;
  bool edate = false;
  String? _formattedSDate;
  String? _formattedEDate;
  //PlaceLocation? _selectedLocation;
  File? _selectedImage;
  String dropDownValue = list.first;
  bool enableButton = false;
  final _selectedLocation = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _selectedLocation.dispose();
    _description.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _selectedStartDate = picked;
          _formattedSDate = DateFormat.yMd().format(_selectedStartDate!);
          sdate = true;
        } else {
          _selectedEndDate = picked;
          _formattedEDate = DateFormat.yMd().format(_selectedEndDate!);
          edate = true;
        }
        _enableButton();
      });

      if ((_selectedEndDate != null &&
              isStartDate == true &&
              (!_selectedEndDate!.isAfter(picked) &&
                  !_selectedEndDate!.isAtSameMomentAs(picked))) ||
          (_selectedStartDate != null &&
              isStartDate == false &&
              (_selectedStartDate!.isAfter(picked) &&
                  !_selectedStartDate!.isAtSameMomentAs(picked)))) {
        setState(() {
          enableButton = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End time must be after start time.'),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.dial,
      context: context,
      initialTime: isStartTime
          ? _selectedStartTime ?? TimeOfDay.now()
          : _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _selectedStartTime = picked;
          stime = true;
        } else {
          _selectedEndTime = picked;
          etime = true;
        }
        _enableButton();
      });

      if (isStartTime &&
          _selectedEndTime != null &&
          _selectedStartDate!.isAtSameMomentAs(_selectedEndDate!)) {
        if (!checkTime(picked, _selectedEndTime!)) {
          setState(() {
            enableButton = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time.'),
            ),
          );
        }
      } else if (!isStartTime &&
          _selectedStartTime != null &&
          _selectedStartDate!.isAtSameMomentAs(_selectedEndDate!)) {
        if (!checkTime(_selectedStartTime!, picked)) {
          setState(() {
            enableButton = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time.'),
            ),
          );
        }
      }
    }
  }

  void _enableButton() {
    if ((stime &&
        etime &&
        sdate &&
        edate &&
        _selectedImage != null &&
        _selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null)) {
      setState(() {
        enableButton = true;
      });
    }
  }

  //TODO: Create method to compare if start time is unable to be set before end time on matching date

  bool checkTime(TimeOfDay time1, TimeOfDay time2) {
    DateTime first = DateTime(time1.hour, time1.minute);
    DateTime second = DateTime(time2.hour, time2.minute);
    return second.isAfter(first);
  }

  // String get currentImageId() async{
  //   final supabase;
  // }

  //TO-DO: generate unique image name to replace '/anotherimage' otherwise error occurs
  dynamic uploadImage(File imageFile) async {
    final supabase = (await ref.watch(supabaseInstance));
    final userId = supabase.client.auth.currentUser!.id.toString();

    var uuid = const Uuid();
    final currentImageName = uuid.v4();

    final response = await supabase.client.storage
        .from('Images')
        .upload('$userId/images/$currentImageName', imageFile);

    var imgId = await supabase.client.from('Images').insert(
        {'image_url': '$userId/images/$currentImageName'}).select('images_id');

    return imgId[0]["images_id"];

    // if (response.error == null) {
    //   print('Image uploaded successfully');
    // } else {
    //   print('Upload error: ${response.error!.message}');
    // }
  }

  Future<void> createEvent(
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedStartDate,
      DateTime selectedEndDate,
      File selectedImage,
      String inviteType,
      String location,
      String title,
      String description) async {
    DateTime start = DateTime(selectedStartDate.year, selectedStartDate.month,
        selectedStartDate.day, selectedStart.hour, selectedStart.minute);
    DateTime end = DateTime(selectedEndDate.year, selectedEndDate.month,
        selectedEndDate.day, selectedEnd.hour, selectedEnd.minute);

    var imageId = await uploadImage(selectedImage);
    final supabase = (await ref.watch(supabaseInstance)).client;
    final newEventRowMap = {
      'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
      'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
      'location': location,
      'description': description,
      'host': supabase.auth.currentUser!.id,
      'invitationType': inviteType,
      'image_id': imageId,
      'title': title
    };

    await supabase.from('Event').insert(newEventRowMap);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text('Create',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                )),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 69, 69, 69),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    "Start",
                    style: TextStyle(fontSize: 15),
                  ),
                  TextButton(
                    onPressed: () =>
                        _selectDate(context, true), // Select start date
                    child: Text(
                      _formattedSDate ??
                          "Select Start Date", // Format start date
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const Text("-"),
                  TextButton(
                    onPressed: sdate
                        ? () => _selectTime(context, true)
                        : null, // Select start time
                    child: Text(
                      _selectedStartTime?.format(context) ??
                          "Select Start Time", // Format start time
                      style: const TextStyle(fontSize: 15),
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
                        _selectDate(context, false), // Select end date
                    child: Text(
                      _formattedEDate ?? "Select End Date", // Format end date
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                  const Text("-"),
                  TextButton(
                    onPressed: edate
                        ? () => _selectTime(context, false)
                        : null, // Select end time
                    child: Text(
                      _selectedEndTime?.format(context) ??
                          "Select End Time", // Format end time
                      style: const TextStyle(fontSize: 15),
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
                      icon: const SizedBox.shrink(),
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
              child: TextField(
                controller: _selectedLocation,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter The Event's Address",
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
            // child: LocationInput(
            //   onSelectedLocation: (location) {
            //     _selectedLocation = location;
            //   },
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _title,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Enter Your Event Title",
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
            InkWell(
              onTap: () {
                if (_selectedImage == null) {
                  const snackbar =
                      SnackBar(content: Text('Select an image for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (sdate == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a start date for your event'));
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (edate == false) {
                  const snackbar = SnackBar(
                      content: Text('Select an end date for your event'));
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
                          _selectedStartDate!,
                          _selectedEndDate!,
                          _selectedImage!,
                          dropDownValue,
                          _selectedLocation.text,
                          _title.text,
                          _description.text,
                        );
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: ((context) => const RecommendedScreen())));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Event Created'),
                          ),
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
