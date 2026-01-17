import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

class GroundBookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> args;
  const GroundBookingDetailPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final court = args['court'] as Map<String, dynamic>;
    final iso = args['iso'] as String;
    final slot = args['slot'] as String;
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('booking_details_title', fallback: 'Booking details'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 160, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 12),
          Text(court['name']?.toString() ?? 'Hover ground', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
            const SizedBox(width: 4),
            Expanded(child: Text(court['address']?.toString() ?? '', style: const TextStyle(color: Colors.white70))),
          ]),
          const SizedBox(height: 16),
          Text(loc.t('common_facilities', fallback: 'Facilities'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _FacilityChip(label: loc.t('facility_parking', fallback: 'Parking')),
              _FacilityChip(label: loc.t('facility_camera', fallback: 'Camera')),
              _FacilityChip(label: loc.t('facility_waiting', fallback: 'Waiting')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _kv(loc.t('booking_detail_ground_label', fallback: 'Ground'), court['name']?.toString() ?? 'Ground'),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_code', fallback: 'Booking Code'), '—'),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_date', fallback: 'Date'), iso.substring(0, 10)),
              const SizedBox(height: 10),
              _kv(loc.t('booking_detail_time', fallback: 'Time'), slot),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.payment, arguments: args),
          child: Text(loc.t('booking_proceed_payment', fallback: 'Proceed to payment')),
        ),
      ),
    );
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
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
