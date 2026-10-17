import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/live_queue.dart';
import '../bookings/appointment_helpers.dart';
import '../../services/localization_service.dart';

part 'operations_board/board_header.dart';
part 'operations_board/board_columns.dart';
part 'operations_board/detail_sheet.dart';
part 'operations_board/lanes.dart';
part 'operations_board/booking_helpers.dart';

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
      barrierLabel: tr('booking_details_title'),
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
    // One complete sentence per action and language (keys ops_<kind>_<status>).
    String text(String kind) => tr('ops_${kind}_$targetStatus');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(text('title')),
        content: Text(text('question')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(tr('ops_back')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(text('button')),
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
            content: Text(text('done')),
            backgroundColor: const Color(0xFF132018),
          ),
        );
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(text('failed')),
            backgroundColor: const Color(0xFF5B2020),
          ),
        );
      }
      return false;
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
            if (status != null) 'status': status,
            if (paymentStatus != null) 'payment_status': paymentStatus,
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
                            title: tr('ops_board_refresh_failed'),
                            subtitle: tr('ops_board_refresh_failed_body'),
                            icon: Icons.wifi_off_rounded,
                          ),
                        ),
                      ),
                    if (bookings.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
                          child: _EmptyBoardState(
                            title: tr('ops_board_empty'),
                            subtitle: tr('ops_board_empty_body'),
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

_ResponsiveBoardMode _responsiveMode(double width) {
  if (width < 600) return _ResponsiveBoardMode.mobile;
  if (width < 900) return _ResponsiveBoardMode.tablet;
  if (width < 1200) return _ResponsiveBoardMode.laptop;
  return _ResponsiveBoardMode.desktop;
}
