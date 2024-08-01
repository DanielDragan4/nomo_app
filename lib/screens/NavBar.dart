import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/calendar_screen.dart';
import 'package:nomo/screens/friends_screen.dart';
import 'package:nomo/screens/new_event_screen.dart';
import 'package:nomo/screens/profile_screen.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'package:nomo/screens/search_screen.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key});

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  int _index = 0;
  final PageController _pageController = PageController();

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onItemTapped(int index) {
    if (index == _index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _index = index;
      });
      _pageController.jumpToPage(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    var navBarTheme = Theme.of(context).bottomNavigationBarTheme;
    ref.read(profileProvider.notifier).decodeData();

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available_outlined, color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.event_available, color: navBarTheme.selectedItemColor),
            label: "Events",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded, color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.search_rounded, color: navBarTheme.selectedItemColor),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined, color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.calendar_month, color: navBarTheme.selectedItemColor),
            label: "Calendar",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined, color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.people, color: navBarTheme.selectedItemColor),
            label: "Friends",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined, color: navBarTheme.unselectedItemColor),
            activeIcon: Icon(Icons.person_2, color: navBarTheme.selectedItemColor),
            label: "Profile",
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _index = index;
          });
        },
        children: [
          _buildPage(const RecommendedScreen(), _navigatorKeys[0]),
          _buildPage(const SearchScreen(), _navigatorKeys[1]),
          _buildPage(const CalendarScreen(), _navigatorKeys[2]),
          _buildPage(const FriendsScreen(isGroupChats: false), _navigatorKeys[3]),
          _buildPage(ProfileScreen(isUser: true), _navigatorKeys[4]),
        ],
      ),
    );
  }

  Widget _buildPage(Widget child, GlobalKey<NavigatorState> navigatorKey) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => child,
        );
      },
    );
  }
}
