import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  ReviewFilter _filter = ReviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final whiteLabel =
        Provider.of<WhiteLabelConfig?>(context, listen: false) ??
        WhiteLabelConfig.tresAmigos;
    final visibleReviews = _demoReviews
        .where((review) => review.matches(_filter))
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Opiniones',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .2,
          ),
        ),
      ),
      body: BarbershopPremiumBackdrop(
        backgroundAsset: whiteLabel.heroBackground,
        backgroundOpacity: .18,
        blurSigma: 20,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 28),
            children: [
              const _HeaderSection(),
              const SizedBox(height: 18),
              _RatingSummaryCard(
                rating: whiteLabel.rating,
                totalReviews: whiteLabel.reviewCount,
                distribution: _ratingDistribution,
              ),
              const SizedBox(height: 16),
              _FeaturedReviewCard(review: _featuredReview),
              const SizedBox(height: 18),
              _FilterRow(
                selected: _filter,
                onChanged: (next) => setState(() => _filter = next),
              ),
              const SizedBox(height: 12),
              _SectionTitle(
                title: visibleReviews.isEmpty
                    ? 'Sin resultados'
                    : 'Reseñas destacadas',
                subtitle: visibleReviews.isEmpty
                    ? 'Probá otro filtro para ver más opiniones.'
                    : '${visibleReviews.length} opiniones visibles',
              ),
              const SizedBox(height: 12),
              if (visibleReviews.isEmpty)
                const _EmptyState()
              else
                Column(
                  children: [
                    for (var i = 0; i < visibleReviews.length; i++) ...[
                      _ReviewCard(review: visibleReviews[i]),
                      if (i != visibleReviews.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'OPINIONES',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Lo que dicen nuestros clientes',
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
          style: TextStyle(
            color: Colors.white70,
            height: 1.45,
            fontSize: 14,
          ),
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
    return BarbershopPremiumCard(
      radius: 28,
      borderColor: AppColors.primary.withValues(alpha: .16),
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
                      AppColors.primary.withValues(alpha: .30),
                      AppColors.primary.withValues(alpha: .10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .22),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
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
                    const Text(
                      'Basado en 128 opiniones',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'La barbería mantiene una reputación consistente con una valoración alta y estable.',
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
        border: Border.all(color: AppColors.primary.withValues(alpha: .34)),
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
              color: AppColors.primary.withValues(alpha: .12),
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

class _FilterRow extends StatelessWidget {
  final ReviewFilter selected;
  final ValueChanged<ReviewFilter> onChanged;

  const _FilterRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
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
                color: isSelected
                    ? AppColors.primary
                    : const Color(0xFF171311),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: .06),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: .20),
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

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

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
    return BarbershopPremiumCard(
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            color: AppColors.primary.withValues(alpha: .88),
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
                        AppColors.primary.withValues(alpha: .96),
                        AppColors.tertiary.withValues(alpha: .88),
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

  const _StarStrip({
    this.rating = _summaryRating,
    this.iconSize = 15,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Icon(icon, color: AppColors.primary, size: iconSize),
        );
      }),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  final ReviewEntry review;
  final double size;

  const _AvatarBadge({required this.review, required this.size});

  @override
  Widget build(BuildContext context) {
    final initials = review.initials;
    if (review.avatarUrl != null && review.avatarUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          review.avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(initials),
        ),
      );
    }
    return _initialsAvatar(initials);
  }

  Widget _initialsAvatar(String initials) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .24),
            AppColors.primary.withValues(alpha: .08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
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

  const _MetaChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 13, color: AppColors.primary),
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

  const _HighlightedMetaChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: .26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
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

enum ReviewFilter { all, fiveStars, premium, corte, barba }

extension on ReviewFilter {
  String get label {
    switch (this) {
      case ReviewFilter.all:
        return 'Todas';
      case ReviewFilter.fiveStars:
        return '5 estrellas';
      case ReviewFilter.premium:
        return 'Premium';
      case ReviewFilter.corte:
        return 'Corte';
      case ReviewFilter.barba:
        return 'Barba';
    }
  }
}

class ReviewEntry {
  final String customerName;
  final double rating;
  final String dateLabel;
  final String text;
  final String? serviceName;
  final String? barberName;
  final String? avatarUrl;
  final bool isPremium;

  const ReviewEntry({
    required this.customerName,
    required this.rating,
    required this.dateLabel,
    required this.text,
    this.serviceName,
    this.barberName,
    this.avatarUrl,
    this.isPremium = false,
  });

  factory ReviewEntry.fromMap(Map<String, dynamic> map) {
    return ReviewEntry(
      customerName: _text(map, ['customerName', 'name']),
      rating: _number(map, ['rating'], fallback: 5),
      dateLabel: _text(map, ['dateLabel', 'date']),
      text: _text(map, ['text', 'comment', 'review']),
      serviceName: _optionalText(map, ['serviceName', 'service']),
      barberName: _optionalText(map, ['barberName', 'barber']),
      avatarUrl: _optionalText(map, ['avatarUrl', 'avatar']),
      isPremium: _bool(map, ['isPremium', 'premium']),
    );
  }

  String get initials {
    final parts = customerName.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final letters = parts
        .map((part) => part.substring(0, 1))
        .take(2)
        .join();
    return letters.isEmpty ? 'R' : letters.toUpperCase();
  }

  bool matches(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.all:
        return true;
      case ReviewFilter.fiveStars:
        return rating >= 4.95;
      case ReviewFilter.premium:
        return isPremium;
      case ReviewFilter.corte:
        return _contains(serviceName, 'corte') || _contains(serviceName, 'experiencia premium');
      case ReviewFilter.barba:
        return _contains(serviceName, 'barba');
    }
  }
}

const double _summaryRating = 4.9;
const int _totalReviews = 128;

const Map<int, int> _ratingDistribution = {
  5: 98,
  4: 18,
  3: 7,
  2: 3,
  1: 2,
};

final ReviewEntry _featuredReview = ReviewEntry.fromMap(
  const {
    'customerName': 'Andrés Mora',
    'rating': 5.0,
    'dateLabel': '14 jun 2026',
    'text':
        'La experiencia premium vale totalmente la pena. El ambiente, la atención y el acabado se sienten de primer nivel.',
    'serviceName': 'Experiencia Premium Completa',
    'barberName': 'Diego Morales',
    'isPremium': true,
  },
);

final List<ReviewEntry> _demoReviews = [
  ReviewEntry.fromMap(
    const {
      'customerName': 'Juan Carlos',
      'rating': 5.0,
      'dateLabel': '18 jun 2026',
      'text':
          'Excelente atención y muy buen ambiente. El corte quedó perfecto.',
      'serviceName': 'Corte de cabello',
      'barberName': 'Carlos Ramirez',
      'isPremium': false,
    },
  ),
  ReviewEntry.fromMap(
    const {
      'customerName': 'Andrés Mora',
      'rating': 5.0,
      'dateLabel': '14 jun 2026',
      'text':
          'Muy recomendado. La experiencia premium vale totalmente la pena.',
      'serviceName': 'Experiencia Premium Completa',
      'barberName': 'Diego Morales',
      'isPremium': true,
    },
  ),
  ReviewEntry.fromMap(
    const {
      'customerName': 'Felipe Solís',
      'rating': 4.9,
      'dateLabel': '11 jun 2026',
      'text':
          'El perfilado de barba quedó limpio y profesional.',
      'serviceName': 'Recorte de barba',
      'barberName': 'Andres Vega',
      'isPremium': false,
    },
  ),
  ReviewEntry.fromMap(
    const {
      'customerName': 'Daniel Rojas',
      'rating': 5.0,
      'dateLabel': '9 jun 2026',
      'text':
          'Buen trato, puntualidad y excelente acabado.',
      'serviceName': 'Corte y Barba',
      'barberName': 'Luis Fernandez',
      'isPremium': false,
    },
  ),
  ReviewEntry.fromMap(
    const {
      'customerName': 'Mauricio Vargas',
      'rating': 4.8,
      'dateLabel': '5 jun 2026',
      'text':
          'Ambiente cómodo, buena música y atención de primera.',
      'serviceName': 'Corte a Tijera / Cabello Largo',
      'barberName': 'Carlos Ramirez',
      'isPremium': false,
    },
  ),
];

bool _contains(String? value, String needle) {
  return value != null && value.toLowerCase().contains(needle.toLowerCase());
}

String _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String? _optionalText(Map<String, dynamic> map, List<String> keys) {
  final text = _text(map, keys);
  return text.isEmpty ? null : text;
}

double _number(
  Map<String, dynamic> map,
  List<String> keys, {
  required double fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool _bool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return false;
}
