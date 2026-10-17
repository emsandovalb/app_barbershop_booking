part of '../operations_board.dart';

enum _ResponsiveBoardMode { mobile, tablet, laptop, desktop }

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
                  tr('ops_lane_column_title', args: {'lane': spec.label}),
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
                tr('ops_average', args: {'value': averageWaitLabel}),
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
