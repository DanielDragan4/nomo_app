import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/message_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/message_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatterUser, required this.currentUser});
  final Friend chatterUser;
  final String currentUser;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  var _chatStream;
  late final state;

  @override
  void initState() {
    super.initState();
    _initializeChatStream();
  }
  Future<void> getChatStream(String user1Id, String user2Id) async {
  final supabaseClient = Supabase.instance.client; // Ensure the client is initialized correctly
  final chatID = await ref.read(chatsProvider.notifier).readChatId(user1Id, user2Id);
  
  final stream = supabaseClient
    .from('Messages')
    .stream(primaryKey: ['id']) // Ensure the primary key is specified
    .eq('chat_id', chatID)
    .order('created_at', ascending: true);

  state = stream;
}


  Future<void> _initializeChatStream() async {
    await getChatStream(widget.currentUser, widget.chatterUser.friendProfileId);
    setState(() {
      _chatStream = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(widget.chatterUser.friendProfileName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data != null) {
                  return ListView(
                    controller: _scrollController,
                    children: [
                      for (var message in snapshot.data!)
                        MessageWidget(message: message, currentUser: widget.currentUser)
                    ],
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSecondary,),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSecondary,),
                      hintText: 'Send message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width *.01),
                IconButton(
                  icon: Icon(Icons.send, color: Theme.of(context).colorScheme.onSecondary,),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                     ref.read(chatsProvider.notifier).sendMessage(widget.currentUser, widget.chatterUser.friendProfileId, _controller.text);
                       _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
