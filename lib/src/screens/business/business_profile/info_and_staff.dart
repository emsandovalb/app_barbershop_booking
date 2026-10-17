part of '../business_profile_page.dart';

class _BusinessInfoSection extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;

  const _BusinessInfoSection({required this.whiteLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BusinessInfoCard(
          icon: Icons.schedule_rounded,
          title: whiteLabel.hoursLabel,
          body: whiteLabel.hoursSummary,
        ),
        const SizedBox(height: 12),
        _BusinessInfoCard(
          icon: Icons.event_busy_rounded,
          title: 'Política de cancelación',
          body:
              '${whiteLabel.cancellationPolicyText} (${whiteLabel.cancellationWindowHours} horas)',
        ),
        const SizedBox(height: 12),
        _BusinessInfoCard(
          icon: Icons.location_on_rounded,
          title: 'Ubicación y contacto',
          body:
              '${whiteLabel.locationFull}\n\n${whiteLabel.phone}\n${whiteLabel.email}',
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
    final theme = context.watch<BrandTheme>();
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.primary.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: theme.primary),
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

class _EmptySectionCard extends StatelessWidget {
  final String title;
  final String body;

  const _EmptySectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return BarbershopPremiumCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.5,
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
    final theme = context.watch<BrandTheme>();
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
    ], fallback: 'Profesional premium');
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
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      )
                    : const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF151C31), Color(0xFF10172A)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                          ),
                        ),
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
                 Icon(
                  Icons.star_rounded,
                  color: theme.primary,
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
