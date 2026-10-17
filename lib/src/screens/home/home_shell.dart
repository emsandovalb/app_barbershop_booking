import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../admin/admin_reservations_page.dart';
import '../bookings/bookings_tab.dart';
import '../grounds/filtered_courts_page.dart';
import '../profile/profile_tab.dart';
import 'home_tab.dart';

class HomeShell extends StatefulWidget {
  final String? initialTab;

  const HomeShell({super.key, this.initialTab});

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
  int _bookingsRefreshVersion = 0;
  int _adminReservationsRefreshVersion = 0;

  @override
  void initState() {
    super.initState();
    index = _initialIndexFromTab(widget.initialTab);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final auth = context.watch<AuthProvider>();
    // Rebuild the tab labels when the language changes.
    context.watch<LocalizationService>();
    final isLoggedIn = auth.isLoggedIn;
    final canManageBusiness = auth.canManageBusiness;
    final tabs = _buildTabs(
      canManageBusiness: canManageBusiness,
      config: config,
      bookingsRefreshVersion: _bookingsRefreshVersion,
      adminReservationsRefreshVersion: _adminReservationsRefreshVersion,
    );

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
      body: SafeArea(
        child: IndexedStack(
          index: index,
          children: tabs.map((t) => t.page).toList(growable: false),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) {
          if (!isLoggedIn && profileIndex != -1 && i == profileIndex) {
            Navigator.of(context).pushNamed('/login');
            return;
          }
          setState(() {
            // IndexedStack keeps every tab alive. Refresh the two views that
            // present server-side reservations whenever the user enters them,
            // otherwise they can retain the request made before a new booking
            // was submitted.
            if (tabs[i].type == _TabType.bookings) {
              _bookingsRefreshVersion++;
            }
            if (tabs[i].type == _TabType.reservations) {
              _adminReservationsRefreshVersion++;
            }
            index = i;
          });
        },
        backgroundColor: config.brand.backgroundColor,
        selectedItemColor: config.brand.primaryColor,
        // Businesses can be light- or dark-themed, so a hardcoded white
        // disappears against a light background — pick the unselected
        // icon color from the background's own brightness instead.
        unselectedItemColor:
            ThemeData.estimateBrightnessForColor(
                  config.brand.backgroundColor,
                ) ==
                Brightness.light
            ? Colors.black.withValues(alpha: .45)
            : Colors.white.withValues(alpha: .58),
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

int _initialIndexFromTab(String? tab) {
  switch (tab?.toLowerCase()) {
    case 'services':
      return 1;
    case 'bookings':
      return 2;
    case 'reservations':
      return 3;
    case 'profile':
      return 4;
    case 'home':
    default:
      return 0;
  }
}

List<_TabConfig> _buildTabs({
  required bool canManageBusiness,
  required AppConfig config,
  required int bookingsRefreshVersion,
  required int adminReservationsRefreshVersion,
}) {
  final tabs = <_TabConfig>[
    _TabConfig(
      page: const HomeTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: tr('nav_home'),
      ),
      type: _TabType.home,
    ),
    _TabConfig(
      page: FilteredCourtsPage(title: tr('nav_services')),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.content_cut_outlined),
        activeIcon: const Icon(Icons.content_cut),
        label: tr('nav_services'),
      ),
      type: _TabType.services,
    ),
    if (config.features.showReservations)
      _TabConfig(
        page: BookingsTab(key: ValueKey('bookings-$bookingsRefreshVersion')),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          activeIcon: const Icon(Icons.calendar_month),
          label: tr('nav_bookings'),
        ),
        type: _TabType.bookings,
      ),
    if (config.features.showAdminReservations && canManageBusiness)
      _TabConfig(
        page: AdminReservationsPage(
          key: ValueKey('admin-reservations-$adminReservationsRefreshVersion'),
        ),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.event_note_outlined),
          activeIcon: const Icon(Icons.event_note),
          label: tr('nav_appointments'),
        ),
        type: _TabType.reservations,
      ),
    _TabConfig(
      page: const ProfileTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: tr('nav_profile'),
      ),
      type: _TabType.profile,
    ),
  ];

  return tabs;
}
