import 'package:flutter/material.dart';

import 'home_tab.dart';
import '../profile/profile_tab.dart';
import '../bookings/bookings_tab.dart';
import '../events/events_tab.dart';
// ignore: unused_import
import '../common/coming_soon_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeTab(),
      const BookingsTab(),
      const EventsTab(),
      const Placeholder(),
      const ProfileTab(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (i == 2) {
            Navigator.of(
              context,
            ).pushNamed('/coming-soon', arguments: {'title': 'Events'});
            return;
          }
          if (i == 3) {
            Navigator.of(
              context,
            ).pushNamed('/coming-soon', arguments: {'title': 'History'});
            return;
          }
          setState(() => index = i);
        },
        backgroundColor: const Color(0xFF101010),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(.6),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month_outlined),
            activeIcon: Icon(Icons.calendar_month),
            label: 'Booking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.celebration_outlined),
            activeIcon: Icon(Icons.celebration),
            label: 'Event',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
