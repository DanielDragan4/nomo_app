import 'package:flutter/material.dart';
import 'package:nomo/screens/calendar/time_block.dart';

class DayScreen extends StatefulWidget {
  DayScreen({super.key, required this.day});

  DateTime day;

  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<Map<String, dynamic>> blockedHours =
      List.generate(24 * 60, (index) => {'blocked': false, 'title': ''});
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? blockTitle;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
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

  void _confirmTimeRange(BuildContext context) {
    if (startTime != null && endTime != null && blockTitle != null) {
      setState(() {
        int startMinutes = startTime!.hour * 60 + startTime!.minute;
        int endMinutes = endTime!.hour * 60 + endTime!.minute;

        for (int i = startMinutes; i <= endMinutes; i++) {
          blockedHours[i] = {'blocked': true, 'title': blockTitle};
        }
      });
    }
    Navigator.of(context).pop();
  }

  String formatTimeOfDay(TimeOfDay time) {
    final hours = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hours:$minutes $period';
  }

  void _showTimeRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 250,
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
                          setState(() {
                            blockTitle = value;
                          });
                        },
                      ),
                    ),
                    ElevatedButton(
                      onPressed: blockTitle == null || blockTitle!.isEmpty
                          ? null // Disable button if title is empty
                          : () {
                              _confirmTimeRange(context);
                            },
                      child: Text('Confirm'),
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

  @override
  Widget build(BuildContext context) {
    List<Widget> hourLabels = [];
    List<Widget> timeBlocks = [];

    for (int i = 0; i < 24; i++) {
      final startingHour = i % 12 == 0 ? 12 : i % 12;
      final timeLabel =
          '${startingHour == 0 ? 12 : startingHour}:00 ${i < 12 ? 'AM' : 'PM'}';

      hourLabels.add(Container(
        height: 50.0,
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black))),
        child: Row(
          children: [
            Container(
              width: 80,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                '$timeLabel',
                style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
      ));
    }

    for (int minute = 0; minute < 24 * 60; minute++) {
      if (blockedHours[minute]['blocked']) {
        int blockStart = minute;
        int blockEnd = blockStart;

        while (blockEnd < 24 * 60 &&
            blockedHours[blockEnd]['blocked'] &&
            blockedHours[blockEnd]['title'] ==
                blockedHours[blockStart]['title']) {
          blockEnd++;
        }

        int blockMinutes = blockEnd - blockStart;
        double blockHeight = (blockMinutes / 60) * 50.0;

        timeBlocks.add(
          Positioned(
            top: blockStart / 60 * 50.0,
            left: 80,
            right: 0,
            child: TimeBlock(
              title: blockedHours[blockStart]['title'],
              hourCount: blockMinutes / 60,
            ),
          ),
        );

        minute = blockEnd - 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.day.month}/${widget.day.day}/${widget.day.year}'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                ListView(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: hourLabels,
                ),
                ...timeBlocks,
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTimeRangePicker(context);
        },
        child: Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
