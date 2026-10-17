part of '../business_profile_page.dart';

class _TopBar extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;

  const _TopBar({required this.whiteLabel});

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
        Text(
          whiteLabel.businessProfileLabel,
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
  final WhiteLabelConfig whiteLabel;
  final int staffCount;
  final int serviceCount;

  const _HeroSection({
    required this.whiteLabel,
    required this.staffCount,
    required this.serviceCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return BarbershopCinematicPanel(
      backgroundAsset: whiteLabel.heroBackground,
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
              child: PremiumBadge(
                label: whiteLabel.businessProfileLabel.toUpperCase(),
              ),
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
                    assetPath: whiteLabel.logoTransparent,
                    fallbackLabel: whiteLabel.shortName,
                    size: 126,
                    glowColor: theme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    whiteLabel.displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 31,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    whiteLabel.tagline,
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
                    children: [
                      _HeroInfoPill(
                        icon: Icons.star_rounded,
                        text: whiteLabel.rating.toStringAsFixed(1),
                      ),
                      _HeroInfoPill(
                        icon: Icons.cut_rounded,
                        text: whiteLabel.subtitle,
                      ),
                      _HeroInfoPill(
                        icon: Icons.location_on_rounded,
                        text: whiteLabel.locationShort,
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
    final theme = context.watch<BrandTheme>();
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
          Icon(icon, size: 14, color: theme.primary),
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
    final theme = context.watch<BrandTheme>();
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
              color: theme.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primary, size: 18),
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
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF14100E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.primary.withValues(alpha: .22)),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: .06),
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
                    theme.primary.withValues(alpha: .20),
                    theme.primary.withValues(alpha: .06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: theme.primary.withValues(alpha: .30),
                ),
              ),
              child: Icon(icon, color: theme.primary, size: 22),
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

class _AvatarMark extends StatelessWidget {
  const _AvatarMark();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.primary.withValues(alpha: .26),
            theme.primary.withValues(alpha: .10),
          ],
        ),
        border: Border.all(color: theme.primary.withValues(alpha: .18)),
      ),
      child: const Icon(Icons.person_rounded, color: Colors.white, size: 21),
    );
  }
}
