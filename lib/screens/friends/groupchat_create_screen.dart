import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/widgets/friend_tab.dart';

class NewGroupChatScreen extends ConsumerStatefulWidget {
  const NewGroupChatScreen({super.key});

  @override
  ConsumerState<NewGroupChatScreen> createState() => _NewGroupChatScreenState();
}

class _NewGroupChatScreenState extends ConsumerState<NewGroupChatScreen> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late Future<List<Friend>> _friendsFuture;
  bool _isLoading = false;
  List<Friend> _friends = [];
  List<String> members = [];
  bool createGroup = false;

  @override
  void initState() {
    super.initState();
    _friendsFuture = _getFriends();
    _scrollController.addListener(_onScrolled);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Friend>> _getFriends() async {
    final friends = await ref.read(profileProvider.notifier).decodeFriends();
    return friends;
  }

  void _onScrolled() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _loadMoreFriends();
    }
  }

  Future<void> _loadMoreFriends() async {
    setState(() {
      _isLoading = true;
    });

    final newFriends = await _getFriends();
    setState(() {
      _friends.addAll(newFriends);
      _isLoading = false;
    });
  }

  void _addToGroup(bool removeAdd, String userId) {
    /*
      Adds a user to a group chat based on their userId based on wether they should be removed or added

      Params: bool removeAdd, String userId
      
      Returns: none
    */
    setState(() {
      if (removeAdd) {
        members.add(userId);
      } else {
        members.remove(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (titleController.text.isNotEmpty && members.isNotEmpty) {
      createGroup = true;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: MediaQuery.of(context).size.height * .1,
        title: const Text('New Group'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              autofocus: false,
              controller: titleController,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(MediaQuery.of(context).size.height * .005),
                border: const UnderlineInputBorder(borderSide: BorderSide()),
                hintText: 'Add a title',
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                focusColor: Theme.of(context).colorScheme.onSecondary,
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: FutureBuilder<List<Friend>>(
                future: _friendsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    _friends = snapshot.data ?? [];
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: _friends.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < _friends.length) {
                          return FriendTab(
                            friendData: _friends[index],
                            isRequest: true,
                            groupMemberToggle: _addToGroup,
                            toggle: true,
                            isEventAttendee: false,
                          );
                        } else {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: createGroup
                  ? () {
                      ref.read(chatsProvider.notifier).createNewGroup(titleController.text, members);
                      Navigator.popUntil(
                        context,
                        ModalRoute.withName('/'),
                      );
                    }
                  : null,
              child: const Text('Create'),
            )
          ],
        ),
      ),
    );
  }
}
