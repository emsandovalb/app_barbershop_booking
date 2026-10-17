import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';
import '../../services/localization_service.dart';

part 'reviews/summary.dart';
part 'reviews/review_list.dart';
part 'reviews/data.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  ReviewFilter _filter = ReviewFilter.all;

  @override
  Widget build(BuildContext context) {
    final whiteLabel = Provider.of<WhiteLabelConfig>(context, listen: false);
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
        title: Text(
          whiteLabel.reviewsLabel.toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: .2),
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
              _HeaderSection(whiteLabel: whiteLabel),
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
                    ? tr('reviews_no_results')
                    : tr('reviews_featured'),
                subtitle: visibleReviews.isEmpty
                    ? tr('reviews_try_other_filter')
                    : tr(
                        'reviews_visible_count',
                        args: {'count': visibleReviews.length},
                      ),
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
