import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/event_cal_tab.dart';
import 'package:nomo/screens/calendar/day_screen.dart';
import 'package:nomo/widgets/DayScreenPageView.dart'; // Make sure to import DayScreen

class Month extends ConsumerWidget {
  Month(
      {super.key,
      required this.selectedMonth,
      required this.eventsByDate,
      required this.firstDayOfWeek,
      required this.lastOfMonth,
      required this.yearDisplayed,
      required this.selectedDatesWithTime});

  final int selectedMonth;
  final eventsByDate;
  final int firstDayOfWeek;
  int lastOfMonth;
  int cellIndex = 0;
  final int yearDisplayed;
  final Map<DateTime, bool> selectedDatesWithTime;

  String monthName(int month) {
    switch (month) {
      case 1:
        return "January";
      case 2:
        return "February";
      case 3:
        return "March";
      case 4:
        return "April";
      case 5:
        return "May";
      case 6:
        return "June";
      case 7:
        return "July";
      case 8:
        return "August";
      case 9:
        return "September";
      case 10:
        return "October";
      case 11:
        return "November";
      case 12:
        return "December";
    }
    return "";
  }

  bool findBorderWidth(cellPosition) {
    bool borderWidth;

    if ((cellIndex - firstDayOfWeek) < lastOfMonth &&
        (cellIndex - firstDayOfWeek) >= 0) {
      borderWidth = true;
    } else {
      borderWidth = false;
    }

    return borderWidth;
  }

  Color findCellColor(int cellPosition, List<Event> events) {
    Color cellColor = const Color.fromARGB(255, 226, 194, 231); // Default color

    var dayInGrid = cellPosition - firstDayOfWeek;

    // Check if the day falls within the current month grid
    if (dayInGrid < lastOfMonth && dayInGrid >= 0) {
      // Iterate through all events to check if any event covers this day
      for (var event in events) {
        DateTime eventStart = DateTime.parse(event.sdate);
        DateTime eventEnd = DateTime.parse(event.edate);

        // Check if the current day is within the event's start and end dates
        if (DateTime(yearDisplayed, selectedMonth, dayInGrid + 1)
                .isAfter(eventStart.subtract(Duration(days: 1))) &&
            DateTime(yearDisplayed, selectedMonth, dayInGrid + 1)
                .isBefore(eventEnd)) {
          cellColor = const Color.fromARGB(136, 162, 24, 248);
          break;
        }
      }
    } else {
      cellColor = const Color.fromARGB(0, 255, 255, 255);
    }

    return cellColor;
  }

  List<bool> hasEvent(int cellPosition, List<Event> events) {
    List<bool> eventStatus = [
      false,
      false
    ]; // Index 0: single day event, Index 1: multi-day event

    // Calculate the day in grid
    var dayInGrid = cellPosition - firstDayOfWeek;

    if (dayInGrid < lastOfMonth && dayInGrid >= 0) {
      for (var event in events) {
        DateTime eventStart = DateTime.parse(event.sdate);
        DateTime eventEnd = DateTime.parse(event.edate);

        if (eventStart.day <= (dayInGrid + 1) &&
            (dayInGrid + 1) <= eventEnd.day) {
          if (eventStart.day == eventEnd.day ||
              (dayInGrid + 1) == eventStart.day) {
            eventStatus[0] = true; // Single day event
          } else {
            eventStatus[1] = true; // Multi-day event
          }
        }
      }
    }

    return eventStatus;
  }

  String daysOfMonth(cellPosition) {
    String dayToDisplay;

    var dayInGrid = cellIndex - firstDayOfWeek;

    if (dayInGrid < lastOfMonth && dayInGrid >= 0) {
      dayToDisplay = "${dayInGrid + 1} ";
    } else {
      dayToDisplay = '';
    }

    cellIndex++;
    return dayToDisplay;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Event> calEvents = ref
        .read(attendEventsProvider.notifier)
        .eventsAttendingByMonth(yearDisplayed, selectedMonth);
    List<Availability> availability = ref
        .watch(profileProvider.notifier)
        .availabilityByMonth(yearDisplayed, selectedMonth);

    return Container(
      alignment: Alignment.center,
      child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Header and month name
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "${monthName(selectedMonth)} $yearDisplayed",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColorLight,
                  ),
                ),
              ),
              Divider(),
              Row(
                children: [
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.0528,
                    width: MediaQuery.sizeOf(context).width * .95,
                    decoration: BoxDecoration(
                        // color:
                        //     Theme.of(context).primaryColorLight.withOpacity(0.35),
                        // border: Border.all(width: 1),
                        // borderRadius: BorderRadius.circular(20),
                        ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Spacer(),
                        Text(
                          'S',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'M',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'T',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'W',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'T',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'F',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'S',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColorLight),
                        ),
                        Spacer(),
                      ],
                    ),
                  )
                ],
              ),
              Divider(),

              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7),
                  itemCount: 42,
                  itemBuilder: (context, index) {
                    DateTime currentDate = DateTime(yearDisplayed,
                        selectedMonth, index - firstDayOfWeek + 1);
                    bool hasTimeSelected =
                        selectedDatesWithTime[currentDate] ?? false;

                    bool hasBlockedTime = availability.any((avail) =>
                        avail.sTime.year == currentDate.year &&
                        avail.sTime.month == currentDate.month &&
                        avail.sTime.day == currentDate.day &&
                        avail.eventId == null);

                    DateTime cellDate;
                    bool isCurrentMonth = true;

                    if (index < firstDayOfWeek) {
                      // Previous month
                      cellDate = DateTime(yearDisplayed, selectedMonth, 0)
                          .subtract(Duration(days: firstDayOfWeek - index - 1));
                      isCurrentMonth = false;
                    } else if (index >= firstDayOfWeek + lastOfMonth) {
                      // Next month
                      cellDate = DateTime(yearDisplayed, selectedMonth + 1,
                          index - firstDayOfWeek - lastOfMonth + 1);
                      isCurrentMonth = false;
                    } else {
                      // Current month
                      cellDate = DateTime(yearDisplayed, selectedMonth,
                          index - firstDayOfWeek + 1);
                    }

                    return DayButton(
                      isSelected: false,
                      borderWidth: findBorderWidth(index),
                      cellColor: findCellColor(index, calEvents),
                      dayDisplayed: '${cellDate.day}',
                      index: index,
                      hasEvent: hasEvent(index, calEvents),
                      hasTimeSelected: hasTimeSelected,
                      currentDate: currentDate,
                      selectedMonth: selectedMonth, // pass the current date
                      availabilityByMonth: availability,
                      hasBlockedTime: hasBlockedTime,
                      isCurrentMonth: isCurrentMonth,
                    );
                  },
                ),
              ),
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
              const Divider(),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.14,
                child: ListView(
                  key: const PageStorageKey<String>('cal'),
                  children: [
                    for (Event i in calEvents) EventCalTab(eventData: i)
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

class DayButton extends StatelessWidget {
  const DayButton({
    super.key,
    required this.isSelected,
    required this.borderWidth,
    required this.cellColor,
    required this.dayDisplayed,
    required this.index,
    required this.hasEvent,
    required this.hasTimeSelected,
    required this.currentDate,
    required this.selectedMonth,
    required this.availabilityByMonth,
    required this.hasBlockedTime,
    required this.isCurrentMonth,
  });

  final bool isSelected;
  final bool borderWidth;
  final Color cellColor;
  final String dayDisplayed;
  final int index;
  final List hasEvent;
  final bool hasTimeSelected;
  final DateTime currentDate;
  final int selectedMonth;
  final List<Availability> availabilityByMonth;
  final bool hasBlockedTime;
  final bool isCurrentMonth;

  @override
  Widget build(BuildContext context) {
    // Determine border widths
    double leftBorderWidth = 1.0;
    double topBorderWidth = 1.0;

    return GestureDetector(
      onTap: () {
        if (currentDate.month == selectedMonth) {
          Navigator.of(context).push(MaterialPageRoute(
              builder: ((context) => DayScreenPageView(
                    initialDay: currentDate,
                    blockedTime: availabilityByMonth,
                  ))));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: Color.fromARGB(255, 0, 0, 0)!,
              width: leftBorderWidth,
            ),
            top: BorderSide(
              color: Color.fromARGB(255, 0, 0, 0)!,
              width: topBorderWidth,
            ),
          ),
          color:
              isCurrentMonth ? cellColor : Color.fromARGB(120, 128, 128, 128),
          //borderRadius: borderRadius,
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Text(
                  dayDisplayed,
                  style: TextStyle(
                    fontSize: 16,
                    color: isCurrentMonth
                        ? Colors.white
                        : Color.fromARGB(170, 149, 149, 149),
                  ),
                ),
              ),
            ),
            if (hasTimeSelected || hasBlockedTime)
              Positioned(
                left: 0,
                top: 0,
                child: CustomPaint(
                  size: Size(16, 16),
                  painter: TrianglePainter(
                    color: hasTimeSelected ? Colors.blue : Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
