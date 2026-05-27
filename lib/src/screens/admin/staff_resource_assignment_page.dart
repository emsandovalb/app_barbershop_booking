import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

class StaffResourceAssignmentPage extends StatefulWidget {
  final int staffId;
  final Map<String, dynamic>? initialStaff;

  const StaffResourceAssignmentPage({
    super.key,
    required this.staffId,
    this.initialStaff,
  });

  @override
  State<StaffResourceAssignmentPage> createState() => _StaffResourceAssignmentPageState();
}

class _StaffResourceAssignmentPageState extends State<StaffResourceAssignmentPage> {
  Future<Map<String, dynamic>>? _future;
  Future<Map<String, dynamic>>? _resourcesFuture;

  @override
  void initState() {
    super.initState();
    _future = widget.initialStaff != null
        ? Future.value(widget.initialStaff!)
        : _loadStaff();
    _resourcesFuture = _loadResources();
  }

  Future<Map<String, dynamic>> _loadStaff() {
    return context.read<AuthProvider>().api.getStaffById(widget.staffId);
  }

  Future<Map<String, dynamic>> _loadResources() {
    return context.read<AuthProvider>().api.getResources(perPage: 100);
  }

  Future<void> _refresh() async {
    final staff = await _loadStaff();
    final resources = await _loadResources();
    if (!mounted) return;
    setState(() {
      _future = Future.value(staff);
      _resourcesFuture = Future.value(resources);
    });
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
      appBar: AppBar(
        title: Text(loc.t('staff_resources', fallback: 'Services')),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, staffSnap) {
          if (staffSnap.connectionState != ConnectionState.done && !staffSnap.hasData && !staffSnap.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (staffSnap.hasError || staffSnap.data == null) {
            return Center(
              child: Text(loc.t('staff_load_failed', fallback: 'Failed to load staff')),
            );
          }
          final staff = staffSnap.data!;
          final assignedIds = _assignedIds(staff);
          return FutureBuilder<Map<String, dynamic>>(
            future: _resourcesFuture,
            builder: (context, resourceSnap) {
              if (resourceSnap.connectionState != ConnectionState.done && !resourceSnap.hasData && !resourceSnap.hasError) {
                return const Center(child: CircularProgressIndicator());
              }
              if (resourceSnap.hasError || resourceSnap.data == null) {
                return Center(
                  child: Text(loc.t('resource_load_failed', fallback: 'Failed to load resources')),
                );
              }
              final resources = (resourceSnap.data?['data'] as List?) ?? const [];
              if (resources.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 160),
                      Center(
                        child: Text(
                          loc.t('staff_no_resources', fallback: 'No service assignments yet'),
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
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final resource = Map<String, dynamic>.from(resources[index] as Map);
                    final resourceId = resource['id'] as int;
                    final assigned = assignedIds.contains(resourceId);
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C2430),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: assigned ? Colors.greenAccent.withOpacity(.5) : Colors.white10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          resource['name']?.toString() ?? loc.t('staff_resource', fallback: 'Service'),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          resource['address']?.toString() ?? '',
                          style: TextStyle(color: Colors.white.withOpacity(.72)),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white.withOpacity(.12),
                          child: Icon(
                            assigned ? Icons.link : Icons.link_off,
                            color: assigned ? Colors.greenAccent : Colors.white70,
                          ),
                        ),
                        trailing: Switch(
                          value: assigned,
                          onChanged: (value) async {
                            final api = context.read<AuthProvider>().api;
                            if (value) {
                              await api.assignStaffToResource(widget.staffId, resourceId);
                            } else {
                              await api.removeStaffFromResource(widget.staffId, resourceId);
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
