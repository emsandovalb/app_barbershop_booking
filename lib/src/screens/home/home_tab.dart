import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../ground/ground_detail_page.dart';
import '../../widgets/court_image.dart';
import '../../services/localization_service.dart';
import '../../data/number_categories.dart';
import '../grounds/filtered_courts_page.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const int _homePageSize = 5;
  String q = '';
  List<dynamic> popular = [];
  List<dynamic> nearby = [];
  bool loadingPopular = false;
  bool loadingNearby = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadPopular(page: 1),
      _loadNearby(page: 1),
    ]);
  }

  Future<void> _loadPopular({required int page}) async {
    if (loadingPopular) return;
    setState(() => loadingPopular = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getCourts(sort: 'rating', page: page, perPage: _homePageSize);
      if (!mounted) return;
      final data = (res['data'] as List?) ?? [];
      setState(() {
        popular = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        popular = [];
      });
    } finally {
      if (mounted) setState(() => loadingPopular = false);
    }
  }

  Future<void> _loadNearby({required int page}) async {
    if (loadingNearby) return;
    setState(() => loadingNearby = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getCourts(page: page, perPage: _homePageSize);
      if (!mounted) return;
      final data = (res['data'] as List?) ?? [];
      setState(() {
        nearby = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        nearby = [];
      });
    } finally {
      if (mounted) setState(() => loadingNearby = false);
    }
  }

  void _openFilteredResults({Map<String, dynamic>? filters, String? title}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FilteredCourtsPage(
          initialFilters: filters,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
        SliverAppBar(
          pinned: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                final auth = context.watch<AuthProvider>();
                final name = (auth.user?['first_name'] ?? auth.user?['name'] ?? 'Guest').toString();
                return Text('${loc.t('home_hello', fallback: 'Hello')}, $name', style: const TextStyle(fontSize: 14, color: Colors.white70));
              }),
              const SizedBox(height: 2),
              Text(
                '${loc.t('home_good_morning', fallback: 'Good morning')} 🌞',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
              ),
            ],
          ),
          actions: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none))
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => q = v,
                        onSubmitted: (_) {
                          final query = q.trim();
                          if (query.isEmpty) return;
                          _openFilteredResults(filters: {'q': query}, title: loc.t('home_search_results', fallback: 'Results'));
                        },
                        decoration: InputDecoration(
                          hintText: loc.t('home_search_hint', fallback: 'Search'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _openFilteredResults(
                        title: loc.t('filter_results_title', fallback: 'Filtered courts'),
                      ),
                      child: Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.tune, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('home_categories', fallback: 'Categories'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    InkWell(
                      onTap: () => _openFilteredResults(
                        title: loc.t('home_categories', fallback: 'Categories'),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(loc.t('home_view_all', fallback: 'View all'),
                            style: TextStyle(color: Colors.white.withOpacity(.8))),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 16,
                      children: NumberCategories.list.map((item) {
                        final label = item.label;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => _openFilteredResults(
                              filters: {'category': label},
                              title: '${loc.t('home_category_results', fallback: 'Category')} $label',
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(
                                item.asset,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.black30,
                                  alignment: Alignment.center,
                                  child: Text(
                                    label,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('home_popular', fallback: 'Popular ground'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    InkWell(
                      onTap: () => _openFilteredResults(
                        filters: const {'sort': 'rating'},
                        title: loc.t('home_popular', fallback: 'Popular ground'),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(loc.t('home_view_all', fallback: 'View all'),
                            style: TextStyle(color: Colors.white.withOpacity(.8))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: loadingPopular
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) => _GroundCard(index: i, data: i < popular.length ? popular[i] : null),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: popular.length,
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('home_nearby', fallback: 'Nearby you'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    InkWell(
                      onTap: () => _openFilteredResults(
                        title: loc.t('home_nearby', fallback: 'Nearby you'),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(loc.t('home_view_all', fallback: 'View all'),
                            style: TextStyle(color: Colors.white.withOpacity(.8))),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: loadingNearby
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (_, i) => _GroundCard(index: i, data: i < nearby.length ? nearby[i] : null),
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: nearby.length,
                        ),
                ),
              ],
            ),
          ),
        )
      ],
      ),
    );
  }
}

class _GroundCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic>? data;
  const _GroundCard({required this.index, this.data});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return InkWell(
      onTap: () {
        if (data != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroundDetailPage(court: data!)),
          );
        }
      },
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: AppColors.black30,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CourtImage(
                      images: data?['images'],
                      radius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.place, size: 14, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(loc.t('home_distance_sample', fallback: '1.2 km'), style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data?['name']?.toString() ?? 'Ground ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data?['address']?.toString() ?? 'Address',
                          style: TextStyle(color: Colors.white.withOpacity(.75)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
