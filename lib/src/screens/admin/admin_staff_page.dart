import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/brand_theme.dart';
import '../../widgets/loadable_collection_view.dart';
import 'admin_page_scaffold.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  late final LoadableController<List<Map<String, dynamic>>> _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoadableController<List<Map<String, dynamic>>>(
      _load,
      preserveDataOnError: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final auth = context.read<AuthProvider>();
    await auth.ready;

    final response = await auth.api.getStaff(perPage: 100);
    final data = response['data'];
    if (data is! List) {
      return const [];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Future<void> _refresh({bool clearData = false}) {
    return _controller.load(clearData: clearData);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF132018),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final config = context.watch<AppConfig>();
    final loc = context.watch<LocalizationService>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    final auth = context.watch<AuthProvider>();
    final canManage =
        config.features.adminStaffManagement && auth.canManageBusiness;

    if (!canManage) {
      return Scaffold(
        backgroundColor: theme.background,
        appBar: buildAdminAppBar(context, title: loc.t('manage_staff')),
        body: Center(
          child: Text(
            loc.t('admin_only'),
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Scaffold(
          appBar: buildAdminAppBar(
            context,
            title: loc.t('manage_staff'),
            actions: [
              IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final saved = await Navigator.of(context).pushNamed<bool>(
                AppRoutes.staffForm,
                arguments: const {'createMode': true},
              );
              if (saved == true) {
                await _refresh();
                _showSuccess(
                  '${whiteLabel.staffDisplayName} creado correctamente.',
                );
              }
            },
            icon: const Icon(Icons.add),
            label: Text(
              loc.t('add_staff', args: {'staff': whiteLabel.staffDisplayName}),
            ),
          ),
          body: LoadableCollectionView<List<Map<String, dynamic>>>(
            controller: _controller,
            isEmpty: (items) => items.isEmpty,
            loadingBuilder: (_, __) {
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (_, error, retry) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _staffErrorMessage(error),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: retry,
                          child: Text(tr('btn_retry')),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            emptyBuilder: (_, __) {
              return RefreshIndicator(
                onRefresh: () => _refresh(clearData: false),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loc.t('staff_empty_title'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.t('staff_empty_hint'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            dataBuilder: (_, items, __, isLoading) {
              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => _refresh(clearData: false),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final staff = items[index];
                        final role = (staff['role'] as Map?) ?? const {};
                        final services =
                            (staff['services'] as List?) ?? const [];
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
                                        .withValues(alpha: .18),
                                    backgroundImage:
                                        (staff['avatar_url']?.toString() ?? '')
                                            .isNotEmpty
                                        ? NetworkImage(
                                            staff['avatar_url'].toString(),
                                          )
                                        : null,
                                    child:
                                        (staff['avatar_url']?.toString() ?? '')
                                            .isEmpty
                                        ? const Icon(
                                            Icons.content_cut_outlined,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff['name']?.toString() ??
                                              loc.t('staff_title'),
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
                                            color: Colors.white.withValues(
                                              alpha: .7,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${services.length} ${loc.t('staff_services')}',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: .7,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isActive,
                                    onChanged: (value) async {
                                      final api = context
                                          .read<AuthProvider>()
                                          .api;
                                      if (value) {
                                        await api.updateStaff(
                                          staff['id'] as int,
                                          {'is_active': true},
                                        );
                                      } else {
                                        await api.deactivateStaff(
                                          staff['id'] as int,
                                        );
                                      }
                                      await _refresh(clearData: false);
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if ((staff['email']?.toString() ?? '').isNotEmpty)
                                Text(
                                  staff['email'].toString(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .78),
                                  ),
                                ),
                              if ((staff['phone']?.toString() ?? '')
                                  .isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  staff['phone'].toString(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: .78),
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
                                    label: Text(tr('staff_view_profile')),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final saved = await Navigator.of(context)
                                          .pushNamed(
                                            AppRoutes.staffForm,
                                            arguments: {
                                              'staff': staff,
                                              'createMode': false,
                                            },
                                          );
                                      if (saved == true) {
                                        await _refresh(clearData: false);
                                      }
                                    },
                                    icon: const Icon(Icons.edit_outlined),
                                    label: Text(loc.t('edit')),
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
                                        await _refresh(clearData: false);
                                      }
                                    },
                                    icon: const Icon(Icons.link_outlined),
                                    label: Text(loc.t('assign')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLoading)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(minHeight: 2),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  String _staffErrorMessage(Object error) {
    final text = error.toString();
    if (text.contains('401')) {
      return tr('admin_session_expired');
    }
    if (text.contains('403')) {
      return tr('admin_no_permission');
    }
    if (text.contains('404')) {
      return tr('admin_business_not_found');
    }
    if (text.contains('422')) {
      return tr('admin_invalid_response');
    }
    if (text.contains('500')) {
      return tr('admin_team_server_error');
    }
    return tr('admin_team_load_failed');
  }
}
