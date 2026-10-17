import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../bookings/appointment_helpers.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';
import 'admin_page_scaffold.dart';
import '../bookings/booking_detail_page.dart';
import '../gallery/gallery_page.dart';
import '../reviews/reviews_page.dart';
import '../../services/business_clock.dart';
import '../../services/localization_service.dart';

part 'admin_dashboard/hero.dart';
part 'admin_dashboard/modules.dart';
part 'admin_dashboard/metrics.dart';
part 'admin_dashboard/appointments.dart';
part 'admin_dashboard/data.dart';
part 'admin_dashboard/helpers.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late Future<_AdminDashboardData> _future;
  bool _quickActionBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<_AdminDashboardData> _loadData() async {
    final auth = context.read<AuthProvider>();
    await auth.ready;
    final api = auth.api;
    final today = DateFormat('yyyy-MM-dd').format(BusinessClock.today());

    final responses = await Future.wait([
      _safeFetch(
        () => api.getReservationsForDay(today),
        fallback: _fallbackReservationsResponse,
      ),
      _safeFetch(
        () => api.getStaff(perPage: 100),
        fallback: _fallbackStaffResponse,
      ),
      _safeFetch(
        () => api.getResources(page: 1, perPage: 100, sort: 'rating'),
        fallback: _fallbackResourcesResponse,
      ),
    ]);
    final reservationsResponse = responses[0];
    final staffResponse = responses[1];
    final resourcesResponse = responses[2];

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

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF132018),
      ),
    );
  }

  void _openBooking(Map<String, dynamic> booking) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
  }

  Future<void> _openNamedRoute(
    String route, {
    Map<String, dynamic>? arguments,
    String? successMessage,
  }) async {
    if (_quickActionBusy) return;
    setState(() => _quickActionBusy = true);
    try {
      final result = await Navigator.of(
        context,
      ).pushNamed(route, arguments: arguments);
      if (!mounted) return;
      if (successMessage != null && result == true) {
        _showSuccess(successMessage);
      }
    } catch (_) {
      if (mounted) {
        _showPlaceholder(tr('admin_section_unavailable'));
      }
    } finally {
      if (mounted) {
        setState(() => _quickActionBusy = false);
      }
    }
  }

  Future<void> _openBookingEntryPoint() {
    return _openNamedRoute(
      AppRoutes.home,
      arguments: const {'tab': 'services'},
    );
  }

  Future<void> _createBarber() {
    return _openNamedRoute(
      AppRoutes.staffForm,
      arguments: const {'createMode': true},
      successMessage: tr('admin_profile_created'),
    );
  }

  Future<void> _createService() {
    return _openNamedRoute(
      AppRoutes.adminServiceForm,
      arguments: const {'createMode': true},
      successMessage: tr('admin_service_created'),
    );
  }

  Future<void> _openAgenda() {
    return _openNamedRoute(AppRoutes.adminReservations);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final auth = context.watch<AuthProvider>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    if (!auth.canManageBusiness) {
      return Scaffold(
        backgroundColor: Color(0xFF090909),
        body: Center(
          child: Text(
            tr('admin_only'),
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: tr('admin_center'),
        subtitle: whiteLabel.displayName,
      ),
      backgroundColor: theme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF0D0D0D), Color(0xFF121212)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: theme.primary,
            onRefresh: _refresh,
            child: FutureBuilder<_AdminDashboardData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data ?? _AdminDashboardData.empty;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                final config = context.watch<AppConfig>();
                final metrics = _buildMetrics(data);
                final topServices = _buildTopServices(data);
                final performance = _buildPerformance(data);
                final modules = _buildModules(config);

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
                              whiteLabel: whiteLabel,
                              isLoading: isLoading,
                              onRefresh: _refresh,
                            ),
                            const SizedBox(height: 14),
                            _SectionIntro(
                              title: tr('admin_today_summary'),
                              subtitle: tr('admin_today_summary_body'),
                            ),
                            const SizedBox(height: 12),
                            _KpiGrid(metrics: metrics),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: tr('admin_today_appointments'),
                              actionLabel: tr('admin_view_schedule'),
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
                              title: tr('admin_team_performance'),
                              actionLabel: tr('admin_center'),
                              onTap: () =>
                                  _openNamedRoute(AppRoutes.adminDashboard),
                            ),
                            const SizedBox(height: 12),
                            _PerformanceList(items: performance),
                            const SizedBox(height: 18),
                            _SectionHeaderRow(
                              title: tr('admin_top_services'),
                              actionLabel: tr('admin_manage_services'),
                              onTap: () =>
                                  _openNamedRoute(AppRoutes.adminServices),
                            ),
                            const SizedBox(height: 12),
                            _TopServicesList(items: topServices),
                            const SizedBox(height: 24),
                            _SectionIntro(
                              title: tr('admin_management'),
                              subtitle: tr('admin_management_body'),
                            ),
                            const SizedBox(height: 12),
                            _AdminModuleGrid(
                              modules: modules,
                              onTap: (module) {
                                switch (module.id) {
                                  case 'reservations':
                                    _openNamedRoute(
                                      AppRoutes.adminReservations,
                                    );
                                    return;
                                  case 'staff':
                                    _openNamedRoute(AppRoutes.adminStaff);
                                    return;
                                  case 'services':
                                    _openNamedRoute(AppRoutes.adminServices);
                                    return;
                                  case 'business':
                                    _openNamedRoute(AppRoutes.businessProfile);
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
                                }
                              },
                            ),
                            const SizedBox(height: 24),
                            _SectionIntro(
                              title: tr('admin_quick_actions'),
                              subtitle: tr('admin_quick_actions_body'),
                            ),
                            const SizedBox(height: 12),
                            _QuickActionsRail(
                              isBusy: _quickActionBusy,
                              onAction: (action) {
                                switch (action.id) {
                                  case 'new_appointment':
                                    unawaited(_openBookingEntryPoint());
                                    return;
                                  case 'new_barber':
                                    unawaited(_createBarber());
                                    return;
                                  case 'new_service':
                                    unawaited(_createService());
                                    return;
                                  case 'schedule':
                                    unawaited(_openAgenda());
                                    return;
                                }
                              },
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

  List<_AdminModuleData> _buildModules(AppConfig config) {
    return [
      _AdminModuleData(
        id: 'reservations',
        icon: Icons.event_available_rounded,
        title: tr('admin_module_appointments'),
        subtitle: tr('admin_module_appointments_body'),
        badge: tr('active'),
      ),
      _AdminModuleData(
        id: 'staff',
        icon: Icons.groups_rounded,
        title: tr('admin_module_team'),
        subtitle: tr('admin_module_team_body'),
        badge: config.features.adminStaffManagement
            ? tr('active')
            : tr('admin_badge_demo'),
      ),
      _AdminModuleData(
        id: 'services',
        icon: Icons.content_cut_rounded,
        title: tr('admin_module_services'),
        subtitle: tr('admin_module_services_body'),
        badge: tr('active'),
      ),
      _AdminModuleData(
        id: 'business',
        icon: Icons.storefront_rounded,
        title: tr('admin_module_business'),
        subtitle: tr('admin_module_business_body'),
        badge: tr('active'),
      ),
      _AdminModuleData(
        id: 'gallery',
        icon: Icons.photo_library_rounded,
        title: tr('admin_module_gallery'),
        subtitle: tr('admin_module_gallery_body'),
        badge: tr('admin_badge_new'),
      ),
      _AdminModuleData(
        id: 'reviews',
        icon: Icons.rate_review_rounded,
        title: tr('reviews_title'),
        subtitle: tr('admin_module_reviews_body'),
        badge: tr('active'),
      ),
    ];
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
        label: tr('admin_today_appointments'),
        value: '${reservations.length}',
        footnote: pendingCount > 0
            ? tr('admin_metric_pending', args: {'count': pendingCount})
            : tr('admin_metric_steady'),
      ),
      _MetricData(
        icon: Icons.payments_rounded,
        label: tr('admin_metric_revenue'),
        value: _formatCrc(totalRevenue),
        footnote: serviceRevenue.isNotEmpty
            ? tr('admin_metric_top', args: {'name': serviceRevenue.keys.first})
            : tr('admin_metric_revenue_note'),
      ),
      _MetricData(
        icon: Icons.groups_rounded,
        label: tr('admin_metric_active_team'),
        value: '${activeBarbers.length}',
        footnote: activeBarbers.isNotEmpty
            ? tr('admin_metric_team_available')
            : tr('admin_metric_no_activity'),
      ),
      _MetricData(
        icon: Icons.content_cut_rounded,
        label: tr('admin_top_services'),
        value: '${serviceCounts.values.fold<int>(0, (a, b) => a + b)}',
        footnote: serviceRevenue.isNotEmpty
            ? tr('admin_metric_top', args: {'name': serviceRevenue.keys.first})
            : tr('admin_metric_based_on_today'),
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

    if (items.isNotEmpty) return items;

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

    if (items.isNotEmpty) return items;

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
