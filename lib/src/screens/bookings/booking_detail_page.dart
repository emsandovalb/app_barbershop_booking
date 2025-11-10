import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../ground/select_date_time_page.dart';
import '../../navigation/app_router.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
    final court = (b['court'] as Map<String, dynamic>?) ?? {};
    final when = DateTime.tryParse((b['date'] ?? '').toString());
    final dateText = when != null ? DateFormat('EEE. dd MMM').format(when) : '';
    final timeText = (b['time_slot'] ?? '').toString();
    final code = (b['booking_code'] ?? '—').toString();

    final isUpcoming = when != null ? when.isAfter(DateTime.now()) : false;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 160, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 12),
          Text(court['name']?.toString() ?? 'Ground', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(child: Text(court['address']?.toString() ?? '', style: const TextStyle(color: Colors.white70)))
          ]),
          const SizedBox(height: 16),
          const Text('Facilities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (final f in const ['Parking', 'Camera', 'Waiting', 'Chang'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(14)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(f, style: const TextStyle(color: Colors.white)),
                ]),
              )
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _kv('Ground', 'Ground 01'),
              const SizedBox(height: 10),
              _kv('Booking Code', code),
              const SizedBox(height: 10),
              _kv('Date', dateText),
              const SizedBox(height: 10),
              _kv('Time', timeText),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: loading
              ? null
              : () async {
                  if (isUpcoming) {
                    await _cancel();
                  } else {
                    await _rebook();
                  }
                },
          child: Text(loading
              ? (isUpcoming ? 'Cancelling...' : 'Re-booking...')
              : (isUpcoming ? 'Cancel' : 'Re-book')),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final b = widget.booking;
    final when = DateTime.tryParse((b['date'] ?? '').toString());
    if (when == null) return;
    final hoursUntil = when.difference(DateTime.now()).inHours;
    if (hoursUntil < 24) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cancellation not allowed within 24 hours of start time'),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Cancel booking', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this booking?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => loading = true);
    try {
      await context.read<AuthProvider>().api.cancelBooking(b['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking cancelled')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancel failed: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rebook() async {
    final b = widget.booking;
    final court = (b['court'] as Map<String, dynamic>?) ?? {};
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => SelectDateTimePage(court: court)),
    );
    if (result == null) return;
    setState(() => loading = true);
    try {
      await context.read<AuthProvider>().api.rebook(
            b['id'] as int,
            date: result['iso'] as String,
            timeSlot: result['slot'] as String,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.orderPlaced, arguments: {
        'title': 'Re-booked',
        'subtitle': 'Your booking has been re-scheduled. Cancellations must be made at least 24 hours before the start time.',
        'buttonText': 'Back to home',
        'backRoute': AppRoutes.home,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Re-book failed: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _kv(String k, String v) => Row(
        children: [
          Text(k, style: const TextStyle(color: Colors.white70)),
          const Spacer(),
          Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ],
      );
}
