import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<AuthProvider>().api.getEvents(),
      builder: (context, snap) {
        final items = (snap.data?['data'] as List?) ?? [];
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final e = items[i] as Map<String, dynamic>;
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
                title: Text(e['title']?.toString() ?? 'Event'),
                subtitle: Text(e['date']?.toString().substring(0, 10) ?? ''),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: items.length,
        );
      },
    );
  }
}
