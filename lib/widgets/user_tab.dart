import 'package:flutter/material.dart';
import 'package:nomo/models/user_model.dart';

class UserTab extends StatelessWidget {
  const UserTab({super.key, required this.userData});

  final User userData;

  @override
  Widget build(BuildContext context) {
    var username = userData.username;
    var avatar = userData.avatar;
    var calendar = userData.availability;

    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(
          radius: 25,
          backgroundImage: avatar.image,
        ),
        SizedBox(width: 10),
        Text(username),
        Spacer(),
        ElevatedButton(onPressed: () {}, child: const Text("View Calendar")),
      ]),
    );
  }
}
