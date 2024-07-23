import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/notification-bell_provider.dart';
import 'package:nomo/providers/notification-provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/groupchat_create_screen.dart';
import 'package:nomo/screens/notifications_screen.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';
import 'package:nomo/widgets/group_tab.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, required this.isGroupChats});

  final bool isGroupChats;
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  var friends = true;
  late List<bool> isSelected;

  @override
  void initState() {
    isSelected = [true, false];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnreadNotifications = ref.watch(notificationBellProvider);
    //Start on friends list. If false, show requests list

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.isGroupChats ? 'Groups' : 'Friends',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    )),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ));

                    // Mark notifications as read when notifications icon is tapped
                    ref.read(notificationBellProvider.notifier).setBellState(false);
                    print('Bell state set to false after viewing notifications.');
                  },
                  icon: hasUnreadNotifications
                      ? Icon(
                          Icons.notifications_active,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.notifications_none,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                  iconSize: MediaQuery.of(context).devicePixelRatio * 10,
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15),
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
                      ToggleButtons(
                        constraints: const BoxConstraints(maxHeight: 250, minWidth: 150, maxWidth: 200),
                        borderColor: Colors.black,
                        fillColor: Theme.of(context).primaryColor,
                        borderWidth: 1,
                        selectedBorderColor: Colors.black,
                        selectedColor: Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                        onPressed: (int index) {
                          setState(() {
                            for (int i = 0; i < isSelected.length; i++) {
                              isSelected[i] = i == index;
                            }
                            friends = !friends;
                          });
                        },
                        isSelected: isSelected,
                        children: const [
                          Padding(
                              padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                              child: Text(
                                'Friends',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              )),
                          Padding(
                            padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                            child: Text(
                              'Requests',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
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
            Expanded(
                child: widget.isGroupChats
                    ? FutureBuilder(
                        future: ref.read(chatsProvider.notifier).getGroupChatInfo(),
                        builder: (context, snapshot) {
                          if (snapshot.data != null) {
                            return ListView(
                              children: [for (var groupChat in snapshot.data!) GroupTab(groupData: groupChat)],
                            );
                          }
                          return Text(
                            'Loading Groups',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                          );
                        },
                      )
                    : friends
                        ? StreamBuilder(
                            stream: ref.read(profileProvider.notifier).decodeFriends().asStream(),
                            builder: (context, snapshot) {
                              if (snapshot.data != null) {
                                return ListView(key: const PageStorageKey('page'), children: [
                                  for (Friend i in snapshot.data!)
                                    FriendTab(
                                      friendData: i,
                                      isRequest: true,
                                      toggle: false,
                                      isEventAttendee: false,
                                    ),
                                ]);
                              } else {
                                return Center(
                                  child: Text(
                                    'No Friends Were Found. Add Some',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                                  ),
                                );
                              }
                            })
                        : StreamBuilder(
                            stream: ref.read(profileProvider.notifier).decodeRequests().asStream(),
                            builder: (context, snapshot) {
                              print(snapshot.data);
                              if (snapshot.data != null) {
                                return ListView(
                                  key: const PageStorageKey('page'),
                                  children: [
                                    for (Friend i in snapshot.data!)
                                      FriendTab(
                                        friendData: i,
                                        isRequest: false,
                                        toggle: false,
                                        isEventAttendee: false,
                                      )
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
        Positioned(
          right: 16,
          bottom: widget.isGroupChats ? MediaQuery.of(context).padding.bottom + 34 : 16,
          child: CircularIconButton(
            icon: widget.isGroupChats ? Icons.group_add : Icons.groups,
            label: widget.isGroupChats ? 'Create\nGroup' : 'Groups',
            onPressed: () {
              if (widget.isGroupChats) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: Theme.of(context).colorScheme.onPrimary,
                    title: Text(
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
            color: Theme.of(context).colorScheme.onSecondary,
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
