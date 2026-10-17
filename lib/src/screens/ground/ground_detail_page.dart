import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/court_image.dart';
import '../booking/barber_picker_bottom_sheet.dart';
import '../ground/select_date_time_page.dart';

class GroundDetailPage extends StatelessWidget {
  final Map<String, dynamic> court;
  final Map<String, dynamic>? preferredStaff;
  const GroundDetailPage({super.key, required this.court, this.preferredStaff});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final loc = context.watch<LocalizationService>();
    final resource = court;
    final barbers = (resource['staff'] as List?) ?? const [];
    final isPremium = _isPremium(resource);
    final price = _formatCrc(resource['price_per_hour']);
    final duration = _durationLabel(
      resource['duration_hours'],
      resource['duration_minutes'],
    );
    final description = resource['description']?.toString() ?? '';
    final businessHours = resource['business_hours_note']?.toString() ?? '';
    final selectedStaffName = preferredStaff?['name']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('booking_detail_ground_label'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 210,
            child: Stack(
              children: [
                Positioned.fill(child: CourtImage(images: resource['images'])),
                if (isPremium)
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .45),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        loc.t('home_premium_badge'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              Text(
                price,
                style: const TextStyle(
                  color: Color(0xFFC9A56A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resource['name']?.toString() ?? tr('appointment_default_service'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description.isNotEmpty
                ? description
                : loc.t('ground_description_placeholder'),
            style: TextStyle(color: Colors.white.withValues(alpha: .85)),
          ),
          if (selectedStaffName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1D1712),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.primary.withValues(alpha: .18)),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: theme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr(
                        'booking_selected_staff',
                        args: {'name': selectedStaffName},
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _MiniStat(
                icon: Icons.schedule_outlined,
                label: loc.t('booking_detail_duration'),
                value: duration,
              ),
              const SizedBox(width: 12),
              _MiniStat(
                icon: Icons.payments_outlined,
                label: loc.t('booking_detail_price'),
                value: price,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            loc.t('common_facilities'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AmenityChip(label: loc.t('facility_parking')),
              _AmenityChip(label: loc.t('facility_camera')),
              _AmenityChip(label: loc.t('facility_waiting')),
              _AmenityChip(label: loc.t('facility_changing')),
            ],
          ),
          const SizedBox(height: 16),
          if (businessHours.isNotEmpty) ...[
            Text(
              loc.t('home_business_hours_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                businessHours,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (barbers.isNotEmpty) ...[
            Text(
              loc.t('booking_barber_picker_title'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: barbers
                  .take(4)
                  .map((item) {
                    final barber = item is Map
                        ? Map<String, dynamic>.from(item)
                        : const <String, dynamic>{};
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF282828),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        barber['name']?.toString() ??
                            loc.t('booking_barber_label'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            loc.t('ground_list_title'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) => Container(
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF282828),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      loc.t('ground_main_label'),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: 3,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            final auth = context.read<AuthProvider>();
            if (!auth.isLoggedIn) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.t('ground_login_required'))),
              );
              Navigator.of(context).pushNamed(AppRoutes.login);
              return;
            }
            final staff =
                preferredStaff ??
                await showModalBottomSheet<Map<String, dynamic>>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) =>
                      BarberPickerBottomSheet(serviceId: resource['id'] as int),
                );
            if (staff == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.t('booking_barber_required'))),
                );
              }
              return;
            }
            if (!context.mounted) return;
            final result = await Navigator.of(context)
                .push<Map<String, dynamic>>(
                  MaterialPageRoute(
                    builder: (_) => SelectDateTimePage(
                      court: resource,
                      preferredStaff: staff,
                    ),
                  ),
                );
            if (result == null) return;
            if (!context.mounted) return;
            Navigator.of(context).pushNamed(
              AppRoutes.bookingDetail,
              arguments: {
                'resource': resource,
                'court': resource,
                'iso': result['iso'],
                'slot': result['slot'],
                if (result['staff'] != null) 'staff': result['staff'],
                if (result['staff_id'] != null) 'staff_id': result['staff_id'],
              },
            );
          },
          child: Text(loc.t('ground_book_now')),
        ),
      ),
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final String label;
  const _AmenityChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFC9A56A), size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
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
    locale: 'es_CR',
    symbol: 'CRC ',
    decimalDigits: 0,
  ).format(number);
}

String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
  final minutes = durationMinutes is num
      ? durationMinutes.toInt()
      : int.tryParse(durationMinutes?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 h' : '$hours h';
    }
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    return '${hours}h ${remainder}m';
  }
  final hours = durationHours is num
      ? durationHours.toInt()
      : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}

bool _isPremium(dynamic resource) {
  final name = resource?['name']?.toString().toLowerCase() ?? '';
  final category = resource?['category']?.toString().toLowerCase() ?? '';
  return name.contains('premium') || category == 'premium';
}
