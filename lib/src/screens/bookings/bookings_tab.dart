import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';

class BookingsTab extends StatelessWidget {
  final int initialIndex;
  const BookingsTab({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final tabs = [
      _BookingList(status: 'active'),
      _BookingList(status: 'completed'),
    ];

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex.clamp(0, 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(loc.t('bookings_title', fallback: 'My appointments')),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white10),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Tab(text: loc.t('bookings_tab_upcoming', fallback: 'Upcoming')),
                    Tab(text: loc.t('bookings_tab_completed', fallback: 'Completed')),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(children: tabs),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  final String status;
  const _BookingList({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.t('bookings_login_prompt', fallback: 'Please log in to view your appointments'),
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: Text(loc.t('login_button', fallback: 'Log in')),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: auth.api.getReservations(status: status),
      builder: (context, snap) {
        final items = (snap.data?['data'] as List?) ?? [];
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return Center(
            child: Text(
              status == 'active'
                  ? loc.t('bookings_empty_active', fallback: 'No active appointments yet.')
                  : loc.t('bookings_empty_completed', fallback: 'No appointment history yet.'),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final booking = items[i] as Map<String, dynamic>;
            final resource = (booking['resource'] as Map<String, dynamic>?) ?? (booking['court'] as Map<String, dynamic>?) ?? {};
            final when = DateTime.tryParse((booking['date'] ?? '').toString());
            final dateText = when != null ? DateFormat('d MMMM, EEEE').format(when) : '';

            return _BookingCard(
              title: resource['name']?.toString() ?? 'Service',
              location: resource['address']?.toString().split('\n').first ?? '',
              dateText: dateText,
              showRebook: status == 'completed',
              onRebook: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (date == null) return;
                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                if (time == null) return;
                final iso = DateTime(date.year, date.month, date.day, time.hour, time.minute).toIso8601String();
                await context.read<AuthProvider>().api.rebookReservation(
                  booking['id'] as int,
                  {
                    'date': iso,
                    'time_slot': time.format(context),
                  },
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.t('bookings_rebooked_toast', fallback: 'Appointment rebooked'))),
                  );
                }
              },
              onTap: () {
                Navigator.of(context).pushNamed('/bookings/show', arguments: {'booking': booking});
              },
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: items.length,
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final String title;
  final String location;
  final String dateText;
  final bool showRebook;
  final VoidCallback onRebook;
  final VoidCallback? onTap;

  const _BookingCard({
    required this.title,
    required this.location,
    required this.dateText,
    required this.showRebook,
    required this.onRebook,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(width: 72, height: 72, color: Colors.black38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: const TextStyle(color: Colors.white70))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(dateText, style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            if (showRebook)
              TextButton(
                onPressed: onRebook,
                child: Text(loc.t('booking_rebook_cta', fallback: 'Rebook')),
              ),
          ],
        ),
      ),
    );
  }
}
