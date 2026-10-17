import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../config/white_label_config.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';

part 'gallery/header.dart';
part 'gallery/tiles.dart';
part 'gallery/viewer.dart';

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
      asset: '',
      title: 'Fade Signature',
      description: 'Líneas limpias, textura controlada y acabado premium.',
      category: 'cortes',
      tag: 'Antes / Después',
      heightFactor: 1.18,
    ),
    _GalleryItem(
      asset: '',
      title: 'Experiencia Premium',
      description:
          'Un servicio pensado para sentirse impecable de principio a fin.',
      category: 'premium',
      tag: 'Feature',
      heightFactor: 1.05,
    ),
    _GalleryItem(
      asset: '',
      title: 'Barba Clásica',
      description: 'Perfilado preciso, balance visual y detalles limpios.',
      category: 'barbas',
      tag: 'Barba',
      heightFactor: 1.1,
    ),
    _GalleryItem(
      asset: '',
      title: 'Spa Facial',
      description: 'Una pausa premium para refrescar la piel y relajar el día.',
      category: 'spa',
      tag: 'Spa',
      heightFactor: 1.15,
    ),
  ];

  static const _galleryItems = <_GalleryItem>[
    _GalleryItem(
      asset: '',
      title: 'Fade Classic',
      description: 'Transición suave y textura natural.',
      category: 'cortes',
      tag: 'Fade',
      heightFactor: 1.12,
    ),
    _GalleryItem(
      asset: '',
      title: 'Barba Clean',
      description: 'Perfilado detallado con acabado definido.',
      category: 'barbas',
      tag: 'Beard',
      heightFactor: 1.32,
    ),
    _GalleryItem(
      asset: '',
      title: 'Premium Lounge',
      description: 'Ambiente oscuro, cómodo y de alto estándar.',
      category: 'instalaciones',
      tag: 'Lounge',
      heightFactor: 1.02,
    ),
    _GalleryItem(
      asset: '',
      title: 'Spa Facial',
      description: 'Cuidado facial con sensación de limpieza profunda.',
      category: 'spa',
      tag: 'Spa',
      heightFactor: 1.18,
    ),
    _GalleryItem(
      asset: '',
      title: 'Corte Premium',
      description: 'Volumen controlado y acabado elegante.',
      category: 'premium',
      tag: 'Premium',
      heightFactor: 1.28,
    ),
    _GalleryItem(
      asset: '',
      title: 'Barba y Navaja',
      description: 'Líneas finas para un look más pulido.',
      category: 'barbas',
      tag: 'Detail',
      heightFactor: 1.05,
    ),
    _GalleryItem(
      asset: '',
      title: 'Corte Fade',
      description: 'Una de nuestras firmas más pedidas.',
      category: 'cortes',
      tag: 'Classic',
      heightFactor: 1.22,
    ),
    _GalleryItem(
      asset: '',
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
    final whiteLabel = Provider.of<WhiteLabelConfig>(context, listen: false);
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
                    whiteLabel: whiteLabel,
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
                    whiteLabel: whiteLabel,
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
                    actionLabel: 'Ver toda la ${whiteLabel.galleryLabel}',
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
