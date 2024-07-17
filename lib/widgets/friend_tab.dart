import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/availability_screen.dart';
import 'package:nomo/screens/chat_screen.dart';
import 'package:nomo/screens/profile_screen.dart';

// Widget displaying friend name and avatar in friends and requests lists
//
// Parameters:
// - 'friendData': relevant data for each friend/request widget, including name and image
// - 'isRequest': if the widget represents an existing friend or a friend request
// - 'isSearch': if the widget is a search result
// - 'groupMemberToggle': a toggle that enables adding the user to a group
// - 'toggle': group toggle value
// - 'isEventAttendee': if the widget represents the attendee of an event

class FriendTab extends ConsumerStatefulWidget {
  const FriendTab({
    super.key,
    required this.friendData,
    required this.isRequest,
    this.isSearch,
    this.groupMemberToggle,
    required this.toggle,
    required this.isEventAttendee, // New optional parameter
  });

  final isRequest;
  final isSearch;
  final bool toggle;
  final void Function(bool, String)? groupMemberToggle;
  final Friend friendData;
  final bool isEventAttendee; // New field

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FriendTabState();
}

class _FriendTabState extends ConsumerState<FriendTab> {
  bool selectedUser = false;

  Future<String> getCurrentUser() async {
    return await ref.read(profileProvider.notifier).getCurrentUserId();
  }

  void navigateToProfile() async {
    String currentId = await getCurrentUser();
    Navigator.of(context).push(MaterialPageRoute(
      builder: ((context) => ProfileScreen(
            isUser: widget.friendData.friendProfileId != currentId ? false : true,
            userId: widget.friendData.friendProfileId,
          )),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.friendData.friendUsername;
    final avatar = widget.friendData.avatar;
    final currentUser = ref.read(profileProvider.notifier).state!.profile_id;
    final List<String> users = [currentUser, widget.friendData.friendProfileId];

    if (widget.isEventAttendee) {
      // Simplified view for event attendees
      return GestureDetector(
        onTap: navigateToProfile,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * .1,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
        ),
      );
    }

    // Original FriendTab layout
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: () async {
            String currentId = await getCurrentUser();
            Navigator.of(context).push(MaterialPageRoute(
                builder: ((context) => ProfileScreen(
                      isUser: widget.friendData.friendProfileId != currentId ? false : true,
                      userId: widget.friendData.friendProfileId,
                    ))));
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * .1,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (widget.isSearch == null)
          widget.toggle
              ? IconButton(
                  iconSize: 30.0,
                  padding: const EdgeInsets.only(left: 4, right: 4, top: 0),
                  icon: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: selectedUser == true
                          ? Icon(
                              Icons.circle,
                              color: Theme.of(context).colorScheme.onSecondary,
                            )
                          : Icon(
                              Icons.circle_outlined,
                              color: Theme.of(context).colorScheme.onSecondary,
                            )),
                  onPressed: () {
                    setState(() {
                      selectedUser = !selectedUser;
                    });
                    widget.groupMemberToggle!(selectedUser, widget.friendData.friendProfileId);
                  },
                )
              : widget.isRequest
                  ? Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            ref.read(profileProvider.notifier).decodeData();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatterUser: widget.friendData,
                                currentUser: ref.read(profileProvider.notifier).state!.profile_id,
                              ),
                            ));
                          },
                          icon: Icon(
                            Icons.messenger_outline,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => AvailableTimesScreen(
                                users: users,
                              ),
                            ));
                          },
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: Theme.of(context).colorScheme.onSecondary,
                          ),
                        )
                      ],
                    )
                  : Row(children: [
                      IconButton(
                          onPressed: () {
                            ref.read(profileProvider.notifier).addFriend(widget.friendData.friendProfileId, true);
                          },
                          icon: const Icon(
                            Icons.check,
                            color: Colors.green,
                          ),
                          splashRadius: 15),
                      const SizedBox(width: 10),
                      IconButton(
                          onPressed: () {
                            ref.read(profileProvider.notifier).removeRequest(widget.friendData.friendProfileId);
                          },
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                          ),
                          splashRadius: 15),
                    ]),
      ]),
    );
  }
}
