import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/friend_tab.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  final TextEditingController searchController = TextEditingController();
  var friends;

  Future<void> getFriends() async{
    friends = ref
      .read(profileProvider.notifier)
      .decodeFriends();
  }
  @override
  void initState() {
    getFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    //Start on friends list. If false, show requests list

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: 
        AppBar(
          toolbarHeight: MediaQuery.of(context).size.height *.1,
          title: Text('New Group'),
          actions: [SizedBox(
            height: MediaQuery.of(context).size.height *.07,
            width: MediaQuery.of(context).size.width*.75,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 10, 10, 10),
                child: SearchBar(
                  controller: searchController,
                  hintText: 'Who are you looking for?',
                  padding: const WidgetStatePropertyAll<EdgeInsets>(
                      EdgeInsets.symmetric(horizontal: 12.0)),
                  leading: const Icon(Icons.search),
                )),
          ),],
        ),
      body: Column(
        children: [
          Expanded(
            child: 
             StreamBuilder(
                stream: ref
                    .read(profileProvider.notifier)
                    .decodeFriends()
                    .asStream(),
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return ListView(
                      key: const PageStorageKey('page'),
                      children:[
                              for (Friend i in snapshot.data!)
                                FreindTab(
                                  friendData: i,
                                  isRequest: false,
                                )
                            ],
                    );
                  } else if(snapshot.connectionState == ConnectionState.active) {
                    return Center(
                      child: Text(
                        'No Friends Were Found. Add Some',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                    );
                  }
                  else{
                    return Center(
                      child: Text(
                        'No Friends',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary),
                      ),
                    );
                  }
                }),
          ),
          
        ],
      ),
    );
  }
}
