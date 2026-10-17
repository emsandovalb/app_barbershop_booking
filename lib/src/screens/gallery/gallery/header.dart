part of '../gallery_page.dart';

class _GalleryTopBar extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onBack;
  final VoidCallback onReserve;

  const _GalleryTopBar({
    required this.whiteLabel,
    required this.onBack,
    required this.onReserve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Row(
      children: [
        _IconBubble(icon: Icons.arrow_back_rounded, onTap: onBack),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            whiteLabel.galleryLabel.toUpperCase(),
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
            foregroundColor: theme.secondary,
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
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onReserve;
  final VoidCallback onInstagram;
  final VoidCallback onWhatsApp;

  const _GalleryHero({
    required this.whiteLabel,
    required this.onReserve,
    required this.onInstagram,
    required this.onWhatsApp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: SizedBox(
        height: 370,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (whiteLabel.heroBackground.trim().isNotEmpty)
              Image.asset(whiteLabel.heroBackground, fit: BoxFit.cover)
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF151C31),
                      Color(0xFF10172A),
                      Color(0xFF0B1020),
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
                      theme.primary.withValues(alpha: .12),
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
                      PremiumBadge(label: whiteLabel.displayName),
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
                    'Cada foto está pensada para transmitir confianza, detalle y el estándar visual del negocio.',
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
    final theme = context.watch<BrandTheme>();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? theme.primary : const Color(0xFF171311),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? theme.primary.withValues(alpha: .42)
                  : Colors.white.withValues(alpha: .06),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.primary.withValues(alpha: .14),
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
