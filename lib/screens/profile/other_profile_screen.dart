import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/functions/image-handling.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/event-providers/other_attending_profile.dart';
import 'package:nomo/providers/notification-providers/friend-notif-manager.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/friends/chat_screen.dart';
import 'package:nomo/widgets/event_tab.dart';

class OtherProfileScreen extends ConsumerStatefulWidget {
  OtherProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<OtherProfileScreen> createState() {
    return ProfileScreenState();
  }
}

class ProfileScreenState extends ConsumerState<OtherProfileScreen> {
  Future<Profile>? profileInfo;
  UniqueKey _futureBuilderKey = UniqueKey();
  final TextEditingController searchController = TextEditingController();
  bool? private;
  List<bool> isSelected = [true, false];
  late bool isFriend = true;
  bool _isLoading = true;
  bool showUpcoming = true;
  bool showPassed = false;
  bool showHosting = true;
  bool friendPending = false;
  var profile;

// Initializes appropriate user data, depending on if viewing own profile or someone else's
  @override
  void initState() {
    super.initState();
    _fetchData();

    ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
    checkPendingRequest();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

// Called from Event Tab to refresh data when leaving anothe profile view
  void refreshData() async {
    if (mounted) {
      setState(() {
        _fetchData();
        _futureBuilderKey = UniqueKey();
      });
    }

    ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
  }

// Loads profile info and event info
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchProfileInfo();
    await _fetchEvents();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Gets all relevant profile information for profile being viewed
  Future<void> _fetchProfileInfo() async {
    final newProfileInfo = await fetchInfo(widget.userId);
    setState(() {
      profileInfo = Future.value(newProfileInfo);
    });
  }

// Gets all relevant event/attendance information for profile being viewed
  Future<void> _fetchEvents() async {
    ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
  }

// Returns relevant profile information to _fetchProfileInfo, or sets default values to avoid error
  Future<Profile> fetchInfo(String userId) async {
    await Future.delayed(const Duration(microseconds: 1));
    Profile profileState;

    profileState = await ref.read(profileProvider.notifier).fetchProfileById(userId);
    isFriend = await ref.read(profileProvider.notifier).isFriend(userId);
    private = profileState.private;
    return profileState;
  }

// Updates profile information after editing profile. Called from Create Account Screen when popping
  void updateProfileInfo() {
    if (mounted) {
      setState(() {
        _fetchData();
        _futureBuilderKey = UniqueKey();
      });
    }
  }

  Future<void> addFriend() async {
    String friendId = await ref.read(profileProvider.notifier).addFriend(widget.userId, false);
    await FriendNotificationManager.handleAddFriend(ref, friendId);
    await checkPendingRequest();
  }

// Checks if a friend request is pending with the viewed account
  Future<void> checkPendingRequest() async {
    final requests = await ref.read(profileProvider.notifier).readOutgoingRequests();
    final currentUserId = (await ref.read(supabaseInstance)).client.auth.currentUser!.id;
    setState(() {
      friendPending =
          requests.any((request) => (request['sender_id'] == currentUserId && request['reciever_id'] == widget.userId)
              //     ||
              // (request['reciever_id'] == currentUserId &&
              //     request['sender_id'] == widget.userId)
              );
    });
  }

  Future<void> removeFriend() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    String friendId =
        await ref.read(profileProvider.notifier).removeFriend(supabase.auth.currentUser!.id, widget.userId);
    await FriendNotificationManager.handleRemoveFriend(ref, friendId);
  }

  void refreshEvents() {
    if (mounted) {
      setState(() {
        _fetchEvents();
        _futureBuilderKey = UniqueKey();
      });
    }
  }

  Widget _buildProfileHeader(Profile profile) {
    return Padding(
      padding: EdgeInsets.only(
        left: MediaQuery.of(context).size.width / 12,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: MediaQuery.of(context).size.width / 12,
            backgroundImage: profile.avatar != null ? NetworkImage(profile.avatar!) : null,
            child: profile.avatar == null ? Icon(Icons.person, size: 40) : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.profile_name ?? 'Loading...',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                Text(
                  '@${profile.username ?? 'username'}',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 24,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double calculateAppBarHeight(BuildContext context) {
    double appBarHeight = MediaQuery.of(context).padding.top +
        MediaQuery.of(context).size.height / 60 +
        kToolbarHeight +
        10; // Top padding + toolbar height

    // Profile header
    appBarHeight += MediaQuery.of(context).size.width / 6; // Avatar height
    appBarHeight += 16; // Padding around header (vertical)

    // Upcoming events column height
    appBarHeight += MediaQuery.of(context).size.width / 20 + MediaQuery.of(context).size.width / 24;

    // Toggle buttons
    appBarHeight += 40 + 24;

    // Extra padding
    //appBarHeight += 20;

    return appBarHeight;
  }

  @override
  Widget build(BuildContext context) {
    // Listen to changes in the profileProvider
    ref.listen<Profile?>(profileProvider, (previous, next) {
      if (next != null && next != profile) {
        setState(() {
          profile = next;
        });
      }
    });

    // If it's the user's own profile, decode the data
    // if (widget.isUser) {
    //   //ref.read(profileProvider.notifier).decodeData();
    //   ref.read(attendEventsProvider.notifier).deCodeData();
    //   profile = ref.watch(profileProvider);
    // } else {
    //   // For other users, use the profileInfo
    //   profile = ref.watch(profileProvider.select((value) => value));
    // }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: kToolbarHeight + 50,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    expandedHeight: calculateAppBarHeight(context),
                    floating: false,
                    pinned: false,
                    snap: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + MediaQuery.of(context).size.height / 60),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).primaryColor,
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            FutureBuilder<Profile>(
                              key: _futureBuilderKey,
                              future: profileInfo,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: _buildProfileHeader(snapshot.data!),
                                  );
                                } else {
                                  return CircularProgressIndicator();
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    StreamBuilder<List<Event>>(
                                      stream: ref.read(otherEventsProvider.notifier).stream,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final events = snapshot.data!;
                                          final now = DateTime.now();
                                          int upcomingEventCount = events.where((event) {
                                            final eventStartDate = DateTime.parse(event.attendeeDates['time_start']);
                                            final isUpcoming = eventStartDate.isAfter(now);

                                            return isUpcoming;
                                          }).length;

                                          return Column(
                                            children: [
                                              Text(
                                                upcomingEventCount.toString(),
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                              Text(
                                                "Upcoming Events",
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 24,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          return Column(
                                            children: [
                                              Text(
                                                '0',
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                              Text(
                                                "Upcoming Events",
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 24,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      isFriend
                                          ? ElevatedButton(
                                              onPressed: () {
                                                // Unfriend functionality
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: Text('Are you sure you want to unfriend this user?'),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          await removeFriend();
                                                          Navigator.pop(context);
                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                            SnackBar(content: Text("User unfriended")),
                                                          );
                                                        },
                                                        child: Text('Unfriend'),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => Navigator.pop(context),
                                                        child: Text('Cancel'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Text("Unfriend"),
                                            )
                                          : ElevatedButton(
                                              onPressed: friendPending ? null : addFriend,
                                              child: Text(friendPending
                                                  ? "Pending"
                                                  : (private == false ? "Friend" : "Request Friend")),
                                            ),
                                      SizedBox(width: MediaQuery.of(context).size.width / 20),
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          color: Theme.of(context).primaryColor,
                                        ),
                                        child: IconButton(
                                          onPressed: () async {
                                            Friend friend = Friend(
                                                avatar: (await profileInfo)?.avatar,
                                                friendProfileId: widget.userId!,
                                                friendProfileName: (await profileInfo)!.profile_name,
                                                friendUsername: (await profileInfo)!.username);
                                            Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
                                                builder: (context) => ChatScreen(
                                                      chatterUser: friend,
                                                      currentUser: ref.read(profileProvider.notifier).state!.profile_id,
                                                    )));
                                          },
                                          icon: const Icon(Icons.message),
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Container(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: List.generate(2 * 2 - 1, (index) {
                                      if (index.isOdd) {
                                        return Container(
                                          width: 1,
                                          height: 20,
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
                                            });
                                          },
                                          child: Container(
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isSelected[buttonIndex]
                                                  ? Theme.of(context).primaryColorLight
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Center(
                                              child: Text(
                                                buttonIndex == 0 ? 'Attending Events' : 'Hosting Events',
                                                style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 30,
                                                  fontWeight: FontWeight.w700,
                                                  color: isSelected[buttonIndex]
                                                      ? Theme.of(context).colorScheme.onPrimary
                                                      : Theme.of(context).colorScheme.onSecondary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isSelected.first)
                    if (private == false || isFriend)
                      StreamBuilder(
                        stream: ref.read(otherEventsProvider.notifier).stream,
                        builder: (context, snapshot) {
                          if (snapshot.data != null) {
                            final hostingEvents = snapshot.data!.where((event) {
                              if (showHosting && event.otherHost != null) {
                                return true;
                              } else {
                                return false;
                              }
                            }).toList();
                            final attendingEvents = snapshot.data!.where((event) {
                              final now = DateTime.now();
                              if (showUpcoming &&
                                  event.otherAttend != null &&
                                  event.sdate.last.compareTo(now.toString()) > 0) return true;
                              if (showPassed &&
                                  event.otherAttend != null &&
                                  event.edate.last.compareTo(now.toString()) < 0) return true;
                              return false;
                            }).toList();
                            if (attendingEvents.isEmpty && isSelected.first) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    "No Events Found",
                                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSecondary),
                                  ),
                                ),
                              );
                            } else if (isSelected.first && attendingEvents != null && attendingEvents.isNotEmpty) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = attendingEvents[index];

                                    preloadImages(context, attendingEvents, index, 4);

                                    return EventTab(
                                      eventData: event,
                                      preloadedImage: NetworkImage(event.imageUrl),
                                    );
                                  },
                                  childCount: attendingEvents.length,
                                ),
                              );
                            } else if (isSelected.last && hostingEvents.isNotEmpty) {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = hostingEvents[index];

                                    preloadImages(context, hostingEvents, index, 4);

                                    return EventTab(
                                      eventData: event,
                                      preloadedImage: NetworkImage(event.imageUrl),
                                    );
                                  },
                                  childCount: hostingEvents.length,
                                ),
                              );
                            } else {
                              return const SliverFillRemaining(
                                child: Center(
                                  child: Text("No Events Hosted"),
                                ),
                              );
                            }
                          } else {
                            return const SliverFillRemaining(
                              child: Center(
                                child: Text("No Data Retrieved"),
                              ),
                            );
                          }
                        },
                      )
                    else
                      SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'This profile is private',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                          ),
                        ),
                      )
                  else if ((private == false) || isFriend)
                    StreamBuilder(
                      stream: ref.read(otherEventsProvider.notifier).stream,
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          // Only useful when viewing a profile through means other than an event header
                          final hostingEvents = snapshot.data!.where((event) => event.otherHost).toList();
                          if (hostingEvents.isEmpty) {
                            return const SliverFillRemaining(
                              child: Center(
                                child: Text("This User Is Not Hosting Any Events at the Moment"),
                              ),
                            );
                          } else {
                            return SliverList(
                              delegate: SliverChildListDelegate(
                                hostingEvents.map((event) {
                                  return EventTab(eventData: event, bookmarkSet: true);
                                }).toList(),
                              ),
                            );
                          }
                        } else {
                          return const SliverFillRemaining(
                            child: Center(
                              child: Text("No Data Retrieved"),
                            ),
                          );
                        }
                      },
                    )
                  else
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'This profile is private',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
