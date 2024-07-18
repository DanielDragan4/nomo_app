import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/functions/image-handling.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/chat_screen.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/screens/new_event_screen.dart';
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
  late List<bool> isSelected;
  late bool isFriend = true;
  bool _isLoading = true;
  bool isHosting = false;
  bool friendPending = false;

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
    isSelected = [true, false];
  }

// Called from Event Tab to refresh data when leaving anothe profile view
  void refreshData() async {
    setState(() {
      _fetchData();
      _futureBuilderKey = UniqueKey();
    });
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
    await _fetchProfileInfo();
    await _fetchEvents();
    setState(() {
      _isLoading = false;
    });
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
    setState(() {
      _fetchData();
      _futureBuilderKey = UniqueKey();
    });
  }

  Future<void> addFriend() async {
    await ref.read(profileProvider.notifier).addFriend(widget.userId, false);
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
    await ref.read(profileProvider.notifier).removeFriend(supabase.auth.currentUser!.id, widget.userId);
  }

  @override
  Widget build(BuildContext contex) {
    //Calculation to prevent appbar overflow on all devices
    double appBarHeight = MediaQuery.of(context).padding.top + MediaQuery.of(context).size.width * 0.24 + 245;

    if (widget.isUser) {
      appBarHeight += 10;
    }

    final profile;

    if (widget.isUser) {
      profile = ref.watch(profileProvider);
      ref.read(attendEventsProvider.notifier).deCodeData();
      ref.read(profileProvider.notifier).decodeData();
    } else {
      profile = profileInfo;
    }
    var imageUrl;

    if (ref.read(profileProvider.notifier).state == null) {
      imageUrl = '';
    } else {
      imageUrl = ref.read(profileProvider.notifier).state?.avatar;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  expandedHeight: appBarHeight,
                  floating: true,
                  pinned: false,
                  snap: true,
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
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '@${profile?.username ?? 'username'}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onSecondary,
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
                                                color: Theme.of(context).colorScheme.onSecondary,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              '@${profile.username}',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(context).colorScheme.onSecondary,
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
                                                color: Theme.of(context).colorScheme.onSecondary),
                                          ),
                                          StreamBuilder(
                                            stream: ref.read(attendEventsProvider.notifier).stream,
                                            builder: (context, snapshot) {
                                              if (snapshot.data != null) {
                                                final attendingEvents = snapshot.data!
                                                    .where((event) => event.attending || event.isHost)
                                                    .toList();
                                                var attendingEventCount = attendingEvents.length;
                                                return Text(
                                                  attendingEventCount.toString(),
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.onSecondary),
                                                );
                                              } else {
                                                return Text(
                                                  "0",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                      color: Theme.of(context).colorScheme.onSecondary),
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
                                                  removeFriend();
                                                  isFriend = !isFriend;
                                                });
                                              },
                                              child: const Text("Remove"),
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
                                          MaterialPageRoute(builder: (context) => const NewEventScreen(event: null)));
                                    },
                                    icon: const Icon(Icons.add),
                                    color: Theme.of(context).colorScheme.onSecondary,
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
                                    isSelected[i] = i == index;
                                  }
                                });
                              },
                              isSelected: isSelected,
                              children: [
                                Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: widget.isUser
                                        ? const Text(
                                            'Your Events',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          )
                                        : const Text(
                                            "Attending Events",
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          )),
                                Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 3),
                                    child: widget.isUser
                                        ? const Text(
                                            'Bookmarked',
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          )
                                        : const Text(
                                            "Hosting Events",
                                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                          )),
                              ],
                            ),
                          ),
                          if (widget.isUser && isSelected[0])
                            CheckboxListTile(
                              title: Text("Hosting Only"),
                              value: isHosting,
                              onChanged: (newValue) {
                                setState(() {
                                  isHosting = newValue!;
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isSelected.first)
                  if (private == false || isFriend || widget.isUser)
                    StreamBuilder(
                      stream: ref.read(attendEventsProvider.notifier).stream,
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          final relevantEvents;
                          if (isHosting == false) {
                            relevantEvents = snapshot.data!.where((event) => event.attending || event.isHost).toList();
                          } else {
                            relevantEvents = snapshot.data!.where((event) => event.isHost).toList();
                          }
                          if (relevantEvents.isEmpty) {
                            return const SliverFillRemaining(
                              child: Center(
                                child: Text("Not Attending Any Events"),
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
                  else
                    SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'This profile is private',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                        ),
                      ),
                    )
                else if (private == false || isFriend || widget.isUser)
                  StreamBuilder(
                    stream: ref.read(attendEventsProvider.notifier).stream,
                    builder: (context, snapshot) {
                      if (snapshot.data != null) {
                        if (widget.isUser) {
                          final bookmarkedEvents = snapshot.data!.where((event) => event.bookmarked).toList();
                          if (bookmarkedEvents.isEmpty) {
                            return const SliverFillRemaining(
                              child: Center(
                                child: Text("No Bookmarked Events"),
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
                          final hostingEvents = snapshot.data!.where((event) => event.isHost).toList();
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
    );
  }
}
