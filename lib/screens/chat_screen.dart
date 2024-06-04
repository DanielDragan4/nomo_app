import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/models/message_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/supabase_provider.dart';
import 'package:nomo/widgets/message_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends ConsumerStatefulWidget {
  ChatScreen(
      {super.key, this.chatterUser, required this.currentUser, this.groupInfo});
  final Friend? chatterUser;
  final String currentUser;
  Map? groupInfo;

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<List<Map<String, dynamic>>>? _chatStream;
  late final state;

  @override
  void initState() {
    super.initState();
    if (widget.groupInfo == null) {
      _initializeChatStream();
    } else {
      _initializeGroupChatStream();
    }
  }

  Future<void> _initializeChatStream() async {
    final supabaseClient =
        Supabase.instance.client; // Ensure the client is initialized correctly
    final chatID = await ref
        .read(chatsProvider.notifier)
        .readChatId(widget.currentUser, widget.chatterUser!.friendProfileId);
    setState(() {
      _chatStream = supabaseClient
          .from('Messages')
          .stream(primaryKey: ['id']) // Ensure the primary key is specified
          .eq('chat_id', chatID)
          .order('created_at', ascending: false)
          .map((event) => event.map((e) => e as Map<String, dynamic>).toList());
    });
  }

  Future<void> _initializeGroupChatStream() async {
    final supabaseClient =
        Supabase.instance.client; // Ensure the client is initialized correctly
    setState(() {
      _chatStream = supabaseClient
          .from('Group_Messages')
          .stream(primaryKey: ['group_message_id']) // Ensure the primary key is specified
          .eq('group_id', widget.groupInfo!['group_id']!)
          .order('created_at', ascending: false)
          .map((event) => event.map((e) => e as Map<String, dynamic>).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text((widget.groupInfo == null)
            ? widget.chatterUser!.friendProfileName
            : widget.groupInfo!['title']),
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
                            return MessageWidget(
                                message: message,
                                currentUser: widget.currentUser);
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
                    controller: _controller,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                    decoration: InputDecoration(
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSecondary,
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
                    if (widget.groupInfo == null) {
                      if (_controller.text.trim().isNotEmpty) {
                        ref.read(chatsProvider.notifier).sendMessage(
                            widget.currentUser,
                            widget.chatterUser!.friendProfileId,
                            _controller.text);
                        _controller.clear();
                      }
                    } else {
                      if (_controller.text.trim().isNotEmpty) {
                        ref.read(chatsProvider.notifier).sendGroupMessage(
                            widget.groupInfo!['group_id'],
                            _controller.text);
                        _controller.clear();
                      }
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
