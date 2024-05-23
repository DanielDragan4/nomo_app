import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/data/dummy_data.dart';
import 'package:nomo/models/user_model.dart';

class FreindTab extends ConsumerWidget {
  const FreindTab({super.key,  this.friendData,  required this.isRequest});

  final isRequest;
  final friendData;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // var username = friendData.username; // turn this into provided friend data username 
    // var avatar = friendData.avatar;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(
          radius: 25,
          child: dummyFriends.first.avatar,
        ),
        const SizedBox(width: 10),
        Text(
          'Username',
        style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
        ),
        const Spacer(),
        isRequest
            ? Row(
              children: [
                IconButton(onPressed: () {},
                 icon: Icon(Icons.messenger_outline, color: Theme.of(context).colorScheme.onSecondary,),),
                 IconButton(onPressed: () {},
                 icon: Icon(Icons.calendar_month_outlined, color: Theme.of(context).colorScheme.onSecondary,),)
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
