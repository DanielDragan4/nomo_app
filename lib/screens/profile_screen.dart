import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
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
    var user = ref.watch(profileProvider.notifier).state![0].profile_name;
    final infoMap = {
      'profile_name': user,
      'avatar': avatar,
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
                              child: Image.network(snapshot.data!['avatar'],
                                  fit: BoxFit.fill),
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
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text("Edit Profile"),
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
                //for (Event i in dummyEvents) EventTab(eventData: i),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
