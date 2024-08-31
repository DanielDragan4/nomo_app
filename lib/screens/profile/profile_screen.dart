import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/functions/image-handling.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/event-providers/attending_events_provider.dart';
import 'package:nomo/providers/event-providers/other_attending_profile.dart';
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
  bool showHosting = false;
  bool friendPending = false;
  var profile;

// Initializes appropriate user data, depending on if viewing own profile or someone else's
  @override
  void initState() {
    super.initState();
    _fetchData();
    if (widget.isUser) {
      ref.read(profileProvider.notifier).decodeData();
      print('init');
      ref.read(attendEventsProvider.notifier).deCodeData();
      isFriend = false;
    } else {
      ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
      checkPendingRequest();
    }
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
    if (widget.isUser) {
      print('refresh');
      await ref.read(attendEventsProvider.notifier).deCodeData();
    } else {
      print('refresh');
      ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
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
      print('fetch');
      ref.read(attendEventsProvider.notifier).deCodeData();
    } else {
      ref.read(otherEventsProvider.notifier).deCodeDataWithId(widget.userId!);
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

  Widget _buildProfileHeader() {
    return Row(
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
          child: CircleAvatar(
            radius: MediaQuery.of(context).size.width / 12,
            backgroundImage: profile?.avatar != null ? NetworkImage(profile!.avatar!) : null,
            child: profile?.avatar == null ? Icon(Icons.person, size: 40) : null,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile?.profile_name ?? 'Loading...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Text(
                '@${profile?.username ?? 'username'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (widget.isUser)
          IconButton(
            icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
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
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculation of appBarHeight
    double appBarHeight = MediaQuery.of(context).padding.top; // Start with top padding

    // Add height for profile header
    appBarHeight += MediaQuery.of(context).size.width * 0.24; // Avatar size (assuming it's proportional to width)
    appBarHeight += 16; // Padding below avatar

    // Add height for profile name and username
    appBarHeight += 24 + 16 + 5; // Text heights and spacing

    // Add height for stats row (Upcoming Events, etc.)
    appBarHeight += MediaQuery.of(context).size.width / 20; // Text size for number
    appBarHeight += MediaQuery.of(context).size.width / 24; // Text size for label
    appBarHeight += 20; // Extra padding

    // Add height for toggle buttons
    appBarHeight += 40; // Height of toggle buttons
    appBarHeight += 24; // Padding around toggle buttons

    // Add height for filter icon (if present)
    if (widget.isUser && isSelected[0]) {
      appBarHeight += MediaQuery.of(context).size.width / 15; // Icon size
      appBarHeight += 16; // Padding around icon
    }

    // Add some extra padding for visual comfort
    appBarHeight += 20;

    // Assign toolbar height
    double toolbar = widget.isUser ? 10 : 50;

    ref.read(attendEventsProvider.notifier).state;
    if (widget.isUser) {
      print('build');
      ref.read(attendEventsProvider.notifier).deCodeData();
    }

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
                    toolbarHeight: kToolbarHeight + toolbar,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    expandedHeight: appBarHeight / 1.3,
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
                              Theme.of(context).primaryColor,
                              Theme.of(context).colorScheme.surface,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            widget.isUser
                                ? Container(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: _buildProfileHeader())
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
                                                fontSize: MediaQuery.of(context).size.width / 20,
                                                color: Theme.of(context).colorScheme.onPrimary,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                    },
                                  ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            StreamBuilder<List<Event>>(
                                              stream: widget.isUser
                                                  ? ref.read(attendEventsProvider.notifier).stream
                                                  : ref.read(otherEventsProvider.notifier).stream,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  final events = snapshot.data!;
                                                  final now = DateTime.now();
                                                  int upcomingEventCount = events.where((event) {
                                                    final eventStartDate =
                                                        DateTime.parse(event.attendeeDates['time_start']);
                                                    final isUpcoming = eventStartDate.isAfter(now);
                                                    final isRelevant = widget.isUser
                                                        ? (event.attending || event.isHost)
                                                        : (event.otherAttend == true || event.otherHost == true);
                                                    return isUpcoming && isRelevant;
                                                  }).length;

                                                  return Text(
                                                    upcomingEventCount.toString(),
                                                    style: TextStyle(
                                                      fontSize: MediaQuery.of(context).size.width / 20,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.onPrimary,
                                                    ),
                                                  );
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                    "Error",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Theme.of(context).colorScheme.error,
                                                    ),
                                                  );
                                                } else {
                                                  return Text(
                                                    "0",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      color: Theme.of(context).colorScheme.onPrimary,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                            Text(
                                              "Upcoming Events",
                                              style: TextStyle(
                                                  fontSize: MediaQuery.of(context).size.width / 24,
                                                  color: Theme.of(context).colorScheme.onPrimary),
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
                                                                          content: Text("User unfriended"),
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
                                      icon: Icon(
                                        Icons.calendar_month_outlined,
                                        size: MediaQuery.of(context).size.width / 15,
                                      ),
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
                            Row(
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: 40, // Maintain original height
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: List.generate(2 * 2 - 1, (index) {
                                          if (index.isOdd) {
                                            // This is a divider
                                            return Container(
                                              width: 1,
                                              height: 20, // Taller divider
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
                                                height: 40, // Full height of parent
                                                decoration: BoxDecoration(
                                                  color: isSelected[buttonIndex]
                                                      ? Theme.of(context).primaryColorLight
                                                      : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    buttonIndex == 0
                                                        ? (widget.isUser ? 'Joined Events' : 'Attending Events')
                                                        : (widget.isUser ? 'Bookmarked' : 'Hosting Events'),
                                                    style: TextStyle(
                                                      fontSize:
                                                          MediaQuery.of(context).size.width / 30, // Original font size
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
                                if (widget.isUser && isSelected[0])
                                  IconButton(
                                    onPressed: () {
                                      _showFilterDialog();
                                    },
                                    icon: Icon(
                                      Icons.filter_list_outlined,
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      size: MediaQuery.of(context).size.width / 15,
                                    ),
                                  ),
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
                        stream: ref.read(attendEventsProvider.notifier).stream,
                        builder: (context, snapshot) {
                          if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                            final relevantEvents = snapshot.data!.where((event) {
                              final now = DateTime.now();
                              if (showHosting && !showUpcoming && !showPassed && event.isHost) return true;
                              if (showUpcoming &&
                                  !showHosting &&
                                  event.attending &&
                                  !event.isHost &&
                                  event.attendeeDates['time_start'].compareTo(now.toString()) > 0) return true;
                              if (showPassed &&
                                  !showHosting &&
                                  event.attending &&
                                  !event.isHost &&
                                  event.attendeeDates['time_end'].compareTo(now.toString()) < 0) return true;
                              if (showUpcoming && showPassed && !showHosting && event.attending && !event.isHost)
                                return true;
                              if (showHosting &&
                                  showUpcoming &&
                                  !showPassed &&
                                  event.isHost &&
                                  event.attendeeDates['time_start'].compareTo(now.toString()) > 0) return true;
                              if (showHosting &&
                                  !showUpcoming &&
                                  showPassed &&
                                  event.isHost &&
                                  event.attendeeDates['time_end'].compareTo(now.toString()) < 0) return true;
                              //if (showHosting && (showUpcoming || showPassed) && event.isHost) return true;
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
                      stream: (widget.isUser)
                          ? ref.read(attendEventsProvider.notifier).stream
                          : ref.read(otherEventsProvider.notifier).stream,
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
          title: Text("Filter Events", style: TextStyle(color: Theme.of(context).colorScheme.primary)),
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
                        if (showUpcoming && showPassed) showHosting = false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Passed"),
                    value: showPassed,
                    onChanged: (bool? value) {
                      setState(() {
                        showPassed = value!;
                        if (showUpcoming && showPassed) showHosting = false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text("Hosting"),
                    value: showHosting,
                    onChanged: (bool? value) {
                      setState(() {
                        showHosting = value!;
                        if (showHosting && showUpcoming && showPassed) {
                          showUpcoming = false;
                          showPassed = false;
                        }
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
