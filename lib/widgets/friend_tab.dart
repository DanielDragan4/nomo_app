import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/friend_model.dart';
import 'package:nomo/providers/chats_provider.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/chat_screen.dart';
import 'package:nomo/screens/profile_screen.dart';

class FreindTab extends ConsumerWidget {
  const FreindTab(
      {super.key, required this.friendData, required this.isRequest});

  final isRequest;
  final Friend friendData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var username = friendData
        .friendUsername; // turn this into provided friend data username
    var avatar = friendData.avatar;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: ((context) => ProfileScreen(
                      isUser: false,
                      userId: friendData.friendProfileId,
                    ))));
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: MediaQuery.of(context).size.width * .1,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 10),
              Text(
                username,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
        ),
        const Spacer(),
        isRequest
            ? Row(
                children: [
                  IconButton(
                    onPressed: ()async{
                      ref.read(profileProvider.notifier).decodeData();
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatterUser: friendData,
                          currentUser: ref
                              .read(profileProvider.notifier)
                              .state
                              !.profile_id,
                        ),
                      ));
                    },
                    icon: Icon(
                      Icons.messenger_outline,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.calendar_month_outlined,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  )
                ],
              )
            : Row(children: [
                IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                    splashRadius: 15),
                const SizedBox(width: 10),
                IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    splashRadius: 15),
              ]),
      ]),
    );
  }
}
