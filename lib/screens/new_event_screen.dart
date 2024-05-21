import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';

const List<String> list = <String>['Public', 'Private', 'Selective'];

class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key, required this.isNewEvent, this.event});
  final bool isNewEvent;
  final Event? event;

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
  void initState() {
    if (!widget.isNewEvent) {
      _title.text = widget.event!.title;
      _description.text = widget.event!.description;
      _selectedLocation.text = widget.event!.location;
      //_selectedImage = widget.event!.imageUrl;
      stime = true;
      etime = true;
      sdate = true;
      edate = true;
      _selectedStartTime =
          TimeOfDay.fromDateTime(DateTime.parse(widget.event!.sdate));
      _selectedEndTime =
          TimeOfDay.fromDateTime(DateTime.parse(widget.event!.edate));
      _selectedStartDate = DateTime.parse(widget.event!.sdate);
      _selectedEndDate = DateTime.parse(widget.event!.edate);
      _formattedEDate =
          DateFormat.yMd().format(DateTime.parse(widget.event!.edate));
      _formattedSDate =
          DateFormat.yMd().format(DateTime.parse(widget.event!.sdate));
      enableButton = true;

      for (int i = 0; i < list.length; i++) {
        if (list[i] == widget.event!.eventType) {
          dropDownValue = list[i];
          break;
        }
      }
    }
    super.initState();
  }

  @override
  void dispose() {
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
        (_selectedImage != null || widget.isNewEvent == false) &&
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

  Future<void> updateEvent(
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedStartDate,
      DateTime selectedEndDate,
      File? selectedImage,
      String inviteType,
      String location,
      String title,
      String description) async {
    DateTime start = DateTime(selectedStartDate.year, selectedStartDate.month,
        selectedStartDate.day, selectedStart.hour, selectedStart.minute);
    DateTime end = DateTime(selectedEndDate.year, selectedEndDate.month,
        selectedEndDate.day, selectedEnd.hour, selectedEnd.minute);

    final newEventRowMap;
    final supabase = (await ref.watch(supabaseInstance)).client;

    if (selectedImage != null) {
      final previousImage = await supabase
          .from('Images')
          .select('image_url')
          .eq('images_id', widget.event?.imageId)
          .single()
          .then((response) => response['image_url'] as String);
      await supabase.storage.from('Images').remove([previousImage]);
      var imageId = await uploadImage(selectedImage);

      newEventRowMap = {
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'image_id': imageId,
        'title': title
      };
    } else {
      newEventRowMap = {
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'title': title
      };
    }

    await supabase
        .from('Event')
        .update(newEventRowMap)
        .eq('event_id', widget.event?.eventId);
    ref.read(attendEventsProvider.notifier).deCodeData();
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text(widget.isNewEvent ? 'Create' : 'Update',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                )),
          ),
        ),
        // bottom: PreferredSize(
        //   preferredSize: const Size.fromHeight(4.0),
        //   child: Container(
        //     color: const Color.fromARGB(255, 69, 69, 69),
        //     height: 1.0,
        //   ),
        // ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height / 6,
                      width: double.infinity,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                              child: const Text("Select from Gallery"),
                              onPressed: () {
                                _pickImageFromGallery();
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text("Take a Picture"),
                              onPressed: () {
                                _pickImageFromCamera();
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text("Close"),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ]),
                    );
                  },
                );
              },
              child: Container(
                height: MediaQuery.of(context).size.height / 3,
                //color: Colors.grey.shade200,
                decoration: _selectedImage != null
                    ? BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                        color: Colors.grey.shade200,
                        image: DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.fill))
                    : BoxDecoration(
                        border: Border.all(color: Colors.black87, width: 2),
                        color: Colors.grey.shade200,
                      ),
                child: _selectedImage == null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: MediaQuery.of(context).size.height / 15,
                            ),
                            const Text("Add An Image")
                          ],
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 30),
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
                if (_selectedImage == null && widget.isNewEvent) {
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
                    ? widget.isNewEvent
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
                            ).then((value) => Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                                    builder: ((context) => const NavBar()))));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event Created'),
                              ),
                            );
                          }
                        : () {
                            updateEvent(
                              _selectedStartTime!,
                              _selectedEndTime!,
                              _selectedStartDate!,
                              _selectedEndDate!,
                              _selectedImage,
                              dropDownValue,
                              _selectedLocation.text,
                              _title.text,
                              _description.text,
                            );
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: ((context) =>
                                    const RecommendedScreen())));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event Updated'),
                              ),
                            );
                          }
                    : null,
                child:
                    Text(widget.isNewEvent ? 'Create Event' : 'Update Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
