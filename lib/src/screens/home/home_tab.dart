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
    final name =
        (auth.user?['first_name'] ?? auth.user?['name'] ?? 'Admin Demo')
            .toString();

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
                  'Hola, $name',
                  style:  TextStyle(
                    fontSize: 13,
                    color: theme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Buenos dias',
                  style: TextStyle(
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
                                title:
                                    'Resultados de ${whiteLabel.servicesLabel}',
                              );
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            cursorColor: theme.primary,
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar ${whiteLabel.servicesLabel}, ${whiteLabel.staffPluralLabel}...',
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
                            title: 'Servicios filtrados',
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
                      label: Text('Ver ${whiteLabel.galleryLabel}'),
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
                    title:
                        '${_capitalize(whiteLabel.servicesLabel)} destacados',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title:
                          '${_capitalize(whiteLabel.servicesLabel)} destacados',
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_popularController.state.hasError ||
                      _premiumController.state.hasError)
                    if (featuredServices.isEmpty)
                      _StateCard(
                        title:
                            '${_capitalize(whiteLabel.servicesLabel)} destacados',
                        body:
                            'No fue posible cargar los ${whiteLabel.servicesLabel}.',
                        actionLabel: 'Reintentar',
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
                        emptyMessage:
                            'No hay ${whiteLabel.servicesLabel} destacados disponibles.',
                        onEmptyTap: () => _openFilteredResults(
                          filters: const {'sort': 'rating'},
                          title:
                              '${_capitalize(whiteLabel.servicesLabel)} destacados',
                        ),
                        itemBuilder: (index, data) =>
                            _ServiceCard(index: index, data: data),
                      )
                  else if (featuredServices.isEmpty)
                    _StateCard(
                      title:
                          '${_capitalize(whiteLabel.servicesLabel)} destacados',
                      body:
                          'No hay ${whiteLabel.servicesLabel} destacados disponibles.',
                      actionLabel: 'Ver todos',
                      onAction: () => _openFilteredResults(
                        filters: const {'sort': 'rating'},
                        title:
                            '${_capitalize(whiteLabel.servicesLabel)} destacados',
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
                      emptyMessage:
                          'No hay ${whiteLabel.servicesLabel} destacados disponibles.',
                      onEmptyTap: () => _openFilteredResults(
                        filters: const {'sort': 'rating'},
                        title:
                            '${_capitalize(whiteLabel.servicesLabel)} destacados',
                      ),
                      itemBuilder: (index, data) =>
                          _ServiceCard(index: index, data: data),
                    ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: '${_capitalize(whiteLabel.servicesLabel)} populares',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title:
                          '${_capitalize(whiteLabel.servicesLabel)} populares',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceListSection(
                    controller: _popularController,
                    title: '${_capitalize(whiteLabel.servicesLabel)} populares',
                    emptyMessage:
                        'No hay ${whiteLabel.servicesLabel} populares disponibles.',
                    loadingMessage: 'Cargando ${whiteLabel.servicesLabel}...',
                    errorMessage:
                        'No fue posible cargar los ${whiteLabel.servicesLabel}.',
                    retryLabel: 'Reintentar',
                    onViewAll: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title:
                          '${_capitalize(whiteLabel.servicesLabel)} populares',
                    ),
                    items: popular,
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                    onRetry: _refreshAll,
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: '${_capitalize(whiteLabel.servicesLabel)} premium',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: '${_capitalize(whiteLabel.servicesLabel)} premium',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceListSection(
                    controller: _premiumController,
                    title: '${_capitalize(whiteLabel.servicesLabel)} premium',
                    emptyMessage:
                        'No hay ${whiteLabel.servicesLabel} premium disponibles.',
                    loadingMessage: 'Cargando ${whiteLabel.servicesLabel}...',
                    errorMessage:
                        'No fue posible cargar los ${whiteLabel.servicesLabel}.',
                    retryLabel: 'Reintentar',
                    onViewAll: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: '${_capitalize(whiteLabel.servicesLabel)} premium',
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

class _ServiceListSection extends StatelessWidget {
  final LoadableController<List<Map<String, dynamic>>> controller;
  final String title;
  final String emptyMessage;
  final String loadingMessage;
  final String errorMessage;
  final String retryLabel;
  final VoidCallback onViewAll;
  final Future<void> Function() onRetry;
  final List<Map<String, dynamic>> items;
  final Widget Function(int index, dynamic data) itemBuilder;

  const _ServiceListSection({
    required this.controller,
    required this.title,
    required this.emptyMessage,
    required this.loadingMessage,
    required this.errorMessage,
    required this.retryLabel,
    required this.onViewAll,
    required this.onRetry,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    if (state.isLoading && !state.hasData) {
      return _StateCard(
        title: title,
        body: loadingMessage,
        leading: const CircularProgressIndicator(),
      );
    }

    if (state.hasError && !state.hasData) {
      return _StateCard(
        title: title,
        body: errorMessage,
        actionLabel: retryLabel,
        onAction: onRetry,
        leading: const Icon(Icons.error_outline, color: Colors.white70),
      );
    }

    if (items.isEmpty) {
      return _StateCard(
        title: title,
        body: emptyMessage,
        actionLabel: 'Ver todos',
        onAction: onViewAll,
        leading: const Icon(Icons.inbox_outlined, color: Colors.white70),
      );
    }

    return _ServiceCarousel(
      isLoading: state.isLoading,
      items: items,
      emptyMessage: emptyMessage,
      onEmptyTap: onViewAll,
      itemBuilder: itemBuilder,
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  const _StateCard({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      backgroundColor: const Color(0xFF130F0C).withValues(alpha: .94),
      borderColor: Colors.white.withValues(alpha: .08),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .74),
                    height: 1.3,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
                      style:  TextStyle(
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
            title: 'Ubicación y contacto',
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
              child:  Icon(
                Icons.storefront_rounded,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conocé ${whiteLabel.businessProfileLabel}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Entrá al ${whiteLabel.businessProfileLabel} premium de ${whiteLabel.displayName}.',
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
              child:  Icon(
                Icons.dashboard_rounded,
                color: theme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Centro administrativo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestioná tu salón desde un solo lugar.',
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
              child:  Icon(
                Icons.favorite_rounded,
                color: theme.primary,
              ),
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
                    '${whiteLabel.rating.toStringAsFixed(1)} basado en ${whiteLabel.reviewCount} ${whiteLabel.reviewsLabel}',
                    style: const TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ver ${whiteLabel.reviewsLabel}',
                    style:  TextStyle(
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

class _ServiceCard extends StatelessWidget {
  final int index;
  final dynamic data;

  const _ServiceCard({required this.index, this.data});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final isPremium = _isPremium(data);
    final price = _formatCrc(data?['price_per_hour']);
    final duration = _durationLabel(
      data?['duration_hours'],
      data?['duration_minutes'],
    );
    final title = data?['name']?.toString() ?? 'Servicio ${index + 1}';

    return InkWell(
      onTap: () {
        if (data != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroundDetailPage(court: data!)),
          );
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 176,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14100E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CourtImage(
                      images: data?['images'],
                      radius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: .45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (isPremium)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: PremiumBadge(label: 'PREMIUM', compact: true),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style:  TextStyle(
                        color: theme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
  final minutes = durationMinutes is num
      ? durationMinutes.toInt()
      : int.tryParse(durationMinutes?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    if (remainder == 0) return hours == 1 ? '1 h' : '$hours h';
    return '${hours == 1 ? '1' : hours} h $remainder min';
  }

  final hours = durationHours is num
      ? durationHours.toInt()
      : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}

List<dynamic> _mergeFeaturedServices(
  List<dynamic> popular,
  List<dynamic> premium,
) {
  final seen = <String>{};
  final merged = <dynamic>[];
  for (final item in <dynamic>[...popular, ...premium]) {
    final key = _serviceKey(item);
    if (seen.add(key)) {
      merged.add(item);
    }
    if (merged.length >= 5) break;
  }
  return merged;
}

String _serviceKey(dynamic data) {
  if (data is Map<String, dynamic>) {
    final id = data['id'];
    if (id != null) return id.toString();
    final name = data['name'];
    if (name != null) return name.toString().toLowerCase();
  }
  return data?.hashCode.toString() ?? 'null';
}

bool _isPremium(dynamic data) {
  final name = data?['name']?.toString().toLowerCase() ?? '';
  final category = data?['category']?.toString().toLowerCase() ?? '';
  return name.contains('premium') || category == 'premium';
}

class _ServiceCarousel extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> items;
  final String emptyMessage;
  final VoidCallback onEmptyTap;
  final Widget Function(int index, dynamic data) itemBuilder;

  const _ServiceCarousel({
    required this.isLoading,
    required this.items,
    required this.emptyMessage,
    required this.onEmptyTap,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const SizedBox(
        height: 224,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return InkWell(
        onTap: onEmptyTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF14100E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => itemBuilder(index, items[index]),
      ),
    );
  }
}
