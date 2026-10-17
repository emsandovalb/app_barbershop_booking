part of '../business_profile_page.dart';

class _ServiceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> resources;

  const _ServiceGrid({required this.resources});

  @override
  Widget build(BuildContext context) {
    final items = resources.take(4).toList(growable: false);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemBuilder: (context, index) {
        return _ServiceCard(resource: items[index]);
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> resource;

  const _ServiceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final name = _stringValue(resource, [
      'name',
      'title',
    ], fallback: tr('appointment_default_service'));
    final price = _formatCrc(resource['price_per_hour'] ?? resource['price']);
    final duration = _durationLabel(
      resource['duration_hours'],
      resource['duration_minutes'],
    );
    final category = _stringValue(resource, ['category'], fallback: 'premium');

    return BarbershopPremiumCard(
      padding: EdgeInsets.zero,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CourtImage(
                  images: resource['images'],
                  radius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .58),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: PremiumBadge(label: 'PREMIUM', compact: true),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  price,
                  style: TextStyle(
                    color: theme.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 11,
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
