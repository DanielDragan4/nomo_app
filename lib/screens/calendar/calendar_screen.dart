import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/day_screen.dart';
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
          child: Container(
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                Text(
                  'Select Time Range',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
                SizedBox(height: 20),
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
                        startTime == null
                            ? 'Start Time'
                            : formatTimeOfDay(startTime!),
                        style: TextStyle(color: Colors.white),
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
                        endTime == null
                            ? 'End Time'
                            : formatTimeOfDay(endTime!),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Title',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
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
                  child: Text('Confirm'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmTimeRange(BuildContext context, DateTime? selectedDate) {
    if (startTime != null &&
        endTime != null &&
        blockTitle != null &&
        blockTitle!.isNotEmpty &&
        selectedDate != null) {
      final profileId = ref.read(profileProvider)!.profile_id;
      if (profileId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile ID is missing')),
        );
        return;
      }

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

      ref.watch(profileProvider.notifier).createBlockedTime(
            profileId,
            startDateTime.toString(),
            endDateTime.toString(),
            blockTitle!,
            null
          );

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter all the details for the time block')),
      );
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      //initialEntryMode: TimePickerEntryMode.input
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

  @override
  Widget build(BuildContext context) {
    ref.read(attendEventsProvider.notifier).deCodeData();
    final int firstDayOfWeek =
        DateTime(yearDisplayed, monthDisplayed, 1).weekday;
    final int lastOfMonth = DateTime(yearDisplayed, monthDisplayed + 1, 0).day;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                  onPressed: () {
                    setState(() {
                      monthDisplayed--;

                      if (monthDisplayed < 1) {
                        monthDisplayed = 12;
                        yearDisplayed--;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_back_ios,
                      color: Theme.of(context).colorScheme.onSecondary)),
              IconButton(
                  onPressed: () {
                    setState(() {
                      monthDisplayed++;
                      if (monthDisplayed > 12) {
                        monthDisplayed = 1;
                        yearDisplayed++;
                      }
                    });
                  },
                  icon: Icon(Icons.arrow_forward_ios,
                      color: Theme.of(context).colorScheme.onSecondary))
            ],
          ),
          Expanded(
            child: Month(
              selectedMonth: monthDisplayed,
              eventsByDate: const [],
              firstDayOfWeek: firstDayOfWeek,
              lastOfMonth: lastOfMonth,
              yearDisplayed: yearDisplayed,
              selectedDatesWithTime: selectedDatesWithTime,
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
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(context)
                                        .push(MaterialPageRoute(
                                            builder: ((context) =>
                                                const NewEventScreen(
                                                    isNewEvent: true,
                                                    event: null))))
                                        .then(
                                            (result) => Navigator.pop(context)),
                                    child: const Text('CREATE EVENT')),
                                TextButton(
                                    onPressed: () async {
                                      selectedDate =
                                          await _showDatePickerDialog(context);
                                      if (selectedDate != null) {
                                        _showTimeRangePicker(context);
                                      }
                                    },
                                    child: const Text('CREATE BLOCKED TIME')),
                              ],
                            ));
                  },
                  icon: Icon(Icons.add_box_rounded,
                      size: 45,
                      color: Theme.of(context).colorScheme.onSecondary)),
            ],
          )
        ],
      ),
    );
  }
}
