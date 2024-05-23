import 'package:flutter/material.dart';
import 'package:nomo/screens/calendar/month_widget.dart';
import 'package:nomo/screens/new_event_screen.dart';
//import 'package:nomo/widgets/app_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DateTime currentDate = DateTime.now();

  int monthDisplayed = DateTime.now().month;
  int yearDisplayed = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
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
                  icon:  Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSecondary)),
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
                  icon:  Icon(Icons.arrow_forward_ios, color: Theme.of(context).colorScheme.onSecondary))
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
              IconButton(onPressed: (){Navigator.of(context).push(MaterialPageRoute(builder: ((context) => 
              const NewEventScreen(isNewEvent: true, event: null))));}, icon:  Icon(Icons.add_box_rounded, size: 45, color: Theme.of(context).colorScheme.onSecondary)),
            ],
          )
        ],
      ),
    );
  }
}
