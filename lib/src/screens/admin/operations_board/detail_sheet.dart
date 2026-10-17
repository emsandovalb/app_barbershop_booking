part of '../operations_board.dart';

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
                    title: tr('ops_client'),
                    icon: Icons.person_rounded,
                    children: [
                      _DetailRow(label: tr('form_name'), value: customer),
                      _DetailRow(
                        label: tr('form_phone'),
                        value: _bookingPhone(booking),
                      ),
                      _DetailRow(
                        label: tr('ops_code'),
                        value: operationsBookingIdentity(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: tr('appointment_default_service'),
                    icon: Icons.content_cut_rounded,
                    children: [
                      _DetailRow(
                        label: tr('appointment_default_service'),
                        value: appointmentServiceName(booking),
                      ),
                      _DetailRow(
                        label: tr('booking_barber_label'),
                        value: appointmentBarberName(booking),
                      ),
                      _DetailRow(
                        label: tr('ops_elapsed'),
                        value: operationsElapsedLabel(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: tr('ops_actions'),
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
                          tr('ops_final_state'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .68),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: tr('ops_schedule'),
                    icon: Icons.history_rounded,
                    children: [
                      _DetailRow(
                        label: tr('booking_detail_date'),
                        value: appointmentDateLabel(booking),
                      ),
                      _DetailRow(
                        label: tr('booking_detail_time'),
                        value: appointmentTimeLabel(booking),
                      ),
                      _DetailRow(
                        label: tr('booking_detail_duration'),
                        value: _bookingDurationLabel(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: tr('booking_status'),
                    icon: Icons.warning_amber_rounded,
                    children: [
                      _DetailRow(
                        label: tr('booking_status'),
                        value: operationsStatusLabel(booking),
                      ),
                      _DetailRow(
                        label: tr('booking_detail_price'),
                        value: appointmentPriceLabel(booking),
                      ),
                      _DetailRow(
                        label: tr('ops_notes'),
                        value: _bookingNotes(booking),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DetailSection(
                    title: tr('ops_code'),
                    icon: Icons.info_outline_rounded,
                    children: [
                      _DetailRow(
                        label: tr('ops_code'),
                        value: operationsBookingIdentity(booking),
                      ),
                      _DetailRow(
                        label: tr('ops_last_update'),
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
        label: tr('ops_button_confirmed'),
        icon: Icons.check_rounded,
        accent: primaryColor,
        targetStatus: 'confirmed',
      ),
      _LaneAction(
        label: tr('ops_button_rejected'),
        icon: Icons.block_rounded,
        accent: Color(0xFFFF8A80),
        targetStatus: 'rejected',
      ),
      _LaneAction(
        label: tr('btn_cancel'),
        icon: Icons.cancel_outlined,
        accent: Color(0xFFFF8A80),
        targetStatus: 'cancelled',
      ),
    ],
    'confirmed' => [
      _LaneAction(
        label: tr('ops_complete_appointment'),
        icon: Icons.task_alt_rounded,
        accent: primaryColor,
        targetStatus: 'completed',
      ),
      _LaneAction(
        label: tr('btn_cancel'),
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
      _LaneAction(
        label: tr('ops_mark_paid'),
        icon: Icons.payments_rounded,
        accent: Color(0xFF65D6A5),
        targetStatus: 'paid',
      ),
    ];
  }
  return actions;
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
  return tr('ops_not_registered');
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
  if (raw.isEmpty) return tr('ops_no_notes');
  return raw;
}
