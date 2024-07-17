import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/availability_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/month_widget.dart';
import 'package:nomo/screens/new_event_screen.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() {
    return _CalendarScreenState();
  }
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final PageController _pageController = PageController(initialPage: DateTime.now().month - 1);
  final DateTime currentDate = DateTime.now();
  int monthDisplayed = DateTime.now().month;
  int yearDisplayed = DateTime.now().year;

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? blockTitle;
  Map<DateTime, bool> selectedDatesWithTime = {};

  Future<DateTime?> _showDatePickerDialog(BuildContext context) async {
    DateTime? selectedDate;

    selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        this.selectedDate = selectedDate;
      });
      Navigator.of(context).pop(); // Close the dialog when a date is selected
    }

    return selectedDate;
  }

  void _showTimeRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Select Time Range',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark,
                      ),
                      onPressed: () {
                        _selectTime(context, true);
                      },
                      child: Text(
                        startTime == null ? 'Start Time' : formatTimeOfDay(startTime!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark,
                      ),
                      onPressed: () {
                        _selectTime(context, false);
                      },
                      child: Text(
                        endTime == null ? 'End Time' : formatTimeOfDay(endTime!),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Title',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onChanged: (value) {
                      blockTitle = value;
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _confirmTimeRange(context, selectedDate);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmTimeRange(BuildContext context, DateTime? selectedDate) {
    /*
      Checks to see date is selected to create the time block
      
      Returns: none
    */
    if (startTime != null && endTime != null && blockTitle != null && blockTitle!.isNotEmpty && selectedDate != null) {
      final profileId = ref.read(profileProvider)!.profile_id;

      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        startTime!.hour,
        startTime!.minute,
      );
      final endDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        endTime!.hour,
        endTime!.minute,
      );

      setState(() {
        selectedDatesWithTime[selectedDate] = true;
      });

      ref
          .watch(profileProvider.notifier)
          .createBlockedTime(profileId, startDateTime.toString(), endDateTime.toString(), blockTitle!, null);

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all the details for the time block')),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    /*
      Checks to see if start time has been set, and sets it to the selected time if it hasnt been, if not
      then sets it to end time

      Returns: none
    */
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime != null) {
      setState(() {
        if (isStartTime) {
          startTime = pickedTime;
        } else {
          endTime = pickedTime;
        }
      });
    }
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hours = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hours:$minutes $period';
  }

  Future<void> setProfileAvail() async {
    /*
      Sets the state of the availability provider to the new value when a new time block is created

      Params: none
      
      Returns: none
    */
    await ref.read(profileProvider.notifier).decodeData();
    ref
        .read(availabilityProvider.notifier)
        .updateAvailability(ref.watch(profileProvider.notifier).availabilityByMonth(yearDisplayed, monthDisplayed));
  }

  @override
  Widget build(BuildContext context) {
    setProfileAvail();
    ref.read(attendEventsProvider.notifier).deCodeData();
    final int firstDayOfWeek = DateTime(yearDisplayed, monthDisplayed, 1).weekday;
    final int lastOfMonth = DateTime(yearDisplayed, monthDisplayed + 1, 0).day;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text('Availability',
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
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (int index) {
                setState(() {
                  monthDisplayed = (index % 12) + 1;
                  yearDisplayed = DateTime.now().year + (index ~/ 12);
                });
              },
              itemBuilder: (context, index) {
                final currentMonth = (index % 12) + 1;
                final currentYear = DateTime.now().year + (index ~/ 12);
                final firstDayOfWeek = DateTime(currentYear, currentMonth, 1).weekday;
                final lastOfMonth = DateTime(currentYear, currentMonth + 1, 0).day;

                return Month(
                  selectedMonth: currentMonth,
                  eventsByDate: const [],
                  firstDayOfWeek: firstDayOfWeek,
                  lastOfMonth: lastOfMonth,
                  yearDisplayed: currentYear,
                  selectedDatesWithTime: selectedDatesWithTime,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              backgroundColor: Theme.of(context).canvasColor,
                              title: Text(
                                'What would you like to do?',
                                style: TextStyle(color: Theme.of(context).primaryColor),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: ((context) => const NewEventScreen(event: null))))
                                        .then((result) => Navigator.pop(context)),
                                    child: const Text('CREATE EVENT')),
                                TextButton(
                                    onPressed: () async {
                                      selectedDate = await _showDatePickerDialog(context);
                                      if (selectedDate != null) {
                                        _showTimeRangePicker(context);
                                      }
                                    },
                                    child: const Text('CREATE BLOCKED TIME')),
                              ],
                            ));
                  },
                  icon: Icon(Icons.add_box_rounded, size: 45, color: Theme.of(context).colorScheme.onSecondary)),
            ],
          )
        ],
      ),
    );
  }
}
