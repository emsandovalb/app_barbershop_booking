import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../config/white_label_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/court_image.dart';
import '../../widgets/loadable_collection_view.dart';
import 'admin_page_scaffold.dart';
import 'service_management_utils.dart';

class AdminServicesPage extends StatefulWidget {
  const AdminServicesPage({super.key});

  @override
  State<AdminServicesPage> createState() => _AdminServicesPageState();
}

class _AdminServicesPageState extends State<AdminServicesPage> {
  late final LoadableController<List<Map<String, dynamic>>> _controller;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<List<Map<String, dynamic>>>(_loadServices);
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadServices() async {
    final response = await context.read<AuthProvider>().api.getMyResources(
      perPage: 100,
    );
    return _extractItems(response);
  }

  Future<void> _refresh() async {
    await _controller.load();
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> _openForm({Map<String, dynamic>? service}) async {
    final result = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.adminServiceForm,
      arguments: {'service': service, 'createMode': service == null},
    );
    if (result == true && mounted) {
      await _refresh();
      _showSnack(
        service == null
            ? 'Servicio creado correctamente.'
            : 'Servicio actualizado correctamente.',
        success: true,
      );
    }
  }

  Future<void> _openAssignment(Map<String, dynamic> service) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.adminServiceAssignment,
      arguments: {'service': service},
    );
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> service) async {
    final id = service['id'] as int?;
    if (id == null || _actionInProgress) return;
    setState(() => _actionInProgress = true);
    final api = context.read<AuthProvider>().api;
    final nextStatus = serviceIsActive(service) ? 'inactive' : 'active';
    try {
      await api.updateResource(id, {'status': nextStatus});
      if (!mounted) return;
      _showSnack(
        nextStatus == 'active' ? 'Servicio activado.' : 'Servicio desactivado.',
        success: true,
      );
      await _refresh();
    } catch (_) {
      if (mounted) {
        _showSnack(
          'No pudimos cambiar el estado del servicio.',
          success: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
      }
    }
  }

  void _showSnack(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF132018)
            : const Color(0xFF1A1512),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final auth = context.watch<AuthProvider>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    if (!auth.canManageBusiness) {
      return  Scaffold(
        backgroundColor: theme.background,
        body: Center(
          child: Text(
            'Solo los administradores pueden acceder a esta sección',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.background,
      appBar: buildAdminAppBar(
        context,
        title: 'Administrar ${whiteLabel.servicesLabel}',
        subtitle: 'Catálogo, precios y asignaciones',
        actions: [
          IconButton(
            onPressed: _actionInProgress ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _actionInProgress ? null : () => _openForm(),
        backgroundColor: theme.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Nuevo ${whiteLabel.serviceLabel}',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: BarbershopCinematicPanel(
        backgroundAsset: '',
        opacity: .22,
        blurSigma: 14,
        child: SafeArea(
          child: LoadableCollectionView<List<Map<String, dynamic>>>(
            controller: _controller,
            isEmpty: (services) => services.isEmpty,
            loadingBuilder: (context, retry) {
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, retry) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'No fue posible cargar los servicios.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Revisa tu conexión e intenta nuevamente.',
                          style: TextStyle(color: Colors.white54),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _actionInProgress ? null : retry,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            emptyBuilder: (context, retry) {
              return RefreshIndicator(
                color: theme.primary,
                onRefresh: _refresh,
                child: _ServicesBody(
                  services: const [],
                  whiteLabel: whiteLabel,
                  onNewService: _openForm,
                  onEdit: _openForm,
                  onAssignBarbers: _openAssignment,
                  onToggleStatus: _toggleStatus,
                  showEmptyState: true,
                ),
              );
            },
            dataBuilder: (context, services, retry, isLoading) {
              return RefreshIndicator(
                color: theme.primary,
                onRefresh: _refresh,
                child: _ServicesBody(
                  services: services,
                  whiteLabel: whiteLabel,
                  onNewService: _openForm,
                  onEdit: _openForm,
                  onAssignBarbers: _openAssignment,
                  onToggleStatus: _toggleStatus,
                  showEmptyState: false,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ServicesBody extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final WhiteLabelConfig whiteLabel;
  final Future<void> Function({Map<String, dynamic>? service}) onNewService;
  final Future<void> Function({Map<String, dynamic>? service}) onEdit;
  final Future<void> Function(Map<String, dynamic> service) onAssignBarbers;
  final Future<void> Function(Map<String, dynamic> service) onToggleStatus;
  final bool showEmptyState;

  const _ServicesBody({
    required this.services,
    required this.whiteLabel,
    required this.onNewService,
    required this.onEdit,
    required this.onAssignBarbers,
    required this.onToggleStatus,
    required this.showEmptyState,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final activeCount = services.where(serviceIsActive).length;
    final totalBarbers = services.fold<int>(
      0,
      (sum, service) => sum + serviceStaffCount(service),
    );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      children: [
        BarbershopPremiumCard(
          radius: 30,
          padding: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFF140F0C).withValues(alpha: .96),
          borderColor: theme.primary.withValues(alpha: .18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const PremiumBadge(
                    label: 'ADMINISTRAR SERVICIOS',
                    compact: true,
                  ),
                  const Spacer(),
                  Text(
                    '${services.length} servicios',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Catálogo del negocio',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Gestiona el catálogo, activa o desactiva ${whiteLabel.servicesLabel} y asigna ${whiteLabel.staffPluralLabel} cuando corresponda.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .72),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(label: 'Activos', value: '$activeCount'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatChip(
                      label: whiteLabel.staffPluralLabel,
                      value: '$totalBarbers',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionTitle(
          title: 'Servicios',
          subtitle:
              'Edita, activa, desactiva o asigna ${whiteLabel.staffPluralLabel} desde cada tarjeta.',
          actionLabel: 'Nuevo servicio',
          onAction: () => onNewService(),
        ),
        const SizedBox(height: 12),
        if (showEmptyState)
          _EmptyState(whiteLabel: whiteLabel)
        else
          ...services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceCard(
                service: service,
                whiteLabel: whiteLabel,
                onEdit: () => onEdit(service: service),
                onAssignBarbers: () => onAssignBarbers(service),
                onToggleStatus: () => onToggleStatus(service),
              ),
            ),
          ),
      ],
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final WhiteLabelConfig whiteLabel;
  final VoidCallback onEdit;
  final VoidCallback onAssignBarbers;
  final VoidCallback onToggleStatus;

  const _ServiceCard({
    required this.service,
    required this.whiteLabel,
    required this.onEdit,
    required this.onAssignBarbers,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final active = serviceIsActive(service);
    final image = serviceImage(service);

    return BarbershopPremiumCard(
      radius: 26,
      padding: const EdgeInsets.all(14),
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .96),
      borderColor: active
          ? theme.primary.withValues(alpha: .18)
          : Colors.white.withValues(alpha: .08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: image.isNotEmpty
                      ? CourtImage(
                          images: image,
                          height: 92,
                          width: 92,
                          radius: BorderRadius.circular(18),
                        )
                      : Container(
                          color: Colors.white.withValues(alpha: .04),
                          child:  Icon(
                            Icons.content_cut_rounded,
                            color: theme.primary,
                            size: 30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          label: active ? 'Activo' : 'Inactivo',
                          color: active ? theme.success : Colors.redAccent,
                        ),
                        _Badge(
                          label: serviceCategory(service),
                          color: theme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      serviceName(service),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service['description']?.toString().trim().isNotEmpty ==
                              true
                          ? service['description'].toString()
                          : 'Sin descripción',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .68),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaChip(
                          icon: Icons.payments_rounded,
                          label: formatCrc(servicePrice(service)),
                        ),
                        _MetaChip(
                          icon: Icons.schedule_rounded,
                          label: serviceDurationLabel(service),
                        ),
                        _MetaChip(
                          icon: Icons.people_alt_rounded,
                          label:
                              '${serviceStaffCount(service)} ${whiteLabel.staffPluralLabel}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionPill(
                label: 'Editar',
                icon: Icons.edit_rounded,
                onTap: onEdit,
              ),
              _ActionPill(
                label: whiteLabel.staffPluralLabel,
                icon: Icons.group_rounded,
                onTap: onAssignBarbers,
              ),
              _ActionPill(
                label: active ? 'Desactivar' : 'Activar',
                icon: active
                    ? Icons.toggle_off_rounded
                    : Icons.toggle_on_rounded,
                onTap: onToggleStatus,
                highlighted: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionPill({
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: highlighted ? Colors.black : theme.primary,
        backgroundColor: highlighted
            ? theme.primary
            : theme.primary.withValues(alpha: .10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.primary.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .70),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .68),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionLabel,
            style:  TextStyle(
              color: theme.secondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final WhiteLabelConfig whiteLabel;

  const _EmptyState({required this.whiteLabel});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    return BarbershopPremiumCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      backgroundColor: const Color(0xFF120E0B).withValues(alpha: .96),
      borderColor: Colors.white.withValues(alpha: .08),
      child: Center(
        child: Column(
          children: [
             Icon(
              Icons.content_cut_rounded,
              color: theme.primary,
              size: 40,
            ),
            const SizedBox(height: 10),
            Text(
              'Todavía no hay servicios creados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .82),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Crea el primer servicio para empezar a asignar ${whiteLabel.staffPluralLabel}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: .64),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
