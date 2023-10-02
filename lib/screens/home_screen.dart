import 'package:flutter/material.dart';

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

    int _index = 1;

    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [SingleChildScrollView()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (index) {
          _pageViewController.animateToPage(index,
              duration: const Duration(milliseconds: 500),
              curve: Curves.decelerate);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book, color: Color.fromARGB(255, 0, 0, 0)),
            label: "History",
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined),
              activeIcon:
                  Icon(Icons.add_box, color: Color.fromARGB(255, 0, 0, 0)),
              label: 'New'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_2_outlined),
              activeIcon:
                  Icon(Icons.person_2, color: Color.fromARGB(255, 0, 0, 0)),
              label: "Profile"),
        ],
      ),
    );
  }
}
