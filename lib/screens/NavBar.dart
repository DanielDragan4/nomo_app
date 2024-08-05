import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/calendar_screen.dart';
import 'package:nomo/screens/friends/friends_screen.dart';
import 'package:nomo/screens/profile/profile_screen.dart';
import 'package:nomo/screens/recommended_screen.dart';
import 'package:nomo/screens/search_screen.dart';

class NavBar extends ConsumerStatefulWidget {
  const NavBar({super.key});

  @override
  ConsumerState<NavBar> createState() => _NavBarState();
}

class _NavBarState extends ConsumerState<NavBar> {
  int _index = 0;

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
    }
  }

  bool _handlePopScope() {
    final isFirstRouteInCurrentTab = !(_navigatorKeys[_index].currentState?.canPop() ?? false);
    if (isFirstRouteInCurrentTab) {
      if (_index != 0) {
        setState(() {
          _index = 0;
        });
        return false;
      }
    } else {
      _navigatorKeys[_index].currentState?.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    var navBarTheme = Theme.of(context).bottomNavigationBarTheme;
    ref.read(profileProvider.notifier).decodeData();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handlePopScope();
      },
      child: Scaffold(
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
        body: Stack(
          children: List.generate(_navigatorKeys.length, (index) {
            return _buildOffstageNavigator(index);
          }),
        ),
      ),
    );
  }

  Widget _buildOffstageNavigator(int index) {
    return Offstage(
      offstage: _index != index,
      child: Navigator(
        key: _navigatorKeys[index],
        onGenerateRoute: (routeSettings) {
          return MaterialPageRoute(
            builder: (context) => _buildPage(index),
          );
        },
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return RecommendedScreen();
      case 1:
        return SearchScreen(
          searchingPeople: false,
        );
      case 2:
        return CalendarScreen();
      case 3:
        return FriendsScreen(isGroupChats: false);
      case 4:
        return ProfileScreen(isUser: true);
      default:
        return Container();
    }
  }
}
