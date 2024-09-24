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
  const RecommendedScreen({
    super.key,
    //this.university
  });
  // final String? university;

  @override
  ConsumerState<RecommendedScreen> createState() => _RecommendedScreenState();
}

class _RecommendedScreenState extends ConsumerState<RecommendedScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<bool> selectedDays = List.generate(7, (_) => false);
  double maxDistance = 50.0; // Default max distance in miles
  bool filtersSet = false;
  DateTime? tempStartDate;
  DateTime? tempEndDate;
  List<bool> tempSelectedDays = List.generate(7, (_) => false);
  double tempMaxDistance = 50.0;

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
    tempStartDate = startDate;
    tempEndDate = endDate;
    tempSelectedDays = List.from(selectedDays);
    tempMaxDistance = maxDistance;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Filter Events",
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
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
                  child: Text("Clear",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: MediaQuery.of(context).size.width / 30)),
                  onPressed: () {
                    setState(() {
                      tempStartDate = null;
                      tempEndDate = null;
                      tempSelectedDays = List.generate(7, (_) => false);
                      tempMaxDistance = 50.0;
                    });
                  },
                ),
                TextButton(
                  child: Text("Apply",
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: MediaQuery.of(context).size.width / 30)),
                  onPressed: () {
                    this.setState(() {
                      startDate = tempStartDate;
                      endDate = tempEndDate;
                      selectedDays = List.from(tempSelectedDays);
                      maxDistance = tempMaxDistance;
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text("Date Range",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: MediaQuery.of(context).size.width / 30,
              )),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        tempStartDate = picked;
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tempStartDate != null ? DateFormat.yMd().format(tempStartDate!.toLocal()) : "From",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: MediaQuery.of(context).size.width / 30,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onSecondary.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: tempEndDate ?? (tempStartDate ?? DateTime.now()),
                      firstDate: tempStartDate ?? DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        tempEndDate = picked;
                      });
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    tempEndDate != null ? DateFormat.yMd().format(tempEndDate!.toLocal()) : "To",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: MediaQuery.of(context).size.width / 30,
                    ),
                  ),
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
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Days of Week",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: MediaQuery.of(context).size.width / 30,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            return FilterChip(
              label: Text(days[index]),
              selected: tempSelectedDays[index],
              onSelected: (bool selected) {
                setState(() {
                  tempSelectedDays[index] = selected;
                });
              },
              checkmarkColor: Theme.of(context).colorScheme.onPrimary,
              selectedColor: Theme.of(context).primaryColorLight,
              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: MediaQuery.of(context).size.width / 30,
              ),
            ),
            Text(
              "${tempMaxDistance.round()} miles",
              style: TextStyle(
                color: Theme.of(context).primaryColorLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: tempMaxDistance,
          min: 0,
          max: 100,
          divisions: 100,
          label: tempMaxDistance.round().toString(),
          onChanged: (double value) {
            setState(() {
              tempMaxDistance = value;
            });
          },
          activeColor: Theme.of(context).primaryColorLight,
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
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: MediaQuery.of(context).devicePixelRatio * 10,
                                      fontFamily: 'Epilogue',
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

                  if (events.isNotEmpty) {
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
                  } else {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'There do not seem to be any events in your area. Try updating your location in the profile page!',
                          style: TextStyle(
                              fontSize: MediaQuery.of(context).devicePixelRatio * 7,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSecondary),
                        ),
                      ),
                    );
                  }
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
