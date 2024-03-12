import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/widgets/event_tab.dart';

class RecommendedScreen extends ConsumerWidget {
  const RecommendedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var eventsList = ref.read(eventsProvider.notifier).state;

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
              children: (ref.watch(eventsProvider.notifier).state == null
                  ? [Text("is Empty")]
                  : [for (Event i in eventsList!) EventTab(eventData: i)]),
            ),
          ),
        ],
      ),
    );
  }
}
