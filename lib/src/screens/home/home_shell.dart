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

enum _TabType { home, booking, event, reservations, profile }

class _TabConfig {
  const _TabConfig({
    required this.page,
    required this.item,
    required this.type,
  });

  final Widget page;
  final BottomNavigationBarItem item;
  final _TabType type;
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    final tabs = _buildTabs(isAdmin: isAdmin, loc: loc);
    if (index >= tabs.length) {
      index = tabs.length - 1;
    }
    final profileIndex = tabs.indexWhere((t) => t.type == _TabType.profile);
    if (!isLoggedIn && profileIndex != -1 && index == profileIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && index == profileIndex) {
          setState(() => index = 0);
        }
      });
    }

    final eventIndex = tabs.indexWhere((t) => t.type == _TabType.event);

    return Scaffold(
      body: SafeArea(child: tabs[index].page),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (eventIndex != -1 && i == eventIndex) {
            Navigator.of(
              context,
            ).pushNamed('/coming-soon', arguments: {'title': loc.t('nav_event', fallback: 'Event')});
            return;
          }
          if (!isLoggedIn && profileIndex != -1 && i == profileIndex) {
            Navigator.of(context).pushNamed(AppRoutes.login);
            return;
          }
          setState(() => index = i);
        },
        backgroundColor: const Color(0xFF101010),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(.6),
        type: BottomNavigationBarType.fixed,
        items: tabs.map((t) => t.item).toList(growable: false),
      ),
    );
  }
}

List<_TabConfig> _buildTabs({
  required bool isAdmin,
  required LocalizationService loc,
}) {
  if (isAdmin) {
    return [
      _TabConfig(
        page: const AdminReservationsPage(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.event_note_outlined),
          activeIcon: const Icon(Icons.event_note),
          label: loc.t('nav_reservations', fallback: 'Reservations'),
        ),
        type: _TabType.reservations,
      ),
      _TabConfig(
        page: const BookingsTab(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          activeIcon: const Icon(Icons.calendar_month),
          label: loc.t('nav_booking', fallback: 'Booking'),
        ),
        type: _TabType.booking,
      ),
      _TabConfig(
        page: const HomeTab(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.home_outlined),
          activeIcon: const Icon(Icons.home),
          label: loc.t('nav_home', fallback: 'Home'),
        ),
        type: _TabType.home,
      ),
      _TabConfig(
        page: const EventsTab(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.celebration_outlined),
          activeIcon: const Icon(Icons.celebration),
          label: loc.t('nav_event', fallback: 'Event'),
        ),
        type: _TabType.event,
      ),
      _TabConfig(
        page: const ProfileTab(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: loc.t('nav_profile', fallback: 'Profile'),
        ),
        type: _TabType.profile,
      ),
    ];
  }

  return [
    _TabConfig(
      page: const HomeTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: loc.t('nav_home', fallback: 'Home'),
      ),
      type: _TabType.home,
    ),
    _TabConfig(
      page: const BookingsTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.calendar_month_outlined),
        activeIcon: const Icon(Icons.calendar_month),
        label: loc.t('nav_booking', fallback: 'Booking'),
      ),
      type: _TabType.booking,
    ),
    _TabConfig(
      page: const EventsTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.celebration_outlined),
        activeIcon: const Icon(Icons.celebration),
        label: loc.t('nav_event', fallback: 'Event'),
      ),
      type: _TabType.event,
    ),
    _TabConfig(
      page: const ProfileTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: loc.t('nav_profile', fallback: 'Profile'),
      ),
      type: _TabType.profile,
    ),
  ];
}
