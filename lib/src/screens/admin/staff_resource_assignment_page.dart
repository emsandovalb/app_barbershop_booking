import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/loadable_collection_view.dart';
import 'admin_page_scaffold.dart';

class StaffResourceAssignmentPage extends StatefulWidget {
  final int staffId;
  final Map<String, dynamic>? initialStaff;

  const StaffResourceAssignmentPage({
    super.key,
    required this.staffId,
    this.initialStaff,
  });

  @override
  State<StaffResourceAssignmentPage> createState() =>
      _StaffResourceAssignmentPageState();
}

class _StaffResourceAssignmentPageState
    extends State<StaffResourceAssignmentPage> {
  Future<Map<String, dynamic>>? _future;
  late final LoadableController<List<Map<String, dynamic>>>
  _resourcesController;

  @override
  void initState() {
    super.initState();
    _future = widget.initialStaff != null
        ? Future.value(widget.initialStaff!)
        : _loadStaff();
    _resourcesController = LoadableController<List<Map<String, dynamic>>>(
      _loadResources,
    );
    _resourcesController.load();
  }

  @override
  void dispose() {
    _resourcesController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadStaff() {
    return context.read<AuthProvider>().api.getStaffById(widget.staffId);
  }

  Future<List<Map<String, dynamic>>> _loadResources() async {
    final response = await context.read<AuthProvider>().api.getResources(
      perPage: 100,
    );
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    return const [];
  }

  Future<void> _refresh() async {
    final staff = await _loadStaff();
    if (!mounted) return;
    setState(() {
      _future = Future.value(staff);
    });
    await _resourcesController.load();
  }

  Set<int> _assignedIds(Map<String, dynamic> staff) {
    final services = (staff['services'] as List?) ?? const [];
    return services
        .map((entry) {
          final map = Map<String, dynamic>.from(entry as Map);
          final resource = (map['resource'] as Map?) ?? const {};
          return resource['id'] as int?;
        })
        .whereType<int>()
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: loc.t('staff_resources', fallback: 'Services'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, staffSnap) {
          if (staffSnap.connectionState != ConnectionState.done &&
              !staffSnap.hasData &&
              !staffSnap.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (staffSnap.hasError || staffSnap.data == null) {
            return Center(
              child: Text(
                loc.t('staff_load_failed', fallback: 'Failed to load staff'),
              ),
            );
          }
          final staff = staffSnap.data!;
          final assignedIds = _assignedIds(staff);
          return AnimatedBuilder(
            animation: _resourcesController,
            builder: (context, _) {
              final resourceState = _resourcesController.state;
              final resources = resourceState.data ?? const [];
              if (resourceState.isLoading && !resourceState.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (resourceState.hasError && !resourceState.hasData) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No fue posible cargar los servicios.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .78),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _refresh,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              }
              if (resources.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: Text(
                          loc.t(
                            'staff_no_resources',
                            fallback: 'No service assignments yet',
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: resources.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final resource = resources[index];
                    final resourceId = resource['id'] as int;
                    final assigned = assignedIds.contains(resourceId);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2430),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: assigned
                              ? Colors.greenAccent.withValues(alpha: .5)
                              : Colors.white10,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          resource['name']?.toString() ??
                              loc.t('staff_resource', fallback: 'Service'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          resource['address']?.toString() ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: .12),
                          child: Icon(
                            assigned ? Icons.link : Icons.link_off,
                            color: assigned
                                ? Colors.greenAccent
                                : Colors.white70,
                          ),
                        ),
                        trailing: Switch(
                          value: assigned,
                          onChanged: (value) async {
                            final api = context.read<AuthProvider>().api;
                            if (value) {
                              await api.assignStaffToResource(
                                widget.staffId,
                                resourceId,
                              );
                            } else {
                              await api.removeStaffFromResource(
                                widget.staffId,
                                resourceId,
                              );
                            }
                            await _refresh();
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
