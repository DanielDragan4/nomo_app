import 'package:flutter/material.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/data/dummy_data.dart';
import 'package:nomo/widgets/profile_dropdown.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  Widget optionalWidget = Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Column(
        children: [
          CircleAvatar(backgroundColor: Colors.blue, radius: 30),
          Text(
            "Dummy Account",
            style: TextStyle(fontSize: 15),
          ),
        ],
      ),
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
  );

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
                  const Column(
                    children: [
                      CircleAvatar(backgroundColor: Colors.blue, radius: 30),
                      Text(
                        "Dummy Account",
                        style: TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
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
