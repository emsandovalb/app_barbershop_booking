import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/court_image.dart';
import 'admin_page_scaffold.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  late DateTime _selectedDay;
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final auth = context.read<AuthProvider>();
    final iso = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return auth.api.getReservationsForDay(iso);
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    if (!isAdmin) {
      return Scaffold(
        appBar: buildAdminAppBar(
          context,
          title: loc.t('admin_reservations_title', fallback: 'Appointments'),
        ),
        body: Center(
          child: Text(
            loc.t(
              'grounds_admin_only',
              fallback: 'Only administrators can access this section',
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: loc.t('admin_reservations_title', fallback: 'Appointments today'),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data?['data'] as List?) ?? [];
          if (items.isEmpty) {
            return Center(
              child: Text(
                loc.t(
                  'admin_reservations_empty',
                  fallback: 'No appointments for this day',
                ),
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final booking = items[i] as Map<String, dynamic>;
              final court = (booking['court'] as Map<String, dynamic>?) ?? {};
              final user = (booking['user'] as Map<String, dynamic>?) ?? {};
              final timeSlot = booking['time_slot']?.toString() ?? '';
              final price = booking['price']?.toString() ?? '';
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CourtImage(
                        images: court['images'],
                        radius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Legacy `court` payload is retained until the backend generic alias lands.
                          Text(
                            court['name']?.toString() ?? 'Service',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeSlot,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${user['name'] ?? user['email'] ?? ''}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '#${booking['id']}',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDay,
        label: Text(DateFormat('EEEE, d MMM').format(_selectedDay)),
        icon: const Icon(Icons.event),
      ),
    );
  }
}
