import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';

class EventCalTab extends StatelessWidget {
  EventCalTab({super.key, required this.eventData});

  final Event eventData;

  @override
  Widget build(BuildContext context) {

    final DateTime sDate = DateTime.parse(eventData.sdate);
    final DateTime eDate = DateTime.parse(eventData.edate);

    var formattedDate = "${sDate.month}/${sDate.day}/${sDate.year} to ${eDate.month}/${eDate.day}/${eDate.year}";

    return Padding(
      padding: const EdgeInsets.all(5.0),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(formattedDate)
              ]
        )
      ),
    );
  }
}