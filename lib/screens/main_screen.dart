import 'package:flutter/material.dart';
import 'package:flutter_travel/screens/home.dart';
import 'package:flutter_travel/screens/itinerary_page.dart';
import 'package:flutter_travel/screens/liked_places_page.dart';
import 'package:flutter_travel/screens/map_page.dart';
import 'package:flutter_travel/screens/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _page = 0;
  final GlobalKey<LikedPlacesPageState> _likedPageKey =
      GlobalKey<LikedPlacesPageState>();
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = const <Widget>[
      DiscoverPage(),
      ItineraryPage(),
      MapPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = <Widget>[
      _screens[0],
      _screens[1],
      _screens[2],
      LikedPlacesPage(key: _likedPageKey),
      _screens[3],
    ];
    return Scaffold(
      body: IndexedStack(
        index: _page,
        children: screens,
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
            label: '发现',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note),
            label: '行程',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: '地图',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: '喜欢',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void navigationTapped(int page) {
    FocusScope.of(context).unfocus();
    setState(() {
      _page = page;
    });
    if (page == 3) {
      _likedPageKey.currentState?.refreshLikedPlaces();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
