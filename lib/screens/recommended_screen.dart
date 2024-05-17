import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/app_bar.dart';
import 'package:nomo/widgets/event_tab.dart';

class RecommendedScreen extends ConsumerWidget {
  const RecommendedScreen({super.key});

  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    await ref.read(eventsProvider.notifier).deCodeData();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(eventsProvider.notifier).deCodeData();
    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            expandedHeight: 10,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.all(0),
              background: Padding(
                padding: const EdgeInsets.only(
                    top: 35), // Add padding above the title
                child: Center(
                  child: Text(
                    'Upcoming Events',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {Navigator.of(context).push(MaterialPageRoute(builder: ((context) => const SearchScreen())));},
                icon: const Icon(Icons.search),
                iconSize: 35,
                padding: const EdgeInsets.only(top: 20, right: 20),
              ),
            ],
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () => _onRefresh(context, ref),
          child: StreamBuilder(
            stream: ref.read(eventsProvider.notifier).stream,
            builder: (context, snapshot) {
              if (snapshot.data != null) {
                return ListView(
                  key: const PageStorageKey<String>('page'),
                  children: [
                    for (Event i in snapshot.data!) EventTab(eventData: i)
                  ],
                );
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
  }
}
