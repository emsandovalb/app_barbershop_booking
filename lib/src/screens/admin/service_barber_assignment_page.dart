import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import 'service_management_utils.dart';

class ServiceBarberAssignmentPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceBarberAssignmentPage({
    super.key,
    required this.service,
  });

  @override
  State<ServiceBarberAssignmentPage> createState() =>
      _ServiceBarberAssignmentPageState();
}

class _ServiceBarberAssignmentPageState
    extends State<ServiceBarberAssignmentPage> {
  Future<_AssignmentData>? _future;
  bool _saving = false;

  int get _serviceId => widget.service['id'] as int;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_AssignmentData> _loadData() async {
    final api = context.read<AuthProvider>().api;
    final responses = await Future.wait([
      api.getResourceStaff(_serviceId),
      api.getStaff(perPage: 100),
    ]);
    final assignedRaw = (responses[0]['data'] as List?) ?? const [];
    final staffRaw = (responses[1]['data'] as List?) ?? const [];

    final assignedIds = <int>{};
    for (final item in assignedRaw) {
      if (item is! Map) continue;
      final staff = Map<String, dynamic>.from(item);
      final id = staff['id'] as int?;
      if (id != null) {
        assignedIds.add(id);
      }
    }

    final barbers = staffRaw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where(staffIsBarber)
        .toList(growable: false)
      ..sort((a, b) => staffDisplayName(a).compareTo(staffDisplayName(b)));

    return _AssignmentData(
      barbers: barbers,
      assignedIds: assignedIds,
    );
  }

  Future<void> _refresh() async {
    final next = await _loadData();
    if (!mounted) return;
    setState(() {
      _future = Future.value(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: .22),
        foregroundColor: Colors.white,
        title: const Text('Asignar barberos'),
      ),
      body: BarbershopCinematicPanel(
        backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
        opacity: .16,
        blurSigma: 14,
        child: SafeArea(
          child: FutureBuilder<_AssignmentData>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done &&
                  !snap.hasData &&
                  !snap.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError || snap.data == null) {
                return Center(
                  child: Text(
                    'No se pudieron cargar los barberos',
                    style: TextStyle(color: Colors.white.withValues(alpha: .78)),
                  ),
                );
              }

              final data = snap.data!;
              final assignedIds = data.assignedIds;

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    BarbershopPremiumCard(
                      radius: 28,
                      padding: const EdgeInsets.all(16),
                      backgroundColor:
                          const Color(0xFF140F0C).withValues(alpha: .96),
                      borderColor: AppColors.primary.withValues(alpha: .18),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: 86,
                              height: 86,
                              child: CourtImage(
                                images: serviceImage(widget.service),
                                height: 86,
                                width: 86,
                                radius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const PremiumBadge(
                                  label: 'ASIGNACIÓN DE EQUIPO',
                                  compact: true,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  serviceName(widget.service),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${serviceStaffCount(widget.service)} barberos asignados · ${serviceDurationLabel(widget.service)}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .72),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _SectionTitle(
                      title: 'Barberos asignados',
                      subtitle: 'Activa o desactiva la relación de cada barbero con este servicio.',
                    ),
                    const SizedBox(height: 12),
                    if (data.barbers.isEmpty)
                      const _EmptyState()
                    else
                      ...data.barbers.map(
                        (barber) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BarberTile(
                            barber: barber,
                            assigned: assignedIds.contains(barber['id']),
                            busy: _saving,
                            onChanged: (value) => _toggleBarber(
                              barber,
                              value,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _toggleBarber(
    Map<String, dynamic> barber,
    bool assign,
  ) async {
    final id = barber['id'] as int?;
    if (id == null) return;
    setState(() => _saving = true);
    final api = context.read<AuthProvider>().api;
    try {
      if (assign) {
        await api.assignStaffToResource(id, _serviceId);
      } else {
        await api.removeStaffFromResource(id, _serviceId);
      }
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo actualizar la asignación: $e'),
            backgroundColor: const Color(0xFF1A1512),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _BarberTile extends StatelessWidget {
  final Map<String, dynamic> barber;
  final bool assigned;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _BarberTile({
    required this.barber,
    required this.assigned,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final active = barber['is_active'] != false;
    final avatar = barber['avatar_url']?.toString().trim() ?? barber['avatar']?.toString().trim() ?? '';

    return BarbershopPremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .96),
      borderColor: assigned
          ? AppColors.primary.withValues(alpha: .36)
          : Colors.white.withValues(alpha: .08),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: .08),
            backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
            child: avatar.isEmpty
                ? const Icon(Icons.content_cut_rounded, color: AppColors.primary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staffDisplayName(barber),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staffRoleLabel(barber),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .68),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniBadge(
                      label: active ? 'Activo' : 'Inactivo',
                      color: active ? AppColors.success : Colors.redAccent,
                    ),
                    _MiniBadge(
                      label: assigned ? 'Asignado' : 'Sin asignar',
                      color: assigned ? AppColors.primary : Colors.white70,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: assigned,
            onChanged: busy ? null : onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .96),
      borderColor: Colors.white.withValues(alpha: .08),
      child: Center(
        child: Text(
          'No se encontraron barberos para asignar.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .76),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}

class _AssignmentData {
  final List<Map<String, dynamic>> barbers;
  final Set<int> assignedIds;

  const _AssignmentData({
    required this.barbers,
    required this.assignedIds,
  });
}
