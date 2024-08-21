import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/functions/image-handling.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/providers/notification-providers/friend-notif-manager.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase-providers/supabase_provider.dart';
import 'package:nomo/screens/calendar/calendar_screen.dart';
import 'package:nomo/screens/friends/chat_screen.dart';
import 'package:nomo/screens/profile/create_account_screen.dart';
import 'package:nomo/screens/events/new_event_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/widgets/profile_dropdown.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key, required this.isUser, this.userId});

  bool isUser;
  String? userId;

  @override
  ConsumerState<ProfileScreen> createState() {
    return ProfileScreenState();
  }
}

class ProfileScreenState extends ConsumerState<ProfileScreen> {
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
    if (widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeData();
      isFriend = false;
    } else {
      ref.read(attendEventsProvider.notifier).deCodeDataWithId(widget.userId!);
      checkPendingRequest();
    }
  }

// Called from Event Tab to refresh data when leaving anothe profile view
  void refreshData() async {
    if (mounted) {
      setState(() {
        _fetchData();
        _futureBuilderKey = UniqueKey();
      });
    }
    await ref.read(attendEventsProvider.notifier).deCodeData();
    if (!widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeDataWithId(widget.userId!);
    }
  }

// Loads profile info and event info
  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });
    if (!widget.isUser) {
      await _fetchProfileInfo();
    }
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
    if (widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeData();
    } else {
      ref.read(attendEventsProvider.notifier).deCodeDataWithId(widget.userId!);
    }
  }

// Returns relevant profile information to _fetchProfileInfo, or sets default values to avoid error
  Future<Profile> fetchInfo(String? userId) async {
    await Future.delayed(const Duration(microseconds: 1));
    Profile profileState;

    if (userId == null) {
      profileState = ref.read(profileProvider.notifier).state ??
          Profile(
              profile_id: 'example',
              avatar: null,
              username: 'User-404',
              profile_name: 'User-404',
              interests: [],
              availability: [],
              private: false);
    } else {
      profileState = await ref.read(profileProvider.notifier).fetchProfileById(userId);
      isFriend = await ref.read(profileProvider.notifier).isFriend(userId);
      private = profileState.private;
    }
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

  @override
  Widget build(BuildContext context) {
    //Calculation to prevent appbar overflow on all devices
    double appBarHeight = MediaQuery.of(context).padding.top + MediaQuery.of(context).size.width * 0.24 + 270;
    double toolbar;

    if (widget.isUser) {
      appBarHeight += 10;
      toolbar = 10;
    } else {
      toolbar = 50;
    }

    if (widget.isUser) {
      ref.read(profileProvider.notifier).decodeData();
      profile = ref.watch(profileProvider.notifier).state;
      ref.read(attendEventsProvider.notifier).deCodeData();
    } else {
      profile = profileInfo;
    }

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
                    toolbarHeight: kToolbarHeight + toolbar,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    expandedHeight: appBarHeight,
                    floating: false,
                    pinned: false,
                    snap: false,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (profile != null && widget.isUser && widget.userId == null) {
                                  Navigator.of(context)
                                      .push(
                                        MaterialPageRoute(
                                          builder: (contex) => CreateAccountScreen(
                                            isNew: false,
                                            avatar: profile.avatar,
                                            profilename: profile.profile_name,
                                            username: profile.username,
                                            onUpdateProfile: updateProfileInfo,
                                          ),
                                        ),
                                      )
                                      .then((_) => updateProfileInfo());
                                }
                              },
                              child: widget.isUser
                                  ? Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 10),
                                        CircleAvatar(
                                          radius: MediaQuery.of(context).size.width * 0.12,
                                          backgroundImage:
                                              profile?.avatar != null ? NetworkImage(profile!.avatar!) : null,
                                          child: profile?.avatar == null
                                              ? Icon(Icons.person, size: MediaQuery.of(context).size.width * 0.12)
                                              : null,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          profile?.profile_name ?? 'Loading...',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text(
                                            '@${profile?.username ?? 'username'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context).colorScheme.onPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    )
                                  : FutureBuilder(
                                      key: _futureBuilderKey,
                                      future: profileInfo,
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return Column(
                                            children: [
                                              const SizedBox(height: 10),
                                              CircleAvatar(
                                                radius: MediaQuery.of(context).size.width * 0.12,
                                                child: const Text("No Image"),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Loading...',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '@username',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          );
                                        } else if (snapshot.connectionState != ConnectionState.done) {
                                          return const CircularProgressIndicator();
                                        } else if (!snapshot.hasData || snapshot.data!.avatar == null) {
                                          return Column(
                                            children: [
                                              const SizedBox(height: 10),
                                              CircleAvatar(
                                                radius: MediaQuery.of(context).size.width * 0.12,
                                                child: const Text("No Image"),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                'Loading...',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onSecondary,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '@username',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Theme.of(context).colorScheme.onSecondary,
                                                ),
                                              ),
                                            ],
                                          );
                                        } else {
                                          var profile = snapshot.data!;
                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(height: 10),
                                              CircleAvatar(
                                                radius: MediaQuery.of(context).size.width * 0.12,
                                                backgroundImage:
                                                    profile?.avatar != null ? NetworkImage(profile.avatar!) : null,
                                                child: profile?.avatar == null
                                                    ? Icon(Icons.person, size: MediaQuery.of(context).size.width * 0.12)
                                                    : null,
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                profile.profile_name ?? 'Loading...',
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                '@${profile.username}',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Theme.of(context).colorScheme.onPrimary,
                                                ),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Text(
                                              "Upcoming Events",
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.onPrimary),
                                            ),
                                            StreamBuilder(
                                              stream: ref.watch(attendEventsProvider.notifier).stream,
                                              builder: (context, snapshot) {
                                                if (snapshot.data != null) {
                                                  final attendingEvents = snapshot.data!
                                                      .where((event) => (event.otherHost == null)
                                                          ? event.attending || event.isHost
                                                          : event.otherAttend || event.otherHost)
                                                      .toList();
                                                  var attendingEventCount = attendingEvents.length;
                                                  for (Event event in attendingEvents) {
                                                    if (event.sdate.last.compareTo(DateTime.now().toString()) < 0) {
                                                      attendingEventCount--;
                                                    }
                                                  }
                                                  return Text(
                                                    attendingEventCount.toString(),
                                                    style: TextStyle(
                                                        fontSize: 18, color: Theme.of(context).colorScheme.onPrimary),
                                                  );
                                                } else {
                                                  return Text(
                                                    "0",
                                                    style: TextStyle(
                                                        fontSize: 18, color: Theme.of(context).colorScheme.onPrimary),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (!widget.isUser)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Row(
                                      children: [
                                        isFriend
                                            //If profile is private, make this a request instead of instant
                                            ? ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    FocusManager.instance.primaryFocus?.unfocus();
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                              title: Text(
                                                                'Are you sure you unfriend this user?',
                                                                style: TextStyle(
                                                                    color: Theme.of(context).primaryColorDark),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed: () async {
                                                                      removeFriend();
                                                                      isFriend = !isFriend;
                                                                      Navigator.pop(context);
                                                                      ScaffoldMessenger.of(context)
                                                                          .hideCurrentSnackBar();
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(
                                                                          content: Text("Event Deleted"),
                                                                        ),
                                                                      );
                                                                    },
                                                                    child: const Text('YES')),
                                                                TextButton(
                                                                    onPressed: () => Navigator.pop(context),
                                                                    child: const Text('CANCEL')),
                                                              ],
                                                            ));
                                                  });
                                                },
                                                child: const Text("Unfriend"),
                                              )
                                            : ElevatedButton(
                                                onPressed: friendPending
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          addFriend();
                                                        });
                                                      },
                                                child: friendPending
                                                    ? const Text("Pending")
                                                    : (private == false
                                                        ? const Text("Friend")
                                                        : const Text("Request Friend")),
                                              ),
                                        SizedBox(width: MediaQuery.of(context).size.width / 20),
                                        Container(
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(100),
                                              color: Theme.of(context).primaryColor),
                                          child: IconButton(
                                            onPressed: () async {
                                              Friend friend = Friend(
                                                  avatar: (await profileInfo)?.avatar,
                                                  friendProfileId: widget.userId!,
                                                  friendProfileName: (await profileInfo)!.profile_name,
                                                  friendUsername: (await profileInfo)!.username);
                                              Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) => ChatScreen(
                                                            chatterUser: friend,
                                                            currentUser:
                                                                ref.read(profileProvider.notifier).state!.profile_id,
                                                          )));
                                            },
                                            icon: const Icon(Icons.message),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (widget.isUser)
                                  Row(children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => const CalendarScreen(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.calendar_month_outlined),
                                      color: Theme.of(context).colorScheme.onPrimary,
                                    ),
                                    ProfileDropdown(
                                      updateProfileInfo: updateProfileInfo,
                                      profileInfo: profileInfo,
                                    ),
                                  ]),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: ToggleButtons(
                                  constraints: BoxConstraints(
                                    minHeight: 40,
                                    minWidth: MediaQuery.of(context).size.width * 0.44,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  selectedBorderColor: Theme.of(context).primaryColor,
                                  selectedColor: Theme.of(context).primaryColor,
                                  fillColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                  color: Colors.grey,
                                  onPressed: (int index) {
                                    setState(() {
                                      for (int i = 0; i < isSelected.length; i++) {
                                        isSelected[i] = (i == index);
                                      }
                                    });
                                  },
                                  isSelected: isSelected,
                                  children: [
                                    Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: widget.isUser
                                            ? Text(
                                                'Joined Events',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context).colorScheme.onPrimary),
                                              )
                                            : Text(
                                                "Attending Events",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context).colorScheme.onPrimary),
                                              )),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: widget.isUser
                                            ? Text(
                                                'Bookmarked',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context).colorScheme.onPrimary),
                                              )
                                            : Text(
                                                "Hosting Events",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: Theme.of(context).colorScheme.onPrimary),
                                              )),
                                  ],
                                ),
                              ),
                            ),
                            if (widget.isUser && isSelected[0])
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      _showFilterDialog();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                    ),
                                    child: Text(
                                      "Filters",
                                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                                    ),
                                  ),
                                  SizedBox(width: 16), // Add some padding
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isSelected.first)
                    if (widget.isUser)
                      StreamBuilder(
                        stream: ref.watch(attendEventsProvider.notifier).stream,
                        builder: (context, snapshot) {
                          if (snapshot.data != null) {
                            final relevantEvents = snapshot.data!.where((event) {
                              final now = DateTime.now();
                              if (showHosting && event.isHost) return true;
                              if (showUpcoming && event.attending && event.attendeeDates['time_start'].compareTo(now.toString()) > 0)
                                return true;
                              if (showPassed && event.attending && event.attendeeDates['time_end'].compareTo(now.toString()) < 0) return true;
                              return false;
                            }).toList();
                            if (relevantEvents.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    "No Events Found",
                                    style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSecondary),
                                  ),
                                ),
                              );
                            } else {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = relevantEvents[index];

                                    preloadImages(context, relevantEvents, index, 4);

                                    return EventTab(
                                      eventData: event,
                                      preloadedImage: NetworkImage(event.imageUrl),
                                    );
                                  },
                                  childCount: relevantEvents.length,
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
                    else if (private == false || isFriend)
                      StreamBuilder(
                        stream: ref.watch(attendEventsProvider.notifier).stream,
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
                              if (showUpcoming && event.otherAttend != null && event.sdate.last.compareTo(now.toString()) > 0)
                                return true;
                              if (showPassed && event.otherAttend != null && event.edate.last.compareTo(now.toString()) < 0)
                                return true;
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
                            } else if (isSelected.first && attendingEvents.isNotEmpty) {
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
                  else if ((private == false) || isFriend || widget.isUser)
                    StreamBuilder(
                      stream: ref.watch(attendEventsProvider.notifier).stream,
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          if (widget.isUser) {
                            final bookmarkedEvents = snapshot.data!.where((event) => event.bookmarked).toList();
                            if (bookmarkedEvents.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text(
                                    "No Bookmarked Events",
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              );
                            } else {
                              return SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final event = bookmarkedEvents[index];
                                    preloadImages(context, bookmarkedEvents, index, 4);
                                    return EventTab(
                                      eventData: event,
                                      preloadedImage: NetworkImage(event.imageUrl),
                                    );
                                  },
                                  childCount: bookmarkedEvents.length,
                                ),
                              );
                            }
                          } else {
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Filter Events", style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
          backgroundColor: Theme.of(context).cardColor,
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  CheckboxListTile(
                    title: Text("Upcoming"),
                    value: showUpcoming,
                    onChanged: (bool? value) {
                      setState(() {
                        showUpcoming = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Passed"),
                    value: showPassed,
                    onChanged: (bool? value) {
                      setState(() {
                        showPassed = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Hosting"),
                    value: showHosting,
                    onChanged: (bool? value) {
                      setState(() {
                        showHosting = value!;
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text("Apply"),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {}); // Refresh the main screen
              },
            ),
          ],
        );
      },
    );
  }
}
