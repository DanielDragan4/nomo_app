import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/widgets/event_tab.dart';

class RecommendedScreen extends ConsumerWidget {
  const RecommendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(eventsProvider.notifier).deCodeData();

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
            child: StreamBuilder(
                stream: ref.watch(eventsProvider.notifier).stream,
                builder: (context, snapshot) {
                  if (snapshot.data != null) {
                    return ListView(
                      key: const PageStorageKey<String>('page'),
                      children: [
                        for (Event i
                            in ref.watch(eventsProvider.notifier).state!)
                          EventTab(eventData: i)
                      ],
                    );
                  } else {
                    return const Text("No Data Retreived");
                  }
                }),
          ),
        ],
      ),
    );
  }
}
