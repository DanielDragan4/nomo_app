import 'package:flutter/material.dart';
import 'package:nomo/data/fyp_data.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/widgets/event_tab.dart';

class RecommendedScreen extends StatelessWidget {
  const RecommendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        title: Center(
          child: Column(
            children: [
              Text(
                'Nomo',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Upcoming Events Near You',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w400,
                      )),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search),
                    iconSize: 35,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              key: const PageStorageKey<String>('page'),
              children: [for (Event i in fypEvents) EventTab(eventData: i)],
            ),
          ),
        ],
      ),
    );
  }
}
