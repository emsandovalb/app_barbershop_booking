part of '../reviews_page.dart';

class _FilterRow extends StatelessWidget {
  final ReviewFilter selected;
  final ValueChanged<ReviewFilter> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ReviewFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = ReviewFilter.values[index];
          final isSelected = filter == selected;
          return InkWell(
            onTap: () => onChanged(filter),
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? theme.primary : const Color(0xFF171311),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? theme.primary
                      : Colors.white.withValues(alpha: .06),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.primary.withValues(alpha: .20),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : const [],
              ),
              child: Text(
                filter.label,
                style: TextStyle(
                  color: isSelected ? const Color(0xFF090909) : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .66),
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntry review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBadge(review: review, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          review.dateLabel,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .58),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    _StarStrip(rating: review.rating, iconSize: 14),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            review.text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .86),
              height: 1.52,
              fontSize: 14.2,
            ),
          ),
          if (review.serviceName != null || review.barberName != null) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (review.serviceName != null)
                  _MetaChip(
                    label: review.serviceName!,
                    icon: Icons.content_cut_rounded,
                  ),
                if (review.barberName != null)
                  _MetaChip(
                    label: review.barberName!,
                    icon: Icons.person_rounded,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return BarbershopPremiumCard(
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: theme.primary.withValues(alpha: .88),
            size: 36,
          ),
          const SizedBox(height: 10),
          const Text(
            'No hay opiniones para este filtro',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Probá otro grupo para seguir explorando reseñas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .68),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final ReviewEntry review;
  final double size;

  const _AvatarBadge({required this.review, required this.size});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final initials = review.initials;
    if (review.avatarUrl != null && review.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          review.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(initials, theme),
        ),
      );
    }
    return _initialsAvatar(initials, theme);
  }

  Widget _initialsAvatar(String initials, BrandTheme theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: .24),
            theme.primary.withValues(alpha: .08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.primary.withValues(alpha: .18)),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * .33,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF171311),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightedMetaChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _HighlightedMetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.primary.withValues(alpha: .26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: theme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
