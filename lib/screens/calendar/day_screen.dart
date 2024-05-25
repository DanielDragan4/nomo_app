import 'package:flutter/material.dart';

class DayScreen extends StatefulWidget {
  DayScreen({super.key, this.day});

  DateTime? day;

  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<bool> blockedHours = List.generate(24, (index) => false);
  TimeOfDay? startTime;
  TimeOfDay? endTime;

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
    if (startTime != null && endTime != null) {
      setState(() {
        blockedHours.fillRange(startTime!.hour, endTime!.hour + 1, true);
      });
    }
    Navigator.of(context).pop(); // Hide the modal bottom sheet
  }

  void _showTimeRangePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 150,
          child: Column(
            children: [
              SizedBox(height: 10),
              Text(
                'Select Time Range',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark),
                    onPressed: () {
                      _selectTime(context, true);
                    },
                    child: Text(
                      startTime == null
                          ? 'Start Time'
                          : '${startTime!.hour}:${startTime!.minute}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColorDark),
                    onPressed: () {
                      _selectTime(context, false);
                    },
                    child: Text(
                      endTime == null
                          ? 'End Time'
                          : '${endTime!.hour}:${endTime!.minute}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  _confirmTimeRange(context);
                },
                child: Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('${widget.day!.month}/${widget.day!.day}/${widget.day!.year}'),
      ),
      body: ListView.builder(
        itemCount: 24,
        itemBuilder: (context, index) {
          final startingHour = index % 12 == 0 ? 12 : index % 12;
          final timeLabel =
              '${startingHour == 0 ? 12 : startingHour}:00 ${index < 12 ? 'AM' : 'PM'}';

          return GestureDetector(
            onTap: () {
              setState(() {
                blockedHours[index] = !blockedHours[index];
              });
            },
            child: Container(
              height: 50,
              color: blockedHours[index]
                  ? Colors.red
                  : Theme.of(context).colorScheme.secondary,
              child: Center(
                child: Text(
                  '$timeLabel',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
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
