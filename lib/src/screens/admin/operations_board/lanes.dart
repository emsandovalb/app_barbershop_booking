part of '../operations_board.dart';

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

Map<OperationsLane, _LaneSpec> get _laneSpecs => {
  OperationsLane.newOrders: _LaneSpec(
    lane: OperationsLane.newOrders,
    label: tr('ops_lane_pending'),
    color: Color(0xFF4DA3FF),
    icon: Icons.inbox_rounded,
    emptyMessage: tr('ops_lane_pending_empty'),
    statuses: ['pending_review', 'confirmed'],
  ),
  OperationsLane.preparing: _LaneSpec(
    lane: OperationsLane.preparing,
    label: tr('ops_status_in_service'),
    color: Color(0xFFFFB84D),
    icon: Icons.kitchen_rounded,
    emptyMessage: tr('ops_lane_in_service_empty'),
    statuses: ['preparing'],
  ),
  OperationsLane.ready: _LaneSpec(
    lane: OperationsLane.ready,
    label: tr('ops_status_to_close'),
    color: Color(0xFF5BD46D),
    icon: Icons.check_circle_rounded,
    emptyMessage: tr('ops_lane_to_close_empty'),
    statuses: ['ready_for_dispatch'],
  ),
  OperationsLane.dispatched: _LaneSpec(
    lane: OperationsLane.dispatched,
    label: tr('bookings_tab_completed'),
    color: Color(0xFF8B8B8B),
    icon: Icons.inventory_2_rounded,
    emptyMessage: tr('ops_lane_completed_empty'),
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
