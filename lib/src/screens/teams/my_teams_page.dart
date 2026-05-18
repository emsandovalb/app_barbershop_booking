import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';

class MyTeamsPage extends StatefulWidget {
  const MyTeamsPage({super.key});

  @override
  State<MyTeamsPage> createState() => _MyTeamsPageState();
}

class _MyTeamsPageState extends State<MyTeamsPage> {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthProvider>().api.getMyTeams();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<AuthProvider>().api.getMyTeams();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationService>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: Text(loc.t('teams_title', fallback: 'My teams'))),
        body: Center(child: Text(loc.t('auth_login_required', fallback: 'Please log in to continue.'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('teams_title', fallback: 'My teams')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: loc.t('btn_refresh', fallback: 'Refresh'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.of(context).pushNamed(AppRoutes.teamForm);
          if (saved == true && mounted) {
            await _refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(loc.t('teams_create', fallback: 'Create team')),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.t('teams_load_failed', fallback: 'Could not load teams. Please try again later.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final items = (snap.data?['data'] as List?) ?? const [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.black30,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.groups_outlined, color: Colors.white70, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          loc.t('teams_empty', fallback: 'No teams yet'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.t('teams_empty_help', fallback: 'Create your first team to enroll it in tournaments.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withValues(alpha: .72)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            final saved = await Navigator.of(context).pushNamed(AppRoutes.teamForm);
                            if (saved == true && mounted) {
                              await _refresh();
                            }
                          },
                          child: Text(loc.t('teams_create', fallback: 'Create team')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final team = Map<String, dynamic>.from(items[index] as Map);
                return _TeamCard(
                  team: team,
                  onTap: () async {
                    final saved = await Navigator.of(context).pushNamed(
                      AppRoutes.teamForm,
                      arguments: {'team': team},
                    );
                    if (saved == true && mounted) {
                      await _refresh();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Map<String, dynamic> team;
  final VoidCallback onTap;

  const _TeamCard({required this.team, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final members = team['users_count'];
    final tournaments = team['tournaments_count'];
    final rawLogo = team['logo_url']?.toString() ?? team['logo']?.toString();
    final status = (team['status'] ?? 'active').toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black30,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 76,
                height: 76,
                child: CourtImage(
                  images: rawLogo,
                  height: 76,
                  width: 76,
                  radius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team['name']?.toString() ?? loc.t('teams_title', fallback: 'Team'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    team['description']?.toString().isNotEmpty == true
                        ? team['description'].toString()
                        : loc.t('teams_empty_help', fallback: 'Create your first team to enroll it in tournaments.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withValues(alpha: .72)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Chip(label: '${members ?? 0} ${loc.t('teams_members', fallback: 'Members')}'),
                      _Chip(label: '${tournaments ?? 0} ${loc.t('teams_tournaments', fallback: 'Tournaments')}'),
                      _Chip(
                        label: status == 'inactive'
                            ? loc.t('tournaments_status_inactive', fallback: 'Inactive')
                            : loc.t('tournaments_status_active', fallback: 'Active'),
                        danger: status == 'inactive',
                      ),
                      if ((team['city'] ?? '').toString().isNotEmpty)
                        _Chip(label: team['city'].toString()),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool danger;
  const _Chip({required this.label, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (danger ? Colors.red : Colors.white).withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: danger ? Colors.redAccent : Colors.white70,
          fontSize: 12,
        ),
      ),
    );
  }
}
