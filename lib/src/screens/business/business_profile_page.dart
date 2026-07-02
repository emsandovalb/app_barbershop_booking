import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../config/white_label_config.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../gallery/gallery_page.dart';
import '../reviews/reviews_page.dart';

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
    try {
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
    } catch (_) {
      return const _BusinessProfileData(staff: [], resources: []);
    }
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
            color: AppColors.primary,
            child: FutureBuilder<_BusinessProfileData>(
              future: _future,
              builder: (context, snapshot) {
                final data =
                    snapshot.data ??
                    const _BusinessProfileData(staff: [], resources: []);
                final staff = data.staff.isNotEmpty
                    ? data.staff
                    : _fallbackStaff;
                final resources = data.resources.isNotEmpty
                    ? data.resources
                    : _fallbackResources;
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData;

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    if (isLoading) ...[
                      const SizedBox(height: 220),
                      const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 220),
                    ] else ...[
                      const _TopBar(),
                      const SizedBox(height: 14),
                      _HeroSection(
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
                      const _BusinessInfoSection(),
                      const SizedBox(height: 18),
                      SectionHeader(
                        title: 'Nuestro equipo',
                        actionLabel: whiteLabel.appointmentLabel,
                        onTap: _openBookingFlow,
                      ),
                      const SizedBox(height: 12),
                      _StaffScroller(staff: staff),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: 'Servicios destacados',
                        actionLabel: whiteLabel.businessProfileLabel,
                        onTap: _openBookingFlow,
                      ),
                      const SizedBox(height: 12),
                      _ServiceGrid(resources: resources),
                      const SizedBox(height: 20),
                      SectionHeader(
                        title: whiteLabel.galleryLabel,
                        actionLabel: 'Ver galería',
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
                                  backgroundColor: AppColors.primary,
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

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: Colors.white,
        ),
        const SizedBox(width: 2),
        const Text(
          'Perfil de la barbería',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends StatelessWidget {
  final int staffCount;
  final int serviceCount;

  const _HeroSection({required this.staffCount, required this.serviceCount});

  @override
  Widget build(BuildContext context) {
    return BarbershopCinematicPanel(
      backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
      radius: 32,
      padding: const EdgeInsets.all(18),
      opacity: .58,
      blurSigma: 3.5,
      child: SizedBox(
        height: 320,
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: const PremiumBadge(label: 'PERFIL DE LA BARBERÍA'),
            ),
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  BarbershopLogoMark(
                    assetPath: 'assets/branding/logo_transparent.png',
                    size: 126,
                    glowColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BARBERÍA TRES AMIGOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Cortes, barba y experiencias premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _HeroInfoPill(icon: Icons.star_rounded, text: '4.9'),
                      _HeroInfoPill(icon: Icons.cut_rounded, text: 'Premium'),
                      _HeroInfoPill(
                        icon: Icons.location_on_rounded,
                        text: 'El Roble',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                children: [
                  Expanded(
                    child: _CounterTile(
                      icon: Icons.people_alt_rounded,
                      label: 'Equipo',
                      value: '$staffCount',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CounterTile(
                      icon: Icons.content_cut_rounded,
                      label: 'Servicios',
                      value: '$serviceCount',
                    ),
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

class _HeroInfoPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroInfoPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CounterTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF130F0C).withValues(alpha: .94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .68),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onLocation;
  final VoidCallback onInstagram;

  const _QuickActionsRow({
    required this.onWhatsApp,
    required this.onCall,
    required this.onLocation,
    required this.onInstagram,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.chat_rounded,
            label: 'WhatsApp',
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.call_rounded,
            label: 'Llamar',
            onTap: onCall,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.place_rounded,
            label: 'Ubicación',
            onTap: onLocation,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_rounded,
            label: 'Instagram',
            onTap: onInstagram,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14100E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: .06),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: .20),
                    AppColors.primary.withValues(alpha: .06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: .30),
                ),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessInfoSection extends StatelessWidget {
  const _BusinessInfoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _BusinessInfoCard(
          icon: Icons.schedule_rounded,
          title: 'Horario de atención',
          body:
              'Lun 10:00 AM - 7:00 PM\nMar - Jue 10:00 AM - 12:00 PM / 2:00 PM - 8:00 PM\nVie - Sáb 10:00 AM - 7:00 PM\nDomingo cerrado',
        ),
        SizedBox(height: 12),
        _BusinessInfoCard(
          icon: Icons.event_busy_rounded,
          title: 'Política de cancelación',
          body: 'Podés cancelar o reprogramar hasta 4 horas antes de tu cita.',
        ),
        SizedBox(height: 12),
        _BusinessInfoCard(
          icon: Icons.location_on_rounded,
          title: 'Ubicación y contacto',
          body:
              'Puntarenas, El Roble, Costa Rica\n\n+506 8888-3366\nhola@barberiatresamigos.com',
        ),
      ],
    );
  }
}

class _BusinessInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _BusinessInfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .76),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffScroller extends StatelessWidget {
  final List<Map<String, dynamic>> staff;

  const _StaffScroller({required this.staff});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: staff.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _StaffCard(staff: staff[index]);
        },
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Map<String, dynamic> staff;

  const _StaffCard({required this.staff});

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    final rawAvatar = _stringValue(staff, [
      'avatar_url',
      'avatar',
      'photo',
      'image',
      'profile_image',
    ]);
    final avatar = api.resolveAssetUrl(rawAvatar);
    final name = _stringValue(staff, [
      'name',
      'full_name',
    ], fallback: 'Barbero premium');
    final title = _stringValue(staff, [
      'title',
      'role_name',
      'specialty',
      'headline',
    ], fallback: 'Estilista senior');
    final rating = _doubleValue(staff, [
      'rating',
      'average_rating',
    ], fallback: 4.9);
    final specialties = _splitSpecialties(
      _stringValue(staff, [
        'specialties',
        'bio',
        'description',
      ], fallback: 'Fade · Barba · Corte clásico'),
    );

    return SizedBox(
      width: 172,
      child: BarbershopPremiumCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 94,
                width: double.infinity,
                child: avatar.isNotEmpty
                    ? Image.network(
                        avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/branding/barber_placeholder.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/branding/barber_placeholder.png',
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .70),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  rating.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'premium',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .55),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: specialties
                  .take(2)
                  .map((item) => _MiniChip(label: item))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;

  const _MiniChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .78),
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  final List<Map<String, dynamic>> resources;

  const _ServiceGrid({required this.resources});

  @override
  Widget build(BuildContext context) {
    final items = resources.take(4).toList(growable: false);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .82,
      ),
      itemBuilder: (context, index) {
        return _ServiceCard(resource: items[index]);
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> resource;

  const _ServiceCard({required this.resource});

  @override
  Widget build(BuildContext context) {
    final name = _stringValue(resource, [
      'name',
      'title',
    ], fallback: 'Servicio premium');
    final price = _formatCrc(resource['price_per_hour'] ?? resource['price']);
    final duration = _durationLabel(
      resource['duration_hours'],
      resource['duration_minutes'],
    );
    final category = _stringValue(resource, ['category'], fallback: 'premium');

    return BarbershopPremiumCard(
      padding: EdgeInsets.zero,
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CourtImage(
                  images: resource['images'],
                  radius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .58),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const Positioned(
                  top: 10,
                  right: 10,
                  child: PremiumBadge(label: 'PREMIUM', compact: true),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
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
                      color: Colors.white70,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10.5,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .58),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryGrid extends StatelessWidget {
  const _GalleryGrid();

  @override
  Widget build(BuildContext context) {
    final tiles = _galleryTiles;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tiles.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.06,
      ),
      itemBuilder: (context, index) {
        final tile = tiles[index];
        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(tile.asset, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .60),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  tile.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ReviewsList extends StatelessWidget {
  const _ReviewsList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _reviews
          .map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: BarbershopPremiumCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const _AvatarMark(),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => const Padding(
                                    padding: EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.star_rounded,
                                      color: AppColors.primary,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '“${review.text}”',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.45,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReviewsCta extends StatelessWidget {
  final VoidCallback onTap;

  const _ReviewsCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14100E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .12),
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver todas las opiniones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Abrí la experiencia premium de reseñas y testimonios.',
                    style: TextStyle(color: Colors.white70, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _AvatarMark extends StatelessWidget {
  const _AvatarMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: .26),
            AppColors.primary.withValues(alpha: .10),
          ],
        ),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 21),
    );
  }
}

class _BusinessProfileData {
  final List<Map<String, dynamic>> staff;
  final List<Map<String, dynamic>> resources;

  const _BusinessProfileData({required this.staff, required this.resources});
}

class _GalleryTileData {
  final String asset;
  final String label;

  const _GalleryTileData(this.asset, this.label);
}

class _ReviewData {
  final String name;
  final String text;

  const _ReviewData(this.name, this.text);
}

const List<Map<String, dynamic>> _fallbackStaff = [
  {
    'name': 'Barbero Senior',
    'title': 'Cortes premium',
    'rating': 4.9,
    'specialties': 'Fade, barba, detalle fino',
    'avatar': 'assets/branding/barber_placeholder.png',
  },
  {
    'name': 'Especialista en barba',
    'title': 'Afeitado clásico',
    'rating': 4.8,
    'specialties': 'Barba, perfilado, navaja',
    'avatar': 'assets/branding/barber_placeholder.png',
  },
  {
    'name': 'Estilista creativo',
    'title': 'Look contemporáneo',
    'rating': 5.0,
    'specialties': 'Corte moderno, diseño, acabado',
    'avatar': 'assets/branding/barber_placeholder.png',
  },
];

const List<Map<String, dynamic>> _fallbackResources = [
  {
    'name': 'Corte premium',
    'price_per_hour': 6000,
    'duration_hours': 1,
    'category': 'premium',
    'images': ['assets/branding/service_placeholder_premium.png'],
  },
  {
    'name': 'Barba y perfilado',
    'price_per_hour': 4500,
    'duration_hours': 1,
    'category': 'clásico',
    'images': ['assets/branding/service_placeholder_premium.png'],
  },
  {
    'name': 'Fade signature',
    'price_per_hour': 7000,
    'duration_hours': 1,
    'category': 'premium',
    'images': ['assets/branding/service_placeholder_premium.png'],
  },
  {
    'name': 'Experiencia completa',
    'price_per_hour': 9500,
    'duration_hours': 2,
    'category': 'premium',
    'images': ['assets/branding/service_placeholder_premium.png'],
  },
];

const List<_GalleryTileData> _galleryTiles = [
  _GalleryTileData(
    'assets/branding/barbershop_hero_bg.png',
    'Ambiente premium',
  ),
  _GalleryTileData(
    'assets/branding/logo_transparent.png',
    'Identidad Tres Amigos',
  ),
  _GalleryTileData(
    'assets/branding/barber_placeholder.png',
    'Barberos expertos',
  ),
  _GalleryTileData(
    'assets/branding/service_placeholder_premium.png',
    'Detalles de precisión',
  ),
];

const List<_ReviewData> _reviews = [
  _ReviewData('Cliente frecuente', 'Excelente atención y muy buen ambiente.'),
  _ReviewData('Reserva reciente', 'El corte quedó justo como lo quería.'),
  _ReviewData('Visita premium', 'Muy recomendado, servicio premium.'),
];

String _stringValue(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

double _doubleValue(
  Map<String, dynamic> map,
  List<String> keys, {
  required double fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

List<String> _splitSpecialties(String raw) {
  final normalized = raw
      .replaceAll('\n', ' · ')
      .replaceAll('/', ' · ')
      .replaceAll(',', ' · ')
      .split('·')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  if (normalized.isNotEmpty) return normalized;
  return const ['Fade', 'Barba'];
}

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}

String _durationLabel(dynamic hoursValue, dynamic minutesValue) {
  final minutes = minutesValue is num
      ? minutesValue.toInt()
      : int.tryParse(minutesValue?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    if (remainder == 0) return hours == 1 ? '1 h' : '$hours h';
    return '${hours == 1 ? '1' : hours} h $remainder min';
  }

  final hours = hoursValue is num
      ? hoursValue.toInt()
      : int.tryParse(hoursValue?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}
