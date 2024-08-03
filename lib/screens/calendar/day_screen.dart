import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/availability_model.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/time_block.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:nomo/widgets/custom_time_picker.dart';

class DayScreen extends ConsumerStatefulWidget {
  DayScreen({super.key, required this.day, required this.blockedTime});

  DateTime day; // the specific day
  List<Availability> blockedTime;

  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  late List<Availability> currentBlockedTime;

  TimeOfDay? startTime; // s time
  TimeOfDay? endTime; // e time
  String? blockTitle;

  @override
  void initState() {
    super.initState();
    availabilityByDay();
    _initializeBlockedHours();
  }

  // Called whenever the widget configuration changes.
  // Makes sure to update displayed time blocks approproately
  @override
  void didUpdateWidget(DayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) {
      availabilityByDay();
      _initializeBlockedHours();
    }
  }

  // Filters blocked times for the specific day
  void availabilityByDay() {
    List<Availability> availabilityByDay = [];

    for (var avail in widget.blockedTime) {
      if (avail.sTime.day == widget.day.day) {
        availabilityByDay.add(avail);
      }
    }
    setState(() {
      currentBlockedTime = availabilityByDay;
    });
  }

  List<Map<String, dynamic>> blockedHours = List.generate(
    24 * 60,
    (index) =>
        {'blocked': false, 'title': '', 'start': null, 'end': null, 'isEvent': false, 'event_id': null, 'id': ''},
  );

  // Initializes blocked times for the current day
  void _initializeBlockedHours() {
    // Reset all blocked hours
    blockedHours = List.generate(
      24 * 60,
      (index) =>
          {'blocked': false, 'title': '', 'start': null, 'end': null, 'isEvent': false, 'event_id': null, 'id': ''},
    );

    for (var availability in currentBlockedTime) {
      DateTime start = availability.sTime;
      DateTime end = availability.eTime;
      String title = availability.blockTitle;
      String id = availability.availId ?? '';
      String? event_id = availability.eventId;

      if (start.day == widget.day.day) {
        int startMinute = start.hour * 60 + start.minute;
        int endMinute = end.hour * 60 + end.minute;

        for (int i = startMinute; i < endMinute; i++) {
          blockedHours[i] = {
            'blocked': true,
            'title': title,
            'start': TimeOfDay(hour: start.hour, minute: start.minute),
            'end': TimeOfDay(hour: end.hour, minute: end.minute),
            'isEvent': event_id != null,
            'event_id': event_id,
            'id': id
          };
        }
      }
    }
  }

  // Opens a time picker for user to select or edit a start/end time for their time block
  //
  // Parameters:
  // - 'isStartTime': whether the current selection is being made for the start or end time of a block
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
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

  // Confirms and saves data to database for currently selected time block
  void _confirmTimeRange(BuildContext context) {
    if (startTime != null && endTime != null && blockTitle != null && blockTitle!.isNotEmpty) {
      DateTime supabaseSTime =
          DateTime(widget.day.year, widget.day.month, widget.day.day, startTime!.hour, startTime!.minute);
      DateTime supabaseETime =
          DateTime(widget.day.year, widget.day.month, widget.day.day, endTime!.hour, endTime!.minute);
      String profileId = ref.read(profileProvider.notifier).state!.profile_id;

      setState(() {
        int startMinutes = startTime!.hour * 60 + startTime!.minute;
        int endMinutes = endTime!.hour * 60 + endTime!.minute;

        for (int i = startMinutes; i <= endMinutes; i++) {
          blockedHours[i] = {'blocked': true, 'title': blockTitle, 'start': startTime, 'end': endTime};
        }
      });
      ref
          .read(profileProvider.notifier)
          .createBlockedTime(profileId, supabaseSTime.toString(), supabaseETime.toString(), blockTitle, null);

      Navigator.of(context).pop();
    } else {
      // Show a message if the title is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the time block')),
      );
    }
  }

  // Updates an existing time block with new values
  //
  // Parameters:
  // - 'availID': availability_id of the time block being edited
  void _updateTimeRange(BuildContext context, String availID) {
    if (startTime != null && endTime != null && blockTitle != null && blockTitle!.isNotEmpty) {
      DateTime supabaseSTime =
          DateTime(widget.day.year, widget.day.month, widget.day.day, startTime!.hour, startTime!.minute);
      DateTime supabaseETime =
          DateTime(widget.day.year, widget.day.month, widget.day.day, endTime!.hour, endTime!.minute);
      String profileId = ref.read(profileProvider.notifier).state!.profile_id;

      setState(() {
        print('setting the updated state');
        int startMinutes = startTime!.hour * 60 + startTime!.minute;
        int endMinutes = endTime!.hour * 60 + endTime!.minute;

        for (int i = startMinutes; i <= endMinutes; i++) {
          blockedHours[i] = {'blocked': true, 'title': blockTitle, 'start': startTime, 'end': endTime, 'id': availID};
        }
      });
      ref
          .read(profileProvider.notifier)
          .updateBlockedTime(profileId, supabaseSTime.toString(), supabaseETime.toString(), blockTitle, availID);

      Navigator.of(context).pop();
    } else {
      // Show a message if the title is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for the time block')),
      );
    }
  }

  // Formats TimeOfDay value into a more readable String. Returns in the format HH:MM AM/PM
  //
  // Parameters:
  // - 'time': TimeOfDay value to be converted into readable format
  String formatTimeOfDay(TimeOfDay time) {
    final hours = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minutes = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hours:$minutes $period';
  }

  // Displays a bottom sheet for the creation of a new time block
  void _showTimeRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setModalState) {
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
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () async {
                          await _selectTime(context, true);
                          setModalState(() {});
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
                        onPressed: () async {
                          await _selectTime(context, false);
                          setModalState(() {});
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
                      decoration: const InputDecoration(
                        labelText: 'Title',
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
                      _confirmTimeRange(context); // this is where the block is created
                      startTime = null;
                      endTime = null;
                    },
                    child: const Text('Confirm'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // Displays a bottom sheet to edit an existing time block
  void _showEditTimeBlock(BuildContext context, String availID, int blockStart, int blockEnd, String title) {
    // Initialize editStartTime and editEndTime with the existing values
    startTime = TimeOfDay(hour: blockStart ~/ 60, minute: blockStart % 60);
    endTime = TimeOfDay(hour: blockEnd ~/ 60, minute: blockEnd % 60);

    TextEditingController titleController = TextEditingController(text: title);

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, StateSetter setModalState) {
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
                    'Edit Time Block',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () async {
                          final pickedTime = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (BuildContext context) {
                              return CustomTimePicker(
                                initialTime: startTime!,
                                onTimeSelected: (TimeOfDay selectedTime) {
                                  return selectedTime;
                                },
                                isStartTime: true,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            setState(() {
                              startTime = pickedTime; // Update startTime if a new time is picked
                            });
                          }
                          setModalState(() {});
                        },
                        child: Text(
                          formatTimeOfDay(startTime!),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColorDark,
                        ),
                        onPressed: () async {
                          final pickedTime = await showDialog<TimeOfDay>(
                            context: context,
                            builder: (BuildContext context) {
                              return CustomTimePicker(
                                initialTime: endTime!,
                                onTimeSelected: (TimeOfDay selectedTime) {
                                  return selectedTime;
                                },
                                isStartTime: false,
                              );
                            },
                          );

                          if (pickedTime != null) {
                            setState(() {
                              endTime = pickedTime; // Update endTime if a new time is picked
                            });
                          }
                          setModalState(() {});
                        },
                        child: Text(
                          formatTimeOfDay(endTime!),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Title',
                      ),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
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
                            int newStartMinutes = startTime!.hour * 60 + startTime!.minute;
                            int newEndMinutes = endTime!.hour * 60 + endTime!.minute;

                            // Clear the previous block
                            for (int i = blockStart; i <= blockEnd; i++) {
                              blockedHours[i] = {'blocked': false, 'title': '', 'start': null, 'end': null};
                            }

                            print(titleController.text);
                            print(startTime);
                            print(endTime);
                            print(availID);

                            // Set the new block
                            for (int i = newStartMinutes; i <= newEndMinutes; i++) {
                              blockedHours[i] = {
                                'blocked': true,
                                'title': titleController.text,
                                'start': startTime,
                                'end': endTime,
                                'id': availID
                              };
                            }
                          });
                          print('about to update');
                          _updateTimeRange(context, availID);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            for (int i = blockStart; i <= blockEnd; i++) {
                              blockedHours[i] = {'blocked': false, 'title': '', 'start': null, 'end': null};
                            }
                          });
                          ref.read(profileProvider.notifier).deleteBlockedTime(availID, null);
                          Navigator.of(context).pop();
                          // startTime = null;
                          // endTime = null;
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
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> hourLabels = [];
    List<Widget> timeBlocks = [];

    // Render hour labels
    for (int i = 0; i < 24; i++) {
      final startingHour = i % 12 == 0 ? 12 : i % 12;
      final timeLabel = '${startingHour == 0 ? 12 : startingHour}:00 ${i < 12 ? 'AM' : 'PM'}';

      hourLabels.add(SizedBox(
        height: 50.0,
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    bottom: BorderSide(color: Theme.of(context).colorScheme.inverseSurface),
                    right: BorderSide(color: Theme.of(context).colorScheme.inverseSurface),
                  )),
              width: 80,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                timeLabel,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ));
    }

    // Render time blocks
    for (int minute = 0; minute < 24 * 60; minute++) {
      if (blockedHours[minute]['blocked']) {
        int blockStart = minute;
        int blockEnd = blockStart;

        while (blockEnd < 24 * 60 &&
            blockedHours[blockEnd]['blocked'] &&
            blockedHours[blockEnd]['title'] == blockedHours[blockStart]['title']) {
          blockEnd++;
        }

        int blockMinutes = blockEnd - blockStart;
        double blockHeight = (blockMinutes / 60) * 50.0;
        String availID = blockedHours[blockStart]['id'] ?? '';
        bool isEvent = blockedHours[blockStart]['isEvent'] ?? false;

        timeBlocks.add(
          Positioned(
            top: blockStart / 60 * 50.0,
            left: 80,
            right: 0,
            child: GestureDetector(
              onTap: () async {
                if (!isEvent) {
                  _showEditTimeBlock(context, availID, blockStart, blockEnd - 1, blockedHours[blockStart]['title']);
                } else {
                  Event eventData =
                      await ref.read(eventsProvider.notifier).deCodeLinkEvent(blockedHours[blockStart]['event_id']);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => DetailedEventScreen(
                      eventData: eventData,
                    ),
                  ));
                }
              },
              child: TimeBlock(
                title: blockedHours[blockStart]['title'],
                hourCount: blockMinutes / 60,
                isEvent: isEvent,
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
                  physics: const NeverScrollableScrollPhysics(),
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
