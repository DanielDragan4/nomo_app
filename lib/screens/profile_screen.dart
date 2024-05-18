import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/widgets/profile_dropdown.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<Map>? profileInfo;

  @override
  void initState() {
    super.initState();
    _fetchData();
    ref.read(attendEventsProvider.notifier).deCodeData();
  }

  Future<void> _fetchData() async {
    await Future.delayed(const Duration(microseconds: 1));

    if (mounted) {
      setState(() {
        profileInfo = fetchInfo();
      });
    }
  }

  Future<Map> fetchInfo() async {
    await Future.delayed(const Duration(microseconds: 1));

    if (ref.read(profileProvider.notifier).state == null ||
        ref.read(profileProvider.notifier).state!.isEmpty) {
      return {
        'profile_name': 'Unloaded Name',
        'avatar': 'avatar',
        'username': "userUnloaded",
      };
    }
    final profileState = ref.read(profileProvider.notifier).state?[0];
    final avatar =
        await ref.read(profileProvider.notifier).imageURL(profileState.avatar);
    final profN = profileState.profile_name;
    final userN = profileState.username;

    return {
      'profile_name': profN,
      'avatar': avatar,
      'username': userN,
    };
  }

  void updateProfileInfo() {
    setState(() {
      _fetchData();
    });
  }

  @override
  Widget build(BuildContext contex) {
    ref.read(attendEventsProvider.notifier).deCodeData();
    ref.watch(profileProvider.notifier).decodeData();
    var imageUrl;

    if (ref.read(profileProvider.notifier).state == null ||
        ref.read(profileProvider.notifier).state!.isEmpty) {
      imageUrl = '';
    } else {
      imageUrl = ref.read(profileProvider.notifier).state?[0].avatar;
    }

    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            primary: false,
            titleSpacing: BorderSide.strokeAlignCenter,
            floating: true,
            snap: true,
            toolbarHeight: MediaQuery.sizeOf(context).width / 3,
            title: Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 10),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FutureBuilder<Map>(
                      future: profileInfo,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Column(
                            children: [
                              CircleAvatar(
                                key: ValueKey<String>(imageUrl),
                                radius: MediaQuery.sizeOf(context).width / 12,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(
                                  snapshot.data!['avatar'],
                                ),
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height / 100),
                              Text(
                                snapshot.data!['profile_name'],
                                style: const TextStyle(fontSize: 18),
                              ),
                            ],
                          );
                        } else if (snapshot.hasError) {
                          return Column(
                            children: [
                              CircleAvatar(
                                radius: MediaQuery.sizeOf(context).width / 5,
                                child: const Text("No Image"),
                              ),
                              const Text(
                                "No Username",
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          );
                        } else {
                          return const CircularProgressIndicator();
                        }
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
                        FutureBuilder<Map>(
                          future: profileInfo,
                          builder: ((context, snapshot) {
                            if (snapshot.hasData) {
                              return ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .push(MaterialPageRoute(
                                    builder: ((context) => CreateAccountScreen(
                                          isNew: false,
                                          avatar: snapshot.data!['avatar'],
                                          profilename:
                                              snapshot.data!['profile_name'],
                                          username: snapshot.data!['username'],
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
                      ],
                    ),
                    const ProfileDropdown(),
                  ],
                ),
              ]),
            ),
            centerTitle: true,
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                  stream: ref.watch(attendEventsProvider.notifier).stream,
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      return ListView(
                        key: const PageStorageKey<String>('event'),
                        children: [
                          for (Event i in snapshot.data!)
                            EventTab(eventData: i),
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