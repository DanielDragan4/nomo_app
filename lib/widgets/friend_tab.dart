import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/availability_screen.dart';
import 'package:nomo/screens/chat_screen.dart';
import 'package:nomo/screens/profile_screen.dart';

class FriendTab extends ConsumerStatefulWidget {
  const FriendTab({
    super.key,
    required this.friendData,
    required this.isRequest,
    this.isSearch,
    this.groupMemberToggle,
    required this.toggle,
    this.isEventAttendee = false, // New optional parameter
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: navigateToProfile,
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
          // ... Rest of the original code for buttons and actions ...
          // (This part remains unchanged)
        ],
      ),
    );
  }
}