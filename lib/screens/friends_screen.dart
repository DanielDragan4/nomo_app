import 'package:flutter/material.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  var friends = true;
  late List<bool> isSelected;

  @override
  void initState() {
    isSelected = [true, false];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Start on friends list. If false, show requests list

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        flexibleSpace: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text('Friends',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                )),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: Container(
            color: const Color.fromARGB(255, 69, 69, 69),
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ToggleButtons(
                constraints: const BoxConstraints(
                    maxHeight: 250, minWidth: 150, maxWidth: 200),
                borderColor: Colors.black,
                fillColor: Theme.of(context).primaryColor,
                borderWidth: 1,
                selectedBorderColor: Colors.black,
                selectedColor: Colors.grey,
                borderRadius: BorderRadius.circular(5),
                onPressed: (int index) {
                  setState(() {
                    for (int i = 0; i < isSelected.length; i++) {
                      isSelected[i] = i == index;
                    }
                    friends = !friends;
                  });
                },
                isSelected: isSelected,
                children: const [
                  Padding(
                      padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                      child: Text(
                        'Friends',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      )),
                  Padding(
                    padding: EdgeInsets.fromLTRB(3, 3, 3, 3),
                    child: Text(
                      'Requests',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SearchScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.search,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
            ],
          ),
          Expanded(
             child: FreindTab(friendData: null, isRequest: friends)
             //ListView(
            //   key: const PageStorageKey('page'),
            //   children: friends
            //       ? [
            //           for (User i in dummyFriends)
            //             FreindTab(
            //               userData: i,
            //               isRequest: false,
            //             )
            //         ]
            //       : [
            //           for (User i in dummyRequests)
            //             FreindTab(
            //               userData: i,
            //               isRequest: true,
            //             )
            //         ],
            // ),
          )
        ],
      ),
    );
  }
}
