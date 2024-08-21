import 'dart:typed_data';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:nomo/screens/profile/interests_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/widgets/address_search_widget.dart';
import 'package:nomo/widgets/custom_time_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

const List<String> list = <String>['Public', 'Selective', 'Private'];

class EventCreateScreen extends ConsumerStatefulWidget {
  const EventCreateScreen({super.key, this.event, this.isEdit, this.onEventCreated});
  final Event? event;
  final bool? isEdit;
  final VoidCallback? onEventCreated;

  @override
  ConsumerState<EventCreateScreen> createState() => _EventCreateScreenState();
}

//TO-DO
// Show loading indicator while event is being created
// Reset screen after event is created

class _EventCreateScreenState extends ConsumerState<EventCreateScreen> {
  int _currentStep = 0;
  final List<String> _steps = ['Basics', 'Date & Time', 'Details', 'Review'];

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
  bool _isImageProcessing = false;
  bool _isLoading = false;
  bool _titleError = false;
  bool _descriptionError = false;
  bool _locationError = false;
  bool _dateError = false;
  bool _timeError = false;
  bool _isRecurring = false;
  bool _isTicketed = false;
  bool _step1Valid = false;
  bool _step2Valid = false;
  bool _step3Valid = false;
  List<EventDate> eventDates = [];
  static const int MAX_DATES = 5;

  @override
  void initState() {
    isNewEvent = (widget.event == null);
    if (!isNewEvent) {
      _title.text = widget.event!.title;
      _description.text = widget.event!.description;

      if (widget.event!.isVirtual) {
        _locationController.text = "Virtual";
      } else {
        _locationController.text = widget.event!.location;
      }
      stime = true;
      etime = true;
      sdate = true;
      edate = true;
      for(var i = 0; i< widget.event!.sdate.length; i++) {
      EventDate d = EventDate(); 
      d.startTime = TimeOfDay.fromDateTime(DateTime.parse(widget.event!.sdate[i]));
      d.endTime = TimeOfDay.fromDateTime(DateTime.parse(widget.event!.edate[i]));
      d.startDate = DateTime.parse(widget.event!.sdate[i]);
      d.endDate = DateTime.parse(widget.event!.edate[i]);

      eventDates.add(d);
      }

      enableButton = true;
      virtualEvent = widget.event!.isVirtual;
      _isRecurring = widget.event!.isRecurring;
      _isTicketed = widget.event!.isTicketed;
      categories = convertCategoriesToMap(widget.event!.categories);

      for (int i = 0; i < list.length; i++) {
        if (list[i] == widget.event!.eventType) {
          dropDownValue = list[i];
          break;
        }
      }
    } else {
      categories = {for (var interest in Interests.values) interest: false};
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

  void _validateStep1(bool changedTitle) {
    setState(() {
      _step1Valid = _selectedImage != null && _title.text.isNotEmpty;
      if (changedTitle) {
        _titleError = _title.text.isEmpty;
      }
    });
  }

  void _validateStep2() {
    setState(() {
      bool allDatesValid = eventDates.isNotEmpty &&
          eventDates.every((date) =>
              date.startDate != null &&
              date.endDate != null &&
              date.startTime != null &&
              date.endTime != null &&
              _isValidDateTimeRange(date));

      bool noOverlaps = !_hasOverlappingDates();

      _step2Valid = allDatesValid && noOverlaps;

      if (!noOverlaps) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Date/time ranges cannot overlap. Please adjust your selections.')),
        );
      }
    });
  }

  bool _isValidDateTimeRange(EventDate date) {
    if (date.startDate == null || date.endDate == null || date.startTime == null || date.endTime == null) {
      return false;
    }

    DateTime startDateTime = DateTime(
      date.startDate!.year,
      date.startDate!.month,
      date.startDate!.day,
      date.startTime!.hour,
      date.startTime!.minute,
    );

    DateTime endDateTime = DateTime(
      date.endDate!.year,
      date.endDate!.month,
      date.endDate!.day,
      date.endTime!.hour,
      date.endTime!.minute,
    );

    return endDateTime.isAfter(startDateTime);
  }

  bool _hasOverlappingDates() {
    for (int i = 0; i < eventDates.length; i++) {
      for (int j = i + 1; j < eventDates.length; j++) {
        if (_datesOverlap(eventDates[i], eventDates[j])) {
          return true;
        }
      }
    }
    return false;
  }

  bool _datesOverlap(EventDate date1, EventDate date2) {
    if (date1.startDate == null ||
        date1.endDate == null ||
        date1.startTime == null ||
        date1.endTime == null ||
        date2.startDate == null ||
        date2.endDate == null ||
        date2.startTime == null ||
        date2.endTime == null) {
      return false;
    }

    DateTime start1 = DateTime(
      date1.startDate!.year,
      date1.startDate!.month,
      date1.startDate!.day,
      date1.startTime!.hour,
      date1.startTime!.minute,
    );

    DateTime end1 = DateTime(
      date1.endDate!.year,
      date1.endDate!.month,
      date1.endDate!.day,
      date1.endTime!.hour,
      date1.endTime!.minute,
    );

    DateTime start2 = DateTime(
      date2.startDate!.year,
      date2.startDate!.month,
      date2.startDate!.day,
      date2.startTime!.hour,
      date2.startTime!.minute,
    );

    DateTime end2 = DateTime(
      date2.endDate!.year,
      date2.endDate!.month,
      date2.endDate!.day,
      date2.endTime!.hour,
      date2.endTime!.minute,
    );

    return (start1.isBefore(end2) && end1.isAfter(start2)) || (start2.isBefore(end1) && end2.isAfter(start1));
  }

  void _validateStep3() {
    setState(() {
      _step3Valid = _description.text.isNotEmpty && (_locationController.text.isNotEmpty || virtualEvent);
    });
  }

  void _showLoadingOverlay() {
    setState(() {
      _isLoading = true;
    });
  }

  void _hideLoadingOverlay() {
    setState(() {
      _isLoading = false;
    });
  }

  Map<Interests, bool> convertCategoriesToMap(List<dynamic> categoryStrings) {
    Map<Interests, bool> result = {for (var interest in Interests.values) interest: false};

    for (var categoryString in categoryStrings) {
      for (var interest in Interests.values) {
        if (interest.value == categoryString) {
          result[interest] = true;
          break;
        }
      }
    }

    return result;
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate, int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? eventDates[index].startDate ?? DateTime.now()
          : eventDates[index].endDate ?? eventDates[index].startDate ?? DateTime.now(),
      firstDate: isStartDate ? DateTime.now() : eventDates[index].startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          eventDates[index].startDate = picked;
          _adjustEndDateTime(index);
        } else {
          eventDates[index].endDate = picked;
        }
        _validateStep2();
      });
    }
  }

  void _showDateTimeAdjustmentNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('End date and time have been automatically adjusted to ensure they come after the start.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime, int index) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final initialTime = isStartTime
        ? eventDates[index].startTime ?? TimeOfDay(hour: 12, minute: 00)
        : eventDates[index].endTime ?? TimeOfDay(hour: 12, minute: 00);

    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePicker(
          initialTime: initialTime,
          onTimeSelected: (TimeOfDay selectedTime) {
            return selectedTime;
          },
          isStartTime: isStartTime,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          eventDates[index].startTime = picked;
          _adjustEndDateTime(index);
        } else {
          eventDates[index].endTime = picked;
        }
        _validateStep2();
      });
    }
  }

  void _adjustEndDateTime(int index) {
    if (eventDates[index].startDate != null &&
        eventDates[index].startTime != null &&
        eventDates[index].endDate != null &&
        eventDates[index].endTime != null) {
      DateTime startDateTime = DateTime(
        eventDates[index].startDate!.year,
        eventDates[index].startDate!.month,
        eventDates[index].startDate!.day,
        eventDates[index].startTime!.hour,
        eventDates[index].startTime!.minute,
      );

      DateTime endDateTime = DateTime(
        eventDates[index].endDate!.year,
        eventDates[index].endDate!.month,
        eventDates[index].endDate!.day,
        eventDates[index].endTime!.hour,
        eventDates[index].endTime!.minute,
      );

      if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
        // Set the end date to the start date initially
        endDateTime = DateTime(
          startDateTime.year,
          startDateTime.month,
          startDateTime.day,
          eventDates[index].endTime!.hour,
          eventDates[index].endTime!.minute,
        );

        // If end time is still before or equal to start time, add one day to the end date
        if (endDateTime.isBefore(startDateTime) || endDateTime.isAtSameMomentAs(startDateTime)) {
          endDateTime = endDateTime.add(Duration(days: 1));
        }

        eventDates[index].endDate = endDateTime;

        // Notify user
        _showDateTimeAdjustmentNotification();
      }
    }
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour || (time1.hour == time2.hour && time1.minute > time2.minute);
  }

  void _showTimeAdjustmentNotification() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('End time has been automatically adjusted to ensure it\'s after the start time.'),
        duration: Duration(seconds: 4),
      ),
    );
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
      final response =
          await supabase.client.storage.from('Images').upload('$userId/images/$currentImageName', tempFile);

      // Delete the temporary file
      await tempFile.delete();

      var imgId = await supabase.client
          .from('Images')
          .insert({'image_url': '$userId/images/$currentImageName'}).select('images_id');
      return imgId[0]["images_id"];
    } else {
      // Handle error: unable to decode image
      throw Exception('Unable to decode image');
    }
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    setState(() {
      _isImageProcessing = true;
    });

    try {
      final XFile? pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile == null) {
        setState(() {
          _isImageProcessing = false;
        });
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.ratio16x9,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Image',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = File(croppedFile.path);
          _validateStep1(false);
        });
      }
    } finally {
      setState(() {
        _isImageProcessing = false;
      });
    }
  }

  Future<String> getCords(location) async {
    List<Location> locations = await locationFromAddress(location);
    return 'POINT(${locations.first.longitude} ${locations.first.latitude})';
  }

  Future<void> createEvent(
      File selectedImage,
      String inviteType,
      var location,
      String title,
      String description,
      bool isRecurring,
      bool isTicketed) async {
    _showLoadingOverlay();
    try {
      List<String> start = [];
      List<String> end = [];
      for(var dates in eventDates) {
        start.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(dates.startDate!.year, dates.startDate!.month, dates.startDate!.day,
          dates.startTime!.hour, dates.startTime!.minute)));
        end.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
          dates.endDate!.year, dates.endDate!.month, dates.endDate!.day, dates.endTime!.hour, dates.endTime!.minute)));
      }
      
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
        'location': location,
        'description': description,
        'host': supabase.auth.currentUser!.id,
        'invitationType': inviteType,
        'image_id': imageId,
        'title': title,
        'is_virtual': virtualEvent,
        'point': point,
        'recurring': isRecurring,
        'ticketed': isTicketed
      };
      if (categories.isNotEmpty) {
        final List<String> interestStrings = categories.entries
            .where((entry) => entry.value)
            .map((entry) => ref.read(profileProvider.notifier).enumToString(entry.key))
            .toList();

        newEventRowMap['event_interests'] = interestStrings;
      }

      final responseId = await supabase.from('Event').insert(newEventRowMap).select('event_id').single();
      for(var i = 0; i < start.length; i++) {
        final newDateRowMap = {
          'event_id': responseId['event_id'],
          'time_start': start[i],
          'time_end': end[i],
        };
        await supabase.from('Dates').insert(newDateRowMap);

        ref.read(profileProvider.notifier).createBlockedTime(
            supabase.auth.currentUser!.id,
            start[i],
            end[i],
            title,
            responseId['event_id'],
          );
      }

      eventData = await ref.read(eventsProvider.notifier).deCodeLinkEvent(responseId['event_id']);

    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> updateEvent(
      File? selectedImage,
      String inviteType,
      var location,
      String title,
      String description,
      bool isRecurring,
      bool isTicketed) async {
      List<String> start = [];
      List<String> end = [];
      for(var dates in eventDates) {
        start.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(dates.startDate!.year, dates.startDate!.month, dates.startDate!.day,
          dates.startTime!.hour, dates.startTime!.minute)));
        end.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(
          dates.endDate!.year, dates.endDate!.month, dates.endDate!.day, dates.endTime!.hour, dates.endTime!.minute)));
      }

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
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'image_id': imageId,
        'title': title,
        'point': point,
        'recurring': isRecurring,
        'ticketed': isTicketed
      };
    } else {
      newEventRowMap = {
        'location': location,
        'description': description,
        'invitationType': inviteType,
        'title': title,
        'point': point
      };
    }
    if (categories.isNotEmpty) {
      final List<String> interestStrings = categories.entries
          .where((entry) => entry.value)
          .map((entry) => ref.read(profileProvider.notifier).enumToString(entry.key))
          .toList();

      newEventRowMap['event_interests'] = interestStrings;
    }

    await supabase.from('Event').update(newEventRowMap).eq('event_id', widget.event?.eventId);
    ref.read(attendEventsProvider.notifier).deCodeData();
    for(var i = 0; i < start.length; i++) {
    final newDateRowMap = {
      'event_id': widget.event?.eventId,
      'time_start': start[i],
      'time_end': end[i],
      };
    await supabase.from('Dates').update(newDateRowMap).eq('event_id', widget.event?.eventId);
    }
  }

  Widget _buildInvitationTypeItem(BuildContext context, String title, String description) {
    return Column(
      //crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(widget.isEdit == true ? 'Edit Event' : 'Create Event'),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          body: Column(
            children: [
              _buildCustomStepper(),
              Expanded(
                child: SingleChildScrollView(
                  child: _buildStepContent(),
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }

  Widget _buildCustomStepper() {
    return Container(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _steps.length,
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width / _steps.length,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _currentStep >= index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  child: _currentStep > index
                      ? Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('${index + 1}', style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
                SizedBox(height: 4),
                Text(
                  _steps[index],
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Content();
      case 1:
        return _buildStep2Content();
      case 2:
        return _buildStep3Content();
      case 3:
        return _buildStep4Content();
      default:
        return Container();
    }
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            ElevatedButton(
              onPressed: _onStepCancel,
              child: Text('Back'),
            ),
          ElevatedButton(
            onPressed: _isStepValid(_currentStep) ? _onStepContinue : null,
            child: Text(_currentStep == 3 ? 'Confirm' : 'Continue'),
          ),
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep < _steps.length - 1 && _isStepValid(_currentStep)) {
      setState(() {
        _currentStep += 1;
      });
    } else if (_currentStep == _steps.length - 1) {
      _showConfirmationScreen();
      _enableButton();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _step1Valid;
      case 1:
        return _step2Valid;
      case 2:
        return _step3Valid;
      case 3:
        return true; // Review step is always valid
      default:
        return false;
    }
  }

  Widget _buildStep1Content() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (BuildContext context) {
                // Get screen size
                final screenSize = MediaQuery.of(context).size;
                final double fontSize = screenSize.width * 0.04; // 4% of screen width for font size

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
                        crossAxisAlignment: CrossAxisAlignment.stretch, // Stretches buttons to full width
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
                              _pickAndCropImage(ImageSource.gallery);
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
                              _pickAndCropImage(ImageSource.camera);
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
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              width: double.infinity,
              color: Colors.grey[300],
              child: _isImageProcessing
                  ? Center(child: const CircularProgressIndicator())
                  : _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Icon(Icons.add_a_photo, size: 50),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: TextField(
            controller: _title,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: _titleError ? Colors.red : Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _titleError ? Colors.red : Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _titleError ? Colors.red : Theme.of(context).colorScheme.primary),
              ),
              labelText: "Enter Your Event Title",
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              contentPadding: const EdgeInsets.all(5),
              errorText: _titleError ? "Please add a title to your event" : null,
            ),
            onChanged: (value) => _validateStep1(true),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < eventDates.length; i++) _buildDateTimeFields(i),
            SizedBox(height: 16),
            if (eventDates.length < MAX_DATES)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _step2Valid
                      ? () {
                          _addNewDate();
                          _validateStep2();
                        }
                      : null,
                  icon: Icon(Icons.add),
                  label: Text('Add Another Date'),
                ),
              ),
            SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Event'),
              value: _isRecurring,
              onChanged: (bool value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeFields(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) Divider(height: 32, thickness: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Date ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
            ),
            if (index > 0)
              IconButton(
                onPressed: () {
                  _deleteDate(index);
                  _validateStep2();
                },
                icon: Icon(Icons.close),
                color: Theme.of(context).colorScheme.onSurface,
              ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                title: 'Start Date',
                value: eventDates[index].startDate == null
                    ? 'Not set'
                    : DateFormat('MMM d, yyyy').format(eventDates[index].startDate!),
                onTap: () => _selectDate(context, true, index),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateTimeField(
                title: 'Start Time',
                value: eventDates[index].startTime?.format(context) ?? 'Not set',
                onTap: () => _selectTime(context, true, index),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildDateTimeField(
                title: 'End Date',
                value: eventDates[index].endDate == null
                    ? 'Not set'
                    : DateFormat('MMM d, yyyy').format(eventDates[index].endDate!),
                onTap: () => _selectDate(context, false, index),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildDateTimeField(
                title: 'End Time',
                value: eventDates[index].endTime?.format(context) ?? 'Not set',
                onTap: () => _selectTime(context, false, index),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeField({required String title, required String value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface)),
            SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  void _addNewDate() {
      setState(() {
        eventDates.add(EventDate());
        _validateStep2();
      });
  }

  void _deleteDate(int index) {
    setState(() {
      eventDates.removeAt(index);
      _validateStep2();
    });
  }

  Widget _buildStep3Content() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: TextField(
            controller: _description,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderSide: BorderSide(color: _descriptionError ? Colors.red : Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _descriptionError ? Colors.red : Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _descriptionError ? Colors.red : Theme.of(context).colorScheme.primary),
              ),
              labelText: "Enter Your Event Description",
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              contentPadding: const EdgeInsets.all(5),
              errorText: _descriptionError ? "Please enter a description for your event" : null,
            ),
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            maxLines: null,
            textAlign: TextAlign.start,
            textCapitalization: TextCapitalization.sentences,
            maxLength: 1500,
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            onChanged: (value) {
              setState(() {
                _validateStep3();
              });
            },
          ),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Virtual Event'),
          value: virtualEvent,
          onChanged: (bool value) {
            setState(() {
              virtualEvent = value;
              if (virtualEvent) {
                _locationController.text = 'Virtual';
              } else {
                _locationController.clear();
              }
              _validateStep3();
            });
          },
        ),
        SizedBox(height: 16),
        if (!virtualEvent)
          AddressSearchField(
            controller: _locationController,
            isEvent: true,
            hasError: false,
            isVirtual: virtualEvent,
            onChanged: (value) {
              setState(() {
                _validateStep3();
              });
            },
          ),
        DropdownButtonFormField<String>(
          value: dropDownValue,
          decoration: const InputDecoration(labelText: 'Invitation Type'),
          items: ['Public', 'Private', 'Selective']
              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
              .toList(),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                dropDownValue = newValue;
              });
            }
          },
        ),
        SizedBox(height: 16),
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
          child: const Text('Select Categories'),
        ),
        SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Ticketed Event'),
          value: _isTicketed,
          onChanged: (bool value) {
            setState(() {
              _isTicketed = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep4Content() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
                width: double.infinity, color: Colors.grey[300], child: Image.file(_selectedImage!, fit: BoxFit.cover)),
          ),
          Text(
            'Title: ${_title.text}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Event Dates:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          for (int i = 0; i < eventDates.length; i++)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Date ${i + 1}:',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Start: ${_formatDateTime(eventDates[i].startDate, eventDates[i].startTime)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  Text(
                    'End: ${_formatDateTime(eventDates[i].endDate, eventDates[i].endTime)}',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          Text(
            'Description: ${_description.text}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Location: ${_locationController.text}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Invitation Type: $dropDownValue',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Recurring: ${_isRecurring ? 'Yes' : 'No'}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Ticketed: ${_isTicketed ? 'Yes' : 'No'}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          Text(
            'Categories: ${categories.entries.where((entry) => entry.value).map((entry) => ref.read(profileProvider.notifier).enumToString(entry.key)).join(', ')}',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  void _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  String _formatDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return 'Not set';
    final dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return DateFormat('MMM d, yyyy - h:mm a').format(dateTime);
  }

  void _resetScreen() {
    setState(() {
      _currentStep = 0;
      _selectedImage = null;
      _title.clear();
      _selectedStartDate = null;
      _selectedEndDate = null;
      _selectedStartTime = null;
      _selectedEndTime = null;
      _isRecurring = false;
      _description.clear();
      _locationController.clear();
      virtualEvent = false;
      dropDownValue = list.first;
      categories = {for (var interest in Interests.values) interest: false};
      _isTicketed = false;
      _step1Valid = false;
      _step2Valid = false;
      _step3Valid = false;
    });
  }

  void _showConfirmationScreen() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Event Details'),
          backgroundColor: Theme.of(context).cardColor,
          content: SingleChildScrollView(
            child: _isLoading
                ? Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildStep4Content(),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Edit'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _titleError = _title.text.isEmpty;
                  _descriptionError = _description.text.isEmpty;
                  _locationError = _locationController.text.isEmpty && !virtualEvent;
                  _dateError = !sdate || !edate;
                  _timeError = !stime || !etime;
                });

                if (_titleError || _descriptionError || _locationError || _dateError || _timeError) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                } else if (_selectedImage == null && isNewEvent) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select an image for your event')),
                  );
                }
              },
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(
                      color: Theme.of(context).colorScheme.primary, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onPressed: _step3Valid
                    ? isNewEvent
                        ? () async {
                            try {
                              FocusManager.instance.primaryFocus?.unfocus();
                              await createEvent(
                                  _selectedImage!,
                                  dropDownValue,
                                  _locationController.text,
                                  _title.text,
                                  _description.text,
                                  _isRecurring,
                                  _isTicketed);
                              if (widget.onEventCreated != null) {
                                widget.onEventCreated!();
                              }
                              Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: eventData))));
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Event Created'),
                                ),
                              );
                            } finally {
                              _resetScreen();
                            }
                          }
                        : () {
                            print(widget.event!.imageId);
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Are you sure you want to update this event?',
                                  style: TextStyle(color: Theme.of(context).primaryColorDark),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      await updateEvent(
                                          _selectedImage,
                                          dropDownValue,
                                          _locationController.text,
                                          _title.text,
                                          _description.text,
                                          _isRecurring,
                                          _isTicketed);
                                      Navigator.of(context)
                                          .pushAndRemoveUntil(MaterialPageRoute(builder: ((context) => const NavBar())),
                                              (route) => false)
                                          .then((result) => Navigator.pop(context));
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Event Updated'),
                                        ),
                                      );
                                    },
                                    child: const Text('YES'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CANCEL'),
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
        );
      },
    );
  }
}

class EventDate {
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  EventDate();
}
