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
