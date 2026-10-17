import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/live_queue.dart';
import '../bookings/appointment_helpers.dart';

enum OperationsLane { newOrders, preparing, ready, dispatched }

class OperationsBoard extends StatefulWidget {
  final DateTime selectedDay;

  const OperationsBoard({super.key, required this.selectedDay});

  @override
  State<OperationsBoard> createState() => _OperationsBoardState();
}

class _OperationsBoardState extends State<OperationsBoard> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _localStatusOverrides = {};
  final Map<String, String> _localPaymentOverrides = {};
  final Set<String> _channelFilters = <String>{};
  bool _vipOnly = false;
  bool _duplicateOnly = false;
  bool _priorityOnly = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadBookings() async {
    final auth = context.read<AuthProvider>();
    await auth.ready;
    final iso = DateFormat('yyyy-MM-dd').format(widget.selectedDay);
    final response = await auth.api.getReservationsForDay(iso);
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .where(_belongsToCurrentOrganization)
          .toList(growable: false);
    }
    if (data is Map) {
      final item = Map<String, dynamic>.from(data);
      return _belongsToCurrentOrganization(item) ? [item] : const [];
    }
    return const [];
  }

  bool _belongsToCurrentOrganization(Map<String, dynamic> booking) {
    final user = context.read<AuthProvider>().user;
    final bookingOrg = booking['business_id'] ?? booking['organization_id'];
    final userOrg = user?['business_id'] ?? user?['organization_id'];
    if (bookingOrg == null || userOrg == null) return true;
    return bookingOrg.toString() == userOrg.toString();
  }

  void _selectBooking(Map<String, dynamic> booking) {
    _openSheet(booking);
  }

  void _openSheet(Map<String, dynamic> booking) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Operations detail',
      barrierColor: Colors.black.withValues(alpha: .55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final screen = MediaQuery.sizeOf(dialogContext);
        final panelWidth = screen.width.clamp(480.0, 560.0).toDouble();
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: panelWidth,
              height: screen.height,
              child: OperationsDetailSheet(
                booking: booking,
                lane: _laneForBooking(booking),
                onAction: _performAdminAction,
                onClose: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            );
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  Future<bool> _performAdminAction(
    Map<String, dynamic> booking,
    String targetStatus,
  ) async {
    final action = _adminActionLabel(targetStatus);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$action cita'),
        content: Text('¿Confirmás que querés $action esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;

    final id = int.tryParse(booking['id']?.toString() ?? '');
    if (id == null) return false;
    try {
      final api = context.read<AuthProvider>().api;
      final response = switch (targetStatus) {
        'confirmed' => await api.confirmReservation(id),
        'rejected' => await api.rejectReservation(id),
        'cancelled' => await api.cancelReservation(id),
        'completed' => await api.completeReservation(id),
        'paid' => await api.markReservationPaid(id),
        _ => throw StateError('Unsupported booking status'),
      };
      final key = operationsBookingIdentity(booking);
      setState(() {
        _localStatusOverrides[key] =
            response['status']?.toString() ?? targetStatus;
        if (targetStatus == 'paid') {
          _localPaymentOverrides[key] =
              response['payment_status']?.toString() ?? 'paid';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cita $action.'),
            backgroundColor: const Color(0xFF132018),
          ),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo $action la cita.'),
            backgroundColor: const Color(0xFF5B2020),
          ),
        );
      }
      return false;
    }
  }

  String _adminActionLabel(String targetStatus) {
    switch (targetStatus) {
      case 'confirmed':
        return 'confirmar';
      case 'rejected':
        return 'rechazar';
      case 'cancelled':
        return 'cancelar';
      case 'completed':
        return 'completar';
      case 'paid':
        return 'marcar como pagada';
      default:
        return 'actualizar';
    }
  }

  OperationsLane _laneForBooking(Map<String, dynamic> booking) {
    final key = operationsBookingIdentity(booking);
    return operationsLaneFromStatus(
      _localStatusOverrides[key] ?? booking['status']?.toString(),
    );
  }

  List<Map<String, dynamic>> _decorateBookings(
    List<Map<String, dynamic>> bookings,
  ) {
    return bookings
        .map((booking) {
          final key = operationsBookingIdentity(booking);
          final status = _localStatusOverrides[key];
          final paymentStatus = _localPaymentOverrides[key];
          if (status == null && paymentStatus == null) return booking;
          return {
            ...booking,
            'status': ?status,
            'payment_status': ?paymentStatus,
            if (status != null)
              'kanban_lane': operationsLaneName(
                operationsLaneFromStatus(status),
              ),
          };
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> bookings,
  ) {
    final query = _searchQuery.trim().toLowerCase();
    return bookings
        .where((booking) {
          final lane = _laneForBooking(booking);
          if (_channelFilters.isNotEmpty &&
              !_channelFilters.contains(operationsChannelKey(booking))) {
            return false;
          }
          if (_vipOnly && !operationsIsVip(booking)) return false;
          if (_duplicateOnly && !operationsIsDuplicate(booking)) return false;
          if (_priorityOnly && !operationsIsPriority(booking)) return false;
          if (query.isEmpty) return true;
          final haystack = <String>[
            operationsCustomerName(booking),
            appointmentServiceName(booking),
            operationsBookingIdentity(booking),
            operationsChannelName(booking),
            operationsLaneLabel(lane),
          ].join(' ').toLowerCase();
          return haystack.contains(query);
        })
        .toList(growable: false);
  }

  Map<OperationsLane, List<Map<String, dynamic>>> _groupByLane(
    List<Map<String, dynamic>> bookings,
  ) {
    final grouped = <OperationsLane, List<Map<String, dynamic>>>{
      OperationsLane.newOrders: [],
      OperationsLane.preparing: [],
      OperationsLane.ready: [],
      OperationsLane.dispatched: [],
    };
    final sorted = operationsSortBookings(bookings);
    for (final booking in sorted) {
      grouped[_laneForBooking(booking)]!.add(booking);
    }
    return grouped;
  }

  Map<String, int> _channelCounts(List<Map<String, dynamic>> bookings) {
    final counts = <String, int>{};
    for (final booking in bookings) {
      final key = operationsChannelKey(booking);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  void _toggleChannel(String key) {
    setState(() {
      if (_channelFilters.contains(key)) {
        _channelFilters.remove(key);
      } else {
        _channelFilters.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080808), Color(0xFF0B0A0A), Color(0xFF0A0909)],
        ),
      ),
      child: LiveQueue<List<Map<String, dynamic>>>(
        loader: _loadBookings,
        refreshInterval: const Duration(seconds: 6),
        builder: (context, snapshot) {
          final bookings = _applyFilters(
            _decorateBookings(snapshot.data ?? const []),
          );
          final grouped = _groupByLane(bookings);
          final channelCounts = _channelCounts(bookings);
          final screenWidth = MediaQuery.sizeOf(context).width;
          final mode = _responsiveMode(screenWidth);

          return Stack(
            children: [
              RefreshIndicator(
                color: theme.primary,
                backgroundColor: const Color(0xFF131110),
                onRefresh: () async {
                  await _loadBookings();
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: _BoardHeader(
                          searchController: _searchController,
                          searchQuery: _searchQuery,
                          onSearchChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          lastUpdated: snapshot.lastUpdated,
                          isLoading: snapshot.loading,
                          errorText: snapshot.error?.toString(),
                          onClearFilters: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                              _channelFilters.clear();
                              _vipOnly = false;
                              _duplicateOnly = false;
                              _priorityOnly = false;
                            });
                          },
                          channelFilters: _channelFilters,
                          vipOnly: _vipOnly,
                          duplicateOnly: _duplicateOnly,
                          priorityOnly: _priorityOnly,
                          onToggleVip: () =>
                              setState(() => _vipOnly = !_vipOnly),
                          onToggleDuplicate: () =>
                              setState(() => _duplicateOnly = !_duplicateOnly),
                          onTogglePriority: () =>
                              setState(() => _priorityOnly = !_priorityOnly),
                          onToggleChannel: _toggleChannel,
                          channelCounts: channelCounts,
                          totalCount: bookings.length,
                        ),
                      ),
                    ),
                    if (snapshot.error != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _BoardAlert(
                            title: 'No fue posible actualizar el tablero',
                            subtitle:
                                'La última versión disponible sigue visible mientras se actualizan las citas.',
                            icon: Icons.wifi_off_rounded,
                          ),
                        ),
                      ),
                    if (bookings.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                          child: _EmptyBoardState(
                            title: 'No hay citas para este día.',
                            subtitle:
                                'Las citas de esta fecha aparecerán aquí.',
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                          child: _ResponsiveBoard(
                            mode: mode,
                            grouped: grouped,
                            onCardTap: _selectBooking,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _LiveQueueFooter(
                          total: bookings.length,
                          loaded: snapshot.lastUpdated,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

enum _ResponsiveBoardMode { mobile, tablet, laptop, desktop }

_ResponsiveBoardMode _responsiveMode(double width) {
  if (width < 600) return _ResponsiveBoardMode.mobile;
  if (width < 900) return _ResponsiveBoardMode.tablet;
  if (width < 1200) return _ResponsiveBoardMode.laptop;
  return _ResponsiveBoardMode.desktop;
}

class _ResponsiveBoard extends StatelessWidget {
  final _ResponsiveBoardMode mode;
  final Map<OperationsLane, List<Map<String, dynamic>>> grouped;
  final ValueChanged<Map<String, dynamic>> onCardTap;

  const _ResponsiveBoard({
    required this.mode,
    required this.grouped,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final lanes = OperationsLane.values;
    final columns = lanes
        .map(
          (lane) => OperationsColumn(
            lane: lane,
            bookings: grouped[lane] ?? const [],
            onCardTap: onCardTap,
          ),
        )
        .toList(growable: false);

    switch (mode) {
      case _ResponsiveBoardMode.mobile:
        return _MobileFallbackList(
          bookings: lanes
              .expand((lane) => grouped[lane] ?? const <Map<String, dynamic>>[])
              .toList(),
          onCardTap: onCardTap,
        );
      case _ResponsiveBoardMode.tablet:
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: columns[0]),
                const SizedBox(width: 12),
                Expanded(child: columns[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: columns[2]),
                const SizedBox(width: 12),
                Expanded(child: columns[3]),
              ],
            ),
          ],
        );
      case _ResponsiveBoardMode.laptop:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 1260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < columns.length; i++) ...[
                  SizedBox(width: 300, child: columns[i]),
                  if (i < columns.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        );
      case _ResponsiveBoardMode.desktop:
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < columns.length; i++) ...[
              Expanded(child: columns[i]),
              if (i < columns.length - 1) const SizedBox(width: 12),
            ],
          ],
        );
    }
  }
}

class OperationsColumn extends StatelessWidget {
  final OperationsLane lane;
  final List<Map<String, dynamic>> bookings;
  final ValueChanged<Map<String, dynamic>> onCardTap;

  const OperationsColumn({
    super.key,
    required this.lane,
    required this.bookings,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _operationsLaneSpec(lane);
    final avg = operationsAverageWaitMinutes(bookings);
    final avgLabel = bookings.isEmpty
        ? '0 min'
        : operationsWaitLabel(avg.round());

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121010).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: spec.color.withValues(alpha: .14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3A000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OperationsColumnHeader(
            lane: lane,
            count: bookings.length,
            averageWaitLabel: avgLabel,
          ),
          const SizedBox(height: 12),
          if (bookings.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
              child: _EmptyColumnState(
                message: spec.emptyMessage,
                icon: spec.icon,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (final booking in bookings) ...[
                    OperationsCard(
                      booking: booking,
                      lane: lane,
                      onTap: () => onCardTap(booking),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class OperationsColumnHeader extends StatelessWidget {
  final OperationsLane lane;
  final int count;
  final String averageWaitLabel;

  const OperationsColumnHeader({
    super.key,
    required this.lane,
    required this.count,
    required this.averageWaitLabel,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _operationsLaneSpec(lane);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            spec.color.withValues(alpha: .18),
            spec.color.withValues(alpha: .06),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: spec.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: spec.color.withValues(alpha: .35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Citas ${spec.label.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .56),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '($count)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Promedio: $averageWaitLabel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .70),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class OperationsCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final OperationsLane lane;
  final VoidCallback onTap;

  const OperationsCard({
    super.key,
    required this.booking,
    required this.lane,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final spec = _operationsLaneSpec(lane);
    final customer = operationsCustomerName(booking);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: const Color(0xFF171311),
            borderRadius: BorderRadius.circular(18),
            border: Border(left: BorderSide(color: spec.color, width: 3)),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: spec.color.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.content_cut_rounded,
                      size: 16,
                      color: spec.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${appointmentServiceName(booking)} · ${operationsTimeLabel(booking)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      operationsBookingIdentity(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .44),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniMeta(
                    icon: Icons.schedule_rounded,
                    label: operationsElapsedLabel(booking),
                  ),
                  _MiniMeta(
                    icon: Icons.payments_rounded,
                    label: appointmentPriceLabel(booking),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OperationsDetailSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final OperationsLane lane;
  final Future<bool> Function(Map<String, dynamic> booking, String targetStatus)
  onAction;
  final VoidCallback onClose;

  const OperationsDetailSheet({
    super.key,
    required this.booking,
    required this.lane,
    required this.onAction,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final customer = operationsCustomerName(booking);
    final spec = _operationsLaneSpec(lane);
    final actions = _actionsForBooking(booking, theme.primary);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          color: const Color(0xFF11100F),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 30,
              offset: Offset(-10, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${spec.label} · ${operationsElapsedLabel(booking)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .66),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _DetailSection(
                    title: 'Cliente',
                    icon: Icons.person_rounded,
                    children: [
                      _DetailRow(label: 'Nombre', value: customer),
                      _DetailRow(
                        label: 'Teléfono',
                        value: _bookingPhone(booking),
                      ),
                      _DetailRow(
                        label: 'Código',
                        value: operationsBookingIdentity(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Servicio',
                    icon: Icons.content_cut_rounded,
                    children: [
                      _DetailRow(
                        label: 'Servicio',
                        value: appointmentServiceName(booking),
                      ),
                      _DetailRow(
                        label: 'Barbero',
                        value: appointmentBarberName(booking),
                      ),
                      _DetailRow(
                        label: 'Transcurrido',
                        value: operationsElapsedLabel(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Acciones',
                    icon: Icons.playlist_add_check_rounded,
                    children: [
                      for (final action in actions) ...[
                        _DetailActionButton(
                          label: action.label,
                          icon: action.icon,
                          accent: action.accent,
                          onPressed: () async {
                            if (await onAction(booking, action.targetStatus)) {
                              onClose();
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (actions.isEmpty)
                        Text(
                          'Esta cita ya está en su estado final.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Horario',
                    icon: Icons.history_rounded,
                    children: [
                      _DetailRow(
                        label: 'Fecha',
                        value: appointmentDateLabel(booking),
                      ),
                      _DetailRow(
                        label: 'Hora',
                        value: appointmentTimeLabel(booking),
                      ),
                      _DetailRow(
                        label: 'Duración',
                        value: _bookingDurationLabel(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Estado',
                    icon: Icons.warning_amber_rounded,
                    children: [
                      _DetailRow(
                        label: 'Estado',
                        value: operationsStatusLabel(booking),
                      ),
                      _DetailRow(
                        label: 'Precio',
                        value: appointmentPriceLabel(booking),
                      ),
                      _DetailRow(label: 'Notas', value: _bookingNotes(booking)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: 'Código',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _DetailRow(
                        label: 'Código',
                        value: operationsBookingIdentity(booking),
                      ),
                      _DetailRow(
                        label: 'Última actualización',
                        value: operationsUpdatedLabel(booking),
                      ),
                    ],
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

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161311),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: theme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onPressed;

  const _DetailActionButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: const Color(0xFF090909),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyBoardState extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyBoardState({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151110),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.primary.withValues(alpha: .14)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primary.withValues(alpha: .12),
            ),
            child: Icon(
              Icons.view_column_outlined,
              color: theme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumnState extends StatelessWidget {
  final String message;
  final IconData icon;

  const _EmptyColumnState({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0D0D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white54, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onClearFilters;
  final Set<String> channelFilters;
  final bool vipOnly;
  final bool duplicateOnly;
  final bool priorityOnly;
  final VoidCallback onToggleVip;
  final VoidCallback onToggleDuplicate;
  final VoidCallback onTogglePriority;
  final void Function(String key) onToggleChannel;
  final Map<String, int> channelCounts;
  final int totalCount;

  const _BoardHeader({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.lastUpdated,
    required this.isLoading,
    required this.errorText,
    required this.onClearFilters,
    required this.channelFilters,
    required this.vipOnly,
    required this.duplicateOnly,
    required this.priorityOnly,
    required this.onToggleVip,
    required this.onToggleDuplicate,
    required this.onTogglePriority,
    required this.onToggleChannel,
    required this.channelCounts,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121010).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agenda del día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Citas programadas. $totalCount citas visibles.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(
                    label: isLoading ? 'Sincronizando' : 'Agenda actualizada',
                    accent: isLoading ? Colors.white54 : theme.secondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastUpdated == null
                        ? 'Esperando la primera actualización'
                        : 'Actualizado a las ${DateFormat.Hm().format(lastUpdated!.toLocal())}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .54),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            _BoardAlert(
              title: 'Aviso de datos',
              subtitle: errorText!,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar cliente, código o profesional',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _StatusPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BoardAlert extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _BoardAlert({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1411),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12,
                    height: 1.35,
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

class _MobileFallbackList extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final ValueChanged<Map<String, dynamic>> onCardTap;

  const _MobileFallbackList({required this.bookings, required this.onCardTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final booking in bookings) ...[
          OperationsCard(
            booking: booking,
            lane: operationsLaneFromStatus(booking['status']?.toString()),
            onTap: () => onCardTap(booking),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniMeta({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1715),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveQueueFooter extends StatelessWidget {
  final int total;
  final DateTime? loaded;

  const _LiveQueueFooter({required this.total, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.bolt_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: .7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Se muestran $total citas en este momento.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .66),
              fontSize: 12,
            ),
          ),
        ),
        if (loaded != null)
          Text(
            DateFormat.Hm().format(loaded!.toLocal()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .5),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

class _LaneAction {
  final String label;
  final IconData icon;
  final Color accent;
  final String targetStatus;

  const _LaneAction({
    required this.label,
    required this.icon,
    required this.accent,
    required this.targetStatus,
  });
}

List<_LaneAction> _actionsForBooking(
  Map<String, dynamic> booking,
  Color primaryColor,
) {
  final actions = switch (booking['status']?.toString().toLowerCase()) {
    'pending' || 'pending_review' => [
      _LaneAction(
        label: 'Confirmar',
        icon: Icons.check_rounded,
        accent: primaryColor,
        targetStatus: 'confirmed',
      ),
      const _LaneAction(
        label: 'Rechazar',
        icon: Icons.block_rounded,
        accent: Color(0xFFFF8A80),
        targetStatus: 'rejected',
      ),
      const _LaneAction(
        label: 'Cancelar',
        icon: Icons.cancel_outlined,
        accent: Color(0xFFFF8A80),
        targetStatus: 'cancelled',
      ),
    ],
    'confirmed' => [
      _LaneAction(
        label: 'Completar cita',
        icon: Icons.task_alt_rounded,
        accent: primaryColor,
        targetStatus: 'completed',
      ),
      const _LaneAction(
        label: 'Cancelar',
        icon: Icons.cancel_outlined,
        accent: Color(0xFFFF8A80),
        targetStatus: 'cancelled',
      ),
    ],
    _ => const <_LaneAction>[],
  };
  final terminalWithoutService = const {'cancelled', 'rejected'};
  if (booking['payment_status']?.toString().toLowerCase() != 'paid' &&
      !terminalWithoutService.contains(
        booking['status']?.toString().toLowerCase(),
      )) {
    return [
      ...actions,
      const _LaneAction(
        label: 'Marcar pagada',
        icon: Icons.payments_rounded,
        accent: Color(0xFF65D6A5),
        targetStatus: 'paid',
      ),
    ];
  }
  return actions;
}

class _LaneSpec {
  final OperationsLane lane;
  final String label;
  final Color color;
  final IconData icon;
  final String emptyMessage;
  final List<String> statuses;

  const _LaneSpec({
    required this.lane,
    required this.label,
    required this.color,
    required this.icon,
    required this.emptyMessage,
    required this.statuses,
  });
}

const _laneSpecs = <OperationsLane, _LaneSpec>{
  OperationsLane.newOrders: _LaneSpec(
    lane: OperationsLane.newOrders,
    label: 'Pendientes',
    color: Color(0xFF4DA3FF),
    icon: Icons.inbox_rounded,
    emptyMessage: 'No hay citas pendientes.',
    statuses: ['pending_review', 'confirmed'],
  ),
  OperationsLane.preparing: _LaneSpec(
    lane: OperationsLane.preparing,
    label: 'En atención',
    color: Color(0xFFFFB84D),
    icon: Icons.kitchen_rounded,
    emptyMessage: 'No hay citas en atención.',
    statuses: ['preparing'],
  ),
  OperationsLane.ready: _LaneSpec(
    lane: OperationsLane.ready,
    label: 'Por cerrar',
    color: Color(0xFF5BD46D),
    icon: Icons.check_circle_rounded,
    emptyMessage: 'No hay citas por cerrar.',
    statuses: ['ready_for_dispatch'],
  ),
  OperationsLane.dispatched: _LaneSpec(
    lane: OperationsLane.dispatched,
    label: 'Completadas',
    color: Color(0xFF8B8B8B),
    icon: Icons.inventory_2_rounded,
    emptyMessage: 'No hay citas completadas.',
    statuses: ['dispatched'],
  ),
};

_LaneSpec _operationsLaneSpec(OperationsLane lane) => _laneSpecs[lane]!;

String operationsLaneLabel(OperationsLane lane) =>
    _operationsLaneSpec(lane).label;

String operationsLaneName(OperationsLane lane) {
  switch (lane) {
    case OperationsLane.newOrders:
      return 'new_orders';
    case OperationsLane.preparing:
      return 'preparing';
    case OperationsLane.ready:
      return 'ready_for_dispatch';
    case OperationsLane.dispatched:
      return 'dispatched';
  }
}

String operationsLaneStatus(OperationsLane lane) => operationsLaneName(lane);

OperationsLane operationsLaneFromStatus(String? status) {
  final raw = (status ?? '').trim().toLowerCase();
  if (raw.isEmpty ||
      raw.contains('pending') ||
      raw.contains('confirm') ||
      raw.contains('review')) {
    return OperationsLane.newOrders;
  }
  if (raw.contains('prepar')) return OperationsLane.preparing;
  if (raw.contains('ready')) return OperationsLane.ready;
  if (raw.contains('dispatch') ||
      raw.contains('complete') ||
      raw.contains('done')) {
    return OperationsLane.dispatched;
  }
  return OperationsLane.newOrders;
}

String operationsBookingIdentity(Map<String, dynamic> booking) {
  final code = booking['booking_code']?.toString().trim() ?? '';
  if (code.isNotEmpty) return code;
  final id = booking['id'];
  if (id != null) return id.toString();
  return '${booking['date'] ?? ''}-${booking['time_slot'] ?? ''}';
}

String operationsCustomerName(Map<String, dynamic> booking) {
  final user =
      (booking['user'] as Map?) ?? (booking['client'] as Map?) ?? const {};
  final name = user['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = user['first_name']?.toString().trim() ?? '';
  final last = user['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  if (combined.isNotEmpty) return combined;
  return booking['customer_name']?.toString().trim().isNotEmpty == true
      ? booking['customer_name'].toString()
      : 'Cliente';
}

String operationsChannelKey(Map<String, dynamic> booking) {
  final raw = booking['channel'] ?? booking['source'] ?? booking['origin'];
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.isEmpty) return 'direct';
  if (value.contains('whatsapp')) return 'whatsapp';
  if (value.contains('instagram')) return 'instagram';
  if (value.contains('facebook')) return 'facebook';
  if (value.contains('web') || value.contains('site')) return 'web';
  if (value.contains('phone') || value.contains('call')) return 'phone';
  return value;
}

String operationsChannelName(Map<String, dynamic> booking) {
  switch (operationsChannelKey(booking)) {
    case 'whatsapp':
      return 'WhatsApp';
    case 'instagram':
      return 'Instagram';
    case 'facebook':
      return 'Facebook';
    case 'web':
      return 'Web';
    case 'phone':
      return 'Phone';
    default:
      return 'Direct';
  }
}

IconData operationsChannelIcon(Map<String, dynamic> booking) {
  switch (operationsChannelKey(booking)) {
    case 'whatsapp':
      return Icons.chat_bubble_rounded;
    case 'instagram':
      return Icons.camera_alt_rounded;
    case 'facebook':
      return Icons.facebook_rounded;
    case 'web':
      return Icons.language_rounded;
    case 'phone':
      return Icons.call_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

bool operationsIsVip(Map<String, dynamic> booking) {
  final raw = booking['vip'] ?? booking['is_vip'] ?? booking['priority_tier'];
  if (raw is bool) return raw;
  final value = raw?.toString().toLowerCase() ?? '';
  return value.contains('vip') || value.contains('premium');
}

bool operationsIsDuplicate(Map<String, dynamic> booking) {
  final raw =
      booking['duplicate'] ??
      booking['is_duplicate'] ??
      booking['duplicate_count'];
  if (raw is bool) return raw;
  if (raw is num) return raw > 0;
  final value = raw?.toString().toLowerCase() ?? '';
  return value == 'true' || value == 'yes';
}

bool operationsIsPriority(Map<String, dynamic> booking) {
  final raw =
      booking['priority'] ??
      booking['priority_level'] ??
      booking['high_priority'];
  if (raw is bool) return raw;
  if (raw is num) return raw > 0;
  final value = raw?.toString().toLowerCase() ?? '';
  return value.contains('high') || value.contains('urgent') || value == 'true';
}

double? operationsParserConfidence(Map<String, dynamic> booking) {
  final raw = booking['parser_confidence'] ?? booking['confidence'];
  if (raw is num) {
    final number = raw.toDouble();
    return number <= 1 ? number * 100 : number;
  }
  return double.tryParse(raw?.toString() ?? '');
}

String operationsConfidenceLabel(Map<String, dynamic> booking) {
  final confidence = operationsParserConfidence(booking);
  if (confidence == null) return 'n/a';
  return '${confidence.clamp(0, 100).round()}%';
}

int operationsItemCount(Map<String, dynamic> booking) {
  for (final key in const ['items_count', 'item_count']) {
    final raw = booking[key];
    if (raw is num && raw > 0) return raw.toInt();
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
  }
  for (final key in const ['items', 'line_items', 'services']) {
    final raw = booking[key];
    if (raw is List && raw.isNotEmpty) return raw.length;
  }
  return 1;
}

DateTime? operationsCreatedAt(Map<String, dynamic> booking) {
  final raw = booking['created_at'] ?? booking['updated_at'];
  final created = DateTime.tryParse(raw?.toString() ?? '');
  if (created != null) return created;

  final date = booking['date'];
  final day = date is DateTime
      ? date
      : DateTime.tryParse(date?.toString() ?? '');
  if (day == null) return null;
  final time = booking['time_slot']?.toString().trim() ?? '';
  if (time.isEmpty) return day;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return day;
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

DateTime? operationsScheduledAt(Map<String, dynamic> booking) {
  final date = booking['date'];
  final day = date is DateTime
      ? date
      : DateTime.tryParse(date?.toString() ?? '');
  if (day == null) return null;
  final time = booking['time_slot']?.toString().trim() ?? '';
  if (time.isEmpty) return day;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return day;
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

int operationsAgeMinutes(Map<String, dynamic> booking) {
  final reference =
      operationsCreatedAt(booking) ?? operationsScheduledAt(booking);
  if (reference == null) return 0;
  final delta = DateTime.now().difference(reference);
  return delta.inMinutes < 0 ? 0 : delta.inMinutes;
}

String operationsWaitLabel(int minutes) {
  if (minutes <= 0) return '0 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) {
    return hours == 1 ? '1 h' : '$hours h';
  }
  return hours == 1 ? '1 h $remaining min' : '$hours h $remaining min';
}

String operationsElapsedLabel(Map<String, dynamic> booking) {
  return operationsWaitLabel(operationsAgeMinutes(booking));
}

String operationsTimeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? booking['time'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Hora pendiente';
  return raw;
}

String operationsCreatedLabel(Map<String, dynamic> booking) {
  final created = operationsCreatedAt(booking);
  if (created == null) return 'n/a';
  return DateFormat('yyyy-MM-dd HH:mm').format(created.toLocal());
}

String operationsUpdatedLabel(Map<String, dynamic> booking) {
  final updated = DateTime.tryParse((booking['updated_at'] ?? '').toString());
  if (updated == null) return operationsCreatedLabel(booking);
  return DateFormat('yyyy-MM-dd HH:mm').format(updated.toLocal());
}

String operationsOrganizationLabel(Map<String, dynamic> booking) {
  final raw = booking['business_id'] ?? booking['organization_id'];
  if (raw == null) return 'Barbería actual';
  return raw.toString();
}

String operationsStatusLabel(Map<String, dynamic> booking) {
  final raw = (booking['status'] ?? '').toString().trim().toLowerCase();
  if (raw.isEmpty) return 'Pendiente';
  if (raw.contains('cancel')) return 'Cancelada';
  if (raw.contains('complete') ||
      raw.contains('done') ||
      raw.contains('finish')) {
    return 'Completada';
  }
  if (raw.contains('prepare')) return 'En atención';
  if (raw.contains('ready')) return 'Por cerrar';
  if (raw.contains('pending') || raw.contains('confirm')) return 'Pendiente';
  return raw;
}

String _bookingPhone(Map<String, dynamic> booking) {
  final user =
      (booking['user'] as Map?) ?? (booking['client'] as Map?) ?? const {};
  for (final key in const ['phone', 'mobile', 'phone_number']) {
    final value = user[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  for (final key in const ['customer_phone', 'phone']) {
    final value = booking[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return 'No registrado';
}

String _bookingDurationLabel(Map<String, dynamic> booking) {
  final raw =
      booking['duration_minutes'] ??
      booking['duration_hours'] ??
      booking['duration'];
  final minutes = raw is num
      ? raw.toInt()
      : int.tryParse(raw?.toString() ?? '');
  if (minutes == null || minutes <= 0) return '45 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (remainder == 0) return hours == 1 ? '1 h' : '$hours h';
  return hours == 1 ? '1 h $remainder min' : '$hours h $remainder min';
}

String _bookingNotes(Map<String, dynamic> booking) {
  final raw =
      (booking['notes'] ?? booking['note'] ?? booking['description'])
          ?.toString()
          .trim() ??
      '';
  if (raw.isEmpty) return 'Sin notas';
  return raw;
}

List<Map<String, dynamic>> operationsSortBookings(
  List<Map<String, dynamic>> bookings,
) {
  final items = bookings.toList(growable: false);
  items.sort((a, b) {
    final at =
        operationsCreatedAt(a) ?? operationsScheduledAt(a) ?? DateTime(1970);
    final bt =
        operationsCreatedAt(b) ?? operationsScheduledAt(b) ?? DateTime(1970);
    final diff = at.compareTo(bt);
    if (diff != 0) return diff;
    return operationsBookingIdentity(a).compareTo(operationsBookingIdentity(b));
  });
  return items;
}

double operationsAverageWaitMinutes(List<Map<String, dynamic>> bookings) {
  if (bookings.isEmpty) return 0;
  final total = bookings.fold<int>(
    0,
    (sum, booking) => sum + operationsAgeMinutes(booking),
  );
  return total / bookings.length;
}
