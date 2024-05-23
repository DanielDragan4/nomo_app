import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
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

  late List<bool> isSelected;

  @override
  void initState() {
    super.initState();
    _fetchData();
    ref.read(attendEventsProvider.notifier).deCodeData();
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
    final profileState;

    if (userId == null) {
      // Fetch the current user's profile
      profileState = ref.read(profileProvider.notifier).state ??
          Profile(
              profile_id: 'example',
              avatar: null,
              username: 'User-404',
              profile_name: 'User-404',
              interests: []);
    } else {
      // Fetch the profile for the specified user ID
      profileState =
          await ref.read(profileProvider.notifier).fetchProfileById(userId);
    }
    return profileState;
  }

  void updateProfileInfo() {
    setState(() {
      _fetchData();
      _futureBuilderKey = UniqueKey();
    });
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
      backgroundColor: Theme.of(context).colorScheme.background,
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
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
                                radius: MediaQuery.sizeOf(context).width / 6,
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
                        } else if (!snapshot.hasData) {
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: MediaQuery.sizeOf(context).width / 6,
                                child: const Text("No Image"),
                              ),
                              const Text(
                                "No Username",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          );
                        }
                        //if (snapshot.hasData) {
                        else {
                          return Column(
                            children: [
                              CircleAvatar(
                                key: ValueKey<String>(imageUrl),
                                radius: MediaQuery.sizeOf(context).width / 12,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(
                                  snapshot.data!.avatar,
                                ),
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height / 100),
                              Text(
                                snapshot.data!.profile_name,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          );
                        }
                        //}  else {

                        // }
                      },
                    ),
                    Column(
                      children: [
                        Row(
                          children: [
                            const Column(
                              children: [
                                Text(
                                  "Friends",
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  "xxxx",
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width / 20,
                            ),
                            const Column(
                              children: [
                                Text(
                                  "Upcoming Events",
                                  style: TextStyle(fontSize: 15),
                                ),
                                Text(
                                  "xxxx",
                                  style: TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ],
                        ),
                        //TODO: refresh page after updating account info
                        if (widget.isUser)
                          FutureBuilder<Profile>(
                            key: _futureBuilderKey,
                            future: profileInfo,
                            builder: ((context, snapshot) {
                              if (snapshot.hasData) {
                                return ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .push(MaterialPageRoute(
                                      builder: ((context) =>
                                          CreateAccountScreen(
                                            isNew: false,
                                            avatar: snapshot.data!.avatar,
                                            profilename:
                                                snapshot.data!.profile_name,
                                            username: snapshot.data!.username,
                                            onUpdateProfile: updateProfileInfo,
                                          )),
                                    ))
                                        .then((_) {
                                      updateProfileInfo();
                                    });
                                  },
                                  child: const Text("Edit Profile"),
                                );
                              } else {
                                return const ElevatedButton(
                                  onPressed: null,
                                  child: Text("Edit Profile"),
                                );
                              }
                            }),
                          ),
                        if (!widget.isUser)
                          Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 15.0, horizontal: 8),
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  height: 40,
                                  child: SearchBar(
                                    controller: searchController,
                                    hintText: 'Message',
                                    padding: const MaterialStatePropertyAll<
                                            EdgeInsets>(
                                        EdgeInsets.symmetric(horizontal: 10.0)),
                                    trailing: const [
                                      Icon(Icons.arrow_forward_rounded)
                                    ],
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text("Friend"),
                              ),
                            ],
                          ),
                      ],
                    ),
                    if (widget.isUser) const ProfileDropdown(),
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
                        padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
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
                        padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
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
                const Divider(),
              ]),
            ),
            centerTitle: true,
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: isSelected.first
                  ? StreamBuilder(
                      stream: ref.read(attendEventsProvider.notifier).stream,
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          return ListView(
                            key: const PageStorageKey<String>('event'),
                            children: [
                              for (Event i in snapshot.data!)
                                if (i.attending || i.isHost)
                                  EventTab(eventData: i),
                            ],
                          );
                        } else {
                          return const Text("No Data Retreived");
                        }
                      },
                    )
                  : StreamBuilder(
                      stream: ref.read(attendEventsProvider.notifier).stream,
                      builder: (context, snapshot) {
                        if (snapshot.data != null) {
                          return ListView(
                            key: const PageStorageKey<String>('test'),
                            children: [
                              for (Event i in snapshot.data!)
                                if (i.bookmarked)
                                  EventTab(eventData: i, bookmarkSet: true),
                            ],
                          );
                        } else {
                          return const Text("No Data Retreived");
                        }
                      }),
            ),
          ],
        ),
      ),
    );
  }
}
