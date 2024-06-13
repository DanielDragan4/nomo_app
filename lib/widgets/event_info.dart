import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:flutter_branch_sdk/flutter_branch_sdk.dart';
import 'package:share/share.dart';

enum options { itemOne, itemTwo, itemThree, itemFour, itemFive }

class EventInfo extends ConsumerStatefulWidget {
  EventInfo({super.key, required this.eventsData, this.bookmarkSet});
  final Event eventsData;
  bool? bookmarkSet;

  @override
  ConsumerState<EventInfo> createState() {
    return _EventInfoState();
  }
}

class _EventInfoState extends ConsumerState<EventInfo> {
  Future<String?> generateBranchLink() async {
    try {
      // Create Branch Universal Object
      BranchUniversalObject buo = BranchUniversalObject(
          canonicalIdentifier: 'event/${widget.eventsData.eventId}',
          title: widget.eventsData.title,
          imageUrl: widget.eventsData.imageUrl,
          contentDescription: widget.eventsData.description,
          keywords: [],
          publiclyIndex: true,
          locallyIndex: true,
          contentMetadata: BranchContentMetaData()
            ..addCustomMetadata("event_id", widget.eventsData.eventId));

      // Create Branch Link Properties
      BranchLinkProperties lp = BranchLinkProperties(
        channel: 'app',
        feature: 'sharing',
        campaign: 'event_share',
        stage: 'user_share',
      )
        ..addControlParam('\$fallback_url', 'https://example.com')
        ..addControlParam('\$ios_url', 'https://apps.apple.com/app/id123456789')
        ..addControlParam('\$android_url',
            'https://play.google.com/store/apps/details?id=com.example.nomoapp');

      // Generate the deep link
      BranchResponse response =
          await FlutterBranchSdk.getShortUrl(buo: buo, linkProperties: lp);
      if (response.success) {
        return response.result;
      } else {
        print('Error generating Branch link: ${response.errorMessage}');
        return null;
      }
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<void> _shareEventLink() async {
    final link = await generateBranchLink();
    if (link != null) {
      Share.share(
        'Check out this event: $link',
        subject: 'Event Link',
      );
    } else {
      print('Error: Unable to generate Branch link');
    }
  }

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
                          var attendee = widget.eventsData.attendees[i];
                          if (attendee is Map &&
                              attendee['user_id'] == currentUser) {
                            joinOrLeave = true;
                            break;
                          }
                        }
                        // for (var i = 0;
                        //     i < widget.eventsData.attendees.length;
                        //     i++) {
                        //   if (((widget.eventsData.attendees[i] != null) &&
                        //       (widget.eventsData.attendees[i] ==
                        //           currentUser))) {
                        //     if (((widget.eventsData.attendees[i]['user_id'] !=
                        //             null) &&
                        //         (widget.eventsData.attendees[i]['user_id'] ==
                        //             currentUser))) {
                        //       joinOrLeave = true;
                        //       break;
                        //     }
                        //   }
                        // }
                        if (!joinOrLeave) {
                          text = 'Join';
                          return ElevatedButton(
                            onPressed: () {
                              ref
                                  .read(profileProvider.notifier)
                                  .createBlockedTime(
                                      currentUser,
                                      widget.eventsData.sdate,
                                      widget.eventsData.edate,
                                      widget.eventsData.title,
                                      widget.eventsData.eventId);
                              attendeeJoinEvent();
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Joined ${widget.eventsData.title}")));
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
                                            style: TextStyle(
                                                color: Theme.of(context)
                                                    .primaryColorDark),
                                          ),
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
                                                                    .eventsData,
                                                                isEdit: true,
                                                              ))))
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
                                                    ref
                                                        .read(profileProvider
                                                            .notifier)
                                                        .deleteBlockedTime(
                                                            null,
                                                            widget.eventsData
                                                                .eventId);
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
                        if (bookmarkBool) {
                          deBookmarkEvent();
                        } else if (!bookmarkBool) {
                          bookmarkEvent();
                        }
                        bookmarkBool = !bookmarkBool;
                      });
                    },
                    isSelected: bookmarkBool,
                    selectedIcon: Icon(Icons.bookmark,
                        color: Theme.of(context).colorScheme.onSecondary),
                    icon: Icon(Icons.bookmark_border_outlined,
                        color: Theme.of(context).colorScheme.onSecondary)),
              ],
            ),
          ),
          PopupMenuButton<options>(
            iconColor: Theme.of(context).colorScheme.onSecondary,
            onSelected: (options item) {
              setState(
                () {
                  selectedOption = item;
                  if (item == options.itemThree) {
                    _shareEventLink();
                  }
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
