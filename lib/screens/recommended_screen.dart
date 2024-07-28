import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/events_provider.dart';
import 'package:nomo/providers/notification-bell_provider.dart';
import 'package:nomo/screens/notifications_screen.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/functions/image-handling.dart';

class RecommendedScreen extends ConsumerStatefulWidget {
  const RecommendedScreen({super.key});

  @override
  ConsumerState<RecommendedScreen> createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends ConsumerState<RecommendedScreen> {
  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    await ref.read(eventsProvider.notifier).deCodeData();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref.read(eventsProvider.notifier).deCodeData();
  }

  @override
  Widget build(BuildContext context) {
    final hasUnreadNotifications = ref.watch(notificationBellProvider);
    //Start on friends list. If false, show requests list

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: NestedScrollView(
          floatHeaderSlivers: true,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              toolbarHeight: kToolbarHeight + 30,
              backgroundColor: Theme.of(context).colorScheme.surface,
              floating: true,
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  child: Padding(
                    padding:
                        EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20), // Add padding above the title
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Nomo',
                              style: TextStyle(
                                fontFamily: 'alice', //GoogleFonts.alice,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 30,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => const NotificationsScreen(),
                                ));

                                // Mark notifications as read when notifications icon is tapped
                                ref.read(notificationBellProvider.notifier).setBellState(false);
                              },
                              icon: hasUnreadNotifications
                                  ? Icon(
                                      Icons.notifications_active,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : Icon(
                                      Icons.notifications_none,
                                      color: Theme.of(context).colorScheme.onSecondary,
                                    ),
                              iconSize: MediaQuery.of(context).devicePixelRatio * 10,
                              //padding: const EdgeInsets.only(top: 10, bottom: 10, left: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              centerTitle: true,
            ),
          ],
          body: RefreshIndicator(
            onRefresh: () => _onRefresh(context, ref),
            child: StreamBuilder(
              stream: ref.read(eventsProvider.notifier).stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final events = snapshot.data!;
                  // Preload the first few images
                  preloadImages(context, events, 0, 5);

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    key: const PageStorageKey<String>('page'),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      // Preload next few images when nearing the end of the list
                      if (index % 5 == 0) {
                        preloadImages(context, events, index + 1, 5);
                      }

                      return EventTab(
                        eventData: events[index],
                        preloadedImage: NetworkImage(events[index].imageUrl),
                      );
                    },
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
      ),
    );
  }
}
