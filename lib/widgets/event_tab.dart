import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends ConsumerWidget {
  const EventTab({super.key, required this.eventData});

  final Event eventData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // bool attendingHosting;

    // if(eventData.attending == true || eventData.host == true) {
    //   attendingHosting = true;
    // } else {
    //   attendingHosting = false;
    // }

    String imgurl;

    var formattedDate = "${eventData.sdate}";
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
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
                // Text(
                //   attendingHosting ? eventData.attending ? 'Attending' : 'Hosting' : '',
                //   style: TextStyle(
                //       color: eventData.attending
                //           ? const Color.fromARGB(255, 151, 136, 8)
                //           : const Color.fromARGB(255, 17, 114, 20)),
                // ),
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
                child: FutureBuilder<String>(
                  future: ref
                      .watch(eventsProvider.notifier)
                      .ImageURL(eventData.imageId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.network(snapshot.data!, fit: BoxFit.fill);
                    } else if (snapshot.hasError) {
                      return Text('Error loading image: ${snapshot.error}');
                    } else {
                      return CircularProgressIndicator(); // Or any loading indicator
                    }
                  },
                ),
              ),
            ),
            Container(
              height: 5,
            ),
            EventInfo(
              eventsData: eventData, //attendOrHost: attendingHosting,
            ),
            Container(
              height: 80,
              child: Text(
                eventData.description
              ),
            ),
          ],
        ),
      ),
    );
  }
}
