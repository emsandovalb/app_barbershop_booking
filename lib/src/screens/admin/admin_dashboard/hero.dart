part of '../admin_dashboard_page.dart';

class _TopHero extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _TopHero({
    required this.whiteLabel,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      height: 288,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF17110E), Color(0xFF0E0D0C), Color(0xFF1A1410)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: theme.primary.withValues(alpha: .20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 288,
        child: Stack(
          children: [
            const Positioned(
              top: 0,
              right: 0,
              child: PremiumBadge(label: 'CENTRO ADMINISTRATIVO'),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 36, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        BarbershopLogoMark(
                          assetPath: whiteLabel.logoTransparent,
                          size: 96,
                          glowColor: theme.primary,
                          showGlow: false,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          whiteLabel.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1,
                            letterSpacing: .3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Centro administrativo',
                          style: TextStyle(
                            color: theme.secondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Gestioná citas, servicios y la presencia digital de tu negocio.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 10,
                      spacing: 10,
                      children: [
                        _HeroMetaChip(
                          icon: Icons.event_available_rounded,
                          label: 'Hoy',
                          value: DateFormat(
                            'd MMM',
                            'es',
                          ).format(BusinessClock.today()),
                        ),
                        _HeroMetaChip(
                          icon: Icons.shield_rounded,
                          label: 'Estado',
                          value: isLoading ? 'Sincronizando' : 'Listo',
                        ),
                        TextButton.icon(
                          onPressed: onRefresh,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.primary,
                            backgroundColor: theme.primary.withValues(
                              alpha: .10,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Actualizar',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMetaChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF120E0B).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primary, size: 17),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .60),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRail extends StatelessWidget {
  final void Function(_QuickActionData action) onAction;
  final bool isBusy;

  const _QuickActionsRail({required this.onAction, required this.isBusy});

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: isBusy,
      child: Opacity(
        opacity: isBusy ? .72 : 1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (var i = 0; i < _quickActions.length; i++) ...[
                _QuickActionCard(
                  action: _quickActions[i],
                  onTap: () => onAction(_quickActions[i]),
                ),
                if (i != _quickActions.length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData action;
  final VoidCallback onTap;

  const _QuickActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 156,
        height: 120,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF130F0C).withValues(alpha: .94),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: theme.primary.withValues(alpha: .18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: theme.primary, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              action.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .64),
                fontSize: 11,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
