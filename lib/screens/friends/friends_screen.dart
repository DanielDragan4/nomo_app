import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/theme_provider.dart';
import 'package:nomo/screens/friends/groupchat_create_screen.dart';
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
  var currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    isSelected = [true, false, false];
    super.initState();
  }

  Widget _buildLoadingIndicator() {
    return Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    if (ref.read(profileProvider) != null) {
      currentUser = ref.read(profileProvider)!.username;
    }
    var themeMode = ref.watch(themeModeProvider);

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
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: widget.isGroupChats
                                ? MediaQuery.of(context).devicePixelRatio * 4
                                : MediaQuery.of(context).size.width / 18,
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
                        icon: themeMode == ThemeMode.dark
                            ? Image.asset('assets/icons/search-dark.png')
                            : Image.asset('assets/icons/search-light.png'),
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
                  if (!widget.isGroupChats)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            width: constraints.maxWidth,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: List.generate(3 * 2 - 1, (index) {
                                if (index.isOdd) {
                                  // This is a divider
                                  return Container(
                                    width: 1,
                                    height: 12,
                                    color: Theme.of(context).dividerColor,
                                  );
                                }
                                int buttonIndex = index ~/ 2;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        for (int i = 0; i < isSelected.length; i++) {
                                          isSelected[i] = i == buttonIndex;
                                        }
                                        _isLoading = true;
                                      });
                                      Future.microtask(() async {
                                        await Future.delayed(Duration(milliseconds: 300));
                                        if (mounted) {
                                          setState(() {
                                            _isLoading = false;
                                          });
                                        }
                                      });
                                    },
                                    child: Container(
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: isSelected[buttonIndex]
                                            ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          ['Friends', 'Requests', 'Groups'][buttonIndex],
                                          style: TextStyle(
                                            color: isSelected[buttonIndex]
                                                ? Colors.white
                                                : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                                            fontSize: MediaQuery.of(context).devicePixelRatio * 4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        },
                      ),
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
                  right: 10,
                  bottom: 10,
                  child: CircularIconButton(
                    icon: Icons.group_add,
                    onPressed: () {
                      if (isSelected.last) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Theme.of(context).cardColor,
                            title: Text(
                              'Create Group?',
                              style: TextStyle(
                                color: Theme.of(context).primaryColorLight,
                                fontSize: MediaQuery.of(context).size.width * 0.065,
                                fontWeight: FontWeight.w600,
                              ),
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
                                child: Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSecondary,
                                    fontSize: MediaQuery.of(context).size.width * 0.045,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
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

  final VoidCallback onPressed;

  const CircularIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
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
    ]);
  }
}
