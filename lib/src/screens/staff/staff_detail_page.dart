import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../reviews/reviews_page.dart';
import '../ground/ground_detail_page.dart';

class StaffDetailPage extends StatefulWidget {
  final Map<String, dynamic> staff;

  const StaffDetailPage({super.key, required this.staff});

  @override
  State<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends State<StaffDetailPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStaff();
  }

  Future<Map<String, dynamic>> _loadStaff() async {
    final initial = Map<String, dynamic>.from(widget.staff);
    final id = initial['id'];
    if (id is! int) return initial;

    try {
      final res = await context.read<AuthProvider>().api.getStaffById(id);
      final fetched = _asMap(res['data']) ?? _asMap(res) ?? const <String, dynamic>{};
      return _mergeStaff(initial, fetched);
    } catch (_) {
      return initial;
    }
  }

  Map<String, dynamic> _mergeStaff(
    Map<String, dynamic> initial,
    Map<String, dynamic> fetched,
  ) {
    final merged = <String, dynamic>{...initial, ...fetched};
    merged['services'] = fetched['services'] ?? initial['services'] ?? const [];
    merged['role'] = fetched['role'] ?? initial['role'];
    merged['specialties'] = fetched['specialties'] ?? initial['specialties'];
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF090807), Color(0xFF120E0C), Color(0xFF090909)],
          ),
        ),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done &&
                !snapshot.hasData &&
                !snapshot.hasError) {
              return const Center(child: CircularProgressIndicator());
            }

            final staff = Map<String, dynamic>.from(snapshot.data ?? widget.staff);
            final services = _parseServices(staff);
            final avatar = _avatarUrl(context, staff);
            final name = _text(staff, ['name'], fallback: 'Barbero');
            final title = _text(staff, ['title', 'role_name', 'specialty', 'headline'], fallback: _roleName(staff));
            final rating = _rating(staff);
            final isActive = _isActive(staff);
            final bio = _text(
              staff,
              ['bio', 'about', 'description'],
              fallback:
                  'Especialista en acabados limpios, cortes precisos y una experiencia premium de barbería.',
            );
            final specialties = _specialties(staff, services);
            final schedule = _scheduleText(staff);
            final contacts = _contacts(staff);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 84, 16, 124),
              children: [
                _HeroCard(
                  avatarUrl: avatar,
                  name: name,
                  title: title,
                  rating: rating,
                  servicesCount: services.length,
                  isActive: isActive,
                ),
                const SizedBox(height: 16),
                _ReviewsPreviewCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ReviewsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Sobre mí',
                  child: Text(
                    bio,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .82),
                      height: 1.45,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Especialidades',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: specialties
                        .map((item) => _TagChip(label: item, highlighted: true))
                        .toList(growable: false),
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Servicios disponibles',
                  subtitle: services.isEmpty
                      ? 'Este barbero todavía no tiene servicios asignados.'
                      : '${services.length} servicios listos para reservar',
                  child: services.isEmpty
                      ? Text(
                          'En breve se mostrarán los servicios asignados.',
                          style: TextStyle(color: Colors.white.withValues(alpha: .72)),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < services.length; i++) ...[
                              _ServiceCard(
                                service: services[i],
                                onTap: () => _openServiceDetail(staff, services[i].resource),
                              ),
                              if (i != services.length - 1) const SizedBox(height: 10),
                            ],
                          ],
                        ),
                ),
                if (schedule.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Horario general',
                    child: Text(
                      schedule,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .82),
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
                if (contacts.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Contacto',
                    child: Column(
                      children: [
                        for (var i = 0; i < contacts.length; i++) ...[
                          _ContactRow(contact: contacts[i]),
                          if (i != contacts.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final staff = Map<String, dynamic>.from(snapshot.data ?? widget.staff);
            final services = _parseServices(staff);
            return ElevatedButton.icon(
              onPressed: services.isNotEmpty
                  ? () => _openReservationFlow(staff, services)
                  : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Reservar con este barbero'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF090909),
                disabledBackgroundColor: const Color(0xFF3A3127),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openReservationFlow(
    Map<String, dynamic> staff,
    List<_AssignedService> services,
  ) async {
    if (services.isEmpty) {
      _showMessage(context, 'No hay servicios asignados a este barbero.');
      return;
    }

    if (services.length == 1) {
      await _openServiceDetail(staff, services.first.resource);
      return;
    }

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF101010),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Elegí un servicio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Reservá con este barbero desde el servicio que mejor te convenga.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .72)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: MediaQuery.of(context).size.height * .55,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: services.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return _ServiceSheetCard(
                        service: service,
                        onTap: () => Navigator.of(context).pop(service.resource),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (picked != null) {
      await _openServiceDetail(staff, picked);
    }
  }

  Future<void> _openServiceDetail(
    Map<String, dynamic> staff,
    Map<String, dynamic> service,
  ) async {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroundDetailPage(
          court: Map<String, dynamic>.from(service),
          preferredStaff: staff,
        ),
      ),
    );
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_AssignedService> _parseServices(Map<String, dynamic> staff) {
    final items = (staff['services'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((item) => _AssignedService.fromEntry(Map<String, dynamic>.from(item)))
        .where((service) => service.name.isNotEmpty)
        .toList(growable: false);
  }

  List<String> _specialties(
    Map<String, dynamic> staff,
    List<_AssignedService> services,
  ) {
    final explicit = _toStrings(staff['specialties']);
    if (explicit.isNotEmpty) return explicit;

    final specialties = <String>{};
    final role = _roleName(staff);
    if (role.isNotEmpty) specialties.add(role);
    for (final service in services.take(4)) {
      specialties.add(service.name);
    }
    if (specialties.isEmpty) specialties.add('Experiencia premium');
    return specialties.toList(growable: false);
  }

  List<_ContactItem> _contacts(Map<String, dynamic> staff) {
    final contacts = <_ContactItem>[];
    final phone = _text(staff, ['phone', 'whatsapp']);
    final email = _text(staff, ['email']);
    final instagram = _text(staff, ['instagram', 'instagram_handle', 'social']);

    if (phone.isNotEmpty) {
      contacts.add(
        const _ContactItem(
          icon: Icons.phone_outlined,
          label: 'Teléfono',
          value: '',
        ).withValue(phone),
      );
    }
    if (email.isNotEmpty) {
      contacts.add(
        const _ContactItem(
          icon: Icons.mail_outline,
          label: 'Correo',
          value: '',
        ).withValue(email),
      );
    }
    if (instagram.isNotEmpty) {
      contacts.add(
        const _ContactItem(
          icon: Icons.camera_alt_outlined,
          label: 'Instagram',
          value: '',
        ).withValue(instagram),
      );
    }
    return contacts;
  }

  String _scheduleText(Map<String, dynamic> staff) {
    return _firstNonEmpty([
      staff['schedule'],
      staff['hours'],
      staff['working_hours'],
      staff['business_hours'],
      staff['business_hours_note'],
      staff['availability_note'],
    ]);
  }

  bool _isActive(Map<String, dynamic> staff) => staff['is_active'] != false;

  String _rating(Map<String, dynamic> staff) {
    final raw = staff['rating'] ?? staff['score'] ?? staff['average_rating'];
    final parsed = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
    final value = parsed ?? 4.8;
    return value.toStringAsFixed(1);
  }

  String _roleName(Map<String, dynamic> staff) {
    final role = _asMap(staff['role']);
    final value = _firstNonEmpty([
      role?['name'],
      staff['role_name'],
      staff['title'],
      staff['specialty'],
    ]);
    return value.isEmpty ? 'Barbero' : value;
  }

  String _avatarUrl(BuildContext context, Map<String, dynamic> staff) {
    final raw = _firstNonEmpty([
      staff['avatar_url'],
      staff['avatar'],
      staff['photo_url'],
      staff['image'],
    ]);
    if (raw.isEmpty) return '';
    if (raw.startsWith('assets/')) return raw;
    return context.read<AuthProvider>().api.resolveAssetUrl(raw);
  }

  String _text(
    Map<String, dynamic> staff,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = staff[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  List<String> _toStrings(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }
    if (value is String) {
      final text = value.trim();
      return text.isEmpty ? const [] : [text];
    }
    return const [];
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}

class _HeroCard extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String title;
  final String rating;
  final int servicesCount;
  final bool isActive;

  const _HeroCard({
    required this.avatarUrl,
    required this.name,
    required this.title,
    required this.rating,
    required this.servicesCount,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x70000000),
            blurRadius: 30,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/branding/barbershop_hero_bg.png',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0C0908).withValues(alpha: .18),
                      const Color(0xFF0C0908).withValues(alpha: .78),
                      const Color(0xFF0C0908),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -.45),
                    radius: 1.05,
                    colors: [
                      const Color(0xFFC9A56A).withValues(alpha: .18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 124,
                        height: 124,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: .92),
                              AppColors.secondary.withValues(alpha: .55),
                              const Color(0xFF4B3418),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: 112,
                        height: 112,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF101010),
                        ),
                        child: ClipOval(child: _Avatar(avatarUrl: avatarUrl)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1.02,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .80),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: .26),
                      ),
                    ),
                    child: const Text(
                      'Experiencia premium',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MiniStat(
                        icon: Icons.star_rounded,
                        label: rating,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      _MiniStat(
                        icon: Icons.content_cut_rounded,
                        label: '$servicesCount servicios',
                        iconColor: Colors.white70,
                      ),
                      const SizedBox(width: 10),
                      _StatusPill(isActive: isActive),
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

class _Avatar extends StatelessWidget {
  final String avatarUrl;

  const _Avatar({required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isEmpty) {
      return Image.asset(
        'assets/branding/barber_placeholder.png',
        fit: BoxFit.cover,
      );
    }

    if (avatarUrl.startsWith('assets/')) {
      return Image.asset(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/branding/barber_placeholder.png',
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.network(
      avatarUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/branding/barber_placeholder.png',
        fit: BoxFit.cover,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .30),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isActive;

  const _StatusPill({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF143325) : const Color(0xFF2E2420),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive ? const Color(0xFF2F8A62) : Colors.white.withValues(alpha: .08),
        ),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          color: isActive ? const Color(0xFF8EE0B8) : Colors.white70,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF14100E),
          border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: .12),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Opiniones de clientes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '4.9 basado en 128 opiniones',
                    style: TextStyle(color: Colors.white70, height: 1.3),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ver opiniones',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primary.withValues(alpha: .10)
            : const Color(0xFF1E1916),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: .28)
              : Colors.white.withValues(alpha: .06),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: highlighted ? AppColors.secondary : Colors.white,
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
                ? AppColors.primary.withValues(alpha: .24)
                : Colors.white.withValues(alpha: .06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                service.premium
                    ? Icons.workspace_premium_outlined
                    : Icons.content_cut_outlined,
                color: service.premium ? AppColors.primary : Colors.white70,
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
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                service.premium
                    ? Icons.workspace_premium_outlined
                    : Icons.content_cut_outlined,
                color: service.premium ? AppColors.primary : Colors.white70,
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
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
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

  _ContactItem withValue(String nextValue) => _ContactItem(
        icon: icon,
        label: label,
        value: nextValue,
      );
}

class _ContactRow extends StatelessWidget {
  final _ContactItem contact;

  const _ContactRow({required this.contact});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(contact.icon, color: AppColors.primary, size: 20),
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
    final name = _firstText(
      [resource['name'], entry['name'], resource['title']],
      fallback: 'Servicio',
    );
    final durationLabel = _durationLabel(
      resource['duration_hours'] ?? entry['duration_hours'] ?? entry['duration'],
      resource['duration_minutes'] ?? entry['duration_minutes'],
    );
    final priceLabel = _priceLabel(
      resource['price_per_hour'] ?? entry['price_per_hour'] ?? resource['price'] ?? entry['price'],
    );
    final premium = _isPremium(resource) ||
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
    final number = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
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
    return raw.any((value) =>
        value.contains('premium') || value.contains('vip') || value.contains('gold'));
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
