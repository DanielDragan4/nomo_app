import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/new_event_screen.dart';

enum options { itemOne, itemTwo, itemThree, itemFour }

class EventInfo extends ConsumerStatefulWidget {
  EventInfo({
    super.key,
    required this.eventsData,
    this.bookmarkSet
  });
  final Event eventsData;
  bool? bookmarkSet;

  @override
  ConsumerState<EventInfo> createState() {
    return _EventInfoState();
  }
}

class _EventInfoState extends ConsumerState<EventInfo> {
  Future<void> attendeeJoinEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .joinEvent(supabase.auth.currentUser!.id, widget.eventsData.eventId);
  }

  Future<void> attendeeLeaveEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(attendEventsProvider.notifier)
        .leaveEvent(widget.eventsData.eventId, supabase.auth.currentUser!.id);
  }
  
  Future<void> bookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .bookmark(widget.eventsData.eventId, supabase.auth.currentUser!.id);
  }

  Future<void> deBookmarkEvent() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .unBookmark(widget.eventsData.eventId, supabase.auth.currentUser!.id);
  }
  late bool bookmarkBool;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setState(() {
        bookmarkBool = widget.eventsData.bookmarked;
    });
  }
  @override
  Widget build(BuildContext context) {
    options? selectedOption;
    String text = 'Join';
    

    //isAttending();

    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
              // crossAxisAlignment: CrossAxisAlignment.start,
              // children: [
              //   Text("${widget.eventsData.attendies} Attending"),
              //   Text("${widget.eventsData.friends.length} Friends Attending"),
              // ],
              ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.eventsData.attendees.length.toString()} Attending',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * .037,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                    Text(
                      'XXX Friends Attending',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: MediaQuery.of(context).size.width * .037,
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ],
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width / 9,
                ),
                FutureBuilder(
                  future: ref.read(supabaseInstance),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data != null) {
                        bool joinOrLeave = false;
                        final supabase = snapshot.data!.client;
                        final currentUser = supabase.auth.currentUser!.id;

                        if (widget.eventsData.host == currentUser) {
                          joinOrLeave = true;
                        }

                        for (var i = 0;
                            i < widget.eventsData.attendees.length;
                            i++) {
                          if (widget.eventsData.attendees[i]['user_id'] ==
                              currentUser) {
                            joinOrLeave = true;
                            break;
                          }
                        }
                        if (!joinOrLeave) {
                          text = 'Join';
                          return ElevatedButton(
                            onPressed: () {
                              attendeeJoinEvent();
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Theme.of(context).primaryColor),
                              foregroundColor: MaterialStateProperty.all<Color>(
                                  Theme.of(context).primaryColorLight),
                            ),
                            child: Text(text),
                          );
                        } else if (joinOrLeave) {
                          if (widget.eventsData.host == currentUser) {
                            text = 'Edit';
                            return ElevatedButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          title: Text(
                                              'Are you sure you want to edit the event?',
                                              style: TextStyle(color: Theme.of(context).primaryColorDark),),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('CANCEL')),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .push(MaterialPageRoute(
                                                          builder: ((context) =>
                                                              NewEventScreen(
                                                                  isNewEvent:
                                                                      false,
                                                                  event: widget
                                                                      .eventsData))))
                                                      .then((result) =>
                                                          Navigator.pop(
                                                              context));
                                                },
                                                child: const Text('YES')),
                                          ],
                                        ));
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColor),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColorLight),
                              ),
                              child: Text(text),
                            );
                          } else {
                            text = 'Leave';
                            return ElevatedButton(
                              onPressed: () {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                          title: const Text(
                                              'Are you sure you want to leave the event?'),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('CANCEL')),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    attendeeLeaveEvent();
                                                  });

                                                  Navigator.pop(context);
                                                },
                                                child: const Text('YES')),
                                          ],
                                        ));
                              },
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColor),
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Theme.of(context).primaryColorLight),
                              ),
                              child: Text(text),
                            );
                          }
                        }
                      }
                    }
                    return ElevatedButton(
                      onPressed: () {},
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).primaryColor),
                        foregroundColor: MaterialStateProperty.all<Color>(
                            Theme.of(context).primaryColorLight),
                      ),
                      child: const Text('test'),
                    );
                  }),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                         if(bookmarkBool) {
                          deBookmarkEvent();
                        } else if(!bookmarkBool) {
                          bookmarkEvent();
                        }
                        bookmarkBool = !bookmarkBool;
                      }
                      );
                    },
                    isSelected: bookmarkBool,
                    selectedIcon:  Icon(Icons.bookmark, color: Theme.of(context).colorScheme.onSecondary),
                    icon:  Icon(Icons.bookmark_border_outlined, color: Theme.of(context).colorScheme.onSecondary)),
              ],
            ),
          ),
          PopupMenuButton<options>(
            onSelected: (options item) {
              setState(
                () {
                  selectedOption = item;
                },
              );
            },
            itemBuilder: (context) => <PopupMenuEntry<options>>[
              const PopupMenuItem(
                value: options.itemOne,
                child: Text("Edit Event"),
              ),
              const PopupMenuItem(
                value: options.itemTwo,
                child: Text("Send Invites"),
              ),
              const PopupMenuItem(
                value: options.itemThree,
                child: Text("Share Link"),
              ),
              const PopupMenuItem(
                value: options.itemFour,
                child: Text("View Details"),
              ),
            ],
          )
        ],
      ),
    );
  }
}
