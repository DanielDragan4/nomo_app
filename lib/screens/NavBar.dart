import 'package:flutter/material.dart';
import 'package:nomo/screens/calendar_screen.dart';
import 'package:nomo/screens/friends_screen.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:nomo/screens/profile_screen.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'package:nomo/auth_service.dart';

class NavBar extends StatefulWidget {
  NavBar({super.key});

  @override
  State<NavBar> createState() => _NavBarState();

  final AuthService authService = AuthService();

  // ... home screen content

  Future<void> signOut() async {
    await authService.signOut();
  }
}

class _NavBarState extends State<NavBar> {
  int _index = 0;
  final _pageViewController = PageController(initialPage: 0);

  @override
  Widget build(BuildContext context) {
    var navBarTheme = Theme.of(context).bottomNavigationBarTheme;

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: navBarTheme.backgroundColor,
        currentIndex: _index,
        onTap: (index) {
          _pageViewController.jumpToPage(index);
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
            label: 'New Event',
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_outlined,
                  color: navBarTheme.unselectedItemColor),
              activeIcon: Icon(Icons.calendar_month,
                  color: navBarTheme.selectedItemColor),
              label: "Calendar"),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined,
                  color: navBarTheme.unselectedItemColor),
              activeIcon:
                  Icon(Icons.people, color: navBarTheme.selectedItemColor),
              label: "Friends"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined,
                  color: navBarTheme.unselectedItemColor),
              activeIcon:
                  Icon(Icons.person_2, color: navBarTheme.selectedItemColor),
              label: "Profile"),
        ],
      ),
      body: PageView(
        controller: _pageViewController,
        onPageChanged: (index) {
          setState(() {
            _index = index;
          });
        },
        children: [
          RecommendedScreen(),
          NewEventScreen(),
          CalendarScreen(),
          FriendsScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}
