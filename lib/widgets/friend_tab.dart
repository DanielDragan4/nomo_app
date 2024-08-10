import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/notification-providers/friend-notif-manager.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/friends/availability_screen.dart';
import 'package:nomo/screens/friends/chat_screen.dart';
import 'package:nomo/screens/profile/profile_screen.dart';

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
  FriendTab({
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
  bool isFriend = false;
  bool isPending = false;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FriendTabState();
}

class _FriendTabState extends ConsumerState<FriendTab> {
  bool currentFriend = true; // if the request is current and hasnt been interacted with
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

  Future<void> checkPendingRequest() async {
    final requests = await ref.read(profileProvider.notifier).readOutgoingRequests();
    final currentUserId = (await ref.read(supabaseInstance)).client.auth.currentUser!.id;
    setState(() {
      widget.isPending = requests.any((request) =>
              (request['sender_id'] == currentUserId && request['reciever_id'] == widget.friendData.friendProfileId)
          //     ||
          // (request['reciever_id'] == currentUserId &&
          //     request['sender_id'] == widget.userId)
          );
    });
  }

  Future<void> addFriend() async {
    await ref.read(profileProvider.notifier).addFriend(widget.friendData.friendProfileId, false);
    await checkPendingRequest();
  }

  Future<void> removeFriend() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(profileProvider.notifier)
        .removeFriend(supabase.auth.currentUser!.id, widget.friendData.friendProfileId);
  }

  Future<void> getFriend() async {
    var friend = await ref.read(profileProvider.notifier).isFriend(widget.friendData.friendProfileId);

    setState(() {
      widget.isFriend = friend;
    });
  }

  @override
  void initState() {
    super.initState();
    getFriend();
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.friendData.friendUsername;
    final avatar = widget.friendData.avatar;
    final currentUser = ref.read(profileProvider.notifier).state!.profile_id;
    final List<String> users = [currentUser, widget.friendData.friendProfileId];
    final hasNewMessage = ref.watch(friendNotificationProvider)[widget.friendData.friendProfileId] ?? false;

    Widget buildRightSideWidgets() {
      if (widget.isSearch == null) {
        if (widget.toggle) {
          return IconButton(
            iconSize: 30.0,
            padding: const EdgeInsets.only(left: 4, right: 4, top: 0),
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                selectedUser ? Icons.circle : Icons.circle_outlined,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
            onPressed: () {
              setState(() {
                selectedUser = !selectedUser;
              });
              widget.groupMemberToggle!(selectedUser, widget.friendData.friendProfileId);
            },
          );
        } else if (widget.isRequest) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () async {
                      ref.read(profileProvider.notifier).decodeData();
                      ref
                          .read(friendNotificationProvider.notifier)
                          .resetNotification(widget.friendData.friendProfileId);
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
                  if (hasNewMessage)
                    Positioned(
                      right: 7,
                      top: 7,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
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
          );
        } else {
          return Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
                onPressed: () async {
                  String friendId =
                      await ref.read(profileProvider.notifier).addFriend(widget.friendData.friendProfileId, true);
                  await FriendNotificationManager.handleAddFriend(ref, friendId);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Added $username to friends list')));
                  setState(() {
                    currentFriend = false;
                  });
                },
                icon: const Icon(
                  Icons.check,
                  color: Colors.green,
                ),
                splashRadius: 15),
            const SizedBox(width: 10),
            IconButton(
                onPressed: () async {
                  String friendId =
                      await ref.read(profileProvider.notifier).removeRequest(widget.friendData.friendProfileId);
                  await FriendNotificationManager.handleRemoveFriend(ref, friendId);
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text("Rejected $username's friend request")));
                  setState(() {
                    currentFriend = false;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                ),
                splashRadius: 15),
          ]);
        }
      }
      return SizedBox.shrink();
    }

    if (widget.isEventAttendee) {
      // Simplified view for event attendees
      return GestureDetector(
        onTap: navigateToProfile,
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
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
              )),
              (currentUser != widget.friendData.friendProfileId)
                  ? Container(
                      child: widget.isFriend //If profile is private, make this a request instead of instant
                          ? ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                            title: Text(
                                              'Are you sure you unfriend this user?',
                                              style: TextStyle(color: Theme.of(context).primaryColorDark),
                                            ),
                                            actions: [
                                              TextButton(
                                                  onPressed: () async {
                                                    removeFriend();
                                                    widget.isFriend = !widget.isFriend;
                                                    Navigator.pop(context);
                                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(
                                                        content: Text("Event Deleted"),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text('YES')),
                                              TextButton(
                                                  onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                                            ],
                                          ));
                                });
                              },
                              child: const Text("Unfriend"),
                            )
                          : ElevatedButton(
                              onPressed: widget.isPending
                                  ? null
                                  : () {
                                      setState(() {
                                        addFriend();
                                      });
                                    },
                              child: widget.isPending ? const Text("Pending") : const Text("Friend")),
                    )
                  : SizedBox()
            ],
          ),
        ),
      );
    }

    // Original FriendTab layout
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: MediaQuery.of(context).size.width * .1,
                  backgroundImage: NetworkImage(avatar),
                ),
                const SizedBox(width: 10),
                Flexible(
                  fit: FlexFit.tight,
                  child: Text(
                    username,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 100, // Adjust this width as needed
            child: buildRightSideWidgets(),
          ),
        ],
      ),
    );
  }
}
