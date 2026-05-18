import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../services/localization_service.dart';

class GroundBookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> args;
  const GroundBookingDetailPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final Map<String, dynamic> resource = Map<String, dynamic>.from(
      (args['resource'] as Map<String, dynamic>?) ?? (args['court'] as Map<String, dynamic>?) ?? const {},
    );
    final iso = args['iso'] as String;
    final slot = args['slot'] as String;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('booking_details_title', fallback: 'Appointment details'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 160, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 12),
          Text(
            resource['name']?.toString() ?? 'Service',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
              const SizedBox(width: 4),
              Expanded(child: Text(resource['address']?.toString() ?? '', style: const TextStyle(color: Colors.white70))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('common_facilities', fallback: 'Shop amenities'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              _AmenityChip(label: loc.t('facility_parking', fallback: 'Parking')),
              _AmenityChip(label: loc.t('facility_camera', fallback: 'Security')),
              _AmenityChip(label: loc.t('facility_waiting', fallback: 'Waiting area')),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _kv(loc.t('booking_detail_ground_label', fallback: 'Service'), resource['name']?.toString() ?? 'Service'),
                const SizedBox(height: 10),
                _kv(loc.t('booking_detail_code', fallback: 'Appointment code'), '—'),
                const SizedBox(height: 10),
                _kv(loc.t('booking_detail_date', fallback: 'Date'), iso.substring(0, 10)),
                const SizedBox(height: 10),
                _kv(loc.t('booking_detail_time', fallback: 'Time'), slot),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.payment, arguments: args),
          child: Text(loc.t('booking_proceed_payment', fallback: 'Continue to payment')),
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

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(14)),
      child: Text(label, style: const TextStyle(color: Colors.white)),
    );
  }
}
