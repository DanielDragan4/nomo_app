import 'package:flutter/material.dart';
import 'package:nomo/screens/calendar/time_block.dart';

class DayScreen extends StatefulWidget {
<<<<<<< HEAD
  final DateTime day;

  DayScreen({Key? key, required this.day}) : super(key: key);
=======
  DayScreen({super.key, required this.day});

  DateTime day;
>>>>>>> 4adab42cc7e821db9df5b0f8e2d867558cb85022

  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<Map<String, dynamic>> blockedHours = List.generate(24 * 60,
      (index) => {'blocked': false, 'title': '', 'start': null, 'end': null});
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String? blockTitle;

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.input);

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
    if (startTime != null &&
        endTime != null &&
        blockTitle != null &&
        blockTitle!.isNotEmpty) {
      setState(() {
        int startMinutes = startTime!.hour * 60 + startTime!.minute;
        int endMinutes = endTime!.hour * 60 + endTime!.minute;

        for (int i = startMinutes; i <= endMinutes; i++) {
          blockedHours[i] = {
            'blocked': true,
            'title': blockTitle,
            'start': startTime,
            'end': endTime
          };
        }
      });
      Navigator.of(context).pop();
    } else {
      // Show a message if the title is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title for the time block')),
      );
    }
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
<<<<<<< HEAD
        return Container(
          height: 200,
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Select Time Range',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _selectTime(context, true);
                    },
                    child: Text(
                      startTime == null
                          ? 'Start Time'
                          : '${startTime!.format(context)}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _selectTime(context, false);
                    },
                    child: Text(
                      endTime == null
                          ? 'End Time'
                          : '${endTime!.format(context)}',
=======
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
>>>>>>> 4adab42cc7e821db9df5b0f8e2d867558cb85022
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
<<<<<<< HEAD
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _confirmTimeRange(context);
                },
                child: Text('Confirm'),
              ),
            ],
=======
                ),
                ElevatedButton(
                  onPressed: () {
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
  }

  void _showEditTimeBlock(
      BuildContext context, int blockStart, int blockEnd, String title) {
    TimeOfDay editStartTime =
        TimeOfDay(hour: blockStart ~/ 60, minute: blockStart % 60);
    TimeOfDay editEndTime =
        TimeOfDay(hour: blockEnd ~/ 60, minute: blockEnd % 60);
    TextEditingController titleController = TextEditingController(text: title);

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
                  'Edit Time Block',
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
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: editStartTime,
                            initialEntryMode: TimePickerEntryMode.input);

                        if (pickedTime != null) {
                          setState(() {
                            editStartTime = pickedTime;
                          });
                        }
                      },
                      child: Text(
                        formatTimeOfDay(editStartTime),
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark,
                      ),
                      onPressed: () async {
                        final pickedTime = await showTimePicker(
                            context: context,
                            initialTime: editEndTime,
                            initialEntryMode: TimePickerEntryMode.input);

                        if (pickedTime != null) {
                          setState(() {
                            editEndTime = pickedTime;
                          });
                        }
                      },
                      child: Text(
                        formatTimeOfDay(editEndTime),
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
                    controller: titleController,
                    onChanged: (value) {
                      blockTitle = value;
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          int newStartMinutes =
                              editStartTime.hour * 60 + editStartTime.minute;
                          int newEndMinutes =
                              editEndTime.hour * 60 + editEndTime.minute;

                          for (int i = blockStart; i <= blockEnd; i++) {
                            blockedHours[i] = {
                              'blocked': false,
                              'title': '',
                              'start': null,
                              'end': null
                            };
                          }

                          for (int i = newStartMinutes;
                              i <= newEndMinutes;
                              i++) {
                            blockedHours[i] = {
                              'blocked': true,
                              'title': titleController.text,
                              'start': editStartTime,
                              'end': editEndTime
                            };
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('Save'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          for (int i = blockStart; i <= blockEnd; i++) {
                            blockedHours[i] = {
                              'blocked': false,
                              'title': '',
                              'start': null,
                              'end': null
                            };
                          }
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
>>>>>>> 4adab42cc7e821db9df5b0f8e2d867558cb85022
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.day.month}/${widget.day.day}/${widget.day.year}'),
      ),
      body: ListView.builder(
        itemCount: 24,
        itemBuilder: (context, index) {
          final startingHour = index % 12 == 0 ? 12 : index % 12;
          final timeLabel =
              '${startingHour == 0 ? 12 : startingHour}:00 ${index < 12 ? 'AM' : 'PM'}';

          return Container(
            height: 60,
            margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: blockedHours[index]
                  ? Colors.red.withOpacity(0.7)
                  : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Center(
              child: Text(
                '$timeLabel',
                style: TextStyle(
                  color: blockedHours[index]
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSecondary,
                ),
=======
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
>>>>>>> 4adab42cc7e821db9df5b0f8e2d867558cb85022
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
            child: GestureDetector(
              onTap: () {
                _showEditTimeBlock(context, blockStart, blockEnd - 1,
                    blockedHours[blockStart]['title']);
              },
              child: TimeBlock(
                title: blockedHours[blockStart]['title'],
                hourCount: blockMinutes / 60,
              ),
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
