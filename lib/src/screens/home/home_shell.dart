import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import 'home_tab.dart';
import '../profile/profile_tab.dart';
import '../bookings/bookings_tab.dart';
import '../admin/admin_reservations_page.dart';
import '../../services/localization_service.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum _TabType { home, booking, reservations, profile }

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
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isLoggedIn = auth.isLoggedIn;
    final isAdmin = auth.isAdmin;
    final tabs = _buildTabs(isAdmin: isAdmin, loc: loc, config: config);
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
            Navigator.of(context).pushNamed(AppRoutes.login);
            return;
          }
          setState(() => index = i);
        },
        backgroundColor: config.brand.backgroundColor,
        selectedItemColor: config.brand.primaryColor,
        unselectedItemColor: Colors.white.withOpacity(.58),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        items: tabs.map((t) => t.item).toList(growable: false),
      ),
    );
  }
}

String _navLabel(LocalizationService loc, String key, String en, String es) {
  return loc.t(key, fallback: loc.locale.languageCode == 'es' ? es : en);
}

List<_TabConfig> _buildTabs({
  required bool isAdmin,
  required LocalizationService loc,
  required AppConfig config,
}) {
  final tabs = <_TabConfig>[
    if (config.features.showAdminReservations && isAdmin)
      _TabConfig(
        page: const AdminReservationsPage(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.event_note_outlined),
          activeIcon: const Icon(Icons.event_note),
          label: _navLabel(loc, 'nav_reservations', 'Appointments', 'Citas'),
        ),
        type: _TabType.reservations,
      ),
    if (config.features.showReservations)
      _TabConfig(
        page: const BookingsTab(),
        item: BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_outlined),
          activeIcon: const Icon(Icons.calendar_month),
          label: _navLabel(loc, 'nav_booking', 'Appointments', 'Citas'),
        ),
        type: _TabType.booking,
      ),
    _TabConfig(
      page: const HomeTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.home_outlined),
        activeIcon: const Icon(Icons.home),
        label: _navLabel(loc, 'nav_home', 'Home', 'Inicio'),
      ),
      type: _TabType.home,
    ),
    _TabConfig(
      page: const ProfileTab(),
      item: BottomNavigationBarItem(
        icon: const Icon(Icons.person_outline),
        activeIcon: const Icon(Icons.person),
        label: _navLabel(loc, 'nav_profile', 'Profile', 'Perfil'),
      ),
      type: _TabType.profile,
    ),
  ];

  return tabs;
}
