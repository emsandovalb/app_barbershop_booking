import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/white_label_config.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../gallery/gallery_page.dart';
import '../reviews/reviews_page.dart';

part 'business_profile/hero.dart';
part 'business_profile/info_and_staff.dart';
part 'business_profile/services_and_reviews.dart';
part 'business_profile/data.dart';

class BusinessProfilePage extends StatefulWidget {
  const BusinessProfilePage({super.key});

  @override
  State<BusinessProfilePage> createState() => _BusinessProfilePageState();
}

class _BusinessProfilePageState extends State<BusinessProfilePage> {
  late Future<_BusinessProfileData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<_BusinessProfileData> _loadData() async {
    final api = context.read<AuthProvider>().api;
    final responses = await Future.wait([
      api.getStaff(perPage: 6),
      api.getResources(
        page: 1,
        perPage: 6,
        category: 'premium',
        sort: 'rating',
      ),
    ]);
    return _BusinessProfileData(
      staff: _extractItems(responses[0]),
      resources: _extractItems(responses[1]),
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  void _showPlaceholderAction(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label aún no está configurado.')));
  }

  void _openBookingFlow() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: BarbershopPremiumBackdrop(
        backgroundAsset: whiteLabel.heroBackground,
        backgroundOpacity: .18,
        blurSigma: 18,
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: theme.primary,
            child: FutureBuilder<_BusinessProfileData>(
              future: _future,
              builder: (context, snapshot) {
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      const SizedBox(height: 140),
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
                              onPressed: _refresh,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                final data =
                    snapshot.data ??
                    const _BusinessProfileData(staff: [], resources: []);
                final staff = data.staff;
                final resources = data.resources;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (isLoading) ...[
                      const SizedBox(height: 220),
                      Center(
                        child: CircularProgressIndicator(color: theme.primary),
                      ),
                      const SizedBox(height: 220),
                    ] else ...[
                      _TopBar(whiteLabel: whiteLabel),
                      const SizedBox(height: 14),
                      _HeroSection(
                        whiteLabel: whiteLabel,
                        staffCount: staff.length,
                        serviceCount: resources.length,
                      ),
                      const SizedBox(height: 14),
                      _QuickActionsRow(
                        onWhatsApp: () => _showPlaceholderAction('WhatsApp'),
                        onCall: () => _showPlaceholderAction('Llamar'),
                        onLocation: () => _showPlaceholderAction('Ubicación'),
                        onInstagram: () => _showPlaceholderAction('Instagram'),
                      ),
                      const SizedBox(height: 14),
                      _BusinessInfoSection(whiteLabel: whiteLabel),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Nuestro equipo',
                        actionLabel: whiteLabel.appointmentLabel,
                        onTap: _openBookingFlow,
                      ),
                      const SizedBox(height: 12),
                      staff.isEmpty
                          ? const _EmptySectionCard(
                              title: 'Nuestro equipo',
                              body: 'No quedan profesionales disponibles.',
                            )
                          : _StaffScroller(staff: staff),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Servicios destacados',
                        actionLabel: whiteLabel.businessProfileLabel,
                        onTap: _openBookingFlow,
                      ),
                      const SizedBox(height: 12),
                      resources.isEmpty
                          ? const _EmptySectionCard(
                              title: 'Servicios destacados',
                              body:
                                  'No hay servicios disponibles por el momento.',
                            )
                          : _ServiceGrid(resources: resources),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: whiteLabel.galleryLabel,
                        actionLabel: 'Ver ${whiteLabel.galleryLabel}',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GalleryPage(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const _GalleryGrid(),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'Opiniones'),
                      const SizedBox(height: 12),
                      const _ReviewsList(),
                      const SizedBox(height: 12),
                      _ReviewsCta(
                        whiteLabel: whiteLabel,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ReviewsPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      BarbershopPremiumCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const PremiumBadge(label: 'RESERVÁ AHORA'),
                            const SizedBox(height: 12),
                            Text(
                              'Reservá tu próxima cita con una experiencia premium.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Volvé al inicio o seguí con la reserva desde el listado de servicios.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .74),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _openBookingFlow,
                                icon: const Icon(Icons.calendar_month_rounded),
                                label: const Text('Reservar cita'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primary,
                                  foregroundColor: const Color(0xFF090909),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
