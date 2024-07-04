import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/screens/chat_screen.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/widgets/profile_dropdown.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  ProfileScreen({super.key, required this.isUser, this.userId});

  bool isUser;
  String? userId;

  @override
  ConsumerState<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<Profile>? profileInfo;
  UniqueKey _futureBuilderKey = UniqueKey();
  final TextEditingController searchController = TextEditingController();
  bool? private;
  late List<bool> isSelected;
  late bool isFriend = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    if (widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeData();
      isFriend = false;
    } else {
      ref.read(attendEventsProvider.notifier).deCodeDataWithId(widget.userId!);
    }
    isSelected = [true, false];
  }

  Future<void> _fetchData() async {
    await Future.delayed(const Duration(microseconds: 1));
    if (mounted) {
      final newProfileInfo = await fetchInfo(widget.userId);
      setState(() {
        profileInfo = Future.value(newProfileInfo);
      });
    }
  }

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
      profileState =
          await ref.read(profileProvider.notifier).fetchProfileById(userId);
      isFriend = await ref.read(profileProvider.notifier).isFriend(userId);
      private = profileState.private;
    }
    return profileState;
  }

  void updateProfileInfo() {
    setState(() {
      _fetchData();
      _futureBuilderKey = UniqueKey();
    });
  }

  Future<void> addFriend() async {
    await ref.read(profileProvider.notifier).addFriend(widget.userId, false);
  }

  Future<void> removeFriend() async {
    final supabase = (await ref.read(supabaseInstance)).client;
    await ref
        .read(profileProvider.notifier)
        .removeFriend(supabase.auth.currentUser!.id, widget.userId);
  }

  @override
  Widget build(BuildContext contex) {
    if (widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeData();
      ref.read(profileProvider.notifier).decodeData();
    }
    var imageUrl;

    if (ref.read(profileProvider.notifier).state == null) {
      imageUrl = '';
    } else {
      imageUrl = ref.read(profileProvider.notifier).state?.avatar;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            primary: false,
            titleSpacing: BorderSide.strokeAlignCenter,
            floating: true,
            snap: true,
            toolbarHeight: MediaQuery.sizeOf(context).height / 4.2,
            title: Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 1),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FutureBuilder(
                      key: _futureBuilderKey,
                      future: profileInfo,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: MediaQuery.sizeOf(context).width / 12,
                                child: const Text("No Image"),
                              ),
                              const Text(
                                "No Username",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          );
                        } else if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return const CircularProgressIndicator();
                        } else if (!snapshot.hasData ||
                            snapshot.data!.avatar == null) {
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: MediaQuery.sizeOf(context).width / 12,
                                child: const Text("No Image"),
                              ),
                              const Text(
                                "No Username",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          );
                        } else {
                          var profile = snapshot.data!;
                          var avatar = profile.avatar;
                          var profileName = profile.profile_name ?? 'No Name';
                          return Column(
                            children: [
                              CircleAvatar(
                                key: ValueKey<String>(avatar ?? ''),
                                radius: MediaQuery.sizeOf(context).width / 12,
                                backgroundColor: Colors.white,
                                backgroundImage:
                                    avatar != null && avatar.isNotEmpty
                                        ? NetworkImage(avatar)
                                        : null,
                                child: avatar == null || avatar.isEmpty
                                    ? const Text("No Image")
                                    : null,
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height / 100),
                              Text(
                                profileName,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w600),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            Column(
                              children: [
                                const Text(
                                  "Upcoming Events",
                                  style: TextStyle(fontSize: 15),
                                ),
                                StreamBuilder(
                                  stream: ref
                                      .read(attendEventsProvider.notifier)
                                      .stream,
                                  builder: (context, snapshot) {
                                    if (snapshot.data != null) {
                                      final attendingEvents = snapshot.data!
                                          .where((event) =>
                                              event.attending || event.isHost)
                                          .toList();
                                      var attendingEventCount =
                                          attendingEvents.length;
                                      return Text(
                                        attendingEventCount.toString(),
                                        style: const TextStyle(fontSize: 15),
                                      );
                                    } else {
                                      return const Text(
                                        "0",
                                        style: TextStyle(fontSize: 15),
                                      );
                                    }
                                  },
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
                                        onPressed: () {
                                          setState(() {
                                            addFriend();
                                            isFriend = !isFriend;
                                          });
                                        },
                                        child: private == false
                                            ? const Text("Friend")
                                            : const Text("Request Friend"),
                                      ),
                                SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 20),
                                Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(100),
                                      color: Theme.of(context).primaryColor),
                                  child: IconButton(
                                    onPressed: () async {
                                      Friend friend = Friend(
                                          avatar: (await profileInfo)?.avatar,
                                          friendProfileId: widget.userId!,
                                          friendProfileName:
                                              (await profileInfo)!.profile_name,
                                          friendUsername:
                                              (await profileInfo)!.username);
                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) => ChatScreen(
                                                    chatterUser: friend,
                                                    currentUser: ref
                                                        .read(profileProvider
                                                            .notifier)
                                                        .state!
                                                        .profile_id,
                                                  )));
                                    },
                                    icon: const Icon(Icons.message),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    Row(children: [
                      IconButton(
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    NewEventScreen(event: null)));
                          },
                          icon: const Icon(Icons.add)),
                      if (widget.isUser)
                        ProfileDropdown(
                          updateProfileInfo: updateProfileInfo,
                          profileInfo: profileInfo,
                        ),
                    ]),
                  ],
                ),
                ToggleButtons(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * .05,
                      minWidth: MediaQuery.of(context).size.width * .4,
                      maxWidth: MediaQuery.of(context).size.width * .55),
                  borderColor: Colors.black,
                  fillColor: Theme.of(context).primaryColor,
                  borderWidth: 1,
                  selectedBorderColor: Colors.black,
                  selectedColor: Colors.grey,
                  borderRadius: BorderRadius.circular(15),
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
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: widget.isUser
                            ? const Text(
                                'Your Events',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              )
                            : const Text(
                                "Attending Events",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              )),
                    Padding(
                        padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: widget.isUser
                            ? const Text(
                                'Bookmarked',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              )
                            : const Text(
                                "Hosting Events",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              )),
                  ],
                ),
              ]),
            ),
            centerTitle: true,
          ),
        ],
        body: Column(
          children: [
            const Divider(),
            Expanded(
              child: isSelected.first
                  ? (private == false || isFriend || widget.isUser)
                      ? (StreamBuilder(
                          stream:
                              ref.read(attendEventsProvider.notifier).stream,
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              final attendingEvents = snapshot.data!
                                  .where((event) =>
                                      event.attending || event.isHost)
                                  .toList();
                              if (attendingEvents.isEmpty) {
                                return const Center(
                                  child: Text("Not Attending Any Events"),
                                );
                              } else {
                                return ListView(
                                  key: const PageStorageKey<String>('event'),
                                  children: [
                                    for (Event i in snapshot.data!)
                                      if (i.attending || i.isHost)
                                        EventTab(eventData: i),
                                  ],
                                );
                              }
                            } else {
                              return const Text("No Data Retreived");
                            }
                          },
                        ))
                      : Center(
                          child: Text(
                          'This profile is private',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary),
                        ))
                  : (private == false || isFriend || widget.isUser)
                      ? StreamBuilder(
                          stream:
                              ref.read(attendEventsProvider.notifier).stream,
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              if (widget.isUser) {
                                final bookmarkedEvents = snapshot.data!
                                    .where((event) => event.bookmarked)
                                    .toList();
                                if (bookmarkedEvents.isEmpty) {
                                  return const Center(
                                    child: Text("No Bookmarked Events"),
                                  );
                                } else {
                                  return ListView(
                                    key: const PageStorageKey<String>(
                                        'bookmarked'),
                                    children: [
                                      for (Event event in bookmarkedEvents)
                                        EventTab(
                                            eventData: event,
                                            bookmarkSet: true),
                                    ],
                                  );
                                }
                              } else {
                                //only useful when viewing a profile though means other than an event header
                                final hostingEvents = snapshot.data!
                                    .where((event) => event.isHost)
                                    .toList();
                                if (hostingEvents.isEmpty) {
                                  return const Center(
                                    child: Text(
                                        "This User Is Not Hosting Any Events at the Moment"),
                                  );
                                } else {
                                  return ListView(
                                    key: const PageStorageKey<String>('test'),
                                    children: [
                                      for (Event i in snapshot.data!)
                                        if (i.isHost)
                                          EventTab(
                                              eventData: i, bookmarkSet: true),
                                    ],
                                  );
                                }
                              }
                            } else {
                              return const Text("No Data Retreived");
                            }
                          })
                      : Center(
                          child: Text(
                          'This profile is private',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSecondary),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
