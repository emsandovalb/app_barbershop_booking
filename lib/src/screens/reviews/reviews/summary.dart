part of '../reviews_page.dart';

class _HeaderSection extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;

  const _HeaderSection({required this.whiteLabel});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          whiteLabel.reviewsLabel.toUpperCase(),
          style: TextStyle(
            color: theme.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Lo que dicen nuestros ${whiteLabel.reviewsLabel}',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Una experiencia más confiable, más premium y más comercial para elegir con seguridad.',
          style: TextStyle(color: Colors.white70, height: 1.45, fontSize: 14),
        ),
      ],
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final Map<int, int> distribution;

  const _RatingSummaryCard({
    required this.rating,
    required this.totalReviews,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return BarbershopPremiumCard(
      radius: 28,
      borderColor: theme.primary.withValues(alpha: .16),
      backgroundColor: const Color(0xFF130F0C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.primary.withValues(alpha: .30),
                      theme.primary.withValues(alpha: .10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: theme.primary.withValues(alpha: .22),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star_rounded, color: theme.primary, size: 24),
                    const SizedBox(height: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basado en $totalReviews ${Provider.of<WhiteLabelConfig>(context, listen: false).reviewsLabel}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'El negocio mantiene una reputación consistente con una valoración alta y estable.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const _StarStrip(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...List.generate(5, (index) {
            final star = 5 - index;
            return Padding(
              padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
              child: _DistributionRow(
                stars: star,
                count: distribution[star] ?? 0,
                total: totalReviews,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _FeaturedReviewCard extends StatelessWidget {
  final ReviewEntry review;

  const _FeaturedReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF19120E),
            const Color(0xFF120E0B),
            const Color(0xFF0F0B09),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.primary.withValues(alpha: .34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .30),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 14,
            top: 12,
            child: Icon(
              Icons.format_quote_rounded,
              size: 88,
              color: theme.primary.withValues(alpha: .12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PremiumBadge(label: 'DESTACADA'),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarBadge(review: review, size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            review.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _StarStrip(rating: review.rating),
                          const SizedBox(height: 8),
                          Text(
                            review.dateLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .62),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  review.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.42,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (review.serviceName != null)
                      _HighlightedMetaChip(
                        icon: Icons.content_cut_rounded,
                        label: review.serviceName!,
                      ),
                    if (review.barberName != null)
                      _HighlightedMetaChip(
                        icon: Icons.person_rounded,
                        label: review.barberName!,
                      ),
                    if (review.isPremium)
                      const _HighlightedMetaChip(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Experiencia premium',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DistributionRow extends StatelessWidget {
  final int stars;
  final int count;
  final int total;

  const _DistributionRow({
    required this.stars,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final ratio = total == 0 ? 0.0 : count / total;
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            '$stars estrellas',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .76),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              color: const Color(0xFF1A1613),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.primary.withValues(alpha: .96),
                        theme.accent.withValues(alpha: .88),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .62),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StarStrip extends StatelessWidget {
  final double rating;
  final double iconSize;

  const _StarStrip({this.rating = _summaryRating, this.iconSize = 15});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final icon = rating >= starValue
            ? Icons.star_rounded
            : rating >= starValue - .5
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 2),
          child: Icon(icon, color: theme.primary, size: iconSize),
        );
      }),
    );
  }
}
