import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_tab.dart';
import '../profile/profile_tab.dart';
import '../bookings/bookings_tab.dart';
import '../events/events_tab.dart';
import '../admin/admin_reservations_page.dart';
import '../../services/localization_service.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    final pages = [
      const HomeTab(),
      const BookingsTab(),
      const EventsTab(),
      if (isAdmin) const AdminReservationsPage(),
      const ProfileTab(),
    ];
    if (index >= pages.length) {
      index = pages.length - 1;
    }
    if (!isLoggedIn && index == pages.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && index == pages.length - 1) {
          setState(() => index = 0);
        }
      });
    }

    final eventIndex = 2;
    final reservationsIndex = isAdmin ? 3 : null;
    final profileIndex = isAdmin ? 4 : 3;

    return Scaffold(
      body: SafeArea(child: pages[index]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (i == eventIndex) {
            Navigator.of(
              context,
            ).pushNamed('/coming-soon', arguments: {'title': loc.t('nav_event', fallback: 'Event')});
            return;
          }
          if (reservationsIndex != null && i == reservationsIndex && !isAdmin) {
            return;
          }
          if (i == profileIndex && !isLoggedIn) {
            Navigator.of(context).pushNamed(AppRoutes.login);
            return;
          }
          setState(() => index = i);
        },
        backgroundColor: const Color(0xFF101010),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(.6),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: loc.t('nav_home', fallback: 'Home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_month_outlined),
            activeIcon: const Icon(Icons.calendar_month),
            label: loc.t('nav_booking', fallback: 'Booking'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.celebration_outlined),
            activeIcon: const Icon(Icons.celebration),
            label: loc.t('nav_event', fallback: 'Event'),
          ),
          if (isAdmin)
            BottomNavigationBarItem(
              icon: const Icon(Icons.event_note_outlined),
              activeIcon: const Icon(Icons.event_note),
              label: loc.t('nav_reservations', fallback: 'Reservations'),
            ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: loc.t('nav_profile', fallback: 'Profile'),
          ),
        ],
      ),
    );
  }
}
