import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/availability_screen.dart';
import 'package:nomo/screens/chat_screen.dart';

// Widget displaying group name and avatar in group chats list
//
// Parameters:
// - 'groupData': relevant data for each group widget, including name and image

class GroupTab extends ConsumerStatefulWidget {
  const GroupTab({
    super.key,
    required this.groupData,
  });

  final Map groupData;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FriendTabState();
}

class _FriendTabState extends ConsumerState<GroupTab> {
  List<String> users = [];
  void getUsersIds() async {
    users = await ref.read(chatsProvider.notifier).getGroupMemberIds(widget.groupData['group_id']);
  }

  @override
  void initState() {
    getUsersIds();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatScreen(
            currentUser: ref.read(profileProvider.notifier).state!.profile_id,
            groupInfo: widget.groupData,
          ),
        ));
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * .1,
                backgroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.groupData['title'],
                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      currentUser: ref.read(profileProvider.notifier).state!.profile_id,
                      groupInfo: widget.groupData,
                    ),
                  ));
                },
                icon: Icon(
                  Icons.messenger_outline,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              IconButton(
                onPressed: () async {
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (context) => AvailableTimesScreen(users: users)));
                },
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          )
        ]),
      ),
    );
  }
}
