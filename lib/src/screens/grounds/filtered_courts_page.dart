import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/localization_service.dart';
import '../../providers/auth_provider.dart';
import '../search/filter_page.dart';
import '../../widgets/court_image.dart';
import '../ground/ground_detail_page.dart';
import '../../widgets/pagination_bar.dart';

class FilteredCourtsPage extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  final String? title;
  const FilteredCourtsPage({super.key, this.initialFilters, this.title});

  @override
  State<FilteredCourtsPage> createState() => _FilteredCourtsPageState();
}

class _FilteredCourtsPageState extends State<FilteredCourtsPage> {
  static const int _pageSize = 10;
  Map<String, dynamic> filters = {};
  List<dynamic> courts = [];
  bool loading = true;
  int currentPage = 1;
  int lastPage = 1;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();
    filters = {...?widget.initialFilters}..removeWhere(_emptyValue);
    _load();
  }

  bool _emptyValue(String key, dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  Future<void> _load({int page = 1}) async {
    setState(() {
      loading = true;
      if (page == 1) courts = [];
    });
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getCourts(
        q: filters['q'] as String?,
        minPrice: filters['minPrice'] as double?,
        maxPrice: filters['maxPrice'] as double?,
        sort: filters['sort'] as String?,
        category: filters['category'] as String?,
        durationHours: filters['duration'] as int?,
        page: page,
        perPage: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        final data = (res['data'] as List?) ?? [];
        courts = data;
        final meta = _extractMeta(res, page);
        currentPage = meta['current_page'] as int? ?? page;
        lastPage = meta['last_page'] as int? ?? currentPage;
        totalItems = meta['total'] as int? ?? data.length;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        courts = [];
        currentPage = 1;
        lastPage = 1;
        totalItems = 0;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const FilterPage()),
    );
    if (result != null) {
      filters = {...result}..removeWhere(_emptyValue);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final title = widget.title ?? loc.t('filter_results_title', fallback: 'Filtered courts');
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _openFilters, icon: const Icon(Icons.filter_list)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : courts.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => _load(page: 1),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(loc.t('filters_empty', fallback: 'No courts found'))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _load(page: 1),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: courts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final court = courts[i] as Map<String, dynamic>;
                            return _ResultCard(court: court);
                          },
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${loc.t('filters_showing', fallback: 'Showing')} ${courts.length} ${loc.t('filters_of', fallback: 'of')} $totalItems',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          PaginationBar(
                            current: currentPage,
                            last: lastPage,
                            onSelect: (page) => _load(page: page),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Map<String, dynamic> _extractMeta(Map<String, dynamic> res, int fallbackPage) {
    final meta = res['meta'];
    if (meta is Map<String, dynamic> && meta.isNotEmpty) return meta;
    final result = <String, dynamic>{};
    for (final key in ['current_page', 'last_page', 'per_page', 'total']) {
      final value = res[key];
      if (value != null) result[key] = value;
    }
    result.putIfAbsent('current_page', () => fallbackPage);
    result.putIfAbsent('last_page', () => result['current_page']);
    return result;
  }
}

class _ResultCard extends StatelessWidget {
  final Map<String, dynamic> court;
  const _ResultCard({required this.court});

  @override
  Widget build(BuildContext context) {
    final name = court['name']?.toString() ?? 'Ground';
    final address = court['address']?.toString() ?? '';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GroundDetailPage(court: court)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF1F1F1F), borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: CourtImage(images: court['images']),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(address, style: const TextStyle(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
