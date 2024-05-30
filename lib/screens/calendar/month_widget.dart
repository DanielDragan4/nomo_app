import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/screens/calendar/event_cal_tab.dart';
import 'package:nomo/screens/detailed_event_screen.dart';

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
  final int lastOfMonth;
  int cellIndex = 0;
  final int yearDisplayed;
  final Map<DateTime, bool> selectedDatesWithTime;

  String monthName(int month) {
    switch (month) {
      case 1:
        return "January";
      case 2:
        return "Febuary";
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

  bool findBoarderWidth(cellPosition) {
    bool boarderWidth;

    if ((cellIndex - firstDayOfWeek) < lastOfMonth &&
        (cellIndex - firstDayOfWeek) >= 0) {
      boarderWidth = true;
    } else {
      boarderWidth = false;
    }

    return boarderWidth;
  }

  Color findCellColor(cellPosition, List events) {
    Color cellColor;
    var dayInGrid = cellIndex - firstDayOfWeek;
    if ((dayInGrid) < lastOfMonth && (dayInGrid) >= 0) {
      cellColor = const Color.fromARGB(255, 221, 221, 221);
      for (var day in events) {
        if ((dayInGrid + 1) == DateTime.parse(day.sdate).day) {
          cellColor = const Color.fromARGB(136, 162, 24, 248);
        }
      }
    } else {
      cellColor = const Color.fromARGB(0, 255, 255, 255);
    }

    return cellColor;
  }

  List hasEvent(cellPosition, List events) {
    List hasEvent;
    var dayInGrid = cellIndex - firstDayOfWeek;
    if ((dayInGrid) < lastOfMonth && (dayInGrid) >= 0) {
      hasEvent = [false];
      for (var day in events) {
        if ((dayInGrid) == DateTime.parse(day.sdate).day) {
          hasEvent = [true, day];
        }
      }
    } else {
      hasEvent = [false];
    }

    return hasEvent;
  }

  String daysOfMonth() {
    String dayToDisplay;

    if ((cellIndex - firstDayOfWeek) < lastOfMonth &&
        (cellIndex - firstDayOfWeek) >= 0) {
      dayToDisplay = "${(cellIndex - firstDayOfWeek) + 1} ";
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

    return Container(
      alignment: Alignment.center,
      child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              // Header and month name
              Row(
                children: [
                  Container(
                    height: MediaQuery.sizeOf(context).height * 0.0528,
                    width: MediaQuery.sizeOf(context).width * .95,
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 135, 135, 135),
                      border: Border.all(width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Spacer(),
                        Text(
                          'S',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'M',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'T',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'W',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'T',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'F',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Spacer(),
                        Text(
                          'S',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                      ],
                    ),
                  )
                ],
              ),
              Container(
                alignment: Alignment.topLeft,
                child: Text(
                  "${monthName(selectedMonth)} $yearDisplayed",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
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
                    return DayButton(
                      isSelected: false,
                      boarderWidth: findBoarderWidth(index),
                      cellColor: findCellColor(index, calEvents),
                      dayDisplayed: daysOfMonth(),
                      index: index,
                      hasEvent: hasEvent(index, calEvents),
                      hasTimeSelected: hasTimeSelected,
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
  const DayButton(
      {super.key,
      required this.isSelected,
      required this.boarderWidth,
      required this.cellColor,
      required this.dayDisplayed,
      required this.index,
      required this.hasEvent,
      required this.hasTimeSelected});

  final bool isSelected;
  final bool boarderWidth;
  final Color cellColor;
  final String dayDisplayed;
  final int index;
  final List hasEvent;
  final bool hasTimeSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (hasEvent[0]) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) =>
                      DetailedEventScreen(eventData: hasEvent[1]))));
            }
          },
          child: Stack(
            children: [
              Container(
                height: MediaQuery.sizeOf(context).height * 0.0628,
                alignment: Alignment.topRight,
                decoration: BoxDecoration(
                  border: boarderWidth
                      ? Border.all(width: 1)
                      : Border.all(
                          color: const Color.fromARGB(0, 255, 255, 255)),
                  color: cellColor,
                ),
                child: Text(
                  dayDisplayed,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              if (hasTimeSelected)
                Positioned(
                  left: 0,
                  top: 0,
                  child: CustomPaint(
                    size: Size(20, 20),
                    painter: TrianglePainter(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color.fromARGB(162, 244, 67, 54)
      ..style = PaintingStyle.fill;

    var path = Path()
      ..moveTo(1, 1) // Start at the top-left corner
      ..lineTo(1, size.height) // Draw line to the bottom-left corner
      ..lineTo(size.height, 1) // Draw line to the top-right corner
      ..close(); // Close the path

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
