import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/screens/events/detailed_event_screen.dart';

class EventCalTab extends StatelessWidget {
  const EventCalTab({super.key, required this.eventData});

  final Event eventData;

  @override
  Widget build(BuildContext context) {
    final DateTime sDate = DateTime.parse(eventData.attendeeDates['time_start']);
    final DateTime eDate = DateTime.parse(eventData.attendeeDates['time_end']);

    var formattedDate = "${sDate.month}/${sDate.day}/${sDate.year} to ${eDate.month}/${eDate.day}/${eDate.year}";

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text(
          eventData.title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(formattedDate),
        trailing: Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: eventData))));
        },
      ),
    );
  }
}
