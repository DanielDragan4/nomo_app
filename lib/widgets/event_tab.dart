import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends StatelessWidget {
  const EventTab({super.key, required this.eventData});

  final Event eventData;

  @override
  Widget build(BuildContext context) {

    bool attendingHosting;

    if(eventData.attending == true || eventData.host == true) {
      attendingHosting = true;
    } else {
      attendingHosting = false;
    }

    var formattedDate =
        "${eventData.date.month}/${eventData.date.day}/${eventData.date.year}";
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
                  eventData.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                  Text(
                    attendingHosting ? eventData.attending ? 'Attending' : 'Hosting' : '',
                    style: TextStyle(
                        color: eventData.attending
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
                  eventData.image,
                  fit: BoxFit.fill,
                ),
              ),
            ),
            Container(
              height: 5,
            ),
            EventInfo(eventsData: eventData, attendOrHost: attendingHosting,),
            Container(
              height: 70,
            ),
          ],
        ),
      ),
    );
  }
}
