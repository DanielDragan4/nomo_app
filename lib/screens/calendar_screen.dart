import 'package:flutter/material.dart';
import 'package:scrollable_clean_calendar/controllers/clean_calendar_controller.dart';
import 'package:scrollable_clean_calendar/utils/enums.dart';
import 'package:scrollable_clean_calendar/scrollable_clean_calendar.dart';

class CalendarScreen extends StatelessWidget {
  CalendarScreen({super.key});

  final calendarController = CleanCalendarController(
    minDate: DateTime(2022),
    maxDate: DateTime(2100),
    onDayTapped: (date) {},
    onPreviousMinDateTapped: (date) {},
    onAfterMaxDateTapped: (date) {},
    weekdayStart: DateTime.monday,
    initialFocusDate: DateTime(2023, 12),
  );

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return MaterialApp(
      title: 'Calendar',
      theme: ThemeData(
        colorScheme: ColorScheme(
          primary: theme.primaryColor,
          primaryContainer: theme.primaryColor,
          secondary: theme.secondaryHeaderColor,
          surface: Color(0xFFDEE2E6),
          background: theme.backgroundColor,
          error: Color(0xFF96031A),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          onBackground: Colors.black,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Scrollable Clean Calendar'),
          actions: [
            IconButton(
              onPressed: () {
                calendarController.clearSelectedDates();
              },
              icon: const Icon(Icons.clear),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            //calendarController.;
          },
        ),
        body: ScrollableCleanCalendar(
          calendarController: calendarController,
          layout: Layout.DEFAULT,
          calendarCrossAxisSpacing: 0,
        ),
      ),
    );
  }
}