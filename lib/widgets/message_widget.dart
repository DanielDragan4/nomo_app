import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MessageWidget extends ConsumerWidget {
  const MessageWidget(
      {super.key, required this.message, required this.currentUser});

  final message;
  final currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = message['sender_id'] == currentUser;

    if(message.isNotEmpty)
    {return Container(
        child: Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *.8
        ),
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,  
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          message['message'],
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
          ),
        ),
      ),
    ));}
    else {
      return Container();
    }
  }
}
