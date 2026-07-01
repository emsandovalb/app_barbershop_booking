import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'admin_page_scaffold.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() {
    return context.read<AuthProvider>().api.getStaff(perPage: 100);
  }

  Future<void> _refresh() async {
    final next = await _load();
    if (!mounted) return;
    setState(() {
      _future = Future.value(next);
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final canManage = auth.isAdmin && config.features.adminStaffManagement;

    if (!canManage) {
      return Scaffold(
        appBar: buildAdminAppBar(
          context,
          title: loc.t('manage_staff', fallback: 'Manage barbers'),
        ),
        body: Center(
          child: Text(
            loc.t(
              'admin_only',
              fallback: 'Only administrators can access this section',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: loc.t('manage_staff', fallback: 'Manage barbers'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(
            context,
          ).pushNamed(AppRoutes.staffForm);
          if (saved == true) {
            await _refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(loc.t('add_staff', fallback: 'Add barber')),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done &&
              !snap.hasData &&
              !snap.hasError) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                loc.t('staff_load_failed', fallback: 'Failed to load staff'),
              ),
            );
          }
          final items = (snap.data?['data'] as List?) ?? const [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 160),
                  Center(
                    child: Text(
                      loc.t('staff_empty', fallback: 'No barbers found'),
                      style: const TextStyle(color: Colors.white70),
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
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final staff = Map<String, dynamic>.from(items[index] as Map);
                final role = (staff['role'] as Map?) ?? const {};
                final services = (staff['services'] as List?) ?? const [];
                final isActive = staff['is_active'] == true;
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2430),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: config.brand.primaryColor
                                .withOpacity(.18),
                            backgroundImage:
                                (staff['avatar_url']?.toString() ?? '')
                                    .isNotEmpty
                                ? NetworkImage(staff['avatar_url'].toString())
                                : null,
                            child:
                                (staff['avatar_url']?.toString() ?? '').isEmpty
                                ? const Icon(
                                    Icons.content_cut_outlined,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff['name']?.toString() ??
                                      loc.t('staff_title', fallback: 'Barber'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role['name']?.toString() ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${services.length} ${loc.t('staff_services', fallback: 'services')}',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: isActive,
                            onChanged: (value) async {
                              if (value) {
                                await context
                                    .read<AuthProvider>()
                                    .api
                                    .updateStaff(staff['id'] as int, {
                                      'is_active': true,
                                    });
                              } else {
                                await context
                                    .read<AuthProvider>()
                                    .api
                                    .deactivateStaff(staff['id'] as int);
                              }
                              await _refresh();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((staff['email']?.toString() ?? '').isNotEmpty)
                        Text(
                          staff['email'].toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                          ),
                        ),
                      if ((staff['phone']?.toString() ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          staff['phone'].toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(.78),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.staffDetail,
                                arguments: {'staff': staff},
                              );
                            },
                            icon: const Icon(Icons.person_outline),
                            label: const Text('Ver perfil'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final saved = await Navigator.of(context)
                                  .pushNamed(
                                    AppRoutes.staffForm,
                                    arguments: {'staff': staff},
                                  );
                              if (saved == true) {
                                await _refresh();
                              }
                            },
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(loc.t('edit', fallback: 'Edit')),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final saved = await Navigator.of(context)
                                  .pushNamed(
                                    AppRoutes.staffResourceAssignment,
                                    arguments: {
                                      'staff_id': staff['id'],
                                      'staff': staff,
                                    },
                                  );
                              if (saved == true) {
                                await _refresh();
                              }
                            },
                            icon: const Icon(Icons.link_outlined),
                            label: Text(loc.t('assign', fallback: 'Assign')),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
