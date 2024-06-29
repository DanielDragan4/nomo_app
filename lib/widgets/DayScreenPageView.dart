import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/screens/calendar/day_screen.dart'; // Ensure you import your DayScreen widget
import 'package:nomo/models/availability_model.dart';

class DayScreenPageView extends ConsumerStatefulWidget {
  final DateTime initialDay;
  final List<Availability> blockedTime;

  DayScreenPageView({required this.initialDay, required this.blockedTime});

  @override
  _DayScreenPageViewState createState() => _DayScreenPageViewState();
}

class _DayScreenPageViewState extends ConsumerState<DayScreenPageView> {
  late PageController _pageController;
  late DateTime _currentDay;
  final int initialPage = 1000; // Arbitrary large number to allow for swiping

  @override
  void initState() {
    super.initState();
    _currentDay = widget.initialDay;
    _pageController = PageController(initialPage: initialPage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (int index) {
          setState(() {
            _currentDay = widget.initialDay.add(Duration(days: index - initialPage));
          });
        },
        itemBuilder: (context, index) {
          final day = widget.initialDay.add(Duration(days: index - initialPage));
          return DayScreen(day: day, blockedTime: widget.blockedTime);
        },
      ),
    );
  }
}
