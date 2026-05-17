import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/feedback_page.dart';
import 'package:flutter_travel/screens/home.dart';
import 'package:flutter_travel/screens/itinerary_page.dart';
import 'package:flutter_travel/screens/map_page.dart';
import 'package:flutter_travel/screens/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final PageController _pageController;
  int _page = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _screens = const <Widget>[
      DiscoverPage(),
      ItineraryPage(),
      MapPage(),
      FeedbackPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _page,
        onTap: navigationTapped,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.blueGrey[300],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: 'Itinerary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback_outlined),
            label: 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void navigationTapped(int page) {
    FocusScope.of(context).unfocus();
    _pageController.jumpToPage(page);
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }
}
