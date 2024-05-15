import 'package:flutter/material.dart';
import 'package:nomo/widgets/app_bar.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  createState() {
    return _SettingScreenState();
  }
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            padding: const EdgeInsets.only(
              top: 20,
              bottom: 5,
            ),
            alignment: Alignment.bottomCenter,
            child: Text('Settings',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w400,
                  fontSize: 30,
                )),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          OutlinedButton(
            onPressed: () {},
            style: ButtonStyle(
              alignment: Alignment.centerLeft,
              padding: MaterialStateProperty.all<EdgeInsets>(
                  const EdgeInsets.only(left: 40)),
              shape: MaterialStateProperty.all(const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)))),
            ),
            child: const Text(
              "Account",
              style: TextStyle(fontSize: 25),
            ),
          ),
        ],
      ),
    );
  }
}
