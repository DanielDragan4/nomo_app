import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/notification-providers/notification-bell-provider.dart';
import 'package:nomo/providers/notification-providers/notification-provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/friends/groupchat_create_screen.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:nomo/widgets/group_tab.dart';
import 'package:nomo/widgets/toggle_buttons.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, required this.isGroupChats});

  final bool isGroupChats;
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  var friends = true;
  late List<bool> isSelected;
  var currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    isSelected = [true, false, false];
    super.initState();
    if (ref.read(profileProvider) != null) {
      setState(() {});
      {
        currentUser = ref.read(profileProvider)!.username;
      }
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    return (currentUser != null)
        ? Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: PreferredSize(
                preferredSize: const Size.fromHeight(10),
                child: Container(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: widget.isGroupChats ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.isGroupChats ? 'Groups' : '@${currentUser}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w800,
                            fontSize: widget.isGroupChats ? 25 : 20,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SearchScreen(
                                searchingPeople: true,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(4.0),
                child: Container(
                  color: const Color.fromARGB(255, 69, 69, 69),
                  height: 1.0,
                ),
              ),
            ),
            body: Stack(children: [
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: widget.isGroupChats
                        ? []
                        : [
                            TabStyleToggleButtons(
                              options: const [
                                ToggleOption(label: 'Friends', icon: Icons.people),
                                ToggleOption(label: 'Requests', icon: Icons.person_add),
                                ToggleOption(label: 'Groups', icon: Icons.groups),
                              ],
                              textColor: Theme.of(context).colorScheme.onSecondary.withOpacity(0.75),
                              isSelected: isSelected,
                              onPressed: (index) {
                                setState(() {
                                  for (int i = 0; i < isSelected.length; i++) {
                                    isSelected[i] = i == index;
                                  }
                                  _isLoading = true; // Set loading state to true
                                });
                                // Use a microtask to allow the UI to update before fetching data
                                Future.microtask(() async {
                                  // Simulate a short delay for the loading indicator to be visible
                                  await Future.delayed(Duration(milliseconds: 300));
                                  if (mounted) {
                                    setState(() {
                                      _isLoading = false; // Set loading state back to false
                                    });
                                  }
                                });
                              },
                            ),
                          ],
                  ),
                  Expanded(
                      child: _isLoading
                          ? _buildLoadingIndicator()
                          : isSelected.first
                              ? StreamBuilder(
                                  stream: ref.read(profileProvider.notifier).decodeFriends().asStream(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return _buildLoadingIndicator();
                                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      return ListView(
                                        key: const PageStorageKey('page'),
                                        children: [
                                          for (Friend i in snapshot.data!)
                                            FriendTab(
                                              friendData: i,
                                              isRequest: true,
                                              toggle: false,
                                              isEventAttendee: false,
                                            ),
                                        ],
                                      );
                                    } else {
                                      return Center(
                                        child: Text(
                                          'No Friends Were Found. Add Some',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                                        ),
                                      );
                                    }
                                  })
                              : isSelected.last
                                  ? FutureBuilder(
                                      future: ref.read(chatsProvider.notifier).getGroupChatInfo(),
                                      builder: (context, snapshot) {
                                        if (snapshot.data != null) {
                                          return ListView(
                                            children: [
                                              for (var groupChat in snapshot.data!) GroupTab(groupData: groupChat)
                                            ],
                                          );
                                        }
                                        return Text(
                                          'Loading Groups',
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                                        );
                                      },
                                    )
                                  : StreamBuilder(
                                      stream: ref.read(profileProvider.notifier).decodeRequests().asStream(),
                                      builder: (context, snapshot) {
                                        print(snapshot.data);
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return _buildLoadingIndicator();
                                        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                          return ListView(
                                            key: const PageStorageKey('page'),
                                            children: [
                                              for (Friend i in snapshot.data!)
                                                FriendTab(
                                                  friendData: i,
                                                  isRequest: false,
                                                  toggle: false,
                                                  isEventAttendee: false,
                                                ),
                                            ],
                                          );
                                        } else {
                                          return Center(
                                            child: Text(
                                              'No New Friends Were Found. Add Some',
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                                            ),
                                          );
                                        }
                                      })),
                ],
              ),
              if (isSelected.last)
                Positioned(
                  right: 20,
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                  child: CircularIconButton(
                    icon: Icons.group_add,
                    label: 'Create\nGroup',
                    onPressed: () {
                      if (isSelected.last) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).colorScheme.onPrimary,
                            title: const Text(
                              'Create Group?',
                              style: TextStyle(color: Colors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => const NewGroupChatScreen(),
                                        ),
                                      )
                                      .then((result) => Navigator.pop(context));
                                },
                                child: const Text('Continue'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              )
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendsScreen(isGroupChats: true),
                          ),
                        );
                      }
                    },
                  ),
                ),
            ]),
          )
        : Scaffold(
            body: CircularProgressIndicator(),
          );
  }
}

//Class for the group icons styling
class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const CircularIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).primaryColor,
          ),
          child: IconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            color: Theme.of(context).colorScheme.onPrimary,
            iconSize: MediaQuery.of(context).size.aspectRatio * 90,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSecondary,
          ),
        ),
      ],
    );
  }
}
