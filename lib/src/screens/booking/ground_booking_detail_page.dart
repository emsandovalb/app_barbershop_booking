import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';

class GroundBookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> args;
  const GroundBookingDetailPage({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final court = args['court'] as Map<String, dynamic>;
    final iso = args['iso'] as String;
    final slot = args['slot'] as String;
    return Scaffold(
      appBar: AppBar(title: const Text('Booking details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(height: 160, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 12),
          Text(court['name']?.toString() ?? 'Hover ground', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Colors.white)),
          const SizedBox(height: 4),
          Row(children: const [Icon(Icons.location_on_outlined, size: 16, color: Colors.white70), SizedBox(width: 4), Text('Fairfield', style: TextStyle(color: Colors.white70))]),
          const SizedBox(height: 16),
          const Text('Facilities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: [
            for (final f in const ['Parkin', ' Camer', ' Waitin', ' Chang'])
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(14)),
                child: Text(f, style: const TextStyle(color: Colors.white)),
              )
          ]),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              _kv('Ground', 'Ground 01'),
              const SizedBox(height: 10),
              _kv('Booking Code', '—'),
              const SizedBox(height: 10),
              _kv('Date', iso.substring(0, 10)),
              const SizedBox(height: 10),
              _kv('Time', slot),
            ]),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.payment, arguments: args),
          child: const Text('Proceed to payment'),
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

