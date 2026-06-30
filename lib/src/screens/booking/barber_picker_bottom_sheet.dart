import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

class BarberPickerBottomSheet extends StatefulWidget {
  final int serviceId;

  const BarberPickerBottomSheet({super.key, required this.serviceId});

  @override
  State<BarberPickerBottomSheet> createState() =>
      _BarberPickerBottomSheetState();
}

class _BarberPickerBottomSheetState extends State<BarberPickerBottomSheet> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadBarbers();
  }

  Future<List<Map<String, dynamic>>> _loadBarbers() async {
    final api = context.read<AuthProvider>().api;
    final response = await api.getResourceStaff(widget.serviceId);
    final items = (response['data'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF111827),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    loc.t(
                      'booking_barber_picker_title',
                      fallback: 'Select barber',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    loc.t(
                      'booking_barber_picker_hint',
                      fallback: 'Choose a barber or continue without one.',
                    ),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              loc.t(
                                'booking_barber_picker_error',
                                fallback: 'Failed to load barbers',
                              ),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        final barbers =
                            snapshot.data ?? const <Map<String, dynamic>>[];
                        return ListView(
                          controller: scrollController,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.do_not_disturb_alt_outlined,
                                color: Colors.white70,
                              ),
                              title: Text(
                                loc.t(
                                  'booking_barber_none',
                                  fallback: 'No barber preference',
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                loc.t(
                                  'booking_barber_none_subtitle',
                                  fallback:
                                      'Continue without assigning a barber',
                                ),
                                style: const TextStyle(color: Colors.white70),
                              ),
                              onTap: () => Navigator.of(context).pop(null),
                            ),
                            const Divider(color: Colors.white12),
                            if (barbers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Text(
                                  loc.t(
                                    'booking_barber_none_available',
                                    fallback:
                                        'No barbers available for this service',
                                  ),
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            for (final barber in barbers)
                              Card(
                                color: const Color(0xFF1F2937),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white10,
                                    child: Text(
                                      _initial(barber['name']?.toString()),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    barber['name']?.toString() ??
                                        loc.t(
                                          'booking_barber_label',
                                          fallback: 'Barber',
                                        ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    barber['role'] is Map
                                        ? ((barber['role'] as Map)['name']
                                                  ?.toString() ??
                                              '')
                                        : '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  trailing: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        AppRoutes.staffDetail,
                                        arguments: {'staff': barber},
                                      );
                                    },
                                    child: const Text('Ver perfil'),
                                  ),
                                  onTap: () =>
                                      Navigator.of(context).pop(barber),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }
}
