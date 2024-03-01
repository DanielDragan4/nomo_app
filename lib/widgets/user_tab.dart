import 'package:flutter/material.dart';
import 'package:nomo/models/user_model.dart';

class UserTab extends StatelessWidget {
  const UserTab({super.key, required this.userData, required this.isRequest});

  final bool isRequest;
  final User userData;

  @override
  Widget build(BuildContext context) {
    var username = userData.username;
    var avatar = userData.avatar;
    var calendar = userData.availability;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: avatar.image,
        ),
        const SizedBox(width: 10),
        Text(username),
        const Spacer(),
        !isRequest
            ? ElevatedButton(
                onPressed: () {}, child: const Text("View Calendar"))
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
