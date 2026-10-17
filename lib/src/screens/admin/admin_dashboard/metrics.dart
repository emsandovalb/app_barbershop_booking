part of '../admin_dashboard_page.dart';

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
    final theme = context.watch<BrandTheme>();
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .94),
      borderColor: theme.primary.withValues(alpha: .18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(metric.icon, color: theme.primary, size: 20),
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

class _PerformanceList extends StatelessWidget {
  final List<_PerformanceData> items;

  const _PerformanceList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _DashboardEmptyCard(message: tr('admin_no_team_yet'));
    }
    return Column(
      children: items
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
    final theme = context.watch<BrandTheme>();
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
            backgroundColor: theme.primary.withValues(alpha: .16),
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
                      label: item.active ? tr('active') : tr('inactive'),
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
                  style: TextStyle(
                    color: theme.secondary,
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
    if (items.isEmpty) {
      return _DashboardEmptyCard(message: tr('admin_no_bookings_for_ranking'));
    }
    return Column(
      children: items
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
    final theme = context.watch<BrandTheme>();
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
                style: TextStyle(
                  color: theme.secondary,
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
              valueColor: AlwaysStoppedAnimation(theme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
