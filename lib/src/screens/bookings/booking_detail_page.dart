import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../ground/select_date_time_page.dart';
import '../../navigation/app_router.dart';
import '../../services/localization_service.dart';

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
    final loc = context.watch<LocalizationService>();
    final b = widget.booking;
    final court = (b['court'] as Map<String, dynamic>?) ?? {};
    final when = DateTime.tryParse((b['date'] ?? '').toString());
    final dateText = when != null ? DateFormat('EEE. dd MMM').format(when) : '';
    final timeText = (b['time_slot'] ?? '').toString();
    final code = (b['booking_code'] ?? '—').toString();

    final isUpcoming = when != null ? when.isAfter(DateTime.now()) : false;
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('booking_details_title', fallback: 'Booking details'))),
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
          Text(loc.t('common_facilities', fallback: 'Facilities'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _FacilityChip(label: loc.t('facility_parking', fallback: 'Parking')),
              _FacilityChip(label: loc.t('facility_camera', fallback: 'Camera')),
              _FacilityChip(label: loc.t('facility_waiting', fallback: 'Waiting')),
              _FacilityChip(label: loc.t('facility_changing', fallback: 'Changing room')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _kv(loc.t('booking_detail_ground_label', fallback: 'Ground'), 'Ground 01'),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_code', fallback: 'Booking Code'), code),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_date', fallback: 'Date'), dateText),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_time', fallback: 'Time'), timeText),
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
          child: Text(
            loading
                ? (isUpcoming ? loc.t('booking_cancel_progress', fallback: 'Cancelling...') : loc.t('booking_rebook_progress', fallback: 'Re-booking...'))
                : (isUpcoming ? loc.t('booking_cancel_cta', fallback: 'Cancel') : loc.t('booking_rebook_cta', fallback: 'Re-book')),
          ),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final loc = context.read<LocalizationService>();
    final b = widget.booking;
    final when = DateTime.tryParse((b['date'] ?? '').toString());
    if (when == null) return;
    final hoursUntil = when.difference(DateTime.now()).inHours;
    if (hoursUntil < 24) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(loc.t('booking_cancel_limit', fallback: 'Cancellation not allowed within 24 hours of start time')),
      ));
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(loc.t('booking_cancel_title', fallback: 'Cancel booking'), style: const TextStyle(color: Colors.white)),
        content: Text(loc.t('booking_cancel_confirm', fallback: 'Are you sure you want to cancel this booking?'),
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('btn_no', fallback: 'No'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.t('booking_cancel_confirm_action', fallback: 'Yes, cancel'))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => loading = true);
    try {
      await context.read<AuthProvider>().api.cancelBooking(b['id'] as int);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('booking_cancelled', fallback: 'Booking cancelled'))));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${loc.t('booking_cancel_failed', fallback: 'Cancel failed')}: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rebook() async {
    final loc = context.read<LocalizationService>();
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
        'title': loc.t('booking_rebook_success_title', fallback: 'Re-booked'),
        'subtitle': loc.t(
          'booking_rebook_success_subtitle',
          fallback: 'Your booking has been re-scheduled. Cancellations must be made at least 24 hours before the start time.',
        ),
        'buttonText': loc.t('btn_back_home', fallback: 'Back to home'),
        'backRoute': AppRoutes.home,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.t('booking_rebook_failed', fallback: 'Re-book failed')}: $e')));
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

class _FacilityChip extends StatelessWidget {
  final String label;
  const _FacilityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white)),
      ]),
    );
  }
}
