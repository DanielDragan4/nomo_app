import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jiffy/jiffy.dart';

//Widget used to display all message information in DMs (including sender avatar and message contents)
class MessageWidget extends ConsumerWidget {
  const MessageWidget({super.key, required this.message, required this.currentUser, required this.otherAvatar});

  final message;
  final currentUser;
  final String otherAvatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMe = (message['sender_id'] == currentUser);

    if (message.isNotEmpty) {
      return Container(
          width: MediaQuery.of(context).size.width * .85,
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  children: [
                    !isMe
                        ? CircleAvatar(
                            backgroundImage: NetworkImage(otherAvatar),
                          )
                        : SizedBox(
                            child: Text(
                              Jiffy.parseFromDateTime(DateTime.parse(message['created_at'])).fromNow(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.6),
                                fontSize: MediaQuery.of(context).size.width * 0.03,
                              ),
                            ),
                          ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .05,
                    ),
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .8),
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
                  ],
                ),
              ],
            ),
          ));
    } else {
      return Container();
    }
  }
}
