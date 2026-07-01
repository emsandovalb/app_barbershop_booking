import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../bookings/appointment_helpers.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';
import '../bookings/booking_detail_page.dart';
import '../gallery/gallery_page.dart';
import '../reviews/reviews_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_AdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_AdminDashboardData> _loadData() async {
    final api = context.read<AuthProvider>().api;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final reservationsResponse = await _safeFetch(
      () => api.getReservationsForDay(today),
      fallback: _fallbackReservationsResponse,
    );
    final staffResponse = await _safeFetch(
      () => api.getStaff(perPage: 100),
      fallback: _fallbackStaffResponse,
    );
    final resourcesResponse = await _safeFetch(
      () => api.getResources(page: 1, perPage: 100, sort: 'rating'),
      fallback: _fallbackResourcesResponse,
    );

    final reservations = _extractItems(reservationsResponse);
    final staff = _extractItems(staffResponse);
    final resources = _extractItems(resourcesResponse);

    return _AdminDashboardData(
      reservations: reservations.isNotEmpty
          ? reservations
          : _fallbackReservations,
      staff: staff.isNotEmpty ? staff : _fallbackStaff,
      resources: resources.isNotEmpty ? resources : _fallbackResources,
    );
  }

  Future<Map<String, dynamic>> _safeFetch(
    Future<Map<String, dynamic>> Function() loader, {
    required Map<String, dynamic> fallback,
  }) async {
    try {
      return await loader();
    } catch (_) {
      return fallback;
    }
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  Future<void> _refresh() async {
    final next = await _loadData();
    if (!mounted) return;
    setState(() {
      _future = Future.value(next);
    });
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1512),
      ),
    );
  }

  void _openBooking(Map<String, dynamic> booking) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
  }

  void _openNamedRoute(String route, {Map<String, dynamic>? arguments}) {
    final navigator = Navigator.of(context);
    try {
      navigator.pushNamed(route, arguments: arguments);
    } catch (_) {
      _showPlaceholder('Esta sección todavía no está disponible.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return const Scaffold(
        backgroundColor: Color(0xFF090909),
        body: Center(
          child: Text(
            'Solo los administradores pueden acceder a esta sección',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: BarbershopPremiumBackdrop(
        backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
        backgroundOpacity: .22,
        blurSigma: 14,
        child: SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _refresh,
            child: FutureBuilder<_AdminDashboardData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data ?? _AdminDashboardData.empty;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                final metrics = _buildMetrics(data);
                final topServices = _buildTopServices(data);
                final performance = _buildPerformance(data);

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TopHero(
                              isLoading: isLoading,
                              onRefresh: _refresh,
                              onGoToReservations: () =>
                                  _openNamedRoute(AppRoutes.adminReservations),
                              onGoToStaff: () =>
                                  _openNamedRoute(AppRoutes.adminStaff),
                            ),
                            const SizedBox(height: 14),
                            _KpiGrid(metrics: metrics),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: 'Citas de hoy',
                              actionLabel: 'Ver todas',
                              onTap: () =>
                                  _openNamedRoute(AppRoutes.adminReservations),
                            ),
                            const SizedBox(height: 12),
                            _TodayAppointmentsList(
                              items: data.reservations,
                              onOpen: _openBooking,
                            ),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: 'Rendimiento de barberos',
                              actionLabel: 'Administrar barberos',
                              onTap: () =>
                                  _openNamedRoute(AppRoutes.adminStaff),
                            ),
                            const SizedBox(height: 12),
                            _PerformanceList(items: performance),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: 'Servicios más reservados',
                              actionLabel: 'Administrar servicios',
                              onTap: () => _openNamedRoute(AppRoutes.adminServices),
                            ),
                            const SizedBox(height: 12),
                            _TopServicesList(items: topServices),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: 'Accesos rápidos',
                              actionLabel: 'Perfil del negocio',
                              onTap: () =>
                                  _openNamedRoute(AppRoutes.businessProfile),
                            ),
                            const SizedBox(height: 12),
                            _QuickActionsGrid(
                              onAction: (action) {
                                switch (action.id) {
                                  case 'staff':
                                    _openNamedRoute(AppRoutes.adminStaff);
                                    return;
                                  case 'services':
                                    _openNamedRoute(AppRoutes.adminServices);
                                    return;
                                  case 'reservations':
                                    _openNamedRoute(
                                      AppRoutes.adminReservations,
                                    );
                                    return;
                                  case 'gallery':
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const GalleryPage(),
                                      ),
                                    );
                                    return;
                                  case 'reviews':
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const ReviewsPage(),
                                      ),
                                    );
                                    return;
                                  case 'business':
                                    _openNamedRoute(AppRoutes.businessProfile);
                                    return;
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _SummaryCard(
                              onGoToBusiness: () =>
                                  _openNamedRoute(AppRoutes.businessProfile),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<_MetricData> _buildMetrics(_AdminDashboardData data) {
    final reservations = data.reservations;
    final staff = data.staff;
    final resources = data.resources;

    final activeBarbers = staff
        .where((item) => _isActive(item))
        .toList(growable: false);
    final serviceCounts = _serviceCounts(reservations);
    final serviceRevenue = _estimatedRevenueByService(reservations, resources);
    final totalRevenue = _estimatedRevenue(reservations, resources);
    final pendingCount = reservations.where((item) {
      final bucket = appointmentStatusBucket(item);
      return bucket == AppointmentStatusBucket.upcoming &&
          !_statusText(item).contains('confirm');
    }).length;

    return [
      _MetricData(
        icon: Icons.event_available_rounded,
        label: 'Citas de hoy',
        value: '${reservations.length}',
        footnote: pendingCount > 0
            ? '$pendingCount pendientes'
            : 'Flujo estable',
      ),
      _MetricData(
        icon: Icons.payments_rounded,
        label: 'Ingresos estimados',
        value: _formatCrc(totalRevenue),
        footnote: serviceRevenue.isNotEmpty
            ? 'Top: ${serviceRevenue.keys.first}'
            : 'Estimación con datos locales',
      ),
      _MetricData(
        icon: Icons.groups_rounded,
        label: 'Barberos activos',
        value: '${activeBarbers.length}',
        footnote: activeBarbers.isNotEmpty
            ? 'Equipo disponible'
            : 'Sin actividad',
      ),
      _MetricData(
        icon: Icons.content_cut_rounded,
        label: 'Servicios reservados',
        value: '${serviceCounts.values.fold<int>(0, (a, b) => a + b)}',
        footnote: serviceRevenue.isNotEmpty
            ? 'Top: ${serviceRevenue.keys.first}'
            : 'Basado en citas de hoy',
      ),
    ];
  }

  List<_PerformanceData> _buildPerformance(_AdminDashboardData data) {
    final reservations = data.reservations;
    final staff = data.staff;
    final revenueByStaff = <String, double>{};
    final appointmentsByStaff = <String, int>{};

    for (final booking in reservations) {
      final barber = appointmentBarber(booking);
      final name = _staffName(barber);
      appointmentsByStaff[name] = (appointmentsByStaff[name] ?? 0) + 1;
      revenueByStaff[name] =
          (revenueByStaff[name] ?? 0) +
          _bookingRevenue(booking, data.resources);
    }

    final items =
        staff
            .map((item) {
              final name = _staffName(item);
              final active = _isActive(item);
              return _PerformanceData(
                avatar: _staffAvatar(item),
                name: name,
                appointments: appointmentsByStaff[name] ?? 0,
                revenue: revenueByStaff[name] ?? 0,
                active: active,
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final appointmentDiff = b.appointments.compareTo(a.appointments);
            if (appointmentDiff != 0) return appointmentDiff;
            return b.revenue.compareTo(a.revenue);
          });

    if (items.isNotEmpty) {
      return items;
    }

    return _fallbackStaff
        .map(
          (item) => _PerformanceData(
            avatar: _staffAvatar(item),
            name: _staffName(item),
            appointments: appointmentsByStaff[_staffName(item)] ?? 0,
            revenue: revenueByStaff[_staffName(item)] ?? 0,
            active: true,
          ),
        )
        .toList(growable: false);
  }

  List<_TopServiceData> _buildTopServices(_AdminDashboardData data) {
    final reservations = data.reservations;
    final resources = data.resources;
    final counts = _serviceCounts(reservations);
    final revenueByService = _estimatedRevenueByService(
      reservations,
      resources,
    );
    final resourceLookup = <String, Map<String, dynamic>>{};

    for (final resource in resources) {
      final key = _serviceKey(resource);
      resourceLookup[key] = resource;
      final name = _serviceName(resource);
      resourceLookup[name.toLowerCase()] = resource;
    }

    final items =
        counts.entries
            .map((entry) {
              final key = entry.key;
              final resource =
                  resourceLookup[key.toLowerCase()] ??
                  resourceLookup[key] ??
                  const <String, dynamic>{};
              final estimatedRevenue =
                  revenueByService[key] ??
                  _servicePrice(resource) * entry.value;
              return _TopServiceData(
                name: key,
                reservations: entry.value,
                revenue: estimatedRevenue,
                progress: entry.value == 0
                    ? .05
                    : (entry.value / _highestCount(counts)).clamp(.12, 1),
              );
            })
            .toList(growable: false)
          ..sort((a, b) {
            final reservationDiff = b.reservations.compareTo(a.reservations);
            if (reservationDiff != 0) return reservationDiff;
            return b.revenue.compareTo(a.revenue);
          });

    if (items.isNotEmpty) {
      return items;
    }

    return _fallbackResources
        .take(4)
        .map(
          (resource) => _TopServiceData(
            name: _serviceName(resource),
            reservations: 2,
            revenue: _servicePrice(resource) * 2,
            progress: .65,
          ),
        )
        .toList(growable: false);
  }
}

class _TopHero extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onRefresh;
  final VoidCallback onGoToReservations;
  final VoidCallback onGoToStaff;

  const _TopHero({
    required this.isLoading,
    required this.onRefresh,
    required this.onGoToReservations,
    required this.onGoToStaff,
  });

  @override
  Widget build(BuildContext context) {
    return BarbershopCinematicPanel(
      backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
      radius: 30,
      padding: const EdgeInsets.all(18),
      opacity: .52,
      blurSigma: 3,
      child: SizedBox(
        height: 270,
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              child: PremiumBadge(label: 'PANEL ADMINISTRATIVO'),
            ),
            Positioned(
              top: 42,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BarbershopLogoMark(
                    assetPath: 'assets/branding/logo_transparent.png',
                    size: 102,
                    glowColor: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'BARBERÍA TRES AMIGOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Panel administrativo',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hoy · ${DateFormat('EEEE, d MMMM', 'es').format(DateTime.now())}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                children: [
                  Expanded(
                    child: _HeroActionCard(
                      icon: Icons.event_note_rounded,
                      label: 'Ver citas',
                      onTap: onGoToReservations,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroActionCard(
                      icon: Icons.groups_rounded,
                      label: 'Barberos',
                      onTap: onGoToStaff,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroActionCard(
                      icon: Icons.refresh_rounded,
                      label: isLoading ? 'Cargando' : 'Actualizar',
                      onTap: onRefresh,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeroActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF120E0B).withValues(alpha: .92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _KpiGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.18,
      ),
      itemBuilder: (_, index) {
        final metric = metrics[index];
        return _MetricCard(metric: metric);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .94),
      borderColor: AppColors.primary.withValues(alpha: .18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(metric.icon, color: AppColors.primary, size: 20),
              ),
              const Spacer(),
              const Icon(
                Icons.trending_up_rounded,
                color: Colors.white54,
                size: 18,
              ),
            ],
          ),
          const Spacer(),
          Text(
            metric.value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .82),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.footnote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .60),
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayAppointmentsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onOpen;

  const _TodayAppointmentsList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final list = items.isNotEmpty ? items : _fallbackReservations;
    return Column(
      children: list
          .take(5)
          .map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AppointmentCard(
                booking: booking,
                onTap: () => onOpen(booking),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _AppointmentCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final resource = appointmentResource(booking);
    final barber = appointmentBarber(booking);
    final status = appointmentStatusBucket(booking);
    final client = _clientName(booking);
    final serviceName = appointmentServiceName(booking);
    final barberName = appointmentBarberName(booking);
    final time = _timeLabel(booking);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF130F0C).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/branding/service_placeholder_premium.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _StatusBadge(status: status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    client.isNotEmpty ? client : 'Cliente sin nombre',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    serviceName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .74),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    barberName.isNotEmpty ? barberName : _staffName(barber),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .64),
                      fontSize: 12,
                    ),
                  ),
                  if (_bookingPriceLabel(booking, resource).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      _bookingPriceLabel(booking, resource),
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _PerformanceList extends StatelessWidget {
  final List<_PerformanceData> items;

  const _PerformanceList({required this.items});

  @override
  Widget build(BuildContext context) {
    final list = items.isNotEmpty ? items : _fallbackPerformance;
    return Column(
      children: list
          .take(4)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PerformanceRow(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final _PerformanceData item;

  const _PerformanceRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF130F0C).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: .16),
            backgroundImage: item.avatar.isNotEmpty
                ? AssetImage(item.avatar)
                : null,
            child: item.avatar.isEmpty
                ? const Icon(Icons.content_cut_rounded, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _StatusBadge(
                      status: item.active
                          ? AppointmentStatusBucket.upcoming
                          : AppointmentStatusBucket.cancelled,
                      label: item.active ? 'Activo' : 'Inactivo',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.appointments} citas hoy',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCrc(item.revenue),
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopServicesList extends StatelessWidget {
  final List<_TopServiceData> items;

  const _TopServicesList({required this.items});

  @override
  Widget build(BuildContext context) {
    final list = items.isNotEmpty ? items : _fallbackTopServices;
    return Column(
      children: list
          .take(4)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _TopServiceCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _TopServiceCard extends StatelessWidget {
  final _TopServiceData item;

  const _TopServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF130F0C).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${item.reservations} reservas',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formatCrc(item.revenue),
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${(item.progress * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .55),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: .06),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final void Function(_QuickActionData action) onAction;

  const _QuickActionsGrid({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _quickActions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (_, index) {
        final action = _quickActions[index];
        return InkWell(
          onTap: () => onAction(action),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF130F0C).withValues(alpha: .94),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(action.icon, color: AppColors.primary),
                ),
                const SizedBox(height: 10),
                Text(
                  action.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  action.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .64),
                    fontSize: 11,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final VoidCallback onGoToBusiness;

  const _SummaryCard({required this.onGoToBusiness});

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .94),
      borderColor: AppColors.primary.withValues(alpha: .16),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perfil del negocio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Revisá la experiencia pública, la galería y las opiniones con un vistazo premium.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: onGoToBusiness,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: .10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Abrir',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _SectionHeaderRow({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatusBucket status;
  final String? label;

  const _StatusBadge({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final (text, fg, bg) = switch (status) {
      AppointmentStatusBucket.upcoming => (
        label ?? 'Pendiente',
        AppColors.primary,
        const Color(0xFF2E2315),
      ),
      AppointmentStatusBucket.completed => (
        label ?? 'Completada',
        const Color(0xFFE8D8B8),
        const Color(0xFF16261F),
      ),
      AppointmentStatusBucket.cancelled => (
        label ?? 'Cancelada',
        const Color(0xFFFF9D9D),
        const Color(0xFF301B1C),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final String footnote;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.footnote,
  });
}

class _PerformanceData {
  final String avatar;
  final String name;
  final int appointments;
  final double revenue;
  final bool active;

  const _PerformanceData({
    required this.avatar,
    required this.name,
    required this.appointments,
    required this.revenue,
    required this.active,
  });
}

class _TopServiceData {
  final String name;
  final int reservations;
  final double revenue;
  final double progress;

  const _TopServiceData({
    required this.name,
    required this.reservations,
    required this.revenue,
    required this.progress,
  });
}

class _QuickActionData {
  final String id;
  final IconData icon;
  final String label;
  final String description;

  const _QuickActionData({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _AdminDashboardData {
  final List<Map<String, dynamic>> reservations;
  final List<Map<String, dynamic>> staff;
  final List<Map<String, dynamic>> resources;

  const _AdminDashboardData({
    required this.reservations,
    required this.staff,
    required this.resources,
  });

  static const empty = _AdminDashboardData(
    reservations: [],
    staff: [],
    resources: [],
  );
}

const List<_QuickActionData> _quickActions = [
  _QuickActionData(
    id: 'staff',
    icon: Icons.groups_rounded,
    label: 'Administrar barberos',
    description: 'Equipo, estados y asignaciones.',
  ),
  _QuickActionData(
    id: 'services',
    icon: Icons.content_cut_rounded,
    label: 'Administrar servicios',
    description: 'Catálogo y rendimiento comercial.',
  ),
  _QuickActionData(
    id: 'reservations',
    icon: Icons.event_note_rounded,
    label: 'Ver citas',
    description: 'Agenda completa de hoy.',
  ),
  _QuickActionData(
    id: 'gallery',
    icon: Icons.photo_library_rounded,
    label: 'Galería',
    description: 'Imágenes y presentación pública.',
  ),
  _QuickActionData(
    id: 'reviews',
    icon: Icons.rate_review_rounded,
    label: 'Opiniones',
    description: 'Reseñas y percepción del cliente.',
  ),
  _QuickActionData(
    id: 'business',
    icon: Icons.storefront_rounded,
    label: 'Perfil del negocio',
    description: 'Marca, contacto y narrativa premium.',
  ),
];

const List<Map<String, dynamic>> _fallbackReservations = [
  {
    'id': 901,
    'date': '2026-06-30',
    'time_slot': '09:00',
    'status': 'upcoming',
    'price': 12000,
    'booking_code': 'TA-901',
    'user': {'name': 'Carlos Méndez'},
    'resource': {
      'id': 11,
      'name': 'Corte y Barba',
      'price_per_hour': 12000,
      'images': ['assets/branding/service_placeholder_premium.png'],
    },
    'staff': {'id': 3, 'name': 'Luis Herrera', 'is_active': true},
  },
  {
    'id': 902,
    'date': '2026-06-30',
    'time_slot': '10:30',
    'status': 'completed',
    'price': 9000,
    'booking_code': 'TA-902',
    'user': {'name': 'Andrés Ruiz'},
    'resource': {
      'id': 12,
      'name': 'Fade Signature',
      'price_per_hour': 9000,
      'images': ['assets/branding/service_placeholder_premium.png'],
    },
    'staff': {'id': 2, 'name': 'Marcos Solís', 'is_active': true},
  },
  {
    'id': 903,
    'date': '2026-06-30',
    'time_slot': '12:00',
    'status': 'upcoming',
    'price': 15000,
    'booking_code': 'TA-903',
    'user': {'name': 'Gabriel Pérez'},
    'resource': {
      'id': 13,
      'name': 'Experiencia Completa',
      'price_per_hour': 15000,
      'images': ['assets/branding/service_placeholder_premium.png'],
    },
    'staff': {'id': 4, 'name': 'José Vargas', 'is_active': true},
  },
  {
    'id': 904,
    'date': '2026-06-30',
    'time_slot': '14:00',
    'status': 'pending',
    'price': 7000,
    'booking_code': 'TA-904',
    'user': {'name': 'Ricardo León'},
    'resource': {
      'id': 14,
      'name': 'Perfilado Premium',
      'price_per_hour': 7000,
      'images': ['assets/branding/service_placeholder_premium.png'],
    },
    'staff': {'id': 1, 'name': 'Daniel Mora', 'is_active': true},
  },
];

const List<Map<String, dynamic>> _fallbackStaff = [
  {
    'id': 1,
    'name': 'Daniel Mora',
    'is_active': true,
    'avatar': 'assets/branding/barber_placeholder.png',
    'services': [
      {
        'resource': {'name': 'Corte y Barba'},
      },
      {
        'resource': {'name': 'Fade Signature'},
      },
    ],
  },
  {
    'id': 2,
    'name': 'Marcos Solís',
    'is_active': true,
    'avatar': 'assets/branding/barber_placeholder.png',
    'services': [
      {
        'resource': {'name': 'Perfilado Premium'},
      },
    ],
  },
  {
    'id': 3,
    'name': 'Luis Herrera',
    'is_active': true,
    'avatar': 'assets/branding/barber_placeholder.png',
    'services': [
      {
        'resource': {'name': 'Corte Clásico'},
      },
      {
        'resource': {'name': 'Barba Deluxe'},
      },
    ],
  },
  {
    'id': 4,
    'name': 'José Vargas',
    'is_active': false,
    'avatar': 'assets/branding/barber_placeholder.png',
    'services': [
      {
        'resource': {'name': 'Experiencia Completa'},
      },
    ],
  },
];

const List<Map<String, dynamic>> _fallbackResources = [
  {
    'id': 11,
    'name': 'Corte y Barba',
    'price_per_hour': 12000,
    'duration_hours': 1,
  },
  {
    'id': 12,
    'name': 'Fade Signature',
    'price_per_hour': 9000,
    'duration_hours': 1,
  },
  {
    'id': 13,
    'name': 'Experiencia Completa',
    'price_per_hour': 15000,
    'duration_hours': 2,
  },
  {
    'id': 14,
    'name': 'Perfilado Premium',
    'price_per_hour': 7000,
    'duration_hours': 1,
  },
];

const List<_PerformanceData> _fallbackPerformance = [
  _PerformanceData(
    avatar: 'assets/branding/barber_placeholder.png',
    name: 'Daniel Mora',
    appointments: 4,
    revenue: 42000,
    active: true,
  ),
  _PerformanceData(
    avatar: 'assets/branding/barber_placeholder.png',
    name: 'Marcos Solís',
    appointments: 3,
    revenue: 33000,
    active: true,
  ),
  _PerformanceData(
    avatar: 'assets/branding/barber_placeholder.png',
    name: 'Luis Herrera',
    appointments: 2,
    revenue: 21000,
    active: true,
  ),
  _PerformanceData(
    avatar: 'assets/branding/barber_placeholder.png',
    name: 'José Vargas',
    appointments: 1,
    revenue: 12000,
    active: false,
  ),
];

const List<_TopServiceData> _fallbackTopServices = [
  _TopServiceData(
    name: 'Corte y Barba',
    reservations: 5,
    revenue: 60000,
    progress: .95,
  ),
  _TopServiceData(
    name: 'Fade Signature',
    reservations: 4,
    revenue: 36000,
    progress: .75,
  ),
  _TopServiceData(
    name: 'Experiencia Completa',
    reservations: 2,
    revenue: 30000,
    progress: .48,
  ),
  _TopServiceData(
    name: 'Perfilado Premium',
    reservations: 1,
    revenue: 7000,
    progress: .28,
  ),
];

Map<String, dynamic> get _fallbackReservationsResponse => {
  'data': _fallbackReservations,
};

Map<String, dynamic> get _fallbackStaffResponse => {'data': _fallbackStaff};

Map<String, dynamic> get _fallbackResourcesResponse => {
  'data': _fallbackResources,
};

Map<String, int> _serviceCounts(List<Map<String, dynamic>> reservations) {
  final counts = <String, int>{};
  for (final booking in reservations) {
    final resource = appointmentResource(booking);
    final name = _serviceName(resource);
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts;
}

Map<String, double> _estimatedRevenueByService(
  List<Map<String, dynamic>> reservations,
  List<Map<String, dynamic>> resources,
) {
  final lookup = <String, Map<String, dynamic>>{};
  for (final resource in resources) {
    final name = _serviceName(resource);
    lookup[name.toLowerCase()] = resource;
    lookup[_serviceKey(resource).toLowerCase()] = resource;
  }

  final result = <String, double>{};
  for (final booking in reservations) {
    final resource = appointmentResource(booking);
    final name = _serviceName(resource);
    final resourceInfo = lookup[name.toLowerCase()] ?? resource;
    final price = _bookingRevenue(
      booking,
      resources,
      fallbackResource: resourceInfo,
    );
    result[name] = (result[name] ?? 0) + price;
  }
  return result;
}

double _estimatedRevenue(
  List<Map<String, dynamic>> reservations,
  List<Map<String, dynamic>> resources,
) {
  return reservations.fold<double>(
    0,
    (sum, booking) => sum + _bookingRevenue(booking, resources),
  );
}

double _bookingRevenue(
  Map<String, dynamic> booking,
  List<Map<String, dynamic>> resources, {
  Map<String, dynamic>? fallbackResource,
}) {
  final resource = fallbackResource ?? appointmentResource(booking);
  final raw =
      booking['total_price'] ?? booking['price'] ?? resource['price_per_hour'];
  final number = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString() ?? '');
  if (number != null && number > 0) return number;
  final service = _servicePrice(resource);
  return service > 0 ? service : 72000;
}

double _servicePrice(Map<String, dynamic> resource) {
  final raw = resource['price_per_hour'] ?? resource['price'];
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

int _highestCount(Map<String, int> counts) {
  if (counts.isEmpty) return 1;
  return counts.values.reduce((a, b) => a > b ? a : b);
}

bool _isActive(Map<String, dynamic> staff) => staff['is_active'] != false;

String _staffName(Map<String, dynamic> staff) {
  final name = staff['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = staff['first_name']?.toString().trim() ?? '';
  final last = staff['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  return combined.isNotEmpty ? combined : 'Barbero';
}

String _staffAvatar(Map<String, dynamic> staff) {
  final raw =
      staff['avatar_url'] ??
      staff['avatar'] ??
      staff['photo_url'] ??
      staff['photo'] ??
      staff['image'];
  final value = raw?.toString() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('assets/')) return value;
  return value;
}

String _serviceName(Map<String, dynamic> resource) {
  final name = resource['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  return 'Servicio';
}

String _serviceKey(Map<String, dynamic> resource) {
  final id = resource['id'];
  if (id != null) return id.toString();
  return _serviceName(resource);
}

String _clientName(Map<String, dynamic> booking) {
  final user =
      (booking['user'] as Map?) ?? (booking['client'] as Map?) ?? const {};
  final name = user['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = user['first_name']?.toString().trim() ?? '';
  final last = user['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  if (combined.isNotEmpty) return combined;
  return booking['customer_name']?.toString().trim() ?? '';
}

String _statusText(Map<String, dynamic> booking) {
  return (booking['status'] ?? '').toString().toLowerCase();
}

String _timeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? booking['time'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Hora pendiente';
  if (raw.contains(':')) return raw;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
  return raw;
}

String _bookingPriceLabel(
  Map<String, dynamic> booking,
  Map<String, dynamic> resource,
) {
  final raw =
      booking['price'] ?? booking['total_price'] ?? resource['price_per_hour'];
  final number = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString() ?? '');
  if (number == null || number <= 0) return '';
  return _formatCrc(number);
}

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}
