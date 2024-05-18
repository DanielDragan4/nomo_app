import 'package:flutter/material.dart';

class Help extends StatefulWidget {
  Help({super.key});

  @override
  State<Help> createState() {
    return _HelpState();
  }
}

class _HelpState extends State<Help> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const ListTile(
            title: Text("This is where Helpful Info and Links will be:",
                style: TextStyle(fontSize: 25))),
        ListTile(title: Text("Helpful Link X", style: TextStyle(fontSize: 20))),
        ListTile(title: Text("Helpful Link Y", style: TextStyle(fontSize: 20))),
        ListTile(title: Text("Helpful Link Z", style: TextStyle(fontSize: 20))),
        const Divider(),
        ListTile(
          leading: Text("Contact Us", style: TextStyle(fontSize: 15)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          title: const Text(
            "Nomo",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16.0, color: Colors.grey),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "Some Address, Metuchen NJ, 08840",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.phone, size: 16.0, color: Colors.grey),
                  SizedBox(width: 8.0),
                  Text(
                    "732-111-1111",
                    style: TextStyle(fontSize: 16.0),
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(Icons.email, size: 16.0, color: Colors.grey),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      "nomo.support@gmail.com",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          //Probably Automatically Link to Email
          onTap: () {},
        )
      ],
    );
  }
}
