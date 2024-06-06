import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
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
    if ((startPicked != null) && (endPicked != null) && (int.parse(durationController.text) != null)) {
      final freeTimes = await ref.read(profileProvider.notifier).mutualAvailability(widget.users, startPicked!, endPicked!, (int.parse(durationController.text)));
      setState(() {
        _freeTimes = freeTimes;
      });
      print(_freeTimes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).canvasColor,
      appBar: AppBar(title: Text('Available Times')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    "Start",
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  TextButton(
                    onPressed: () async{
                       startPicked = await showDatePicker(
                        context: context,
                        initialDate: (startPicked!= null) ? startPicked : DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      setState(() {
                        formattedStart = DateFormat.yMd().format(startPicked!);
                      });
                      } ,// Select start date
                    child: Text(
                      formattedStart
                       ??
                          "Select Start Date", // Format start date
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                  Text(
                    "|  ",
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  Text(
                    "End",
                    style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  TextButton(
                    onPressed: () async{
                       endPicked = await showDatePicker(
                        context: context,
                        initialDate: (endPicked!= null) ? endPicked : DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      endPicked = endPicked!.add(const Duration(hours: 23, minutes: 59));
                      setState(() {
                        formattedEnd = DateFormat.yMd().format(endPicked!);
                      });
                      } ,// Select start date
                    child: Text(
                      formattedEnd
                       ??
                          "Select End Date", // Format start date
                      style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: MediaQuery.of(context).size.width *0.35,
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Duration (in hours)',),
                        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                      keyboardType: TextInputType.number,
                      controller: durationController,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: (){
                      _submitForm();
                    },
                    child: Text('Find Free Times'),
                  ),
                ],
              ),
              
              SizedBox(height: MediaQuery.of(context).size.height *0.1),
              Expanded(
                child: ListView.builder(
                  itemCount: _freeTimes.length,
                  itemBuilder: (context, index) {
                    final time = _freeTimes[index];
                    return Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ListTile(
                          tileColor: Theme.of(context).primaryColor,
                          title: Text(
                              'Free from ${DateFormat.yMd().format(time['start_time'])} at ${DateFormat('hh:mm').format(time['start_time'])} to ${DateFormat.yMd().format(time['end_time'])} at ${DateFormat('hh:mm').format(time['end_time'])}'),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
      ),
    );
  }
}