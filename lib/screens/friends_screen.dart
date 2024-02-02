import 'package:flutter/material.dart';
import 'package:nomo/data/dummy_data.dart';
import 'package:nomo/models/user_model.dart';
import 'package:nomo/widgets/user_tab.dart';
import 'package:nomo/widgets/app_bar.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  var friends = true;

  @override
  Widget build(BuildContext context) {
    //Start on friends list. If false, show requests list

    return Scaffold(
        appBar: MainAppBar(),
        // AppBar(
        //   toolbarHeight: 15,
        //   titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        //   title: Center(
        //     child: Text(
        //       'Nomo',
        //       style: TextStyle(
        //         color: Theme.of(context).primaryColor,
        //         fontWeight: FontWeight.bold,
        //       ),
        //     ),
        //   ),
        // ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(style: BorderStyle.solid),
                    ),
                    child: TextButton(
                      child: Text("Friends"),
                      onPressed: () {
                        setState(() {
                          friends = true;
                        });
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      border: Border.all(style: BorderStyle.solid),
                    ),
                    child: TextButton(
                      child: Text("Requests"),
                      onPressed: () {
                        setState(() {
                          friends = false;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                key: const PageStorageKey('page'),
                children: friends
                    ? [for (User i in dummyFriends) UserTab(userData: i)]
                    : [for (User i in dummyFriends) Text("Request Tab TBD")],
              ),
            )
          ],
        ));
  }
}
