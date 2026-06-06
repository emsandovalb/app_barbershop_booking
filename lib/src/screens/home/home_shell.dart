import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_reservations_page.dart';
import '../bookings/bookings_tab.dart';
import '../grounds/filtered_courts_page.dart';
import '../profile/profile_tab.dart';
import 'home_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _TabType { home, services, bookings, reservations, profile }

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
    final config = context.watch<AppConfig>();
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;
    final tabs = _buildTabs(isAdmin: isAdmin, config: config);

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

    return Scaffold(
      body: SafeArea(child: tabs[index].page),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (!isLoggedIn && profileIndex != -1 && i == profileIndex) {
            Navigator.of(context).pushNamed('/login');
            return;
          }
          setState(() => index = i);
        },
        backgroundColor: config.brand.backgroundColor,
        selectedItemColor: config.brand.primaryColor,
        unselectedItemColor: Colors.white.withValues(alpha: .58),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: tabs.map((t) => t.item).toList(growable: false),
      ),
    );
  }
}

List<_TabConfig> _buildTabs({
  required bool isAdmin,
  required AppConfig config,
}) {
  final tabs = <_TabConfig>[
    _TabConfig(
      page: const HomeTab(),
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      type: _TabType.home,
    ),
    _TabConfig(
      page: const FilteredCourtsPage(title: 'Servicios'),
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.content_cut_outlined),
        activeIcon: Icon(Icons.content_cut),
        label: 'Servicios',
      ),
      type: _TabType.services,
    ),
    if (config.features.showReservations)
      _TabConfig(
        page: const BookingsTab(),
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Reservas',
        ),
        type: _TabType.bookings,
      ),
    if (config.features.showAdminReservations && isAdmin)
      _TabConfig(
        page: const AdminReservationsPage(),
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.event_note_outlined),
          activeIcon: Icon(Icons.event_note),
          label: 'Citas',
        ),
        type: _TabType.reservations,
      ),
    _TabConfig(
      page: const ProfileTab(),
      item: const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
      type: _TabType.profile,
    ),
  ];

  return tabs;
}
