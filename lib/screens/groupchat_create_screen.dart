import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/friends_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  var friends;
  List members = [];
  bool createGroup = false;

  Future<void> getFriends() async {
    friends = await ref
      .read(profileProvider.notifier)
      .decodeFriends();
  }

  void addToGroup(bool removeAdd, String userId) {
    setState(() {
      if (removeAdd) {
        members.add(userId);
      } else {
        members.remove(userId);
      }
      print(members);
    });
  }

  @override
  void initState() {
    getFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(titleController.text.isNotEmpty && members.isNotEmpty) {
      createGroup = true;
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * .1,
        title: Text('New Group'),
        actions: [
          SizedBox(
            height: MediaQuery.of(context).size.height * .07,
            width: MediaQuery.of(context).size.width * .75,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
              child: SearchBar(
                controller: searchController,
                hintText: 'Who are you looking for?',
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                    EdgeInsets.symmetric(horizontal: 12.0)),
                leading: const Icon(Icons.search),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey('page'),
              children: (friends != null)
                  ? [
                      for (Friend i in friends)
                        FreindTab(
                          friendData: i,
                          isRequest: true,
                          groupMemberToggle: (bool removeAdd, String userId) =>
                            addToGroup(removeAdd, userId),
                          toggle: true,
                        )
                    ]
                  : [
                      Text('friends are loading')
                    ],
            ),
          ),
          TextField(
                autofocus: false,
                controller: titleController,
                  decoration: InputDecoration(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height *.033, maxWidth:  MediaQuery.of(context).size.width *.75),
                    contentPadding: EdgeInsets.all(MediaQuery.of(context).size.height *.005),
                    border: UnderlineInputBorder(borderSide: BorderSide()),
                    hintText: 'Add a title',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                    focusColor:Theme.of(context).colorScheme.onSecondary
                  ),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                ),
                SizedBox(height: MediaQuery.of(context).size.height*.02,),
                createGroup ?
                  ElevatedButton(onPressed: () {
                    ref.read(chatsProvider.notifier).createNewGroup(titleController.text, members);
                    Navigator.popUntil(context, ModalRoute.withName('/'),);
                  }, child: const Text('Create'),)
                  : 
                  Container()
        ],
      ),
    );
  }
}
