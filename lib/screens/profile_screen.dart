import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    ref.read(profileProvider.notifier).decodeData();
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
            toolbarHeight: MediaQuery.sizeOf(context).height / 4.2,
            title: Padding(
              padding: const EdgeInsets.only(top: 40, bottom: 1),
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
                  children: const [
                    Padding(
                        padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                        child: Text(
                          'Your Events',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700),
                        )),
                    Padding(
                      padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: Text(
                        'Bookmarked',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
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
              child: isSelected.first ? 
              StreamBuilder(
                  stream: ref.watch(attendEventsProvider.notifier).stream,
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      return ListView(
                        key: const PageStorageKey<String>('event'),
                        children: [
                          for (Event i in snapshot.data!)
                            if(i.attending || i.isHost)
                              EventTab(eventData: i),
                        ],
                      );
                    } else {
                      return const Text("No Data Retreived");
                    }
                  },)
                  : 
                  StreamBuilder(
                  stream: ref.watch(attendEventsProvider.notifier).stream,
                  builder: (context, snapshot) {
                    if (snapshot.data != null) {
                      return ListView(
                        key: const PageStorageKey<String>('event'),
                        children: [
                          for (Event i in snapshot.data!)
                            if(i.bookmarked)
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
