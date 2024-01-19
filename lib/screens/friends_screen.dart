import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    var friends = true;

    return Scaffold(
        appBar: AppBar(
          toolbarHeight: 15,
          titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
          title: Center(
            child: Text(
              'Nomo',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
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
                        friends = true;
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
                        friends = false;
                      },
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                key: PageStorageKey('page'),
                children: friends ? [] : [],
              ),
            )
          ],
        ));
  }
}
