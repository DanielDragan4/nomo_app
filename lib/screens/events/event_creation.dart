import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/interests_enum.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/theme_provider.dart';
import 'package:nomo/screens/NavBar.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';
import 'package:nomo/screens/profile/interests_screen.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/settings/setting_blocked.dart';
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
  final List<String> _steps = ['Basics', 'Date & Time', 'Confirm', 'Redirect'];

  TimeOfDay? _selectedStartTime;
  bool stime = false;
  TimeOfDay? _selectedEndTime;
  bool etime = false;
  DateTime? _selectedStartDate;
  bool sdate = false;
  DateTime? _selectedEndDate;
  bool edate = false;
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
  bool _step3Valid = true;
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
      for (var i = 0; i < widget.event!.sdate.length; i++) {
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
    eventDates.add(EventDate());
    super.initState();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _description.dispose();
    _title.dispose();
    super.dispose();
  }

  void _validateStep1(bool setErrors) {
    bool isValid = _selectedImage != null &&
        _title.text.isNotEmpty &&
        _description.text.isNotEmpty &&
        (_locationController.text.isNotEmpty || virtualEvent);

    if (setErrors) {
      setState(() {
        _titleError = _title.text.isEmpty;
        _descriptionError = _description.text.isEmpty;
        _locationError = _locationController.text.isEmpty && !virtualEvent;
      });
    }

    setState(() {
      _step1Valid = isValid;
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

  Future<void> createEvent(File selectedImage, String inviteType, var location, String title, String description,
      bool isRecurring, bool isTicketed) async {
    _showLoadingOverlay();
    try {
      List<String> start = [];
      List<String> end = [];
      for (var dates in eventDates) {
        start.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(dates.startDate!.year, dates.startDate!.month,
            dates.startDate!.day, dates.startTime!.hour, dates.startTime!.minute)));
        end.add(DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime(dates.endDate!.year, dates.endDate!.month,
            dates.endDate!.day, dates.endTime!.hour, dates.endTime!.minute)));
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
      for (var i = 0; i < start.length; i++) {
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
      TimeOfDay selectedStart,
      TimeOfDay selectedEnd,
      DateTime selectedStartDate,
      DateTime selectedEndDate,
      File? selectedImage,
      String inviteType,
      var location,
      String title,
      String description,
      bool isRecurring,
      bool isTicketed) async {
    DateTime start = DateTime(selectedStartDate.year, selectedStartDate.month, selectedStartDate.day,
        selectedStart.hour, selectedStart.minute);
    DateTime end = DateTime(
        selectedEndDate.year, selectedEndDate.month, selectedEndDate.day, selectedEnd.hour, selectedEnd.minute);

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
    final newDateRowMap = {
      'event_id': widget.event?.eventId,
      'time_start': DateFormat('yyyy-MM-dd HH:mm:ss').format(start),
      'time_end': DateFormat('yyyy-MM-dd HH:mm:ss').format(end),
    };
    await supabase.from('Dates').update(newDateRowMap).eq('event_id', widget.event?.eventId);
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
            title: Text(widget.isEdit == true ? 'Edit Event' : 'Create Event',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width / 25)),
            backgroundColor: Theme.of(context).colorScheme.surface,
            centerTitle: true,
          ),
          body: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildStepContent(),
                    ),
                    if (_currentStep < 3) _buildContinueButton(),
                  ],
                ),
              ),
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
        if (_currentStep > 0 && _currentStep < _steps.length - 1) _buildBackButton(),
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

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isStepValid(_currentStep)
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_currentStep == 0) {
                  _validateStep1(true); // Set errors if fields are empty
                } else if (_currentStep == 1) {
                  _validateStep2();
                }
                if (_isStepValid(_currentStep)) {
                  _onStepContinue();
                }
              },
              child: Text(
                _currentStep == 2 ? 'Create Event' : 'Next Step',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: MediaQuery.of(context).size.width / 25,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: MediaQuery.of(context).size.height * .02 + MediaQuery.of(context).padding.top,
      left: MediaQuery.of(context).size.height * .01,
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        height: MediaQuery.of(context).size.width * .1,
        width: MediaQuery.of(context).size.width * .1,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary, // Light grey color
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
        child: Center(
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: _onStepCancel,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            splashRadius: 24,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  void _onStepContinue() async {
    if (_currentStep < 2 && _isStepValid(_currentStep)) {
      setState(() {
        _currentStep += 1;
      });
    } else if (_currentStep == 2) {
      try {
        FocusManager.instance.primaryFocus?.unfocus();
        _showLoadingOverlay();
        await createEvent(_selectedImage!, dropDownValue, _locationController.text, _title.text, _description.text,
            _isRecurring, _isTicketed);
        if (widget.onEventCreated != null) {
          widget.onEventCreated!();
        }
        setState(() {
          _currentStep = 3; // Move to step 4 after event creation
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create event: $e')),
        );
      } finally {
        _hideLoadingOverlay();
      }
    } else if (_currentStep == 3) {
      // Navigate away from the event creation screen
      Navigator.of(context, rootNavigator: true)
          .pushReplacement(MaterialPageRoute(builder: ((context) => const NavBar())));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event Created')),
      );
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

  void _showImageSelectionOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.secondary,
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
                          style: TextStyle(fontSize: fontSize, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        SizedBox(width: screenSize.width * 0.01),
                        Icon(Icons.photo_library_rounded, color: Theme.of(context).colorScheme.onSurface)
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
                          style: TextStyle(fontSize: fontSize, color: Theme.of(context).colorScheme.onSurface),
                        ),
                        SizedBox(width: screenSize.width * 0.01),
                        Icon(Icons.camera_alt_rounded, color: Theme.of(context).colorScheme.onSurface)
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
                      style: TextStyle(fontSize: fontSize, color: Theme.of(context).colorScheme.onSurface),
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
  }

  Widget _buildStep1Content() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add an image',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width / 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 40,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width / 20,
                  ),
                  child: GestureDetector(
                    onTap: _showImageSelectionOptions,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3.5,
                      height: MediaQuery.of(context).size.width / 3.5,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover))
                          : Icon(
                              Icons.image,
                              color: Theme.of(context).colorScheme.onSecondary,
                              size: MediaQuery.of(context).size.width / 10,
                            ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Padding(
                  padding: EdgeInsets.only(
                    right: MediaQuery.of(context).size.width / 20,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.width / 12,
                    width: MediaQuery.of(context).size.width / 2.25,
                    child: ElevatedButton.icon(
                      onPressed: _showImageSelectionOptions,
                      icon: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: MediaQuery.of(context).size.width / 20,
                      ),
                      label: Text(
                        'Choose a photo',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: MediaQuery.of(context).size.width / 30,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 60,
            ),
            Text(
              'Info',
              style: TextStyle(
                color: Colors.white,
                fontSize: MediaQuery.of(context).size.width / 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 80,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width / 30)),
                Row(
                  children: [
                    Text(
                      "Virtual",
                      style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    Checkbox(
                      value: virtualEvent,
                      onChanged: (value) {
                        setState(() {
                          virtualEvent = !virtualEvent;
                          if (virtualEvent) {
                            _locationController.text = 'Virtual';
                          } else {
                            _locationController.clear();
                          }
                        });
                      },
                    )
                  ],
                )
              ],
            ),
            if (!virtualEvent)
              AddressSearchField(
                controller: _locationController,
                isEvent: true,
                hasError: false,
                isVirtual: virtualEvent,
                onChanged: (value) {
                  setState(() {
                    _validateStep1(false);
                  });
                },
              ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 80,
            ),
            Text('Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width / 30)),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                hintText: 'Enter event title',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _titleError ? Colors.red : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _titleError ? Colors.red : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              onChanged: (value) {
                setState(() {
                  _validateStep1(false);
                });
              },
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height / 80,
            ),
            Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width / 30)),
            TextField(
              controller: _description,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.secondary,
                hintText: 'Enter event description',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _descriptionError ? Colors.red : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: _descriptionError ? Colors.red : Theme.of(context).colorScheme.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              maxLines: 3,
              onChanged: (value) {
                setState(() {
                  _validateStep1(false);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2Content() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width / 20,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
            SizedBox(height: 16),
            Text(
              'Invitation Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: MediaQuery.of(context).size.width / 30,
              ),
            ),
            SizedBox(height: 8),
            Container(
              height: 30,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _buildInvitationTypeOption('Public'),
                  _buildVerticalDivider(),
                  _buildInvitationTypeOption('Private'),
                  _buildVerticalDivider(),
                  _buildInvitationTypeOption('Selective'),
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Event Categories',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: MediaQuery.of(context).size.width / 30,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColorLight),
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
                child: Text('Select Categories', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: _isTicketed,
                  onChanged: (value) {
                    setState(() {
                      _isTicketed = value!;
                    });
                  },
                ),
                Text(
                  'Ticketed Event',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width / 30,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 60),
            Divider(),
            SizedBox(height: MediaQuery.of(context).size.height / 60),
            Text(
              'Scheduling',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width / 20,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
            Row(
              children: [
                Checkbox(
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() {
                      _isRecurring = value!;
                    });
                  },
                ),
                Text(
                  'Recurring Event',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width / 30,
                      color: Theme.of(context).colorScheme.onPrimary),
                ),
              ],
            ),
            for (int i = 0; i < eventDates.length; i++) _buildDateTimeFields(i),
            SizedBox(height: 8),
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
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationTypeOption(String option) {
    bool isSelected = dropDownValue == option;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            dropDownValue = option;
          });
        },
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColorLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: MediaQuery.of(context).size.width / 30,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 16,
      color: Theme.of(context).dividerColor,
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
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14),
              child: Text(
                'Date ${index + 1}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.width / 25,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
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
    if (eventDates.length < MAX_DATES) {
      setState(() {
        eventDates.add(EventDate());
        _validateStep2();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum of $MAX_DATES dates allowed')),
      );
    }
  }

  void _deleteDate(int index) {
    setState(() {
      eventDates.removeAt(index);
      _validateStep2();
    });
  }

  Widget _buildStep3Content() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Details',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: MediaQuery.of(context).size.width / 20,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
            SizedBox(height: 16),
            if (_selectedImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Image.file(_selectedImage!, fit: BoxFit.cover),
                ),
              )
            else
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: Icon(Icons.image, size: 50),
                ),
              ),
            SizedBox(height: 16),
            Wrap(children: [
              Row(
                children: [
                  Text(
                    'Title: ',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: MediaQuery.of(context).size.width / 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _title.text,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: MediaQuery.of(context).size.width / 20,
                    ),
                  ),
                ],
              ),
            ]),
            SizedBox(height: 8),
            Text(
              'Event Dates:',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
                fontSize: MediaQuery.of(context).size.width / 20,
              ),
            ),
            for (int i = 0; i < eventDates.length; i++)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 2.0, bottom: 2),
                child: IntrinsicWidth(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date ${i + 1}:',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: MediaQuery.of(context).size.width / 25,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'Start: ',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatDateTime(eventDates[i].startDate, eventDates[i].startTime)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              'End: ',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_formatDateTime(eventDates[i].endDate, eventDates[i].endTime)}',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 8),
            Wrap(
              children: [
                Row(
                  children: [
                    Text(
                      'Description: ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: MediaQuery.of(context).size.width / 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_description.text}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: MediaQuery.of(context).size.width / 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              children: [
                Row(
                  children: [
                    Text(
                      'Location: ',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: MediaQuery.of(context).size.width / 20,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_locationController.text}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: MediaQuery.of(context).size.width / 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Invitation Type: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: MediaQuery.of(context).size.width / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dropDownValue,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: MediaQuery.of(context).size.width / 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Recurring: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: MediaQuery.of(context).size.width / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_isRecurring ? 'Yes' : 'No'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: MediaQuery.of(context).size.width / 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Ticketed: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: MediaQuery.of(context).size.width / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_isTicketed ? 'Yes' : 'No'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: MediaQuery.of(context).size.width / 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Wrap(
              children: [
                Text(
                  'Categories: ',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: MediaQuery.of(context).size.width / 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...categories.entries.where((entry) => entry.value).isEmpty
                    ? [
                        Text(
                          'None',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: MediaQuery.of(context).size.width / 20,
                          ),
                        )
                      ]
                    : categories.entries.where((entry) => entry.value).map((entry) {
                        String category = ref.read(profileProvider.notifier).enumToString(entry.key);
                        return Text(
                          categories.entries.where((e) => e.value).last.key == entry.key ? category : '$category, ',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: MediaQuery.of(context).size.width / 20,
                          ),
                        );
                      }).toList(),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStep4Content() {
    var themeMode = ref.watch(themeModeProvider);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width / 1.5,
                    height: MediaQuery.of(context).size.width / 1.5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: themeMode == ThemeMode.dark
                          ? const RadialGradient(
                              colors: [
                                Color.fromRGBO(2, 44, 34, 0.4),
                                //    Color.fromRGBO(2, 44, 34, 0.1),
                                Color.fromRGBO(2, 44, 34, 0.01),
                              ],
                            )
                          : const RadialGradient(
                              colors: [
                                Color.fromRGBO(20, 184, 100, 0.4),
                                //    Color.fromRGBO(2, 44, 34, 0.1),
                                Color.fromRGBO(20, 184, 100, 0.01),
                              ],
                            ),
                    ),
                  ),
                  Positioned(
                    child: Container(
                      width: MediaQuery.of(context).size.width / 4,
                      height: MediaQuery.of(context).size.width / 4,
                      decoration: themeMode == ThemeMode.dark
                          ? const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(2, 44, 34, 0.8),
                            )
                          : const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color.fromRGBO(209, 250, 229, 1),
                            ),
                      child: Icon(
                        Icons.calendar_today,
                        size: MediaQuery.of(context).size.width / 12,
                        color: Color.fromRGBO(4, 120, 87, 1),
                      ),
                    ),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).size.width / 1.5 / 2 + MediaQuery.of(context).size.width / 6,
                    child: Text(
                      'Your event has been\nsuccessfully created!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true)
                          .pushReplacement(MaterialPageRoute(builder: ((context) => const NavBar())));
                      _resetScreen();
                    },
                    child: Text(
                      'Go to Events',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: MediaQuery.of(context).size.width / 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width / 30),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: eventData))));
                      _resetScreen();
                    },
                    child: Text(
                      'View Your Event',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: MediaQuery.of(context).size.width / 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
      eventDates = [];
      _currentStep = 0;
      _selectedImage = null;
      _title.clear();
      _isRecurring = false;
      _description.clear();
      _locationController.clear();
      virtualEvent = false;
      dropDownValue = list.first;
      categories = {for (var interest in Interests.values) interest: false};
      _isTicketed = false;
      _step1Valid = false;
      _step2Valid = false;
      _step3Valid = true;
    });
  }
}

class EventDate {
  DateTime? startDate;
  DateTime? endDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  EventDate({
    this.startDate,
    this.endDate,
    this.startTime,
    this.endTime,
  });
}
