import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends StatelessWidget {
  const EventTab({super.key, required this.eventsData});

  final Event eventsData;

  @override
  Widget build(BuildContext context) {
    var formattedDate =
        "${eventsData.date.month}/${eventsData.date.day}/${eventsData.date.year}";
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: Color.fromARGB(255, 0, 0, 0),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  eventsData.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  eventsData.attending ? 'Attending' : 'Hosting',
                  style: TextStyle(
                      color: eventsData.attending
                          ? const Color.fromARGB(255, 151, 136, 8)
                          : const Color.fromARGB(255, 17, 114, 20)),
                ),
                Text(formattedDate),
              ],
            ),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15))),
              child: SizedBox(
                width: double.infinity,
                height: 250,
                child: Image.asset(
                  eventsData.image,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Container(
              height: 5,
            ),
            EventInfo(eventsData: eventsData),
            Container(
              height: 70,
            ),
          ],
        ),
      ),
    );
  }
}
