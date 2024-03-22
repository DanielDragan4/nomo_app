import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/attending_events_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/screens/create_account_screen.dart';
import 'package:nomo/widgets/profile_dropdown.dart';
import 'package:nomo/models/profile_model.dart';

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
  }

  Future<void> _fetchData() async {
    await Future.delayed(const Duration(microseconds: 1));

    setState(() {
      profileInfo = fetchInfo();
    });
  }

  Future<Map> fetchInfo() async {
    await Future.delayed(const Duration(microseconds: 1));
    var avatar = await ref
        .watch(profileProvider.notifier)
        .imageURL(ref.watch(profileProvider.notifier).state![0].avatar);
    var profN = ref.watch(profileProvider.notifier).state![0].profile_name;
    var userN = ref.watch(profileProvider.notifier).state![0].username;
    final infoMap = {
      'profile_name': profN,
      'avatar': avatar,
      'username': userN,
    };
    return infoMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        title: Center(
          child: Column(
            children: [
              Text(
                'Nomo',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<Map>(
                    future: profileInfo,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: NetworkImage(
                                snapshot.data!['avatar'],
                              ),
                            ),
                            Text(
                              snapshot.data!['profile_name'],
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        );
                      } else if (snapshot.hasError) {
                        return const Column(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              child: Text("No Image"),
                            ),
                            Text(
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
                  //backgroundColor: Colors.blue,

                  Column(
                    children: [
                      const Row(
                        children: [
                          Column(
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
                            width: 10,
                          ),
                          Column(
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
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: ((context) => CreateAccountScreen(
                                        isNew: false,
                                        avatar: snapshot.data!['avatar'],
                                        profilename:
                                            snapshot.data!['profile_name'],
                                        username: snapshot.data!['username'],
                                      )),
                                ));
                              },
                              child: const Text("Edit Profile"),
                            );
                          } else {
                            return const ElevatedButton(
                              onPressed: null,
                              child: const Text("Edit Profile"),
                            );
                          }
                        }),
                      ),
                    ],
                  ),
                  const ProfileDropdown(),
                ],
              )
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey<String>('event'),
              children: [
                for (Event i in ref.watch(attendEventsProvider.notifier).state) EventTab(eventData: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
