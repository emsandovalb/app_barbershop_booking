import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _BookingList(status: 'active'),
      _BookingList(status: 'completed'),
    ];
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My booking'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Upcoming'), Tab(text: 'Completed')],
            indicatorWeight: 3,
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
    final auth = context.watch<AuthProvider>();
    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please log in to view your bookings', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/login'), child: const Text('Log in')),
            ],
          ),
        ),
      );
    }
    return FutureBuilder<Map<String, dynamic>>(
      future: auth.api.getBookings(status),
      builder: (context, snap) {
        final items = (snap.data?['data'] as List?) ?? [];
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (items.isEmpty) {
          return Center(child: Text(status=='active' ? 'No hay reservas activas.' : 'Sin historial.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final b = items[i] as Map<String, dynamic>;
            final court = (b['court'] as Map<String, dynamic>?) ?? {};
            final when = DateTime.tryParse((b['date'] ?? '').toString());
            final dateText = when != null
                ? DateFormat('d MMMM, EEEE').format(when)
                : '';
            return _BookingCard(
              title: court['name']?.toString() ?? 'Ground',
              location: court['address']?.toString().split('\n').first ?? '',
              dateText: dateText,
              showRebook: status == 'completed',
              onRebook: () async {
                final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: DateTime.now().add(const Duration(days: 1)));
                if (date == null) return;
                final time = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
                if (time == null) return;
                final iso = DateTime(date.year, date.month, date.day, time.hour, time.minute).toIso8601String();
                await context.read<AuthProvider>().api.rebook(b['id'] as int, date: iso, timeSlot: time.format(context));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Re-booked')));
                }
              },
              onTap: () {
                Navigator.of(context).pushNamed('/bookings/show', arguments: {'booking': b});
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
  const _BookingCard({required this.title, required this.location, required this.dateText, required this.showRebook, required this.onRebook, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                Row(children: [
                  const Icon(Icons.place, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Expanded(child: Text(location, style: const TextStyle(color: Colors.white70)))]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.calendar_month, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(dateText, style: const TextStyle(color: Colors.white70)),
                ]),
              ],
            ),
          ),
          if (showRebook)
            TextButton(onPressed: onRebook, child: const Text('Re-book')),
        ],
      ),
    ),
    );
  }
}
