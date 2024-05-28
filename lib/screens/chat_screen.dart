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
  var chatInfo;

  @override
  void initState() {
    ref.read(chatsProvider.notifier).getChatStream(widget.currentUser, widget.chatterUser.friendProfileId);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
            child: Text(widget.chatterUser.friendProfileName,
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
          Expanded(
            child: StreamBuilder(
              stream: ref.read(chatsProvider.notifier).stream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if(snapshot.data != null){
                  return ListView(
                  controller: _scrollController,
                  children: [
                    for(var message in snapshot.data!) MessageWidget(message: message, currentUser: widget.currentUser)
                  ],
                  // itemBuilder: (context, index) {
                  //   final message = snapshot.data![index];
                  //   print(message);
                  //   final isMe = message['sender_id'] == widget.currentUser;
                  //   return Align(
                  //     alignment:
                  //         isMe ? Alignment.centerRight : Alignment.centerLeft,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //           vertical: 8.0, horizontal: 16.0),
                  //       margin: const EdgeInsets.symmetric(
                  //           vertical: 4.0, horizontal: 16.0),
                  //       decoration: BoxDecoration(
                  //         color: isMe
                  //             ? Colors.blueAccent
                  //             : Colors.grey.shade300,
                  //         borderRadius: BorderRadius.circular(8.0),
                  //       ),
                  //       child: Text(
                  //         message['message'],
                  //         style: TextStyle(
                  //           color: isMe ? Colors.white : Colors.black87,
                  //         ),
                  //       ),
                  //     ),
                  //   );
                  // },
                );}
                else {
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
                     //_sendMessage(_controller.text.trim());
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
