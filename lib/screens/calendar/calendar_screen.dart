import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/day_screen.dart';
import 'package:nomo/screens/calendar/month_widget.dart';
import 'package:nomo/screens/new_event_screen.dart';
//import 'package:nomo/widgets/app_bar.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  ConsumerState<CalendarScreen> createState() {
    return _CalendarScreenState();
  }
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final DateTime currentDate = DateTime.now();

  int monthDisplayed = DateTime.now().month;
  int yearDisplayed = DateTime.now().year;

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
                              title: Text(
                                'What would you like to do?',
                                style: TextStyle(
                                    color: Theme.of(context).primaryColorDark),
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
                                      //Navigator.pop(context);
                                      var selectedDate =
                                          await _showDatePickerDialog(context);

                                      Navigator.of(context)
                                          .push(MaterialPageRoute(
                                              builder: ((context) => DayScreen(
                                                    day: selectedDate,
                                                  ))))
                                          .then((result) =>
                                              Navigator.pop(context));
                                    },
                                    child: const Text('VIEW SCHEDULE')),
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

  Future<DateTime?> _showDatePickerDialog(BuildContext context) async {
    DateTime? selectedDate;

    Future<void> _selectDate(BuildContext context) async {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (picked != null) {
        setState(() {
          selectedDate = picked;
        });
        Navigator.pop(context);
      }
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Date'),
          content: Text('Please select a date:'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _selectDate(context);
              },
              child: Text('Select Date'),
            ),
          ],
        );
      },
    );

    return selectedDate;
  }
}
