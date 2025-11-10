import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ground/select_date_time_page.dart';
import '../../widgets/court_image.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class GroundDetailPage extends StatelessWidget {
  final Map<String, dynamic> court;
  const GroundDetailPage({super.key, required this.court});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(height: 180, child: CourtImage(images: court['images'])),
          const SizedBox(height: 12),
          Row(children: const [
            Icon(Icons.star, color: Colors.amber, size: 18),
            SizedBox(width: 4),
            Text('4.5 (140 Reviews)', style: TextStyle(color: Colors.white70)),
            Spacer(),
            Text('4 100.00', style: TextStyle(color: Color(0xFF00D084), fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          Text(court['name']?.toString() ?? 'Hover ground', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Ultricies arcu venenatis in lorem faucibus lobortis at. east odio varius nulla augue aliquam nunc est sit pulv convallis magna est scelerisque Ultricies arcu venen…', style: TextStyle(color: Colors.white.withOpacity(.85))),
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
          const Text('Ground list', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => Container(
                width: 140,
                decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Expanded(child: DecoratedBox(decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.all(Radius.circular(12))))),
                  SizedBox(height: 6),
                  Text('Main ground', style: TextStyle(color: Colors.white)),
                  SizedBox(height: 2),
                  Text('1 Hour', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to book')));
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
          child: const Text('Book now'),
        ),
      ),
    );
  }
}
