part of '../admin_dashboard_page.dart';

class _AdminModuleGrid extends StatelessWidget {
  final List<_AdminModuleData> modules;
  final void Function(_AdminModuleData module) onTap;

  const _AdminModuleGrid({required this.modules, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modules.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: .92,
      ),
      itemBuilder: (_, index) {
        final module = modules[index];
        return _AdminModuleCard(module: module, onTap: () => onTap(module));
      },
    );
  }
}

class _AdminModuleCard extends StatelessWidget {
  final _AdminModuleData module;
  final VoidCallback onTap;

  const _AdminModuleCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: BarbershopPremiumCard(
        radius: 24,
        padding: const EdgeInsets.all(16),
        backgroundColor: const Color(0xFF120E0B).withValues(alpha: .96),
        borderColor: Colors.white.withValues(alpha: .08),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(module.icon, color: theme.primary, size: 22),
                ),
                const Spacer(),
                _ModuleBadge(label: module.badge),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              module.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              module.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .70),
                fontSize: 12,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleBadge extends StatelessWidget {
  final String label;

  const _ModuleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.primary.withValues(alpha: .22)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.secondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionIntro({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .68),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  const _SectionHeaderRow({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final AppointmentStatusBucket status;
  final String? label;

  const _StatusBadge({required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final (text, fg, bg) = switch (status) {
      AppointmentStatusBucket.upcoming => (
        label ?? tr('status_pending'),
        theme.primary,
        const Color(0xFF2E2315),
      ),
      AppointmentStatusBucket.completed => (
        label ?? tr('status_completed'),
        const Color(0xFFE8D8B8),
        const Color(0xFF16261F),
      ),
      AppointmentStatusBucket.cancelled => (
        label ?? tr('status_cancelled'),
        const Color(0xFFFF9D9D),
        const Color(0xFF301B1C),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DashboardEmptyCard extends StatelessWidget {
  final String message;

  const _DashboardEmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        message,
        style: TextStyle(color: Colors.white.withValues(alpha: .72)),
      ),
    );
  }
}

class _DashboardLoadError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _DashboardLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    // A ListView keeps pull-to-refresh working in the error state.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
      children: [
        const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 40),
        const SizedBox(height: 14),
        Text(
          tr('admin_dashboard_load_failed'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr('common_check_connection'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: Text(tr('btn_retry')),
          ),
        ),
      ],
    );
  }
}
