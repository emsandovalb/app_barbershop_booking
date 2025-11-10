import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';
import '../../widgets/court_image.dart';

class MyGroundsPage extends StatelessWidget {
  const MyGroundsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: const Text('My grounds')),
        body: const Center(child: Text('Only administrators can access this section')),
      );
    }
    final api = auth.api;
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('My grounds'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: api.getMyGrounds(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data?['data'] as List?) ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final c = items[i] as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: CourtImage(
                          images: c['images'],
                          height: 72,
                          width: 72,
                          radius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c['name']?.toString() ?? 'Ground',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${c['duration_hours'] ?? 1} Hour',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addGround),
          child: const Text('Add'),
        ),
      ),
    );
  }
}
