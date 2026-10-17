part of '../admin_dashboard_page.dart';

class _TodayAppointmentsList extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final void Function(Map<String, dynamic>) onOpen;

  const _TodayAppointmentsList({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _DashboardEmptyCard(message: tr('admin_no_appointments_today'));
    }
    return Column(
      children: items
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
    final theme = context.watch<BrandTheme>();
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
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF151C31),
                        Color(0xFF10172A),
                        Color(0xFF0B1020),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.event_available_rounded,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
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
                        style: TextStyle(
                          color: theme.primary,
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
                    client.isNotEmpty ? client : tr('admin_client_unnamed'),
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
                      style: TextStyle(
                        color: theme.secondary,
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
