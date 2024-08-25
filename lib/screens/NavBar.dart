import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nomo/providers/profile_provider.dart';
import 'package:nomo/screens/calendar/calendar_screen.dart';
import 'package:nomo/screens/events/event_creation.dart';
import 'package:nomo/screens/events/event_creation.dart';
import 'package:nomo/screens/events/new_event_screen.dart';
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _handlePopScope();
      },
      child: Scaffold(
        bottomNavigationBar: Container(
          height: 75, // Reduce the overall height
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(0, Icons.event_available_outlined, Icons.event_available, 'Events'),
                  _buildNavItem(1, Icons.search_rounded, Icons.search_rounded, 'Search'),
                  SizedBox(width: 60), // Space for the center button
                  _buildNavItem(3, Icons.people_alt_outlined, Icons.people, 'Friends'),
                  _buildNavItem(4, Icons.person_2_outlined, Icons.person_2, 'Profile'),
                ],
              ),
              Positioned(
                top: 5, // Adjust this value to raise the button
                left: 0,
                right: 0,
                child: _buildCenterButton(),
              ),
            ],
          ),
        ),
        body: Stack(
          children: List.generate(_navigatorKeys.length, (index) {
            return _buildOffstageNavigator(index);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    bool isSelected = _index == index;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            height: 24,
            child: IconButton(
              icon: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected
                    ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                    : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
                size: 24,
              ),
              onPressed: () => _onItemTapped(index),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(), // Remove constraints
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).bottomNavigationBarTheme.selectedItemColor
                : Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
            fontSize: 14, // Smaller font size
          ),
        ),
      ],
    );
  }

  Widget _buildCenterButton() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
      child: Center(
        child: IconButton(
          icon: Icon(
            Icons.add_circle_outline_outlined,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () => _onItemTapped(2),
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
        return SearchScreen(searchingPeople: false);
      case 2:
        return EventCreateScreen(); //NewEventScreen();
      case 3:
        return FriendsScreen(isGroupChats: false);
      case 4:
        return ProfileScreen(isUser: true);
      default:
        return Container();
    }
  }
}
