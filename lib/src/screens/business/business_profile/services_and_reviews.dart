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
    ], fallback: 'Servicio premium');
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

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid();

  @override
  Widget build(BuildContext context) {
    final tiles = _galleryTiles;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (tile.asset.isNotEmpty)
                Image.asset(tile.asset, fit: BoxFit.cover)
              else
                Container(
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
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  tile.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Column(
      children: _reviews
          .map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BarbershopPremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _AvatarMark(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: theme.primary,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '“${review.text}”',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReviewsCta extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onTap;

  const _ReviewsCta({required this.whiteLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14100E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.primary.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: .12),
              ),
              child: Icon(Icons.rate_review_rounded, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver todas las ${whiteLabel.reviewsLabel}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Abrí la experiencia premium de ${whiteLabel.reviewsLabel} y testimonios.',
                    style: TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: theme.primary),
          ],
        ),
      ),
    );
  }
}
