import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ground/select_date_time_page.dart';
import '../../widgets/court_image.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';
import '../../services/localization_service.dart';

class GroundDetailPage extends StatelessWidget {
  final Map<String, dynamic> court;
  const GroundDetailPage({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: 180, child: CourtImage(images: court['images'])),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(loc.t('ground_rating_sample', fallback: '4.5 (140 Reviews)'), style: const TextStyle(color: Colors.white70)),
            const Spacer(),
            Text(loc.t('ground_price_sample', fallback: 'S/ 100.00'),
                style: const TextStyle(color: Color(0xFF00D084), fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(court['name']?.toString() ?? 'Hover ground', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            loc.t(
              'ground_description_placeholder',
              fallback:
                  'Ultricies arcu venenatis in lorem faucibus lobortis at. east odio varius nulla augue aliquam nunc est sit pulv convallis magna est scelerisque Ultricies arcu venen…',
            ),
            style: TextStyle(color: Colors.white.withOpacity(.85)),
          ),
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
          Text(loc.t('ground_list_title', fallback: 'Ground list'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => Container(
                width: 140,
                decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Expanded(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.all(Radius.circular(12))))),
                  const SizedBox(height: 6),
                  Text(loc.t('ground_main_label', fallback: 'Main ground'), style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(loc.t('grounds_duration_one', fallback: '1 Hour'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 3,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            final auth = context.read<AuthProvider>();
            if (!auth.isLoggedIn) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(loc.t('ground_login_required', fallback: 'Please log in to book'))));
              Navigator.of(context).pushNamed(AppRoutes.login);
              return;
            }
            final result = await Navigator.of(context).push<Map<String, dynamic>>(
              MaterialPageRoute(builder: (_) => SelectDateTimePage(court: court)),
            );
            if (result == null) return;
            if (!context.mounted) return;
            Navigator.of(context).pushNamed('/booking/detail', arguments: {
              'court': court,
              'iso': result['iso'],
              'slot': result['slot'],
              'duration_hours': result['duration_hours'],
            });
          },
          child: Text(loc.t('ground_book_now', fallback: 'Book now')),
        ),
      ),
    );
  }
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
