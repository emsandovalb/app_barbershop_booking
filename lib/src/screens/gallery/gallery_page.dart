import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../config/white_label_config.dart';
import '../../theme/colors.dart';
import '../../widgets/barbershop_branding.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  static const _categories = <_GalleryCategory>[
    _GalleryCategory(id: 'all', label: 'Todos'),
    _GalleryCategory(id: 'cortes', label: 'Cortes'),
    _GalleryCategory(id: 'barbas', label: 'Barbas'),
    _GalleryCategory(id: 'premium', label: 'Premium'),
    _GalleryCategory(id: 'spa', label: 'Spa Facial'),
    _GalleryCategory(id: 'instalaciones', label: 'Instalaciones'),
  ];

  static const _featuredWork = <_GalleryItem>[
    _GalleryItem(
      asset: 'assets/branding/barbershop_hero_bg.png',
      title: 'Fade Signature',
      description: 'Líneas limpias, textura controlada y acabado premium.',
      category: 'cortes',
      tag: 'Antes / Después',
      heightFactor: 1.18,
    ),
    _GalleryItem(
      asset: 'assets/branding/service_placeholder_premium.png',
      title: 'Experiencia Premium',
      description:
          'Un servicio pensado para sentirse impecable de principio a fin.',
      category: 'premium',
      tag: 'Feature',
      heightFactor: 1.05,
    ),
    _GalleryItem(
      asset: 'assets/branding/barber_placeholder.png',
      title: 'Barba Clásica',
      description: 'Perfilado preciso, balance visual y detalles limpios.',
      category: 'barbas',
      tag: 'Barba',
      heightFactor: 1.1,
    ),
    _GalleryItem(
      asset: 'assets/branding/profile_placeholder.png',
      title: 'Spa Facial',
      description: 'Una pausa premium para refrescar la piel y relajar el día.',
      category: 'spa',
      tag: 'Spa',
      heightFactor: 1.15,
    ),
  ];

  static const _galleryItems = <_GalleryItem>[
    _GalleryItem(
      asset: 'assets/branding/barbershop_hero_bg.png',
      title: 'Fade Classic',
      description: 'Transición suave y textura natural.',
      category: 'cortes',
      tag: 'Fade',
      heightFactor: 1.12,
    ),
    _GalleryItem(
      asset: 'assets/branding/barber_placeholder.png',
      title: 'Barba Clean',
      description: 'Perfilado detallado con acabado definido.',
      category: 'barbas',
      tag: 'Beard',
      heightFactor: 1.32,
    ),
    _GalleryItem(
      asset: 'assets/branding/service_placeholder_premium.png',
      title: 'Premium Lounge',
      description: 'Ambiente oscuro, cómodo y de alto estándar.',
      category: 'instalaciones',
      tag: 'Lounge',
      heightFactor: 1.02,
    ),
    _GalleryItem(
      asset: 'assets/branding/profile_placeholder.png',
      title: 'Spa Facial',
      description: 'Cuidado facial con sensación de limpieza profunda.',
      category: 'spa',
      tag: 'Spa',
      heightFactor: 1.18,
    ),
    _GalleryItem(
      asset: 'assets/branding/barbershop_hero_bg.png',
      title: 'Corte Premium',
      description: 'Volumen controlado y acabado elegante.',
      category: 'premium',
      tag: 'Premium',
      heightFactor: 1.28,
    ),
    _GalleryItem(
      asset: 'assets/branding/barber_placeholder.png',
      title: 'Barba y Navaja',
      description: 'Líneas finas para un look más pulido.',
      category: 'barbas',
      tag: 'Detail',
      heightFactor: 1.05,
    ),
    _GalleryItem(
      asset: 'assets/branding/service_placeholder_premium.png',
      title: 'Corte Fade',
      description: 'Una de nuestras firmas más pedidas.',
      category: 'cortes',
      tag: 'Classic',
      heightFactor: 1.22,
    ),
    _GalleryItem(
      asset: 'assets/branding/profile_placeholder.png',
      title: 'Espacio Premium',
      description: 'Iluminación cálida y una atmósfera de confianza.',
      category: 'instalaciones',
      tag: 'Space',
      heightFactor: 1.1,
    ),
  ];

  String _selectedCategory = 'all';

  List<_GalleryItem> get _filteredItems {
    if (_selectedCategory == 'all') {
      return _galleryItems;
    }
    return _galleryItems
        .where((item) => item.category == _selectedCategory)
        .toList(growable: false);
  }

  void _openImageViewer(_GalleryItem item) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: .92),
        transitionDuration: const Duration(milliseconds: 260),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _GalleryViewerPage(item: item);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );
  }

  void _showPlaceholder(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label todavía no está configurado.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whiteLabel =
        Provider.of<WhiteLabelConfig?>(context, listen: false) ??
        WhiteLabelConfig.tresAmigos;
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: BarbershopPremiumBackdrop(
        backgroundAsset: whiteLabel.heroBackground,
        backgroundOpacity: .10,
        blurSigma: 22,
        child: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _GalleryTopBar(
                    onBack: () => Navigator.of(context).maybePop(),
                    onReserve: () =>
                        Navigator.of(context).pushNamed(AppRoutes.home),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _GalleryHero(
                    onReserve: () =>
                        Navigator.of(context).pushNamed(AppRoutes.home),
                    onInstagram: () => _showPlaceholder('Instagram'),
                    onWhatsApp: () => _showPlaceholder('WhatsApp'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final selected = category.id == _selectedCategory;
                        return _CategoryChip(
                          label: category.label,
                          selected: selected,
                          onTap: () {
                            setState(() => _selectedCategory = category.id);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                  child: SectionHeader(
                    title: 'Featured Work',
                    actionLabel: 'Ver toda la galería',
                    onTap: () => setState(() => _selectedCategory = 'all'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
                  child: SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredWork.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final item = _featuredWork[index];
                        return SizedBox(
                          width: 238,
                          child: _FeaturedCard(
                            item: item,
                            onTap: () => _openImageViewer(item),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
                  child: SectionHeader(
                    title: 'Portfolio',
                    actionLabel: '${items.length} fotos',
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                sliver: SliverToBoxAdapter(
                  child: _MasonryGalleryGrid(
                    items: items,
                    onItemTap: _openImageViewer,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 6)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  child: BarbershopPremiumCard(
                    padding: const EdgeInsets.all(18),
                    radius: 26,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const PremiumBadge(label: 'CONFIRMA TU VISITA'),
                        const SizedBox(height: 12),
                        const Text(
                          '¿Te gustó nuestro trabajo?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reservá, seguinos o escribinos para coordinar tu próxima experiencia premium.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .74),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _SocialActionButton(
                              label: 'Reservar cita',
                              icon: Icons.calendar_month_rounded,
                              filled: true,
                              onTap: () => Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.home),
                            ),
                            _SocialActionButton(
                              label: 'Instagram',
                              icon: Icons.camera_alt_rounded,
                              onTap: () => _showPlaceholder('Instagram'),
                            ),
                            _SocialActionButton(
                              label: 'WhatsApp',
                              icon: Icons.chat_rounded,
                              onTap: () => _showPlaceholder('WhatsApp'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GalleryTopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onReserve;

  const _GalleryTopBar({required this.onBack, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _IconBubble(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'GALERÍA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
        ),
        TextButton(
          onPressed: onReserve,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: const Text(
            'Reservar',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _GalleryHero extends StatelessWidget {
  final VoidCallback onReserve;
  final VoidCallback onInstagram;
  final VoidCallback onWhatsApp;

  const _GalleryHero({
    required this.onReserve,
    required this.onInstagram,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: SizedBox(
        height: 370,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/branding/barbershop_hero_bg.png',
              fit: BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF050505).withValues(alpha: .24),
                    const Color(0xFF050505).withValues(alpha: .52),
                    const Color(0xFF050505).withValues(alpha: .90),
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
                      AppColors.primary.withValues(alpha: .12),
                      Colors.transparent,
                    ],
                    radius: .9,
                    center: const Alignment(0, -.24),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const PremiumBadge(label: 'BARBERÍA TRES AMIGOS'),
                      const Spacer(),
                      _IconBubble(
                        icon: Icons.favorite_border_rounded,
                        onTap: onInstagram,
                      ),
                    ],
                  ),
                  const Spacer(),
                  const Text(
                    'Conocé nuestro trabajo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Cortes, barba y experiencias premium.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .80),
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Cada foto está pensada para transmitir confianza, detalle y el estándar visual de la barbería.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _SocialActionButton(
                          label: 'Reservar cita',
                          icon: Icons.calendar_month_rounded,
                          filled: true,
                          onTap: onReserve,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _SocialActionButton(
                        label: 'Instagram',
                        icon: Icons.camera_alt_rounded,
                        compact: true,
                        onTap: onInstagram,
                      ),
                      const SizedBox(width: 10),
                      _SocialActionButton(
                        label: 'WhatsApp',
                        icon: Icons.chat_rounded,
                        compact: true,
                        onTap: onWhatsApp,
                      ),
                    ],
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : const Color(0xFF171311),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: .42)
                  : Colors.white.withValues(alpha: .06),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .14),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _MasonryGalleryGrid extends StatelessWidget {
  final List<_GalleryItem> items;
  final ValueChanged<_GalleryItem> onItemTap;

  const _MasonryGalleryGrid({required this.items, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return BarbershopPremiumCard(
        padding: const EdgeInsets.all(18),
        radius: 24,
        child: Text(
          'No hay fotos para esta categoría todavía.',
          style: TextStyle(color: Colors.white.withValues(alpha: .72)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980
            ? 4
            : constraints.maxWidth >= 700
            ? 3
            : 2;
        final columnItems = List.generate(columns, (_) => <_GalleryItem>[]);
        for (var index = 0; index < items.length; index++) {
          columnItems[index % columns].add(items[index]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var columnIndex = 0; columnIndex < columns; columnIndex++) ...[
              if (columnIndex > 0) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (
                      var itemIndex = 0;
                      itemIndex < columnItems[columnIndex].length;
                      itemIndex++
                    ) ...[
                      _GalleryTile(
                        item: columnItems[columnIndex][itemIndex],
                        onTap: () =>
                            onItemTap(columnItems[columnIndex][itemIndex]),
                      ),
                      if (itemIndex != columnItems[columnIndex].length - 1)
                        const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _GalleryTile extends StatefulWidget {
  final _GalleryItem item;
  final VoidCallback onTap;

  const _GalleryTile({required this.item, required this.onTap});

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedScale(
      scale: _pressed ? .98 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: Container(
          height: 178 * item.heightFactor,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: const Color(0xFF14100E),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(item.asset, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: .66),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: PremiumBadge(label: item.tag, compact: true),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .74),
                        fontSize: 11.5,
                        height: 1.35,
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

class _FeaturedCard extends StatefulWidget {
  final _GalleryItem item;
  final VoidCallback onTap;

  const _FeaturedCard({required this.item, required this.onTap});

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AnimatedScale(
      scale: _pressed ? .985 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: BarbershopPremiumCard(
          padding: EdgeInsets.zero,
          radius: 28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(item.asset, fit: BoxFit.cover),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .72),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: PremiumBadge(label: item.tag),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .76),
                          height: 1.35,
                        ),
                      ),
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

class _GalleryViewerPage extends StatelessWidget {
  final _GalleryItem item;

  const _GalleryViewerPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: AspectRatio(
                      aspectRatio: 0.82,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(item.asset, fit: BoxFit.cover),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: .84),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 18,
                            right: 18,
                            bottom: 18,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                PremiumBadge(label: item.tag),
                                const SizedBox(height: 14),
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.w900,
                                    height: 1.05,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .78),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 14,
              child: _IconBubble(
                icon: Icons.close_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool compact;

  const _SocialActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : const Color(0xFF171311),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: filled
                  ? AppColors.primary.withValues(alpha: .22)
                  : Colors.white.withValues(alpha: .06),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: filled ? Colors.black : AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBubble({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF171311),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _GalleryCategory {
  final String id;
  final String label;

  const _GalleryCategory({required this.id, required this.label});
}

class _GalleryItem {
  final String asset;
  final String title;
  final String description;
  final String category;
  final String tag;
  final double heightFactor;

  const _GalleryItem({
    required this.asset,
    required this.title,
    required this.description,
    required this.category,
    required this.tag,
    required this.heightFactor,
  });
}
