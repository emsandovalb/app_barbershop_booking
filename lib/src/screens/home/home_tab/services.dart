part of '../home_tab.dart';

class _ServiceListSection extends StatelessWidget {
  final LoadableController<List<Map<String, dynamic>>> controller;
  final String title;
  final String emptyMessage;
  final String loadingMessage;
  final String errorMessage;
  final String retryLabel;
  final VoidCallback onViewAll;
  final Future<void> Function() onRetry;
  final List<Map<String, dynamic>> items;
  final Widget Function(int index, dynamic data) itemBuilder;

  const _ServiceListSection({
    required this.controller,
    required this.title,
    required this.emptyMessage,
    required this.loadingMessage,
    required this.errorMessage,
    required this.retryLabel,
    required this.onViewAll,
    required this.onRetry,
    required this.items,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final state = controller.state;

    if (state.isLoading && !state.hasData) {
      return _StateCard(
        title: title,
        body: loadingMessage,
        leading: const CircularProgressIndicator(),
      );
    }

    if (state.hasError && !state.hasData) {
      return _StateCard(
        title: title,
        body: errorMessage,
        actionLabel: retryLabel,
        onAction: onRetry,
        leading: const Icon(Icons.error_outline, color: Colors.white70),
      );
    }

    if (items.isEmpty) {
      return _StateCard(
        title: title,
        body: emptyMessage,
        actionLabel: 'Ver todos',
        onAction: onViewAll,
        leading: const Icon(Icons.inbox_outlined, color: Colors.white70),
      );
    }

    return _ServiceCarousel(
      isLoading: state.isLoading,
      items: items,
      emptyMessage: emptyMessage,
      onEmptyTap: onViewAll,
      itemBuilder: itemBuilder,
    );
  }
}

class _StateCard extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? leading;

  const _StateCard({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      radius: 26,
      padding: const EdgeInsets.all(18),
      backgroundColor: const Color(0xFF130F0C).withValues(alpha: .94),
      borderColor: Colors.white.withValues(alpha: .08),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 14)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .74),
                    height: 1.3,
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel!),
                  ),
                ],
              ],
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
    final theme = context.watch<BrandTheme>();
    final isPremium = _isPremium(data);
    final price = _formatCrc(data?['price_per_hour']);
    final duration = _durationLabel(
      data?['duration_hours'],
      data?['duration_minutes'],
    );
    final title = data?['name']?.toString() ?? 'Servicio ${index + 1}';

    return InkWell(
      onTap: () {
        if (data != null) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => GroundDetailPage(court: data!)),
          );
        }
      },
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: 176,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF14100E),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: .06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 128,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CourtImage(
                      images: data?['images'],
                      radius: const BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: .45),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 10,
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (isPremium)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: PremiumBadge(label: 'PREMIUM', compact: true),
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
                          size: 12,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            duration,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price,
                      style:  TextStyle(
                        color: theme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
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

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'en_US',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}

String _capitalize(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1);
}

String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
  final minutes = durationMinutes is num
      ? durationMinutes.toInt()
      : int.tryParse(durationMinutes?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    if (remainder == 0) return hours == 1 ? '1 h' : '$hours h';
    return '${hours == 1 ? '1' : hours} h $remainder min';
  }

  final hours = durationHours is num
      ? durationHours.toInt()
      : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}

List<dynamic> _mergeFeaturedServices(
  List<dynamic> popular,
  List<dynamic> premium,
) {
  final seen = <String>{};
  final merged = <dynamic>[];
  for (final item in <dynamic>[...popular, ...premium]) {
    final key = _serviceKey(item);
    if (seen.add(key)) {
      merged.add(item);
    }
    if (merged.length >= 5) break;
  }
  return merged;
}

String _serviceKey(dynamic data) {
  if (data is Map<String, dynamic>) {
    final id = data['id'];
    if (id != null) return id.toString();
    final name = data['name'];
    if (name != null) return name.toString().toLowerCase();
  }
  return data?.hashCode.toString() ?? 'null';
}

bool _isPremium(dynamic data) {
  final name = data?['name']?.toString().toLowerCase() ?? '';
  final category = data?['category']?.toString().toLowerCase() ?? '';
  return name.contains('premium') || category == 'premium';
}

class _ServiceCarousel extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> items;
  final String emptyMessage;
  final VoidCallback onEmptyTap;
  final Widget Function(int index, dynamic data) itemBuilder;

  const _ServiceCarousel({
    required this.isLoading,
    required this.items,
    required this.emptyMessage,
    required this.onEmptyTap,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const SizedBox(
        height: 224,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return InkWell(
        onTap: onEmptyTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF14100E),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: .05)),
          ),
          child: Text(
            emptyMessage,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 224,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) => itemBuilder(index, items[index]),
      ),
    );
  }
}
