part of '../operations_board.dart';

class _BoardHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final DateTime? lastUpdated;
  final bool isLoading;
  final String? errorText;
  final VoidCallback onClearFilters;
  final Set<String> channelFilters;
  final bool vipOnly;
  final bool duplicateOnly;
  final bool priorityOnly;
  final VoidCallback onToggleVip;
  final VoidCallback onToggleDuplicate;
  final VoidCallback onTogglePriority;
  final void Function(String key) onToggleChannel;
  final Map<String, int> channelCounts;
  final int totalCount;

  const _BoardHeader({
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.lastUpdated,
    required this.isLoading,
    required this.errorText,
    required this.onClearFilters,
    required this.channelFilters,
    required this.vipOnly,
    required this.duplicateOnly,
    required this.priorityOnly,
    required this.onToggleVip,
    required this.onToggleDuplicate,
    required this.onTogglePriority,
    required this.onToggleChannel,
    required this.channelCounts,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121010).withValues(alpha: .92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agenda del día',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Citas programadas. $totalCount citas visibles.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusPill(
                    label: isLoading ? 'Sincronizando' : 'Agenda actualizada',
                    accent: isLoading ? Colors.white54 : theme.secondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lastUpdated == null
                        ? 'Esperando la primera actualización'
                        : 'Actualizado a las ${DateFormat.Hm().format(lastUpdated!.toLocal())}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .54),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (errorText != null) ...[
            const SizedBox(height: 12),
            _BoardAlert(
              title: 'Aviso de datos',
              subtitle: errorText!,
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: 14),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar cliente, código o profesional',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color accent;

  const _StatusPill({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: .18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BoardAlert extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _BoardAlert({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1411),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontSize: 12,
                    height: 1.35,
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

class _LiveQueueFooter extends StatelessWidget {
  final int total;
  final DateTime? loaded;

  const _LiveQueueFooter({required this.total, required this.loaded});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.bolt_rounded,
          size: 16,
          color: Colors.white.withValues(alpha: .7),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Se muestran $total citas en este momento.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .66),
              fontSize: 12,
            ),
          ),
        ),
        if (loaded != null)
          Text(
            DateFormat.Hm().format(loaded!.toLocal()),
            style: TextStyle(
              color: Colors.white.withValues(alpha: .5),
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}
