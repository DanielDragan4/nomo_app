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

  void _submitForm() async {
    /*
      gets all values to get valuse for mutual availability from the profile provider. Sets the values for _freeTimes

      Params: none
      
      Returns: none
    */
    FocusManager.instance.primaryFocus?.unfocus();
    if ((startPicked != null) && (endPicked != null) && (int.parse(durationController.text) != null)) {
      final freeTimes = await ref
          .read(profileProvider.notifier)
          .mutualAvailability(widget.users, startPicked!, endPicked!, (int.parse(durationController.text)));
      setState(() {
        _freeTimes = freeTimes;
      });
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
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateSelectionRow(context),
                      const SizedBox(height: 16),
                      _buildDurationAndSubmitRow(context),
                    ],
                  ),
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
                  });
                }
                setState(() {
                  formattedStart = DateFormat.yMd().format(startPicked!);
                });
              }
            },
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
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context, String label, String displayText, VoidCallback onPressed) {
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
          child: Text(
            displayText,
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSecondary),
          ),
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
            decoration: const InputDecoration(
              labelText: 'Duration (hours)',
              border: OutlineInputBorder(),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            keyboardType: TextInputType.number,
            controller: durationController,
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
