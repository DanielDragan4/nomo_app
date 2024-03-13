import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/event_info.dart';

class EventTab extends ConsumerStatefulWidget {
  const EventTab({super.key, required this.eventData,});

  final Event eventData;

  ConsumerState<EventTab> createState() {
    return _EventTabState();
  }
}

class _EventTabState extends ConsumerState<EventTab> {

  Future<String>? _event;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _event = fetchData();
    });
  }

  Future<String> fetchData() async {
    // Your asynchronous operation here
    await Future.delayed(Duration(seconds: 2));
    return await ref.watch(eventsProvider.notifier).ImageURL(widget.eventData.imageId);
  }

  @override
  Widget build(BuildContext context) {
    // bool attendingHosting;

    // if(eventData.attending == true || eventData.host == true) {
    //   attendingHosting = true;
    // } else {
    //   attendingHosting = false;
    // }
    

    String imgurl;

    var formattedDate = "${widget.eventData.sdate}";
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
                  widget.eventData.title,
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
                  future: _event,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.network(snapshot.data!, fit: BoxFit.fill);
                    } else if (snapshot.hasError) {
                      return Text('Error loading image: ${snapshot.error}');
                    } else {
                      return CircularProgressIndicator();
                    }
                  },
                ),
              ),
            ),
            Container(
              height: 5,
            ),
            EventInfo(
              eventsData: widget.eventData, //attendOrHost: attendingHosting,
            ),
            Container(
              height: 80,
              child: Text(
                widget.eventData.description
              ),
            ),
          ],
        ),
      ),
    );
  }
}
