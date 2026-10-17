import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/court_image.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/loadable_collection_view.dart';
import '../ground/ground_detail_page.dart';
import '../search/filter_page.dart';

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
  late final LoadableController<Map<String, dynamic>> _controller;
  int currentPage = 1;
  int lastPage = 1;
  int totalItems = 0;

  @override
  void initState() {
    super.initState();
    filters = {...?widget.initialFilters}..removeWhere(_emptyValue);
    _controller = LoadableController<Map<String, dynamic>>(_load);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _emptyValue(String key, dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  Future<Map<String, dynamic>> _load() async {
    final api = context.read<AuthProvider>().api;
    final res = await api.getResources(
      q: filters['q'] as String?,
      minPrice: filters['minPrice'] as double?,
      maxPrice: filters['maxPrice'] as double?,
      sort: filters['sort'] as String?,
      category: filters['category'] as String?,
      durationHours: filters['duration'] as int?,
      page: currentPage,
      perPage: _pageSize,
    );
    final meta = _extractMeta(res, currentPage);
    currentPage = meta['current_page'] as int? ?? currentPage;
    lastPage = meta['last_page'] as int? ?? currentPage;
    totalItems = meta['total'] as int? ?? ((res['data'] as List?)?.length ?? 0);
    return res;
  }

  Future<void> _reload({int page = 1}) async {
    currentPage = page;
    await _controller.load();
  }

  Future<void> _openFilters() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const FilterPage()),
    );
    if (result != null) {
      filters = {...result}..removeWhere(_emptyValue);
      currentPage = 1;
      await _controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final loc = context.watch<LocalizationService>();
        final title = widget.title ?? loc.t('filter_results_title');
        final state = _controller.state;
        final resources = _extractItems(state.data);
        final isLoading = state.isLoading && !state.hasData;
        final hasError = state.hasError && !state.hasData;

        return Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: [
              IconButton(
                onPressed: _openFilters,
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          body: hasError
              ? RefreshIndicator(
                  onRefresh: () => _reload(page: 1),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'No fue posible cargar los servicios.',
                              style: TextStyle(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Revisa tu conexión e intenta nuevamente.',
                              style: TextStyle(color: Colors.white54),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => _reload(page: 1),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : isLoading
              ? const Center(child: CircularProgressIndicator())
              : resources.isEmpty
              ? RefreshIndicator(
                  onRefresh: () => _reload(page: 1),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(32),
                    children: [
                      const SizedBox(height: 120),
                      Center(child: Text(loc.t('filters_empty'))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _reload(page: 1),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: resources.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final resource = resources[i];
                            return _ResultCard(resource: resource);
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
                              loc.t(
                                'filters_count',
                                args: {
                                  'count': resources.length,
                                  'total': totalItems,
                                },
                              ),
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          PaginationBar(
                            current: currentPage,
                            last: lastPage,
                            onSelect: (page) => _reload(page: page),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic>? response) {
    if (response == null) return const [];
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const [];
  }

  Map<String, dynamic> _extractMeta(
    Map<String, dynamic> res,
    int fallbackPage,
  ) {
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
  final Map<String, dynamic> resource;
  const _ResultCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final name = resource['name']?.toString() ?? 'Resource';
    final address = resource['address']?.toString() ?? '';
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => GroundDetailPage(court: resource)),
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1F1F1F),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 180,
              child: CourtImage(images: resource['images']),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
