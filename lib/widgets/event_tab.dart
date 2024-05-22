import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/detailed_event_screen.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends ConsumerStatefulWidget {
  const EventTab({
    super.key,
    required this.eventData,
  });

  final Event eventData;

  @override
  ConsumerState<EventTab> createState() {
    return _EventTabState();
  }
}

class _EventTabState extends ConsumerState<EventTab> {
  @override
  Widget build(BuildContext context) {
    final DateTime date = DateTime.parse(widget.eventData.sdate);

    String getHour() {
      if (date.hour > 12) {
        return ('${(date.hour - 12)} P.M.');
      } else {
        return ("${date.hour} A.M.");
      }
    }

    var formattedDate =
        "${date.month}/${date.day}/${date.year} at ${getHour()}";
    return Padding(
      padding: const EdgeInsets.only(top: 1, bottom: 10, left: 5, right: 5),
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
            Padding(
              padding:  EdgeInsets.all(MediaQuery.sizeOf(context).width / 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  FutureBuilder(
                    future: ref.read(supabaseInstance),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return CircleAvatar(
                          radius: MediaQuery.sizeOf(context).width / 20,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(
                            widget.eventData.hostProfileUrl,
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Text('Error loading image: ${snapshot.error}');
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                  SizedBox(width: MediaQuery.sizeOf(context).height / 150),
                  Text(
                    widget.eventData.hostUsername,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: MediaQuery.of(context).size.width * .04),
                  )
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: widget.eventData)))),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(15),
                        bottomRight: Radius.circular(15))),
                child: SizedBox(
                  width: double.infinity,
                  height: 250,
                  child: FutureBuilder(
                    future: ref.read(supabaseInstance),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Image.network(widget.eventData.imageUrl,
                            fit: BoxFit.fill);
                      } else if (snapshot.hasError) {
                        return Text('Error loading image: ${snapshot.error}');
                      } else if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              height: 5,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.eventData.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: MediaQuery.of(context).size.width * .04),
                ),
                Text(formattedDate),
              ],
            ),
            Container(
              height: 5,
            ),
            EventInfo(eventsData: widget.eventData),
            GestureDetector(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: ((context) => DetailedEventScreen(eventData: widget.eventData)))),
              child: SizedBox(
                child: Text(widget.eventData.description,
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
