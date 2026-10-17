part of '../staff_detail_page.dart';

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14100E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .24),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .62),
                fontSize: 12.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReviewsPreviewCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ReviewsPreviewCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF14100E),
          border: Border.all(color: theme.primary.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.primary.withValues(alpha: .12),
              ),
              child: Icon(Icons.star_rounded, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('staff_customer_reviews'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(
                      'home_reviews_summary',
                      args: {'rating': '4.9', 'count': 128},
                    ),
                    style: const TextStyle(color: Colors.white70, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('home_view_reviews'),
                    style: TextStyle(
                      color: theme.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: theme.primary),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _TagChip({required this.label, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.primary.withValues(alpha: .10)
            : const Color(0xFF1E1916),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? theme.primary.withValues(alpha: .28)
              : Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? theme.secondary : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _AssignedService service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1410),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: service.premium
                ? theme.primary.withValues(alpha: .24)
                : Colors.white.withValues(alpha: .06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                service.premium
                    ? Icons.workspace_premium_outlined
                    : Icons.content_cut_outlined,
                color: service.premium ? theme.primary : Colors.white70,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (service.premium)
                        const _TagChip(label: 'Premium', highlighted: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationLabel} · ${service.priceLabel}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

class _ServiceSheetCard extends StatelessWidget {
  final _AssignedService service;
  final VoidCallback onTap;

  const _ServiceSheetCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF18120F),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: .06)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                service.premium
                    ? Icons.workspace_premium_outlined
                    : Icons.content_cut_outlined,
                color: service.premium ? theme.primary : Colors.white70,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationLabel} · ${service.priceLabel}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .68),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white54,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactItem {
  final IconData icon;
  final String label;
  final String value;

  const _ContactItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  _ContactItem withValue(String nextValue) =>
      _ContactItem(icon: icon, label: label, value: nextValue);
}

class _ContactRow extends StatelessWidget {
  final _ContactItem contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(contact.icon, color: theme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                contact.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .65),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                contact.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignedService {
  final Map<String, dynamic> resource;
  final String name;
  final String durationLabel;
  final String priceLabel;
  final bool premium;

  const _AssignedService({
    required this.resource,
    required this.name,
    required this.durationLabel,
    required this.priceLabel,
    required this.premium,
  });

  factory _AssignedService.fromEntry(Map<String, dynamic> entry) {
    final resource = _asMap(entry['resource']) ?? entry;
    final name = _firstText([
      resource['name'],
      entry['name'],
      resource['title'],
    ], fallback: tr('appointment_default_service'));
    final durationLabel = _durationLabel(
      resource['duration_hours'] ??
          entry['duration_hours'] ??
          entry['duration'],
      resource['duration_minutes'] ?? entry['duration_minutes'],
    );
    final priceLabel = _priceLabel(
      resource['price_per_hour'] ??
          entry['price_per_hour'] ??
          resource['price'] ??
          entry['price'],
    );
    final premium =
        _isPremium(resource) ||
        entry['is_primary'] == true ||
        entry['premium'] == true ||
        entry['is_premium'] == true;
    return _AssignedService(
      resource: Map<String, dynamic>.from(resource),
      name: name,
      durationLabel: durationLabel,
      priceLabel: priceLabel,
      premium: premium,
    );
  }

  static String _firstText(List<dynamic> values, {required String fallback}) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  static String _priceLabel(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    return NumberFormat.currency(
      locale: 'es_CR',
      symbol: '₡',
      decimalDigits: 0,
    ).format(number);
  }

  static String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
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
        : int.tryParse(durationHours?.toString() ?? '') ?? 1;
    return hours == 1 ? '1 h' : '$hours h';
  }

  static bool _isPremium(Map<String, dynamic> resource) {
    final raw = [
      resource['category'],
      resource['tier'],
      resource['package'],
      resource['type'],
    ].map((value) => value?.toString().trim().toLowerCase() ?? '');
    return raw.any(
      (value) =>
          value.contains('premium') ||
          value.contains('vip') ||
          value.contains('gold'),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
