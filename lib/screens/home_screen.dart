import 'package:flutter/material.dart';
import 'package:nomo/widgets/event_tab.dart';
import 'package:nomo/data/dummy_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final _pageViewController = PageController(initialPage: 1);

    var navBarTheme = Theme.of(context).bottomNavigationBarTheme;

    int _index = 0;

    return Scaffold(
      appBar: AppBar(
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        title: Center(child: Text('Nomo', style: TextStyle(color: Theme.of(context).primaryColor),),),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                EventTab(
                  eventsData: dummyEvents[0],
                ),
                EventTab(
                  eventsData: dummyEvents[1],
                ),
                EventTab(
                  eventsData: dummyEvents[2],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).primaryColorLight.withOpacity(0.6),
        currentIndex: _index,
        onTap: (index) {
          _pageViewController.animateToPage(index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.decelerate);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined,
                color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.event_available,
                color: navBarTheme.selectedItemColor),
            label: "Events",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined,
                  color: navBarTheme.unselectedItemColor),
              activeIcon:
                  Icon(Icons.add_box, color: navBarTheme.selectedItemColor),
              label: 'New Event'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined,
                  color: navBarTheme.unselectedItemColor),
              activeIcon:
                  Icon(Icons.person_2, color: navBarTheme.selectedItemColor),
              label: "Profile"),
        ],
      ),
    );
  }
}
