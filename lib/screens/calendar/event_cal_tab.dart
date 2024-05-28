import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/screens/detailed_event_screen.dart';

class EventCalTab extends StatelessWidget {
  const EventCalTab({super.key, required this.eventData});

  final Event eventData;
 
  @override
  Widget build(BuildContext context) {

    final DateTime sDate = DateTime.parse(eventData.sdate);
    final DateTime eDate = DateTime.parse(eventData.edate);

    var formattedDate = "${sDate.month}/${sDate.day}/${sDate.year} to ${eDate.month}/${eDate.day}/${eDate.year}";

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: eventData))));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(.4),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: const Color.fromARGB(255, 0, 0, 0),
              width: 1,
            ),
          ),
          child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(eventData.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.onSecondary),
                  ),
                  Text(formattedDate, style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))
                ]
          )
        ),
      ),
    );
  }
}