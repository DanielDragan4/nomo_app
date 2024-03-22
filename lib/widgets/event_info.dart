import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';

enum options { itemOne, itemTwo, itemThree, itemFour }

class EventInfo extends ConsumerStatefulWidget {
  const EventInfo({super.key, required this.eventsData});
  final Event eventsData;

  @override
  ConsumerState<EventInfo> createState() {
    return _EventInfoState();
  }
}

class _EventInfoState extends ConsumerState<EventInfo> {
  bool joinOrLeave = true;

  Future<void> attendeeJoinEvent() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    await ref
        .watch(eventsProvider.notifier)
        .joinEvent(supabase.auth.currentUser!.id, widget.eventsData.eventId);
  }

  Future<void> isAttending() async {
    final supabase = (await ref.watch(supabaseInstance)).client;
    final attendee = await supabase
        .from('Attendees')
        .select()
        .eq(
          'event_id',
          widget.eventsData.eventId,
        )
        .eq('user_id', supabase.auth.currentUser!.id);
    joinOrLeave = attendee.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    options? selectedOption;
    isAttending();

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
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
                //(ref.read(eventsProvider.notifier).hasJoined(widget.eventsData.eventId))
                FutureBuilder(
                  future: (ref
                      .read(eventsProvider.notifier)
                      .hasJoined(widget.eventsData.eventId)),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!) {
                        return ElevatedButton(
                          onPressed: attendeeJoinEvent,
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColor),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColorLight),
                          ),
                          child: const Text('Join'),
                        );
                      } else {
                        return ElevatedButton(
                          onPressed: () {},
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColor),
                            foregroundColor: MaterialStateProperty.all<Color>(
                                Theme.of(context).primaryColorLight),
                          ),
                          child: const Text('Leave'),
                        );
                      }
                    } else {
                      return ElevatedButton(
                        onPressed: () {},
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Theme.of(context).primaryColor),
                          foregroundColor: MaterialStateProperty.all<Color>(
                              Theme.of(context).primaryColorLight),
                        ),
                        child: const Text('Join'),
                      );
                    }
                  },
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
