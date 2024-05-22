import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/comments_model.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/comment_widget.dart';
import 'package:nomo/widgets/comments_section_widget.dart';
import 'package:nomo/widgets/event_info.dart';

class DetailedEventScreen extends ConsumerStatefulWidget {
  const DetailedEventScreen({
    super.key,
    required this.eventData,
  });

  final Event eventData;

  @override
  ConsumerState<DetailedEventScreen> createState() {
    return _DetailedEventScreenState();
  }
}

class _DetailedEventScreenState extends ConsumerState<DetailedEventScreen> {

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

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        title: Center(
          child: Column(
            children: [
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(widget.eventData.title,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(2.0),
              child: Container(
                  child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                            radius: MediaQuery.sizeOf(context).width / 24,
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
                    SizedBox(width: MediaQuery.sizeOf(context).width / 150),
                    Text(
                      widget.eventData.hostUsername,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * .047),
                    )
                  ],
                ),
              ),
              SizedBox(width: MediaQuery.sizeOf(context).width / 2.75),
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
                Container(
                  height: 5,
                ),
                EventInfo(eventsData: widget.eventData),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 20,
                  child: Text(widget.eventData.description),
                ),
                Text('Comments',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    )),
                const Divider(),
                CommentsSection(eventId: widget.eventData.eventId)
              ])))
        ]),
      ),
    );
  }
}
