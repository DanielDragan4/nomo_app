import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:nomo/screens/setting_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum options { itemOne, itemTwo, itemThree, itemFour }

class EventInfo extends ConsumerStatefulWidget {
  EventInfo({super.key, required this.eventsData,});
  final Event eventsData;

  @override
  ConsumerState<EventInfo> createState() {
    return _EventInfoState();
  }
}

class _EventInfoState extends ConsumerState<EventInfo> {
  Future<void> attendeeJoinEvent() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    await ref
        .read(eventsProvider.notifier)
        .joinEvent(supabase.auth.currentUser!.id, widget.eventsData.eventId);
  }

  Future<void> attendeeLeaveEvent() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    await ref
        .read(attendEventsProvider.notifier)
        .leaveEvent(supabase.auth.currentUser!.id, widget.eventsData.eventId);
  }

  @override
  Widget build(BuildContext context) {
    options? selectedOption;
    String text = 'Join';
    //isAttending();

    return Padding(
      padding: const EdgeInsets.all(5.0),
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
                FutureBuilder(
                  future: ref.read(supabaseInstance),
                  builder: ((context, snapshot) {
                    if (snapshot.hasData) {
                      if(snapshot.data != null) {
                      bool joinOrLeave = false;
                      final supabase = snapshot.data!.client;
                      final currentUser = supabase.auth.currentUser!.id;

                      if(widget.eventsData.host == currentUser) {
                        joinOrLeave = true;
                      }

                      for (var i = 0; i < widget.eventsData.attendees.length; i++) {
                        if (widget.eventsData.attendees[i]['user_id'] == currentUser) {
                          joinOrLeave = true;
                          break;
                        }
                      }
                      if (!joinOrLeave) {
                        text = 'Join';
                        return ElevatedButton(
                          onPressed: (){
                            attendeeJoinEvent();
                            ref.read(eventsProvider.notifier).deCodeData();
                            },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColor),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColorLight),
                          ),
                          child: Text(text),
                        );
                      } else if(joinOrLeave){
                        if(widget.eventsData.host == currentUser) {
                          text = 'Edit';
                          return ElevatedButton(
                          onPressed: (){
                            showDialog(
                              context: context, 
                              builder: (context) =>
                                AlertDialog(
                                  title: const Text('Are you sure you want to edit the event?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                                    TextButton(onPressed: (){
                                        Navigator.of(context).push(MaterialPageRoute(builder: ((context) => NewEventScreen()))).then((result) => Navigator.pop(context));
                                      }, 
                                      child: const Text('YES')
                                      ),
                                  ],
                                )
                              );
                            },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColor),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColorLight),
                          ),
                          child: Text(text),
                        );
                        }
                        else {
                        text = 'Leave';
                        return ElevatedButton(
                          onPressed: (){
                            showDialog(
                              context: context, 
                              builder: (context) =>
                                AlertDialog(
                                  title: const Text('Are you sure you want to leave the event?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                                    TextButton(onPressed: (){
                                      setState(() {
                                        attendeeLeaveEvent();
                                      });
                                      
                                      Navigator.pop(context);
                                      }, 
                                      child: const Text('YES')
                                      ),
                                  ],
                                )
                              );
                            },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColor),
                            foregroundColor: MaterialStateProperty.all<Color>(
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
                  }
                  ),
                ),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border_outlined)),
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
