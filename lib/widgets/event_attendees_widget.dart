import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/widgets/friend_tab.dart';

class AttendeesSection extends ConsumerStatefulWidget {
  const AttendeesSection(
      {super.key, required this.eventId, required this.areFriends});

  final eventId;
  final bool areFriends;

  @override
  ConsumerState<AttendeesSection> createState() => _AttendeesSectionState();
}

class _AttendeesSectionState extends ConsumerState<AttendeesSection> {
  List<Friend> attendeesList = [];

  @override
  void initState() {
    super.initState();
    receiveComments();
  }

  Future<void> receiveComments() async {
    if (widget.areFriends) {
      var readEventAttendees = await ref
          .read(eventsProvider.notifier)
          .getEventFriends(widget.eventId);
      setState(() {
        attendeesList = readEventAttendees;
      });
    } else {
      var readEventAttendees = await ref
          .read(eventsProvider.notifier)
          .getEventAttendees(widget.eventId);
      setState(() {
        attendeesList = readEventAttendees;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        attendeesList.isNotEmpty
            ? SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: ListView.builder(
                  itemCount: attendeesList.length,
                  itemBuilder: (context, index) => FriendTab(
                    friendData: attendeesList[index],
                    toggle: false,
                    isEventAttendee: true,
                    isRequest: false,
                  ),
                ),
              )
            : Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(MediaQuery.of(context).size.height * 0.02),
                  child: widget.areFriends
                      ? Text(
                          "No Friends Attending This Event",
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary
                                .withOpacity(0.6),
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        )
                      : Text(
                          "No Attendees In This Event",
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSecondary
                                .withOpacity(0.6),
                            fontSize: MediaQuery.of(context).size.width * 0.04,
                          ),
                        ),
                ),
              ),
      ],
    );
  }
}
