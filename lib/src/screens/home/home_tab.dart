import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/loadable_collection_view.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../gallery/gallery_page.dart';
import '../ground/ground_detail_page.dart';
import '../grounds/filtered_courts_page.dart';
import '../reviews/reviews_page.dart';
import '../../services/localization_service.dart';
import '../../services/business_clock.dart';

part 'home_tab/hero_and_teasers.dart';
part 'home_tab/services.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const int _homePageSize = 5;

  String q = '';
  late final LoadableController<List<Map<String, dynamic>>> _popularController;
  late final LoadableController<List<Map<String, dynamic>>> _premiumController;

  @override
  void initState() {
    super.initState();
    _popularController = LoadableController<List<Map<String, dynamic>>>(
      () async => _extractItems(
        await context.read<AuthProvider>().api.getResources(
          sort: 'rating',
          page: 1,
          perPage: _homePageSize,
        ),
      ),
    );
    _premiumController = LoadableController<List<Map<String, dynamic>>>(
      () async => _extractItems(
        await context.read<AuthProvider>().api.getResources(
          page: 1,
          perPage: _homePageSize,
          category: 'premium',
          sort: 'rating',
        ),
      ),
    );
    _refreshAll();
  }

  @override
  void dispose() {
    _popularController.dispose();
    _premiumController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_popularController.load(), _premiumController.load()]);
  }

  void _openFilteredResults({Map<String, dynamic>? filters, String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            FilteredCourtsPage(initialFilters: filters, title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final config = context.watch<AppConfig>();
    final brand = config.brand;
    final whiteLabel = Provider.of<WhiteLabelConfig>(context, listen: false);
    final auth = context.watch<AuthProvider>();
    final name = (auth.user?['first_name'] ?? auth.user?['name'] ?? '')
        .toString()
        .trim();

    final popular =
        _popularController.state.data ?? const <Map<String, dynamic>>[];
    final premium =
        _premiumController.state.data ?? const <Map<String, dynamic>>[];
    final featuredServices = _mergeFeaturedServices(popular, premium);

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF090909),
            surfaceTintColor: Colors.transparent,
            toolbarHeight: 84,
            titleSpacing: 16,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.isEmpty
                      ? tr('home_greeting_anonymous')
                      : tr('home_greeting', args: {'name': name}),
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _greetingForNow(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.businessProfile),
                    borderRadius: BorderRadius.circular(30),
                    child: _HeroCard(
                      brand: brand,
                      logoAsset: whiteLabel.logoTransparent,
                      whiteLabel: whiteLabel,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: TextField(
                            onChanged: (value) => q = value,
                            onSubmitted: (_) {
                              final query = q.trim();
                              if (query.isEmpty) return;
                              _openFilteredResults(
                                filters: {'q': query},
                                title: tr('home_search_results'),
                              );
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            cursorColor: theme.primary,
                            decoration: InputDecoration(
                              hintText: tr('home_search_hint'),
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: .50),
                                fontSize: 14,
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 12,
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  size: 22,
                                  color: Colors.white.withValues(alpha: .88),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(
                                minWidth: 0,
                                minHeight: 0,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 17,
                              ),
                              filled: true,
                              fillColor: const Color(0xFF171311),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: .06),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withValues(alpha: .06),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: brand.primaryColor.withValues(
                                    alpha: .70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          color: brand.primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: brand.primaryColor.withValues(alpha: .30),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () => _openFilteredResults(
                            title: tr('filter_results_title'),
                          ),
                          icon: const Icon(
                            Icons.tune_rounded,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _BusinessInfoCards(whiteLabel: whiteLabel),
                  const SizedBox(height: 16),
                  _BusinessProfileTeaser(
                    whiteLabel: whiteLabel,
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.businessProfile),
                  ),
                  if (auth.canManageBusiness) ...[
                    const SizedBox(height: 10),
                    _AdminDashboardTeaser(
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminDashboard),
                    ),
                  ],
                  const SizedBox(height: 10),
                  _ReviewsPromoCard(
                    whiteLabel: whiteLabel,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReviewsPage()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GalleryPage()),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(tr('home_view_gallery')),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: tr('home_featured_services'),
                    actionLabel: tr('btn_view_all'),
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: tr('home_featured_services'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_popularController.state.hasError ||
                      _premiumController.state.hasError)
                    if (featuredServices.isEmpty)
                      _StateCard(
                        title: tr('home_featured_services'),
                        body: tr('home_services_load_failed'),
                        actionLabel: tr('btn_retry'),
                        onAction: _refreshAll,
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.white70,
                        ),
                      )
                    else
                      _ServiceCarousel(
                        isLoading:
                            _popularController.state.isLoading ||
                            _premiumController.state.isLoading,
                        items: featuredServices,
                        emptyMessage: tr('home_featured_empty'),
                        onEmptyTap: () => _openFilteredResults(
                          filters: const {'sort': 'rating'},
                          title: tr('home_featured_services'),
                        ),
                        itemBuilder: (index, data) =>
                            _ServiceCard(index: index, data: data),
                      )
                  else if (featuredServices.isEmpty)
                    _StateCard(
                      title: tr('home_featured_services'),
                      body: tr('home_featured_empty'),
                      actionLabel: tr('btn_view_all'),
                      onAction: () => _openFilteredResults(
                        filters: const {'sort': 'rating'},
                        title: tr('home_featured_services'),
                      ),
                      leading: const Icon(
                        Icons.inbox_outlined,
                        color: Colors.white70,
                      ),
                    )
                  else
                    _ServiceCarousel(
                      isLoading:
                          _popularController.state.isLoading ||
                          _premiumController.state.isLoading,
                      items: featuredServices,
                      emptyMessage: tr('home_featured_empty'),
                      onEmptyTap: () => _openFilteredResults(
                        filters: const {'sort': 'rating'},
                        title: tr('home_featured_services'),
                      ),
                      itemBuilder: (index, data) =>
                          _ServiceCard(index: index, data: data),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: tr('home_popular_services'),
                    actionLabel: tr('btn_view_all'),
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: tr('home_popular_services'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceListSection(
                    controller: _popularController,
                    title: tr('home_popular_services'),
                    emptyMessage: tr('home_popular_empty'),
                    loadingMessage: tr('home_services_loading'),
                    errorMessage: tr('home_services_load_failed'),
                    retryLabel: tr('btn_retry'),
                    onViewAll: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: tr('home_popular_services'),
                    ),
                    items: popular,
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                    onRetry: _refreshAll,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: tr('home_premium_services'),
                    actionLabel: tr('btn_view_all'),
                    onTap: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: tr('home_premium_services'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceListSection(
                    controller: _premiumController,
                    title: tr('home_premium_services'),
                    emptyMessage: tr('home_premium_empty'),
                    loadingMessage: tr('home_services_loading'),
                    errorMessage: tr('home_services_load_failed'),
                    retryLabel: tr('btn_retry'),
                    onViewAll: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: tr('home_premium_services'),
                    ),
                    items: premium,
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                    onRetry: _refreshAll,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const [];
  }
}

/// Time-of-day greeting on the business's clock.
String _greetingForNow() {
  final hour = BusinessClock.now().hour;
  if (hour < 12) return tr('home_good_morning');
  if (hour < 19) return tr('home_good_afternoon');
  return tr('home_good_evening');
}
