import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/providers/calendar-providers/availability_provider.dart';
import 'package:nomo/providers/calendar-providers/calendar_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/event_cal_tab.dart';
import 'package:nomo/screens/calendar/month_widget.dart';
import 'package:nomo/screens/events/event_creation.dart';
import 'package:nomo/screens/events/new_event_screen.dart';
import 'package:nomo/widgets/custom_time_picker.dart';

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
  var calendarState;
  var attendingEvents;

  void initilizeAttendingEvents() async {
    await ref.read(attendEventsProvider.notifier).deCodeData();
    setState(() {
      calendarState = ref.watch(calendarStateProvider);
      attendingEvents = ref.read(attendEventsProvider.notifier).eventsAttendingByMonth(yearDisplayed, monthDisplayed);
    });
  }

  @override
  void initState() {
    super.initState();
    initilizeAttendingEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAttendingEvents(yearDisplayed, monthDisplayed);
    });
  }

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
    bool isAllDay = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                    color: Theme.of(context).primaryColorLight,
                    fontSize: MediaQuery.of(context).size.width * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      title: Text(
                        'Block Entire Day',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                      ),
                      value: isAllDay,
                      onChanged: (bool? value) {
                        setState(() {
                          isAllDay = value ?? false;
                          if (isAllDay) {
                            startTime = TimeOfDay(hour: 0, minute: 0);
                            endTime = TimeOfDay(hour: 23, minute: 59);
                          } else {
                            startTime = null;
                            endTime = null;
                          }
                        });
                      },
                    ),
                    if (!isAllDay)
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
                        decoration: InputDecoration(
                          labelText: 'Title',
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
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
    final pickedTime = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return CustomTimePicker(
          initialTime: TimeOfDay(hour: 12, minute: 00),
          onTimeSelected: (TimeOfDay selectedTime) {
            return selectedTime;
          },
          isStartTime: isStartTime,
        );
      },
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

  void _updateAttendingEvents(int year, int month) {
    final events = ref.read(attendEventsProvider.notifier).eventsAttendingByMonth(year, month);
    ref.read(calendarStateProvider.notifier).updateAttendingEvents(events);
    setState(() {
      attendingEvents = events;
    }); // Trigger a rebuild
  }

  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    calendarState = ref.read(calendarStateProvider);
    //attendingEvents = calendarState.attendingEvents;
    setProfileAvail();
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
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(left: 15, bottom: 8),
              child: Text(
                "${_getMonthName(calendarState.monthDisplayed)} ${calendarState.yearDisplayed}",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight,
                ),
              ),
            ),
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
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
              children: [
                // SizedBox(
                //   height: MediaQuery.of(context).size.height * 0.02,
                // ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.03, vertical: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                        .map((day) => Text(day,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColorLight)))
                        .toList(),
                  ),
                ),
                Flexible(
                  //height: MediaQuery.of(context).size.height * 0.45,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int index) {
                      final newMonth = (index % 12) + 1;
                      final newYear = DateTime.now().year + (index ~/ 12);
                      ref.read(calendarStateProvider.notifier).updateMonth(newMonth);
                      ref.read(calendarStateProvider.notifier).updateYear(newYear);
                      _updateAttendingEvents(newYear, newMonth);
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
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.37,
            minChildSize: 0.37,
            maxChildSize: .8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                        //offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    child: CustomScrollView(
                      controller: scrollController,
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          floating: false,
                          automaticallyImplyLeading: false,
                          backgroundColor: Theme.of(context).cardColor,
                          flexibleSpace: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      alignment: Alignment.topLeft,
                                      child: Text(
                                        "Attending Events",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                  backgroundColor: Theme.of(context).cardColor,
                                                  title: Text(
                                                    'What would you like to do?',
                                                    style: TextStyle(
                                                      color: Theme.of(context).primaryColorLight,
                                                      fontSize: MediaQuery.of(context).size.width * 0.065,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          Navigator.of(context, rootNavigator: true).push(
                                                              MaterialPageRoute(
                                                                  builder: ((context) =>
                                                                      const EventCreateScreen(event: null))));
                                                        },
                                                        child: Text('Create an Event', style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSecondary,
                                                      fontSize: MediaQuery.of(context).size.width * 0.045,
                                                      fontWeight: FontWeight.w400,
                                                    ),)),
                                                    TextButton(
                                                        onPressed: () async {
                                                          selectedDate = await _showDatePickerDialog(context);
                                                          if (selectedDate != null) {
                                                            _showTimeRangePicker(context);
                                                          }
                                                        },
                                                        child:  Text('Block Time', style: TextStyle(
                                                      color: Theme.of(context).colorScheme.onSecondary,
                                                      fontSize: MediaQuery.of(context).size.width * 0.045,
                                                      fontWeight: FontWeight.w400,
                                                    ),)),
                                                  ],
                                                ));
                                      },
                                      icon: Icon(Icons.add_box_rounded,
                                          size: MediaQuery.of(context).size.width * 0.075,
                                          color: Theme.of(context).colorScheme.onSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Divider(),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              if (attendingEvents == null) {
                                return CircularProgressIndicator();
                              }
                              return EventCalTab(eventData: attendingEvents[index]);
                            },
                            childCount: attendingEvents?.length ?? 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
