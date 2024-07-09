import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:nomo/screens/interests_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/address_search_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

const List<String> list = <String>['Public', 'Selective', 'Private'];

class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key, this.event, this.isEdit});
  final Event? event;
  final bool? isEdit;

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
  File? _selectedImage;
  String dropDownValue = list.first;
  bool enableButton = false;
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _locationController = TextEditingController();
  bool virtualEvent = false;
  Map<Interests, bool> categories = {};
  late bool isNewEvent;
  late Event eventData;

  @override
  void initState() {
    isNewEvent = widget.event == null;
    if (!isNewEvent) {
      _title.text = widget.event!.title;
      _description.text = widget.event!.description;
      _locationController.text = widget.event!.location;
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
      virtualEvent = widget.event!.isVirtual;

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
    _locationController.dispose();
    _description.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      bool isValidDate = true;

      if (isStartDate && _selectedEndDate != null) {
        isValidDate = picked.isBefore(_selectedEndDate!);
      } else if (!isStartDate && _selectedStartDate != null) {
        isValidDate = picked.isAfter(_selectedStartDate!);
      }

      if (isValidDate) {
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
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isStartDate
                ? 'Start date must be before end date.'
                : 'End date must be after start date.'),
          ),
        );
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final TimeOfDay? picked = await showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
        (_selectedImage != null || isNewEvent == false) &&
        _selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null)) {
      setState(() {
        enableButton = true;
      });
    }
  }

  bool checkTime(TimeOfDay time1, TimeOfDay time2) {
    DateTime first = DateTime(time1.hour, time1.minute);
    DateTime second = DateTime(time2.hour, time2.minute);
    return second.isAfter(first);
  }

  dynamic uploadImage(File imageFile) async {
    final supabase = (await ref.read(supabaseInstance));
    final userId = supabase.client.auth.currentUser!.id.toString();
    var uuid = const Uuid();
    final currentImageName = uuid.v4();

    // Read the file
    Uint8List imageBytes = await imageFile.readAsBytes();

    // Decode the image
    img.Image? originalImage = img.decodeImage(imageBytes);

    if (originalImage != null) {
      int originalWidth = originalImage.width;
      int originalHeight = originalImage.height;

      // Calculate dimensions for 16:9 aspect ratio
      int targetWidth, targetHeight;
      if (originalWidth / originalHeight > 16 / 9) {
        // Image is wider than 16:9
        targetHeight = originalHeight;
        targetWidth = (targetHeight * 16 / 9).round();
      } else {
        // Image is taller than 16:9
        targetWidth = originalWidth;
        targetHeight = (targetWidth * 9 / 16).round();
      }

      // Crop to 16:9
      int x = (originalWidth - targetWidth) ~/ 2;
      int y = (originalHeight - targetHeight) ~/ 2;
      img.Image croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: targetWidth,
        height: targetHeight,
      );

      // Resize if width is greater than 1440 pixels
      if (targetWidth > 1440) {
        croppedImage = img.copyResize(
          croppedImage,
          width: 1440,
          height: 810,
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode the image to PNG
      List<int> processedImageBytes = img.encodePng(croppedImage);

      // Create a temporary file with the processed image
      Directory tempDir = await getTemporaryDirectory();
      File tempFile = File('${tempDir.path}/processed_$currentImageName.png');
      await tempFile.writeAsBytes(processedImageBytes);

      // Upload the processed image
      final response = await supabase.client.storage
          .from('Images')
          .upload('$userId/images/$currentImageName', tempFile);

      // Delete the temporary file
      await tempFile.delete();

      var imgId = await supabase.client
          .from('Images')
          .insert({'image_url': '$userId/images/$currentImageName'}).select(
              'images_id');
      return imgId[0]["images_id"];
    } else {
      // Handle error: unable to decode image
      throw Exception('Unable to decode image');
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _enableButton();
    });
  }

  Future<void> _pickImageFromCamera() async {
    final XFile? pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _enableButton();
    });
  }

  Future<String> getCords(location) async {
    List<Location> locations = await locationFromAddress(location);
    return 'POINT(${locations.first.longitude} ${locations.first.latitude})';
  }

  Future<void> createEvent(
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedStartDate,
      DateTime selectedEndDate,
      File selectedImage,
      String inviteType,
      var location,
      String title,
      String description) async {
    DateTime start = DateTime(selectedStartDate.year, selectedStartDate.month,
        selectedStartDate.day, selectedStart.hour, selectedStart.minute);
    DateTime end = DateTime(selectedEndDate.year, selectedEndDate.month,
        selectedEndDate.day, selectedEnd.hour, selectedEnd.minute);

    var imageId = await uploadImage(selectedImage);
    final supabase = (await ref.read(supabaseInstance)).client;

    var point;
    if (virtualEvent) {
      point = null;
      location = null;
    } else {
      point = await getCords(location);
    }
    final newEventRowMap = {
      'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
      'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
      'location': location,
      'description': description,
      'host': supabase.auth.currentUser!.id,
      'invitationType': inviteType,
      'image_id': imageId,
      'title': title,
      'is_virtual': virtualEvent,
      'point': point
    };
    if (categories.isNotEmpty) {
      final List<String> interestStrings = categories.entries
          .where((entry) => entry.value)
          .map((entry) =>
              ref.read(profileProvider.notifier).enumToString(entry.key))
          .toList();

      newEventRowMap['event_interests'] = interestStrings;
    }

    final responseId = await supabase
        .from('Event')
        .insert(newEventRowMap)
        .select('event_id')
        .single();

    eventData = await ref
        .read(eventsProvider.notifier)
        .deCodeLinkEvent(responseId['event_id']);

    ref.read(profileProvider.notifier).createBlockedTime(
          supabase.auth.currentUser!.id,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
          DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
          title,
          responseId['event_id'],
        );
  }

  Future<void> updateEvent(
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedStartDate,
      DateTime selectedEndDate,
      File? selectedImage,
      String inviteType,
      var location,
      String title,
      String description) async {
    DateTime start = DateTime(selectedStartDate.year, selectedStartDate.month,
        selectedStartDate.day, selectedStart.hour, selectedStart.minute);
    DateTime end = DateTime(selectedEndDate.year, selectedEndDate.month,
        selectedEndDate.day, selectedEnd.hour, selectedEnd.minute);

    final Map newEventRowMap;
    final supabase = (await ref.watch(supabaseInstance)).client;
    var point;

    if (virtualEvent) {
      point = null;
      location = null;
    } else {
      point = await getCords(location);
    }

    if (selectedImage != null) {
      await supabase.storage.from('Images').remove([widget.event!.imageUrl]);
      var imageId = await uploadImage(selectedImage);

      newEventRowMap = {
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'image_id': imageId,
        'title': title,
        'point': point
      };
    } else {
      newEventRowMap = {
        'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
        'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'title': title,
        'point': point
      };
    }

    await supabase
        .from('Event')
        .update(newEventRowMap)
        .eq('event_id', widget.event?.eventId);
    ref.read(attendEventsProvider.notifier).deCodeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        actions: [
          if (widget.isEdit == true)
            IconButton(
              onPressed: () {
                FocusManager.instance.primaryFocus?.unfocus();
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(
                            'Are you sure you want to delete this event?',
                            style: TextStyle(
                                color: Theme.of(context).primaryColorDark),
                          ),
                          actions: [
                            TextButton(
                                onPressed: () async {
                                  ref
                                      .read(eventsProvider.notifier)
                                      .deleteEvent(widget.event!);
                                  Navigator.of(context)
                                      .pushAndRemoveUntil(
                                          MaterialPageRoute(
                                              builder: ((context) =>
                                                  const NavBar())),
                                          (route) => false)
                                      .then((result) => Navigator.pop(context));
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Event Deleted"),
                                    ),
                                  );
                                },
                                child: const Text('DELETE')),
                            TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('CANCEL')),
                          ],
                        ));
              },
              icon: Icon(
                Icons.delete_forever,
                size: MediaQuery.of(context).size.aspectRatio * 85,
              ),
              color: const Color.fromARGB(212, 255, 80, 67),
            ),
        ],
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text(isNewEvent ? 'Create Event' : 'Update Event',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                )),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (BuildContext context) {
                    // Get screen size
                    final screenSize = MediaQuery.of(context).size;
                    final double fontSize = screenSize.width *
                        0.04; // 4% of screen width for font size

                    return Container(
                      width: double.infinity, // Ensures full width
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenSize.width * 0.05,
                            vertical: screenSize.height * 0.03,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment
                                .stretch, // Stretches buttons to full width
                            children: [
                              TextButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Select from Gallery",
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    SizedBox(width: screenSize.width * 0.01),
                                    const Icon(Icons.photo_library_rounded)
                                  ],
                                ),
                                onPressed: () {
                                  _pickImageFromGallery();
                                  Navigator.pop(context);
                                },
                              ),
                              const Divider(),
                              SizedBox(height: screenSize.height * 0.01),
                              TextButton(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Take a Picture",
                                      style: TextStyle(fontSize: fontSize),
                                    ),
                                    SizedBox(width: screenSize.width * 0.01),
                                    const Icon(Icons.camera_alt_rounded)
                                  ],
                                ),
                                onPressed: () {
                                  _pickImageFromCamera();
                                  Navigator.pop(context);
                                },
                              ),
                              const Divider(),
                              SizedBox(height: screenSize.height * 0.005),
                              TextButton(
                                child: Text(
                                  "Close",
                                  style: TextStyle(fontSize: fontSize),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      height: MediaQuery.of(context).size.height / 3,
                      decoration: _selectedImage != null
                          ? BoxDecoration(
                              border:
                                  Border.all(color: Colors.black87, width: 2),
                              color: Colors.grey.shade200,
                              image: DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover))
                          : (isNewEvent)
                              ? BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black87, width: 2),
                                  color: Colors.grey.shade200,
                                )
                              : BoxDecoration(
                                  border: Border.all(
                                      color: Colors.black87, width: 2),
                                  color: Colors.grey.shade200,
                                  image: DecorationImage(
                                      image:
                                          NetworkImage(widget.event?.imageUrl),
                                      fit: BoxFit.cover),
                                ),
                      child: _selectedImage == null && isNewEvent
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
                                    size:
                                        MediaQuery.of(context).size.height / 15,
                                  ),
                                  const Text("Add An Image")
                                ],
                              ),
                            )
                          : null,
                    ),
                  ),
                  const Positioned(
                    right: 8,
                    bottom: 8,
                    child: Icon(
                      Icons.mode_edit_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    "Date",
                    style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  TextButton(
                    onPressed: () =>
                        _selectDate(context, true), // Select start date
                    child: Text(
                      _formattedSDate ?? "Start", // Format start date
                      style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                  Text(
                    "to",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  TextButton(
                    onPressed: () =>
                        _selectDate(context, false), // Select end date
                    child: Text(
                      _formattedEDate ?? "End", // Format end date
                      style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Text(
                    "Times",
                    style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  TextButton(
                    onPressed: sdate
                        ? () => _selectTime(context, true)
                        : null, // Select start time
                    child: Text(
                      _selectedStartTime?.format(context) ??
                          "Start", // Format start time
                      style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: edate
                        ? () => _selectTime(context, false)
                        : null, // Select end time
                    child: Text(
                      _selectedEndTime?.format(context) ??
                          "End", // Format end time
                      style: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 10.0),
              child: Row(
                children: [
                  Text(
                    "Invitation Type: ",
                    style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  IconButton(
                      onPressed: () {
                        showAdaptiveDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * .21,
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'The Invatation Type you choose effects who can see the event',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      'Public Events: are visable to all users',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Private Events: are only viable to your Friends',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Selective Events: are only visable to those you have shared a link to',
                                      style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.info,
                        color: Theme.of(context).colorScheme.onSecondary,
                      )),
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
                  Text(
                    "Virtual",
                    style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  IconButton(
                      onPressed: () {
                        setState(() {
                          virtualEvent = !virtualEvent;
                          if (virtualEvent) {
                            _locationController.text = 'Virtual';
                          } else {
                            _locationController.clear();
                          }
                        });
                      },
                      icon: virtualEvent
                          ? Icon(
                              Icons.check_box_outlined,
                              color: Theme.of(context).colorScheme.onSecondary,
                            )
                          : Icon(
                              Icons.check_box_outline_blank,
                              color: Theme.of(context).colorScheme.onSecondary,
                            ))
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AddressSearchField(
                controller: _locationController,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _title,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Enter Your Event Title",
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary),
                  contentPadding: const EdgeInsets.all(5),
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                maxLines: null,
                textAlign: TextAlign.start,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _description,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: "Enter Your Event Description",
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary),
                  contentPadding: const EdgeInsets.all(5),
                ),
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.done,
                maxLines: null,
                textAlign: TextAlign.start,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 200,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
            ElevatedButton(
                onPressed: () async {
                  FocusManager.instance.primaryFocus?.unfocus();
                  final selectedInterests = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (builder) => InterestsScreen(
                        isEditing: false,
                        creatingEvent: true,
                        selectedInterests: categories,
                      ),
                    ),
                  );
                  if (selectedInterests != null) {
                    setState(() {
                      categories = selectedInterests;
                    });
                  }
                },
                child: const Text('Categories')),
            SizedBox(height: MediaQuery.sizeOf(context).height / 80),
            InkWell(
              onTap: () {
                if (_selectedImage == null && isNewEvent) {
                  const snackbar =
                      SnackBar(content: Text('Select an image for your event'));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (sdate == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a start date for your event'));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (edate == false) {
                  const snackbar = SnackBar(
                      content: Text('Select an end date for your event'));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (stime == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a start time for your event'));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(snackbar);
                } else if (etime == false) {
                  const snackbar = SnackBar(
                      content: Text('Select a end time for your event'));
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                    ? isNewEvent
                        ? () async {
                            FocusManager.instance.primaryFocus?.unfocus();
                            createEvent(
                              _selectedStartTime!,
                              _selectedEndTime!,
                              _selectedStartDate!,
                              _selectedEndDate!,
                              _selectedImage!,
                              dropDownValue,
                              _locationController.text,
                              _title.text,
                              _description.text,
                            ).then((value) => Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                                    builder: ((context) => DetailedEventScreen(
                                        eventData: eventData)))));
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event Created'),
                              ),
                            );
                          }
                        : () {
                            print(widget.event!.imageId);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Are you sure you want to update this event?',
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).primaryColorDark),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      await updateEvent(
                                        _selectedStartTime!,
                                        _selectedEndTime!,
                                        _selectedStartDate!,
                                        _selectedEndDate!,
                                        _selectedImage,
                                        dropDownValue,
                                        _locationController.text,
                                        _title.text,
                                        _description.text,
                                      );
                                      Navigator.of(context)
                                          .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: ((context) =>
                                                      const NavBar())),
                                              (route) => false)
                                          .then((result) =>
                                              Navigator.pop(context));
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Event Updated'),
                                        ),
                                      );
                                    },
                                    child: const Text('YES'),
                                  ),
                                ],
                              ),
                            );
                          }
                    : null,
                child: Text(isNewEvent ? 'Create Event' : 'Update Event'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
