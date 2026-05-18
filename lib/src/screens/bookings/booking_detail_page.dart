import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../ground/select_date_time_page.dart';

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
    final booking = widget.booking;
    final resource =
        (booking['resource'] as Map<String, dynamic>?) ??
        (booking['court'] as Map<String, dynamic>?) ??
        {};
    final barber = (booking['staff'] as Map<String, dynamic>?) ?? {};
    final when = DateTime.tryParse((booking['date'] ?? '').toString());
    final dateText = when != null ? DateFormat('EEE. dd MMM').format(when) : '';
    final timeText = (booking['time_slot'] ?? '').toString();
    final code = (booking['booking_code'] ?? '—').toString();
    final isUpcoming = when != null ? when.isAfter(DateTime.now()) : false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('booking_details_title', fallback: 'Appointment details'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            resource['name']?.toString() ?? 'Service',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.white70,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  resource['address']?.toString() ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('common_facilities', fallback: 'Shop amenities'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AmenityChip(
                label: loc.t('facility_parking', fallback: 'Parking'),
              ),
              _AmenityChip(
                label: loc.t('facility_camera', fallback: 'Security'),
              ),
              _AmenityChip(
                label: loc.t('facility_waiting', fallback: 'Waiting area'),
              ),
              _AmenityChip(
                label: loc.t(
                  'facility_changing',
                  fallback: 'Private prep room',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF282828),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kv(
                  loc.t('booking_detail_ground_label', fallback: 'Service'),
                  resource['name']?.toString() ?? 'Service',
                ),
                const SizedBox(height: 10),
                _kv(
                  loc.t('booking_detail_code', fallback: 'Appointment code'),
                  code,
                ),
                const SizedBox(height: 10),
                _kv(loc.t('booking_detail_date', fallback: 'Date'), dateText),
                const SizedBox(height: 10),
                _kv(loc.t('booking_detail_time', fallback: 'Time'), timeText),
                if (barber.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _kv(
                    loc.t('booking_detail_barber', fallback: 'Barber'),
                    barber['name']?.toString() ??
                        loc.t(
                          'booking_barber_unassigned',
                          fallback: 'Unassigned',
                        ),
                  ),
                ],
              ],
            ),
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
                ? (isUpcoming
                      ? loc.t(
                          'booking_cancel_progress',
                          fallback: 'Cancelling...',
                        )
                      : loc.t(
                          'booking_rebook_progress',
                          fallback: 'Rebooking...',
                        ))
                : (isUpcoming
                      ? loc.t('booking_cancel_cta', fallback: 'Cancel')
                      : loc.t('booking_rebook_cta', fallback: 'Rebook')),
          ),
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final loc = context.read<LocalizationService>();
    final booking = widget.booking;
    final when = DateTime.tryParse((booking['date'] ?? '').toString());
    if (when == null) return;
    final hoursUntil = when.difference(DateTime.now()).inHours;
    if (hoursUntil < 24) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.t(
              'booking_cancel_limit',
              fallback:
                  'Cancellation not allowed within 24 hours of start time',
            ),
          ),
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          loc.t('booking_cancel_title', fallback: 'Cancel appointment'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          loc.t(
            'booking_cancel_confirm',
            fallback: 'Are you sure you want to cancel this appointment?',
          ),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('btn_no', fallback: 'No')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              loc.t('booking_cancel_confirm_action', fallback: 'Yes, cancel'),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => loading = true);
    try {
      await context.read<AuthProvider>().api.cancelReservation(
        booking['id'] as int,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.t('booking_cancelled', fallback: 'Appointment cancelled'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc.t('booking_cancel_failed', fallback: 'Cancel failed')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rebook() async {
    final loc = context.read<LocalizationService>();
    final booking = widget.booking;
    final resource =
        (booking['resource'] as Map<String, dynamic>?) ??
        (booking['court'] as Map<String, dynamic>?) ??
        {};
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => SelectDateTimePage(court: resource)),
    );
    if (result == null) return;
    setState(() => loading = true);
    try {
      await context.read<AuthProvider>().api.rebookReservation(
        booking['id'] as int,
        {
          'date': result['iso'] as String,
          'time_slot': result['slot'] as String,
        },
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderPlaced,
        arguments: {
          'title': loc.t(
            'booking_rebook_success_title',
            fallback: 'Appointment rebooked',
          ),
          'subtitle': loc.t(
            'booking_rebook_success_subtitle',
            fallback: 'Your appointment has been rescheduled.',
          ),
          'buttonText': loc.t('btn_back_home', fallback: 'Back to home'),
          'backRoute': AppRoutes.home,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.t('booking_rebook_failed', fallback: 'Rebook failed')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _kv(String k, String v) => Row(
    children: [
      Text(k, style: const TextStyle(color: Colors.white70)),
      const Spacer(),
      Text(
        v,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
