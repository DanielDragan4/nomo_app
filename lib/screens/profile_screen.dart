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

// Called from Event Tab
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

  Future<void> _fetchProfileInfo() async {
    final newProfileInfo = await fetchInfo(widget.userId);
    setState(() {
      profileInfo = Future.value(newProfileInfo);
    });
  }

  Future<void> _fetchEvents() async {
    if (widget.isUser) {
      ref.read(attendEventsProvider.notifier).deCodeData();
    } else {
      ref.read(attendEventsProvider.notifier).deCodeDataWithId(widget.userId!);
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
      profileState = await ref.read(profileProvider.notifier).fetchProfileById(userId);
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
    await checkPendingRequest();
  }

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
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : NestedScrollView(
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
                          GestureDetector(
                            onTap: () {
                              profileInfo?.then((profile) {
                                Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: ((context) => CreateAccountScreen(
                                              isNew: false,
                                              avatar: profile.avatar,
                                              profilename: profile.profile_name,
                                              username: profile.username,
                                              onUpdateProfile: updateProfileInfo,
                                            ))))
                                    .then((_) {
                                  updateProfileInfo();
                                });
                              });
                            },
                            child: FutureBuilder(
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
                                } else if (snapshot.connectionState != ConnectionState.done) {
                                  return const CircularProgressIndicator();
                                } else if (!snapshot.hasData || snapshot.data!.avatar == null) {
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
                                            avatar != null && avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                        child: avatar == null || avatar.isEmpty ? const Text("No Image") : null,
                                      ),
                                      SizedBox(height: MediaQuery.sizeOf(context).height / 100),
                                      Text(
                                        profileName,
                                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
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
                                        stream: ref.read(attendEventsProvider.notifier).stream,
                                        builder: (context, snapshot) {
                                          if (snapshot.data != null) {
                                            final attendingEvents = snapshot.data!
                                                .where((event) => event.attending || event.isHost)
                                                .toList();
                                            var attendingEventCount = attendingEvents.length;
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
                            ],
                          ),
                          if (widget.isUser)
                            Row(children: [
                              IconButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(builder: (context) => NewEventScreen(event: null)));
                                  },
                                  icon: const Icon(Icons.add)),
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
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    )
                                  : const Text(
                                      "Attending Events",
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                    )),
                          Padding(
                              padding: const EdgeInsets.fromLTRB(3, 3, 3, 3),
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
                    ]),
                  ),
                  centerTitle: true,
                ),
              ],
              body: Column(
                children: [
                  if (isSelected[0] && widget.isUser)
                    CheckboxListTile(
                      title: Text("Hosting Only"),
                      value: isHosting,
                      onChanged: (newValue) {
                        setState(() {
                          isHosting = newValue!;
                        });
                      },
                    ),
                  const Divider(),
                  Expanded(
                    child: isSelected.first
                        ? (private == false || isFriend || widget.isUser)
                            ? (StreamBuilder(
                                stream: ref.read(attendEventsProvider.notifier).stream,
                                builder: (context, snapshot) {
                                  if (snapshot.data != null) {
                                    final relevantEvents;
                                    if (isHosting == false) {
                                      relevantEvents =
                                          snapshot.data!.where((event) => event.attending || event.isHost).toList();
                                    } else {
                                      relevantEvents = snapshot.data!.where((event) => event.isHost).toList();
                                    }
                                    if (relevantEvents.isEmpty) {
                                      return const Center(
                                        child: Text("Not Attending Any Events"),
                                      );
                                    } else {
                                      return ListView.builder(
                                        key: const PageStorageKey<String>('event'),
                                        itemCount: relevantEvents.length,
                                        itemBuilder: (context, index) {
                                          final event = relevantEvents[index];

                                          preloadImages(context, relevantEvents, index, 4);

                                          return EventTab(
                                            eventData: event,
                                            preloadedImage: NetworkImage(event.imageUrl),
                                          );
                                        },
                                      );
                                    }
                                  } else {
                                    return const Text("No Data Retrieved");
                                  }
                                },
                              ))
                            : Center(
                                child: Text(
                                'This profile is private',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                              ))
                        : (private == false || isFriend || widget.isUser)
                            ? StreamBuilder(
                                stream: ref.read(attendEventsProvider.notifier).stream,
                                builder: (context, snapshot) {
                                  if (snapshot.data != null) {
                                    if (widget.isUser) {
                                      final bookmarkedEvents =
                                          snapshot.data!.where((event) => event.bookmarked).toList();
                                      if (bookmarkedEvents.isEmpty) {
                                        return const Center(
                                          child: Text("No Bookmarked Events"),
                                        );
                                      } else {
                                        return ListView.builder(
                                          key: const PageStorageKey<String>('bookmarked'),
                                          itemCount: bookmarkedEvents.length,
                                          itemBuilder: (context, index) {
                                            final event = bookmarkedEvents[index];
                                            preloadImages(context, bookmarkedEvents, index, 4);
                                            return EventTab(
                                              eventData: event,
                                              preloadedImage: NetworkImage(event.imageUrl),
                                            );
                                          },
                                        );
                                      }
                                    } else {
                                      //only useful when viewing a profile though means other than an event header
                                      final hostingEvents = snapshot.data!.where((event) => event.isHost).toList();
                                      if (hostingEvents.isEmpty) {
                                        return const Center(
                                          child: Text("This User Is Not Hosting Any Events at the Moment"),
                                        );
                                      } else {
                                        return ListView(
                                          key: const PageStorageKey<String>('test'),
                                          children: [
                                            for (Event i in snapshot.data!)
                                              if (i.isHost) EventTab(eventData: i, bookmarkSet: true),
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
                                style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                              )),
                  ),
                ],
              ),
            ),
    );
  }
}
