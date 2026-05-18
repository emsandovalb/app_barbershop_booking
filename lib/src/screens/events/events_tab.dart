import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'package:intl/intl.dart';

class EventsTab extends StatelessWidget {
  const EventsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<AuthProvider>().api.getEvents(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                loc.t('events_error_generic', fallback: 'Could not load events. Please try again later.'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final items = (snap.data?['data'] as List?) ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                loc.t('events_empty', fallback: 'No events available yet.'),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemBuilder: (_, i) {
            final e = items[i] as Map<String, dynamic>;
            final dateText = _formatEventDate(e['date']);
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.emoji_events)),
                title: Text(e['title']?.toString() ?? 'Event'),
                subtitle: Text(dateText),
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

String _formatEventDate(dynamic raw) {
  if (raw == null) return '';
  final value = raw.toString();
  if (value.isEmpty) return '';

  final parsed = DateTime.tryParse(value);
  if (parsed != null) {
    return DateFormat('d MMMM, EEEE').format(parsed);
  }

  // Fallback to a safe substring or the raw value without throwing
  if (value.length >= 10) {
    return value.substring(0, 10);
  }
  return value;
}
