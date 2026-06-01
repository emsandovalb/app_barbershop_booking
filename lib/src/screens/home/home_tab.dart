import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../ground/ground_detail_page.dart';
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
      final res = await api.getResources(sort: 'rating', page: page, perPage: _homePageSize);
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

  Future<void> _loadNearby({required int page}) async {
    if (loadingNearby) return;
    setState(() => loadingNearby = true);
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
      setState(() => nearby = data);
    } catch (_) {
      if (!mounted) return;
      setState(() => nearby = []);
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
    final config = context.watch<AppConfig>();
    final brand = config.brand;
    final terminology = config.terminology;
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final name = (auth.user?['first_name'] ?? auth.user?['name'] ?? 'Cliente').toString();

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF090909),
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${loc.t('home_hello', fallback: 'Hola')}, $name',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
                const SizedBox(height: 2),
                Text(
                  loc.t('home_good_morning', fallback: 'Buenos días'),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    brand: brand,
                    loc: loc,
                    logoAsset: brand.logoAsset ?? 'assets/branding/logo_transparent.png',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (v) => q = v,
                          onSubmitted: (_) {
                            final query = q.trim();
                            if (query.isEmpty) return;
                            _openFilteredResults(
                              filters: {'q': query},
                              title: loc.t('home_search_results', fallback: '${terminology.services} resultados'),
                            );
                          },
                          decoration: InputDecoration(
                            hintText: loc.t('home_search_hint', fallback: 'Buscar servicios, barberos...'),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _openFilteredResults(
                          title: loc.t('filter_results_title', fallback: 'Servicios filtrados'),
                        ),
                        child: Container(
                          height: 54,
                          width: 54,
                          decoration: BoxDecoration(
                            color: brand.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: brand.primaryColor.withOpacity(.28),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.tune_rounded, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _InfoStrip(),
                  const SizedBox(height: 16),
                  SectionHeader(
                    title: loc.t('home_featured_title', fallback: 'Servicios destacados'),
                    actionLabel: loc.t('home_view_all', fallback: 'Ver todo'),
                    onTap: () => _openFilteredResults(
                      filters: const {'sort': 'rating'},
                      title: loc.t('home_featured_title', fallback: 'Servicios destacados'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 296,
                    child: loadingPopular
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, i) => _ServiceCard(
                              index: i,
                              data: i < popular.length ? popular[i] : null,
                            ),
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: popular.length,
                          ),
                  ),
                  const SizedBox(height: 18),
                  SectionHeader(
                    title: loc.t('home_premium_title', fallback: 'Experiencias premium'),
                    actionLabel: loc.t('home_view_all', fallback: 'Ver todo'),
                    onTap: () => _openFilteredResults(
                      filters: const {'category': 'premium', 'sort': 'rating'},
                      title: loc.t('home_premium_title', fallback: 'Experiencias premium'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 296,
                    child: loadingNearby
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (_, i) => _ServiceCard(
                              index: i,
                              data: i < nearby.length ? nearby[i] : null,
                            ),
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemCount: nearby.length,
                          ),
                  ),
                  if (config.features.showStaff &&
                      config.features.adminStaffManagement &&
                      auth.isAdmin) ...[
                    const SizedBox(height: 24),
                    SectionHeader(
                      title: loc.t('home_staff_title', fallback: terminology.staffMembers),
                      actionLabel: loc.t('home_view_all', fallback: 'Ver todo'),
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminStaff),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => Navigator.of(context).pushNamed(AppRoutes.adminStaff),
                      borderRadius: BorderRadius.circular(24),
                      child: BarbershopPremiumCard(
                        padding: const EdgeInsets.all(16),
                        radius: 24,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: brand.primaryColor.withOpacity(.16),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.content_cut_outlined, color: Colors.white),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    loc.t(
                                      'home_staff_card_title',
                                      fallback: 'Administrar barberos y asignaciones',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    loc.t(
                                      'home_staff_card_body',
                                      fallback: 'Creá, editá, activá y asigná barberos desde un solo lugar.',
                                    ),
                                    style: TextStyle(color: Colors.white.withOpacity(.74)),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
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
    final staff = (data?['staff'] as List?) ?? const [];
    final isPremium = _isPremium(data);
    final price = _formatCrc(data?['price_per_hour']);
    final duration = _durationLabel(data?['duration_hours'], data?['duration_minutes']);
    final description = data?['description']?.toString() ?? '';
    final title = data?['name']?.toString() ?? 'Servicio ${index + 1}';

    return InkWell(
      onTap: () {
        if (data != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroundDetailPage(court: data!)),
          );
        }
      },
      child: SizedBox(
        width: 242,
        child: BarbershopPremiumCard(
          padding: EdgeInsets.zero,
          radius: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 160,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CourtImage(
                        images: data?['images'],
                        radius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(.72),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      if (isPremium)
                        const Positioned(
                          left: 10,
                          top: 10,
                          child: PremiumBadge(label: 'Premium', compact: true),
                        ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(.45),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white.withOpacity(.10)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule_rounded, size: 13, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                duration,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.payments_outlined, size: 16, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  price,
                                  style: const TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Spacer(),
                                if (isPremium)
                                  const PremiumBadge(label: 'Premium', compact: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description.isNotEmpty
                            ? description
                            : (data?['address']?.toString() ?? 'Servicio premium'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.74),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      if (staff.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: staff.take(2).map((item) {
                            final member = item is Map ? Map<String, dynamic>.from(item) : const <String, dynamic>{};
                            final memberName = member['name']?.toString() ?? 'Barbero';
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1F1915),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Colors.white.withOpacity(.06)),
                              ),
                              child: Text(
                                memberName,
                                style: const TextStyle(fontSize: 11, color: Colors.white),
                              ),
                            );
                          }).toList(growable: false),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final BrandConfig brand;
  final LocalizationService loc;
  final String logoAsset;

  const _HeroCard({
    required this.brand,
    required this.loc,
    required this.logoAsset,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 344,
      child: BarbershopCinematicPanel(
        backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
        radius: 30,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        opacity: .56,
        blurSigma: 2,
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: PremiumBadge(label: loc.t('home_brand_badge', fallback: 'Premium Experience')),
            ),
            const Spacer(),
            Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final logoSize = (constraints.maxWidth * .38).clamp(108.0, 150.0);
                  return BarbershopLogoMark(
                    assetPath: logoAsset,
                    size: logoSize,
                    glowColor: brand.primaryColor,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'BARBER�A',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.88),
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
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
                letterSpacing: .4,
                height: .95,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.t(
                'home_hero_subtitle',
                fallback: 'Cortes, barba y experiencias premium',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(.80),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Row(
      children: [
        Expanded(
          child: _MiniInfoCard(
            icon: Icons.schedule_outlined,
            title: loc.t('home_business_hours_title', fallback: 'Horario de atención'),
            body: loc.t(
              'home_hours_card_body',
              fallback: 'Lun 10:00 AM - 7:00 PM · Mar 10:00 AM - 12:00 PM · 2:00 PM - 8:00 PM · Vie-Sáb 10:00 AM - 7:00 PM · Domingo cerrado',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MiniInfoCard(
            icon: Icons.storefront_outlined,
            title: loc.t('home_location_title', fallback: 'Ubicación y contacto'),
            body: loc.t(
              'home_contact_card_body',
              fallback: '+506 8888-3366 · hola@barberiatresamigos.com',
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _MiniInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(14),
      radius: 22,
      backgroundColor: const Color(0xFF15110E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(color: Colors.white.withOpacity(.75), fontSize: 12, height: 1.35),
          ),
        ],
      ),
    );
  }
}

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(locale: 'es_CR', symbol: 'CRC ', decimalDigits: 0)
      .format(number);
}

String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
  final minutes = durationMinutes is num
      ? durationMinutes.toInt()
      : int.tryParse(durationMinutes?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 h' : '$hours h';
    }
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    return '${hours}h ${remainder}m';
  }
  final hours = durationHours is num
      ? durationHours.toInt()
      : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}

bool _isPremium(dynamic data) {
  final name = data?['name']?.toString().toLowerCase() ?? '';
  final category = data?['category']?.toString().toLowerCase() ?? '';
  return name.contains('premium') || category == 'premium';
}


