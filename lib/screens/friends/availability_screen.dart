import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nomo/providers/profile_provider.dart';

class AvailableTimesScreen extends ConsumerStatefulWidget {
  const AvailableTimesScreen({super.key, required this.users});

  final List<String> users;

  @override
  _AvailableTimesScreenState createState() => _AvailableTimesScreenState();
}

class _AvailableTimesScreenState extends ConsumerState<AvailableTimesScreen> {
  List _freeTimes = [];
  TextEditingController durationController = TextEditingController();
  DateTime? startPicked;
  DateTime? endPicked;
  String? formattedStart;
  String? formattedEnd;

  bool _startDateError = false;
  bool _endDateError = false;
  bool _durationError = false;

  void _submitForm() async {
    /*
      gets all values to get valuse for mutual availability from the profile provider. Sets the values for _freeTimes

      Params: none
      
      Returns: none
    */
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _startDateError = startPicked == null;
      _endDateError = endPicked == null;
      _durationError = durationController.text.isEmpty || int.tryParse(durationController.text) == null;
    });

    if (!_startDateError && !_endDateError && !_durationError) {
      final freeTimes = await ref
          .read(profileProvider.notifier)
          .mutualAvailability(widget.users, startPicked!, endPicked!, int.parse(durationController.text));
      setState(() {
        _freeTimes = freeTimes;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields correctly.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Text('How to use', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. Select a start date and end date',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              SizedBox(height: 8),
              Text('2. Enter a minimum duration (in hours) of your desired availability blocks',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              SizedBox(height: 8),
              Text('3. Tap "Find Free Times" to see when both users are available',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(
        title: const Text('Available Times'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('The Following Allows you to find Available times between you and the person you have selecte. Enter A range of days you would like to meet, A number of hours you would like to meet for, and then hit enter To see the available times'
                                                ,style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),),
                        ),),
                      Card(
                        elevation: 4,
                        child:Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildDateSelectionRow(context),
                        ),),
                      Card(
                        elevation: 4,
                        child:
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildDurationAndSubmitRow(context),
                      ),)
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildFreeTimesList(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildInfoCard(BuildContext context) {
  //   return Card(
  //     color: Theme.of(context).colorScheme.onPrimary,
  //     child: Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text(
  //             'How to use:',
  //             style: TextStyle(
  //               fontSize: 18,
  //               fontWeight: FontWeight.bold,
  //               color: Theme.of(context).colorScheme.onSecondary,
  //             ),
  //           ),
  //           const SizedBox(height: 8),
  //           Text(
  //             '1. Select a start date and end date',
  //             style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
  //           ),
  //           Text(
  //             '2. Enter a minimum duration (in hours) of your desired availability blocks',
  //             style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
  //           ),
  //           Text(
  //             '3. Tap "Find Free Times" to see when both users are available',
  //             style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildDateSelectionRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildDateSelector(
            context,
            "Start",
            formattedStart ?? "Select Start Date",
            () async {
              startPicked = await showDatePicker(
                context: context,
                initialDate: startPicked ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (startPicked != null) {
                if (endPicked != null && startPicked!.isAfter(endPicked!)) {
                  endPicked = startPicked;
                  setState(() {
                    formattedEnd = DateFormat.yMd().format(endPicked!);
                    _endDateError = false;
                  });
                }
                setState(() {
                  formattedStart = DateFormat.yMd().format(startPicked!);
                  _startDateError = false;
                });
              }
            },
            _startDateError,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDateSelector(
            context,
            "End",
            formattedEnd ?? "Select End Date",
            () async {
              endPicked = await showDatePicker(
                context: context,
                initialDate: startPicked ?? endPicked ?? DateTime.now(),
                firstDate: startPicked ?? DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (endPicked != null) {
                endPicked = endPicked!.add(const Duration(hours: 23, minutes: 59));
                setState(() {
                  formattedEnd = DateFormat.yMd().format(endPicked!);
                  _endDateError = false;
                });
              }
            },
            _endDateError,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(
      BuildContext context, String label, String displayText, VoidCallback onPressed, bool hasError) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
        ),
        const SizedBox(height: 4),
        OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: hasError ? Colors.red : Theme.of(context).colorScheme.onSecondary),
          ),
          child: Text(
            displayText,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
          ),
        ),
        if (hasError)
          Text(
            'Please select a date',
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildDurationAndSubmitRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
              errorText: _durationError ? 'Please enter a valid duration' : null,
              errorStyle: TextStyle(color: Colors.red),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _durationError ? Colors.red : Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: _durationError ? Colors.red : Theme.of(context).primaryColor),
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            keyboardType: TextInputType.number,
            controller: durationController,
            onChanged: (value) {
              setState(() {
                _durationError = value.isEmpty || int.tryParse(value) == null;
              });
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: _submitForm,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Find Free Times'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFreeTimesList(BuildContext context) {
    return _freeTimes.isEmpty
        ? Center(
            child: Text(
              'No free times available',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
            ),
          )
        : ListView.builder(
            itemCount: _freeTimes.length,
            itemBuilder: (context, index) {
              final time = _freeTimes[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(
                    'Free from ${DateFormat.yMd().add_jm().format(time['start_time'])} \nto ${DateFormat.yMd().add_jm().format(time['end_time'])}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
  }
}
