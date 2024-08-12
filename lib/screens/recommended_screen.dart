import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:nomo/models/events_model.dart';
import 'package:nomo/providers/event-providers/events_provider.dart';
import 'package:nomo/providers/notification-providers/notification-bell-provider.dart';
import 'package:nomo/screens/notifications_screen.dart';
import 'package:nomo/screens/password_handling/login_screen.dart';
import 'package:nomo/screens/search_screen.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/functions/image-handling.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecommendedScreen extends ConsumerStatefulWidget {
  const RecommendedScreen({super.key});

  @override
  ConsumerState<RecommendedScreen> createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends ConsumerState<RecommendedScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<bool> selectedDays = List.generate(7, (_) => false);
  double maxDistance = 50.0; // Default max distance in miles
  bool filtersSet = false;

  Future<void> _onRefresh(BuildContext context, WidgetRef ref) async {
    if (!filtersSet) {
      await ref.read(eventsProvider.notifier).deCodeData();
    } else {
      ref.read(eventsProvider.notifier).applyFilters(
            startDate: startDate,
            endDate: endDate,
            selectedDays: selectedDays,
            maxDistance: maxDistance,
          );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (!filtersSet) {
      ref.read(eventsProvider.notifier).deCodeData();
    }
    //setFilterDistance();
  }

  // Future<void> setFilterDistance() async {
  //   final getLocation = await SharedPreferences.getInstance();
  //   final setRadius = getLocation.getStringList('savedRadius');
  //   final _preferredRadius = double.parse(setRadius!.first);
  //   if (_preferredRadius != null) maxDistance = _preferredRadius;
  // }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Filter Events", style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSecondaryContainer),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).cardColor,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _buildDateRangePicker(setState),
                    SizedBox(height: 16),
                    _buildDayOfWeekFilter(setState),
                    SizedBox(height: 16),
                    _buildDistanceSlider(setState),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Clear"),
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                      selectedDays = List.generate(7, (_) => false);
                      maxDistance = 50.0;
                      filtersSet = false;
                    });
                  },
                ),
                TextButton(
                  child: Text("Apply"),
                  onPressed: () {
                    setState(() {
                      filtersSet = true;
                    });
                    Navigator.of(context).pop();
                    _applyFilters();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateRangePicker(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date Range"),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = picked;
                    });
                  }
                },
                child: Text(
                  startDate != null ? DateFormat.yMd().format(startDate!.toLocal()) : "Start Date",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? (startDate ?? DateTime.now()),
                    firstDate: startDate ?? DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      endDate = picked;
                    });
                  }
                },
                child: Text(
                  endDate != null ? DateFormat.yMd().format(endDate!.toLocal()) : "End Date",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayOfWeekFilter(StateSetter setState) {
    final days = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Days of Week"),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            return FilterChip(
              label: Text(days[index]),
              selected: selectedDays[index],
              onSelected: (bool selected) {
                setState(() {
                  selectedDays[index] = selected;
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDistanceSlider(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Maximum Distance",
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            Text(
              "${maxDistance.round()} miles",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: maxDistance,
          min: 0,
          max: 100,
          divisions: 100,
          label: maxDistance.round().toString(),
          onChanged: (double value) {
            setState(() {
              maxDistance = value;
            });
          },
        ),
      ],
    );
  }

  void _applyFilters() {
    ref.read(eventsProvider.notifier).applyFilters(
          startDate: startDate,
          endDate: endDate,
          selectedDays: selectedDays,
          maxDistance: maxDistance,
        );
    //ref.read(eventsProvider.notifier).deCodeData();
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
              toolbarHeight: kToolbarHeight + 55,
              backgroundColor: Theme.of(context).colorScheme.surface,
              floating: true,
              snap: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  child: Padding(
                    padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                GestureDetector(
                                    onTap: () {
                                      _onRefresh(context, ref);
                                    },
                                    child: Image.asset('assets/images/logo.png', height: 40)),
                                SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  'nomo',
                                  style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontSize: MediaQuery.of(context).devicePixelRatio * 10,
                                      fontFamily: 'fff',
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _showFilterDialog,
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: Theme.of(context).colorScheme.onSecondary,
                                  ),
                                  iconSize: MediaQuery.of(context).devicePixelRatio * 8,
                                  tooltip: 'Filters',
                                ),
                                SizedBox(width: 16), // Add some space between icons
                                IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ));
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
                                  iconSize: MediaQuery.of(context).devicePixelRatio * 8,
                                ),
                              ],
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
