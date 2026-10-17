import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../reviews/reviews_page.dart';
import '../ground/ground_detail_page.dart';

part 'staff_detail/hero.dart';
part 'staff_detail/sections.dart';

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
      final fetched =
          _asMap(res['data']) ?? _asMap(res) ?? const <String, dynamic>{};
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
    final theme = context.watch<BrandTheme>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
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

            final staff = Map<String, dynamic>.from(
              snapshot.data ?? widget.staff,
            );
            final services = _parseServices(staff);
            final avatar = _avatarUrl(context, staff);
            final name = _text(staff, [
              'name',
            ], fallback: whiteLabel.staffDisplayName);
            final title = _text(staff, [
              'title',
              'role_name',
              'specialty',
              'headline',
            ], fallback: _roleName(staff));
            final rating = _rating(staff);
            final isActive = _isActive(staff);
            final bio = _text(
              staff,
              ['bio', 'about', 'description'],
              fallback:
                  'Especialista en acabados limpios, atención precisa y una experiencia premium.',
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
                      MaterialPageRoute(builder: (_) => const ReviewsPage()),
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
                      ? 'Este perfil todavía no tiene servicios asignados.'
                      : '${services.length} servicios listos para reservar',
                  child: services.isEmpty
                      ? Text(
                          'En breve se mostrarán los servicios asignados.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < services.length; i++) ...[
                              _ServiceCard(
                                service: services[i],
                                onTap: () => _openServiceDetail(
                                  staff,
                                  services[i].resource,
                                ),
                              ),
                              if (i != services.length - 1)
                                const SizedBox(height: 10),
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
                          if (i != contacts.length - 1)
                            const SizedBox(height: 10),
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
            final staff = Map<String, dynamic>.from(
              snapshot.data ?? widget.staff,
            );
            final services = _parseServices(staff);
            return ElevatedButton.icon(
              onPressed: services.isNotEmpty
                  ? () => _openReservationFlow(staff, services)
                  : null,
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Reservar con este perfil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primary,
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
      _showMessage(context, 'No hay servicios asignados a este perfil.');
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
                  'Reservá desde el servicio que mejor te convenga.',
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
                        onTap: () =>
                            Navigator.of(context).pop(service.resource),
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_AssignedService> _parseServices(Map<String, dynamic> staff) {
    final items = (staff['services'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map(
          (item) => _AssignedService.fromEntry(Map<String, dynamic>.from(item)),
        )
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
    final parsed = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '');
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
