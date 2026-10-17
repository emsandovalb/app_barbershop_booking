part of '../home_tab.dart';

class _HeroCard extends StatelessWidget {
  final BrandConfig brand;
  final String logoAsset;
  final WhiteLabelConfig whiteLabel;

  const _HeroCard({
    required this.brand,
    required this.logoAsset,
    required this.whiteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 292,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (whiteLabel.heroBackground.trim().isNotEmpty)
              Image.asset(
                whiteLabel.heroBackground,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            if (whiteLabel.heroBackground.trim().isEmpty)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF10172A),
                      Color(0xFF0B1020),
                      Color(0xFF151C31),
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
                    const Color(0xFF050505).withValues(alpha: .26),
                    const Color(0xFF050505).withValues(alpha: .46),
                    const Color(0xFF050505).withValues(alpha: .84),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB77A3E).withValues(alpha: .12),
                      Colors.transparent,
                    ],
                    radius: .98,
                    center: const Alignment(0, -.14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: PremiumBadge(
                      label: whiteLabel.shortName.toUpperCase(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final logoSize = (constraints.maxWidth * .40).clamp(
                            112.0,
                            154.0,
                          );
                          return BarbershopLogoMark(
                            assetPath: logoAsset,
                            size: logoSize,
                            glowColor: brand.primaryColor,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (whiteLabel.displayName.split(' ').first.toUpperCase() !=
                      whiteLabel.shortName.toUpperCase()) ...[
                    Text(
                      whiteLabel.displayName.split(' ').first.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    whiteLabel.shortName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                      height: .95,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessInfoCards extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;

  const _BusinessInfoCards({required this.whiteLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            title: whiteLabel.hoursLabel,
            body: whiteLabel.detailedHours.join('\n'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.location_on_rounded,
            title: tr('home_location_contact'),
            body:
                '${whiteLabel.locationFull}\n\n${whiteLabel.phone}\n\n${whiteLabel.email}',
          ),
        ),
      ],
    );
  }
}

class _BusinessProfileTeaser extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onTap;

  const _BusinessProfileTeaser({required this.whiteLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF17110D),
              const Color(0xFF120E0B).withValues(alpha: .96),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: theme.primary.withValues(alpha: .20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: .14),
              ),
              child: Icon(Icons.storefront_rounded, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('home_business_teaser_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    tr(
                      'home_business_teaser_body',
                      args: {'business': whiteLabel.displayName},
                    ),
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: theme.primary),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardTeaser extends StatelessWidget {
  final VoidCallback onTap;

  const _AdminDashboardTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1512),
              const Color(0xFF120E0B).withValues(alpha: .95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: theme.primary.withValues(alpha: .24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: .14),
              ),
              child: Icon(Icons.dashboard_rounded, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('admin_center'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('admin_center_teaser_body'),
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right_rounded, color: theme.primary),
          ],
        ),
      ),
    );
  }
}

class _ReviewsPromoCard extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onTap;

  const _ReviewsPromoCard({required this.whiteLabel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF18120F),
              const Color(0xFF120E0B).withValues(alpha: .96),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: theme.primary.withValues(alpha: .18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: .14),
              ),
              child: Icon(Icons.favorite_rounded, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_capitalize(whiteLabel.reviewsLabel)} felices',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'home_reviews_summary',
                      args: {
                        'rating': whiteLabel.rating.toStringAsFixed(1),
                        'count': whiteLabel.reviewCount,
                      },
                    ),
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr('home_view_reviews'),
                    style: TextStyle(
                      color: theme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.primary),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14100E),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: .05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
