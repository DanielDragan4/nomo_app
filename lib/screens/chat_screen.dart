import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/main.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/widgets/message_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nomo/providers/chat_id_provider.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.groupInfo == null) {
      _initializeChatStream();
      _fetchChatID();
    } else {
      _initializeGroupChatStream();
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
        title: Text((widget.groupInfo == null) ? widget.chatterUser!.friendProfileName : widget.groupInfo!['title']),
      ),
      body: Column(
        children: [
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
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                      ),
                      hintText: 'Send message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width * .01),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    submitMessage();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.04,
          )
        ],
      ),
    );
  }
}
