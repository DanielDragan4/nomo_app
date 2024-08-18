import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/main.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/profile_model.dart';
import 'package:nomo/providers/chat-providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/widgets/message_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/providers/chat-providers/chat_id_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  ChatScreen({super.key, this.chatterUser, required this.currentUser, this.groupInfo});
  final Friend? chatterUser;
  final String currentUser;
  Map? groupInfo;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> with RouteAware {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List? userIdAndAvatar;
  Stream<List<Map<String, dynamic>>>? _chatStream;
  String? chatID;
  bool _showMemberList = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() async {
    if (widget.groupInfo == null) {
      await _initializeChatStream();
      await _fetchChatID();
    } else {
      await _initializeGroupChatStream();
      // Update activeChatId in App state
      ref.read(activeChatIdProvider.notifier).setActiveChatId(widget.groupInfo!['group_id']);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Register route observer when the widget is created
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // Unsubscribe route observer when the widget is disposed
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPop() {
    // Clear activeChatId when returning to this screen
    ref.read(activeChatIdProvider.notifier).setActiveChatId(null);
  }

  Future<void> _fetchChatID() async {
    /*
      Gets active chat id based on the user ids for the chat from the Chats provider

      Params: none
      
      Returns: none
    */
    final id =
        await ref.read(chatsProvider.notifier).readChatId(widget.currentUser, widget.chatterUser!.friendProfileId);
    setState(() {
      chatID = id;
    });
    // Set activeChatId for direct chat
    ref.read(activeChatIdProvider.notifier).setActiveChatId(chatID);
  }

  Future<void> _initializeChatStream() async {
    /*
      sets an active stream on new records created with a matching chat Id for the chat entered

      Params: none
      
      Returns: none
    */
    final supabaseClient = Supabase.instance.client; // Ensure the client is initialized correctly
    final chatID =
        await ref.read(chatsProvider.notifier).readChatId(widget.currentUser, widget.chatterUser!.friendProfileId);
    setState(() {
      _chatStream = supabaseClient
          .from('Messages')
          .stream(primaryKey: ['id']) // Ensure the primary key is specified
          .eq('chat_id', chatID)
          .order('created_at', ascending: false)
          .map((event) => event.map((e) => e).toList());
    });
  }

  Future<void> _initializeGroupChatStream() async {
    /*
      sets an active stream on new records created with a matching group chat Id for the chat entered

      Params: none
      
      Returns: none
    */
    final supabaseClient = Supabase.instance.client; // Ensure the client is initialized correctly
    userIdAndAvatar = await ref.read(chatsProvider.notifier).getMemberIdAndAvatar(widget.groupInfo!['group_id']!);
    setState(() {
      _chatStream = supabaseClient
          .from('Group_Messages')
          .stream(primaryKey: ['group_message_id']) // Ensure the primary key is specified
          .eq('group_id', widget.groupInfo!['group_id']!)
          .order('created_at', ascending: false)
          .map((event) => event.map((e) => e).toList());
    });
  }

  void submitMessage() {
    /*
      calls function in chats provider to create a new record in the chat

      Params: none
      
      Returns: none
    */
    if (widget.groupInfo == null) {
      if (_controller.text.trim().isNotEmpty) {
        ref
            .read(chatsProvider.notifier)
            .sendMessage(widget.currentUser, widget.chatterUser!.friendProfileId, _controller.text);
        _controller.clear();
      }
    } else {
      if (_controller.text.trim().isNotEmpty) {
        ref.read(chatsProvider.notifier).sendGroupMessage(widget.groupInfo!['group_id'], _controller.text);
        _controller.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: widget.groupInfo != null
            ? GestureDetector(
                onTap: () {
                  setState(() {
                    _showMemberList = !_showMemberList;
                  });
                },
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.groupInfo?['title'] ?? 'Unknown',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(_showMemberList ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.chatterUser?.avatar ?? ''),
                    radius: 20,
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatterUser!.friendProfileName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        "@${widget.chatterUser!.friendUsername}",
                        style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          if (widget.groupInfo != null && _showMemberList) GroupMembersList(members: userIdAndAvatar ?? []),
          Expanded(
            child: _chatStream != null
                ? StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _chatStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data!.length,
                          controller: _scrollController,
                          itemBuilder: (context, index) {
                            var message = snapshot.data![index];
                            var avatar;
                            if (widget.chatterUser != null) {
                              avatar = widget.chatterUser?.avatar;
                            } else {
                              for (var image in userIdAndAvatar!) {
                                if (image['id'] == message['sender_id']) {
                                  avatar = image['avatar'];
                                  break;
                                }
                              }
                            }
                            return MessageWidget(
                                message: message, otherAvatar: avatar, currentUser: widget.currentUser);
                          },
                        );
                      } else {
                        return const Center(child: Text('No messages yet.'));
                      }
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onSubmitted: (value) => submitMessage(),
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                FloatingActionButton(
                  mini: true,
                  child: Icon(Icons.send),
                  onPressed: () {
                    submitMessage();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class GroupMembersList extends ConsumerWidget {
  final List<dynamic> members;

  const GroupMembersList({Key? key, required this.members}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<String> getUsername(String id) async {
      var profile = await ref.read(profileProvider.notifier).fetchProfileById(id);
      return profile.username;
    }

    return Container(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              'Group Chat Members',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          SizedBox(
            height: 125, // Adjust as needed
            child: ListView.builder(
              itemCount: members.length,
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(member['avatar']),
                  ),
                  title: FutureBuilder<String>(
                    future: getUsername(member['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text('Loading...'); // or a CircularProgressIndicator
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Text(
                          snapshot.data ?? 'Unknown',
                          overflow: TextOverflow.ellipsis,
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
