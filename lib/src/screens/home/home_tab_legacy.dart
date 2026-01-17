import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/colors.dart';
import '../../data/categories.dart';
import '../../widgets/category_icon.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../ground/ground_detail_page.dart';
import '../../widgets/court_image.dart';
import '../search/filter_page.dart';
import '../../services/localization_service.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String q = '';
  List<dynamic> popular = [];
  List<dynamic> nearby = [];
  double? minPrice;
  double? maxPrice;
  String? sort;
  String? categoryFilter;
  int? durationFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final pop = await api.getCourts(sort: 'rating');
      final nb = await api.getCourts(category: categoryFilter, durationHours: durationFilter);
      if (!mounted) return;
      setState(() {
        popular = pop['data'] ?? [];
        nearby = nb['data'] ?? [];
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to load courts: ' + e.toString());
      if (!mounted) return;
      setState(() {
        popular = [];
        nearby = [];
      });
    }
  }

  Future<void> _applyFilters() async {
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getCourts(q: q, minPrice: minPrice, maxPrice: maxPrice, sort: sort, category: categoryFilter, durationHours: durationFilter);
      if (!mounted) return;
      setState(() {
        nearby = res['data'] ?? [];
      });
    } catch (e) {
      // ignore: avoid_print
      print('Failed to apply filters: ' + e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return CustomScrollView(
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
                        onSubmitted: (_) => _applyFilters(),
                        decoration: InputDecoration(
                          hintText: loc.t('home_search_hint', fallback: 'Search'),
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () async {
                      final result = await Navigator.of(context).push<Map<String, dynamic>>(
                        MaterialPageRoute(builder: (_) => const FilterPage()),
                      );
                      if (result != null) {
                        minPrice = result['minPrice'] as double?;
                        maxPrice = result['maxPrice'] as double?;
                        sort = result['sort'] as String?;
                        final filterQ = result['q'] as String?;
                        if (filterQ != null && filterQ.isNotEmpty) q = filterQ;
                        categoryFilter = result['category'] as String?;
                        durationFilter = result['duration'] as int?;
                        await _applyFilters();
                      }
                    },
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
                    Text(loc.t('home_view_all', fallback: 'View all'),
                        style: TextStyle(color: Colors.white.withOpacity(.8)))
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 82,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) {
                      final c = AppCategories.list[i % AppCategories.list.length];
                      return Column(
                        children: [
                          CategoryIcon(asset: c.asset, size: 56),
                          const SizedBox(height: 6),
                          Text(c.title, style: const TextStyle(color: Colors.white))
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemCount: AppCategories.list.length,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(loc.t('home_popular', fallback: 'Popular ground'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.categories),
                      child: Text(loc.t('home_view_all', fallback: 'View all'),
                          style: TextStyle(color: Colors.white.withOpacity(.8))),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
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
                    Text(loc.t('home_view_all', fallback: 'View all'),
                        style: TextStyle(color: Colors.white.withOpacity(.8)))
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
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
