import 'package:flutter/material.dart';
import 'package:nomo/screens/calendar/month_widget.dart';
import 'package:nomo/widgets/app_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DateTime currentDate = DateTime.now();

  int monthDisplayed = DateTime.now().month;
  int yearDisplayed = DateTime.now().year;


  @override
  Widget build(BuildContext context) {

    final int firstDayOfWeek = DateTime(yearDisplayed, monthDisplayed, 1).weekday;
    final int lastOfMonth = DateTime(yearDisplayed, monthDisplayed+1, 0).day;

    return Scaffold(
        appBar: const MainAppBar(),
        body: 
              Column(
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(onPressed: () {
                          setState(() {
                            monthDisplayed--;

                            if(monthDisplayed < 1) {
                              monthDisplayed = 12;
                              yearDisplayed--;
                            } 
                          });
                        }, icon: const Icon(Icons.arrow_back_ios)),
                        IconButton(onPressed: () {
                          setState(() {
                            monthDisplayed++;
                            if(monthDisplayed > 12) {
                              monthDisplayed = 1;
                              yearDisplayed++;
                            }

                          });
                        }, icon: const Icon(Icons.arrow_forward_ios))
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
                  )
                ],
              ),

    );
  }
}