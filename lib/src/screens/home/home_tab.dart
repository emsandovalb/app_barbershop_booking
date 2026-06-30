import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
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
  List<dynamic> popular = [];
  List<dynamic> premium = [];
  bool loadingPopular = false;
  bool loadingPremium = false;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadPopular(page: 1), _loadPremium(page: 1)]);
  }

  Future<void> _loadPopular({required int page}) async {
    if (loadingPopular) return;
    setState(() => loadingPopular = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getResources(
        sort: 'rating',
        page: page,
        perPage: _homePageSize,
      );
      if (!mounted) return;
      final data = (res['data'] as List?) ?? [];
      setState(() => popular = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => popular = []);
    } finally {
      if (mounted) setState(() => loadingPopular = false);
    }
  }

  Future<void> _loadPremium({required int page}) async {
    if (loadingPremium) return;
    setState(() => loadingPremium = true);
    try {
      final api = context.read<AuthProvider>().api;
      final res = await api.getResources(
        page: page,
        perPage: _homePageSize,
        category: 'premium',
        sort: 'rating',
      );
      if (!mounted) return;
      final data = (res['data'] as List?) ?? [];
      setState(() => premium = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => premium = []);
    } finally {
      if (mounted) setState(() => loadingPremium = false);
    }
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
    final config = context.watch<AppConfig>();
    final brand = config.brand;
    final auth = context.watch<AuthProvider>();
    final name =
        (auth.user?['first_name'] ?? auth.user?['name'] ?? 'Admin Demo')
            .toString();

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
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
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
                      logoAsset:
                          brand.logoAsset ??
                          'assets/branding/logo_transparent.png',
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
                                title: 'Resultados de servicios',
                              );
                            },
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Buscar servicios, barberos...',
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
                  const _BusinessInfoCards(),
                  const SizedBox(height: 16),
                  _BusinessProfileTeaser(
                    onTap: () => Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.businessProfile),
                  ),
                  const SizedBox(height: 10),
                  _ReviewsPromoCard(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReviewsPage(),
                      ),
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
                      label: const Text('Ver galería'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: 'Servicios destacados',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: 'Servicios destacados',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceCarousel(
                    isLoading: loadingPopular || loadingPremium,
                    items: featuredServices,
                    emptyMessage: 'No hay servicios destacados disponibles.',
                    onEmptyTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: 'Servicios destacados',
                    ),
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Servicios populares',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: 'Servicios populares',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceCarousel(
                    isLoading: loadingPopular,
                    items: popular,
                    emptyMessage: 'No hay servicios populares disponibles.',
                    onEmptyTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: 'Servicios populares',
                    ),
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                  ),
                  const SizedBox(height: 20),
                  SectionHeader(
                    title: 'Experiencias premium',
                    actionLabel: 'Ver todos',
                    onTap: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: 'Experiencias premium',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceCarousel(
                    isLoading: loadingPremium,
                    items: premium,
                    emptyMessage: 'No hay experiencias premium disponibles.',
                    onEmptyTap: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: 'Experiencias premium',
                    ),
                    itemBuilder: (index, data) =>
                        _ServiceCard(index: index, data: data),
                  ),
                ],
              ),
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

  const _HeroCard({required this.brand, required this.logoAsset});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: SizedBox(
        height: 292,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/barbershop_hero_bg.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
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
                  const Align(
                    alignment: Alignment.topCenter,
                    child: PremiumBadge(label: 'PREMIUM EXPERIENCE'),
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
                  const Text(
                    'BARBERIA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'TRES AMIGOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
  const _BusinessInfoCards();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: _InfoCard(
            icon: Icons.schedule_rounded,
            title: 'Horario de atencion',
            body:
                'Lun 10:00 AM - 7:00 PM\nMar - Jue 10:00 AM - 12:00 PM\n2:00 PM - 8:00 PM\nVie - Sab 10:00 AM - 7:00 PM\nDomingo cerrado',
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _InfoCard(
            icon: Icons.location_on_rounded,
            title: 'Ubicacion y contacto',
            body:
                'Puntarenas, El Roble,\nCosta Rica\n\n+506 8888-3366\n\nhola@barberiatresamigos.com',
          ),
        ),
      ],
    );
  }
}

class _BusinessProfileTeaser extends StatelessWidget {
  final VoidCallback onTap;

  const _BusinessProfileTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: AppColors.primary.withValues(alpha: .20)),
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
                color: AppColors.primary.withValues(alpha: .14),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conocé la barbería',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Entrá al perfil premium de Barbería Tres Amigos.',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _ReviewsPromoCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ReviewsPromoCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
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
                color: AppColors.primary.withValues(alpha: .14),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clientes felices',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '4.9 basado en 128 opiniones',
                    style: TextStyle(color: Colors.white70, height: 1.35),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ver opiniones',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
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
              color: AppColors.primary.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
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
                      style: const TextStyle(
                        color: AppColors.primary,
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
