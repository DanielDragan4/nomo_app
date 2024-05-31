import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/time_block.dart';

class DayScreen extends ConsumerStatefulWidget {
  DayScreen({super.key, required this.day});

  DateTime day; // the specipsic day

  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  List<Map<String, dynamic>> blockedHours = List.generate(24 * 60,
      (index) => {'blocked': false, 'title': '', 'start': null, 'end': null});
  TimeOfDay? startTime; // s time
  TimeOfDay? endTime; // e time
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
      DateTime supabaseSTime = DateTime(widget.day.year, widget.day.month,
          widget.day.day, startTime!.hour, startTime!.minute);
      DateTime supabaseETime = DateTime(widget.day.year, widget.day.month,
          widget.day.day, endTime!.hour, endTime!.minute);
      String profileId = ref.read(profileProvider.notifier).state!.profile_id;

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
      ref.read(attendEventsProvider.notifier).createBlockedTime(profileId, true,
          supabaseSTime.toString(), supabaseETime.toString(), blockTitle);

      Navigator.of(context).pop();
    } else {
      // Show a message if the title is empty
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a title for the time block')),
      );
    }
  }

  void _updateTimeRange(BuildContext context) {
    if (startTime != null &&
        endTime != null &&
        blockTitle != null &&
        blockTitle!.isNotEmpty) {
      DateTime supabaseSTime = DateTime(widget.day.year, widget.day.month,
          widget.day.day, startTime!.hour, startTime!.minute);
      DateTime supabaseETime = DateTime(widget.day.year, widget.day.month,
          widget.day.day, endTime!.hour, endTime!.minute);
      String profileId = ref.read(profileProvider.notifier).state!.profile_id;

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
      ref.read(attendEventsProvider.notifier).createBlockedTime(profileId, true,
          supabaseSTime.toString(), supabaseETime.toString(), blockTitle);

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
                    _confirmTimeRange(
                        context); // this is where the block is created
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
                      child: const Text('Save'), // update the time block
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
                        Navigator.of(context).pop(); // remove blocked time
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
          ),
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

      hourLabels.add(SizedBox(
        height: 50.0,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSecondary,
                  border: const Border(bottom: BorderSide(), right: BorderSide())),
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
                color: Colors.white,
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
          color: Theme.of(context).colorScheme.onSecondary,
        ),
      ),
    );
  }
}
