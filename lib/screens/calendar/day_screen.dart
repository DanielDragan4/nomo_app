import 'package:flutter/material.dart';

class DayScreen extends StatefulWidget {
  final DateTime day;

  DayScreen({Key? key, required this.day}) : super(key: key);

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
                    ),
                  ),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
