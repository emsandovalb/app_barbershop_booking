import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';

class TournamentDetailPage extends StatefulWidget {
  final int tournamentId;
  final Map<String, dynamic>? initialTournament;

  const TournamentDetailPage({
    super.key,
    required this.tournamentId,
    this.initialTournament,
  });

  @override
  State<TournamentDetailPage> createState() => _TournamentDetailPageState();
}

class _TournamentDetailPageState extends State<TournamentDetailPage> {
  late Future<_TournamentDetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
    _ensureMyTeamsLoaded();
  }

  Future<_TournamentDetailData> _loadData() async {
    final api = context.read<AuthProvider>().api;
    final tournamentFuture = widget.initialTournament != null
        ? Future.value(Map<String, dynamic>.from(widget.initialTournament!))
        : api.getTournament(widget.tournamentId);
    final enrolledTeamsFuture = api.getTournamentTeams(widget.tournamentId);

    final results = await Future.wait([tournamentFuture, enrolledTeamsFuture]);
    final tournament = Map<String, dynamic>.from(results[0] as Map);
    final enrolledTeamsData = (results[1] as Map<String, dynamic>)['data'] as List? ?? const [];
    final enrolledTeams = enrolledTeamsData
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);

    return _TournamentDetailData(
      tournament: tournament,
      enrolledTeams: enrolledTeams,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _ensureMyTeamsLoaded() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin || !auth.isLoggedIn) {
      return;
    }

    final teams = (auth.user?['teams'] as List?) ?? const [];
    if (teams.isNotEmpty) {
      return;
    }

    try {
      await auth.refreshUser();
    } catch (_) {
      // Keep the existing cached auth state if the network call fails.
    }
  }

  Future<void> _openEnrollSheet(
    Map<String, dynamic> tournament,
    List<Map<String, dynamic>> teams,
  ) async {
    final loc = context.read<LocalizationService>();
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF101010),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _TeamSelectSheet(
        title: loc.t('tournaments_registration_select_team', fallback: 'Select a team'),
        hint: loc.t('tournaments_registration_select_team_hint', fallback: 'Choose one team to continue with enrollment.'),
        teams: teams,
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    await _enrollTeam(tournament, selected);
  }

  Future<void> _enrollTeam(Map<String, dynamic> tournament, Map<String, dynamic> team) async {
    final auth = context.read<AuthProvider>();
    final loc = context.read<LocalizationService>();
    final teamId = team['id'] as int?;
    if (teamId == null) return;

    try {
      final response = await auth.api.enrollTournamentTeam(
        tournamentId: tournament['id'] as int,
        teamId: teamId,
      );
      final enrollment = (response['enrollment'] as Map<String, dynamic>?) ?? const {};
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('tournaments_registration_success', fallback: 'Team enrolled successfully'))),
      );
      setState(() {
        _future = _loadData();
      });
      if (enrollment.isNotEmpty) {
        // no-op, the refreshed future will surface the new status
      }
    } catch (e) {
      if (!mounted) return;
      final message = _friendlyEnrollmentError(e.toString(), loc);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('tournaments_detail_title', fallback: 'Tournament details')),
      ),
      body: FutureBuilder<_TournamentDetailData>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    loc.t('tournaments_detail_error', fallback: 'Could not load tournament details.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!;
          final tournament = data.tournament;
          final enrolledTeams = data.enrolledTeams;
          final court = (tournament['court'] as Map<String, dynamic>?) ?? {};
          final organizer = (tournament['organizer'] as Map<String, dynamic>?) ?? {};
          final teamsCount = tournament['teams_count'];
          final canManage = auth.isAdmin;
          final status = (tournament['status'] ?? 'draft').toString();
          final cover = tournament['cover_image_url']?.toString() ?? tournament['cover_image']?.toString();
          final userTeams = auth.manageableTeams;
          final enrollmentByTeamId = {
            for (final enrollment in enrolledTeams)
              if (enrollment['team_id'] != null) enrollment['team_id'].toString(): enrollment,
          };
          final enrolledUserTeams = userTeams
              .where((team) => enrollmentByTeamId.containsKey(team['id']?.toString()))
              .map((team) {
                final mapped = Map<String, dynamic>.from(team);
                mapped['enrollment'] = enrollmentByTeamId[team['id']?.toString()];
                return mapped;
              })
              .toList(growable: false);
          final availableTeams = userTeams
              .where((team) => !enrollmentByTeamId.containsKey(team['id']?.toString()))
              .toList(growable: false);
          final enrollmentState = _enrollmentState(
            tournament: tournament,
            userTeams: userTeams,
            availableTeams: availableTeams,
            enrolledTeams: enrolledUserTeams,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.black30,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CourtImage(
                      images: cover,
                      height: 220,
                      width: double.infinity,
                      radius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.black30,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tournament['name']?.toString() ?? loc.t('tournaments_fallback_name', fallback: 'Tournament'),
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                _StatusPill(status: status),
                              ],
                            ),
                          ),
                          if (canManage)
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              onSelected: (value) async {
                                if (value == 'edit') {
                                  final updated = await Navigator.of(context).pushNamed(
                                    AppRoutes.tournamentForm,
                                    arguments: {'tournament': tournament},
                                  );
                                  if (updated is Map<String, dynamic>) {
                                    setState(() {
                                      _future = Future.value(
                                        _TournamentDetailData(
                                          tournament: Map<String, dynamic>.from(updated),
                                          enrolledTeams: const [],
                                        ),
                                      );
                                    });
                                  } else {
                                    await _refresh();
                                  }
                                } else if (value == 'close') {
                                  await _closeTournament(tournament);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(loc.t('tournaments_edit', fallback: 'Edit')),
                                ),
                                PopupMenuItem(
                                  value: 'close',
                                  child: Text(loc.t('tournaments_close', fallback: 'Close tournament')),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        tournament['description']?.toString().isNotEmpty == true
                            ? tournament['description'].toString()
                            : loc.t('tournaments_no_description', fallback: 'No description provided.'),
                        style: TextStyle(color: Colors.white.withOpacity(.78), height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!auth.isAdmin) ...[
                  _EnrollmentSection(
                    loc: loc,
                    tournament: tournament,
                    state: enrollmentState,
                    enrolledUserTeams: enrolledUserTeams,
                    availableTeams: availableTeams,
                    onEnroll: () => _openEnrollSheet(tournament, availableTeams),
                    onCreateTeam: () => Navigator.of(context).pushNamed(AppRoutes.teamForm),
                    onOpenTeams: () => Navigator.of(context).pushNamed(AppRoutes.myTeams),
                  ),
                  const SizedBox(height: 16),
                ],
                _InfoGrid(
                  items: [
                    _InfoItem(label: loc.t('tournaments_organizer', fallback: 'Organizer'), value: organizer['name']?.toString() ?? loc.t('tournaments_placeholder_dash', fallback: '—')),
                    _InfoItem(label: loc.t('tournaments_court', fallback: 'Court'), value: court['name']?.toString() ?? loc.t('tournaments_placeholder_dash', fallback: '—')),
                    _InfoItem(label: loc.t('tournaments_max_teams', fallback: 'Max teams'), value: (tournament['max_teams'] ?? loc.t('tournaments_placeholder_dash', fallback: '—')).toString()),
                    _InfoItem(label: loc.t('tournaments_fee', fallback: 'Registration fee'), value: _money(tournament['entry_fee'], loc)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.black30,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.t('tournaments_summary', fallback: 'Tournament summary'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _RowValue(label: loc.t('tournaments_team_count', fallback: 'Registered teams'), value: teamsCount == null ? loc.t('tournaments_team_count_zero', fallback: '0 teams') : teamsCount.toString()),
                      const SizedBox(height: 8),
                      _RowValue(label: loc.t('tournaments_format', fallback: 'Format'), value: _formatLabel(tournament['format']?.toString(), loc)),
                      const SizedBox(height: 8),
                      _RowValue(label: loc.t('tournaments_starts', fallback: 'Starts'), value: _formatDate(tournament['starts_at'], loc)),
                      const SizedBox(height: 8),
                      _RowValue(label: loc.t('tournaments_ends', fallback: 'Ends'), value: _formatDate(tournament['ends_at'], loc)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _closeTournament(Map<String, dynamic> tournament) async {
    final loc = context.read<LocalizationService>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.t('tournaments_close', fallback: 'Close tournament')),
        content: Text(loc.t('tournaments_close_confirm', fallback: 'Do you want to close this tournament? It will be marked inactive.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.t('btn_cancel', fallback: 'Cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.t('btn_close', fallback: 'Close'))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await context.read<AuthProvider>().api.closeTournament(tournament['id'] as int);
      final updated = (response['tournament'] as Map<String, dynamic>?) ?? tournament;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('tournaments_closed', fallback: 'Tournament closed'))),
      );
      setState(() {
        _future = Future.value(
          _TournamentDetailData(
            tournament: Map<String, dynamic>.from(updated),
            enrolledTeams: const [],
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.t('tournaments_close_failed', fallback: 'Failed to close tournament')}: $e')),
        );
      }
    }
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.9,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.black30,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(item.label, style: TextStyle(color: Colors.white.withOpacity(.62), fontSize: 12)),
              const SizedBox(height: 8),
              Text(
                item.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem({required this.label, required this.value});
}

class _RowValue extends StatelessWidget {
  final String label;
  final String value;

  const _RowValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: Colors.white.withOpacity(.72))),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(value, textAlign: TextAlign.right, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

class _EnrollmentSection extends StatelessWidget {
  final LocalizationService loc;
  final Map<String, dynamic> tournament;
  final _TournamentEnrollmentState state;
  final List<Map<String, dynamic>> enrolledUserTeams;
  final List<Map<String, dynamic>> availableTeams;
  final VoidCallback onEnroll;
  final VoidCallback onCreateTeam;
  final VoidCallback onOpenTeams;

  const _EnrollmentSection({
    required this.loc,
    required this.tournament,
    required this.state,
    required this.enrolledUserTeams,
    required this.availableTeams,
    required this.onEnroll,
    required this.onCreateTeam,
    required this.onOpenTeams,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black30,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.t('tournaments_registration', fallback: 'Team registration'),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          _EnrollmentStateBanner(
            loc: loc,
            state: state,
            tournament: tournament,
            availableTeams: availableTeams,
          ),
          if (enrolledUserTeams.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              loc.t('tournaments_registration_status', fallback: 'Enrollment status'),
              style: TextStyle(color: Colors.white.withOpacity(.74)),
            ),
            const SizedBox(height: 10),
            Column(
              children: enrolledUserTeams.map((team) {
                final enrollment = (team['enrollment'] as Map<String, dynamic>?) ?? const {};
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _TeamEnrollmentTile(
                    teamName: team['name']?.toString() ?? loc.t('tournaments_fallback_name', fallback: 'Tournament'),
                    status: (enrollment['status'] ?? 'pending').toString(),
                    subtitle: loc.t('tournaments_registration_already_enrolled', fallback: 'This team is already enrolled in the tournament.'),
                  ),
                );
              }).toList(growable: false),
            ),
          ],
          if (state == _TournamentEnrollmentState.ready) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEnroll,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: Text(loc.t('tournaments_registration_cta', fallback: 'Enroll team')),
              ),
            ),
          ],
          if (state == _TournamentEnrollmentState.needTeam) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCreateTeam,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(loc.t('teams_create', fallback: 'Create team')),
              ),
            ),
          ],
          if (state == _TournamentEnrollmentState.allEnrolled) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenTeams,
                icon: const Icon(Icons.groups_outlined),
                label: Text(loc.t('profile_my_teams', fallback: 'My teams')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamEnrollmentTile extends StatelessWidget {
  final String teamName;
  final String status;
  final String subtitle;

  const _TeamEnrollmentTile({
    required this.teamName,
    required this.status,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(teamName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(.68), height: 1.35)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _EnrollmentStatusChip(status: status, loc: loc),
        ],
      ),
    );
  }
}

class _EnrollmentStateBanner extends StatelessWidget {
  final LocalizationService loc;
  final _TournamentEnrollmentState state;
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> availableTeams;

  const _EnrollmentStateBanner({
    required this.loc,
    required this.state,
    required this.tournament,
    required this.availableTeams,
  });

  @override
  Widget build(BuildContext context) {
    final info = _enrollmentStateInfo(state, loc, tournament);
    final isReady = state == _TournamentEnrollmentState.ready;
    final hasTeams = availableTeams.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isReady ? AppColors.primary.withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isReady ? AppColors.primary.withValues(alpha: 0.30) : Colors.white10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isReady ? AppColors.primary.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(info.message, style: TextStyle(color: Colors.white.withOpacity(.72), height: 1.4)),
                if (isReady) ...[
                  const SizedBox(height: 10),
                  Text(
                    hasTeams
                        ? loc.t('tournaments_registration_choose_team', fallback: 'Choose one of your teams to enroll.')
                        : loc.t('tournaments_registration_no_teams_help', fallback: 'You need to own or manage a team before enrolling in a tournament.'),
                    style: TextStyle(color: Colors.white.withOpacity(.62), height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnrollmentStatusChip extends StatelessWidget {
  final String status;
  final LocalizationService loc;

  const _EnrollmentStatusChip({required this.status, required this.loc});

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isRejected = normalized == 'rejected';
    final isWithdrawn = normalized == 'withdrawn';
    final isApproved = normalized == 'approved';
    final bg = isApproved
        ? Colors.green.withValues(alpha: 0.15)
        : isRejected || isWithdrawn
            ? Colors.red.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.15);
    final fg = isApproved
        ? Colors.greenAccent
        : isRejected || isWithdrawn
            ? Colors.redAccent
            : Colors.orangeAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        _enrollmentStatusLabel(normalized, loc).toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final isInactive = status == 'inactive';
    final isDraft = status == 'draft';
    final bg = isInactive
        ? Colors.red.withValues(alpha: 0.15)
        : isDraft
            ? Colors.orange.withValues(alpha: 0.15)
            : AppColors.success.withValues(alpha: 0.15);
    final fg = isInactive
        ? Colors.redAccent
        : isDraft
            ? Colors.orangeAccent
            : Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(status, loc).toUpperCase(),
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _TeamSelectSheet extends StatefulWidget {
  final String title;
  final String hint;
  final List<Map<String, dynamic>> teams;

  const _TeamSelectSheet({
    required this.title,
    required this.hint,
    required this.teams,
  });

  @override
  State<_TeamSelectSheet> createState() => _TeamSelectSheetState();
}

class _TeamSelectSheetState extends State<_TeamSelectSheet> {
  int? selectedTeamId;

  @override
  void initState() {
    super.initState();
    selectedTeamId = widget.teams.isNotEmpty ? widget.teams.first['id'] as int? : null;
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: bottom + 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(widget.hint, style: TextStyle(color: Colors.white.withOpacity(.68), height: 1.4)),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.teams.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final team = widget.teams[index];
                  final teamId = team['id'] as int?;
                  final isSelected = teamId != null && teamId == selectedTeamId;
                  final pivot = (team['pivot'] as Map?) ?? const {};
                  final role = pivot['role']?.toString();
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => selectedTeamId = teamId),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? AppColors.primary.withValues(alpha: 0.6) : Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  team['name']?.toString() ?? loc.t('tournaments_fallback_name', fallback: 'Team'),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  role == null
                                      ? ''
                                      : role.toUpperCase(),
                                  style: TextStyle(color: Colors.white.withOpacity(.65), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Radio<int?>(
                            value: teamId,
                            groupValue: selectedTeamId,
                            onChanged: (value) => setState(() => selectedTeamId = value),
                            activeColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedTeamId == null
                    ? null
                    : () => Navigator.pop(
                          context,
                          widget.teams.firstWhere(
                            (team) => team['id']?.toString() == selectedTeamId.toString(),
                          ),
                        ),
                child: Text(loc.t('tournaments_registration_enroll_now', fallback: 'Enroll now')),
              ),
            ),
            if (selectedTeamId == null) ...[
              const SizedBox(height: 8),
              Text(loc.t('tournaments_registration_no_selection', fallback: 'Please select a team to continue.'), style: TextStyle(color: Colors.white.withOpacity(.6))),
            ],
          ],
        ),
      ),
    );
  }
}

class _TournamentDetailData {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> enrolledTeams;

  const _TournamentDetailData({
    required this.tournament,
    required this.enrolledTeams,
  });
}

enum _TournamentEnrollmentState {
  draft,
  closed,
  needTeam,
  allEnrolled,
  ready,
}

class _EnrollmentStateInfo {
  final String title;
  final String message;
  final IconData icon;

  const _EnrollmentStateInfo({
    required this.title,
    required this.message,
    required this.icon,
  });
}

String _statusLabel(String status, LocalizationService loc) {
  switch (status) {
    case 'active':
      return loc.t('tournaments_status_active', fallback: 'Active');
    case 'inactive':
      return loc.t('tournaments_status_inactive', fallback: 'Inactive');
    case 'draft':
    default:
      return loc.t('tournaments_status_draft', fallback: 'Draft');
  }
}

_TournamentEnrollmentState _enrollmentState({
  required Map<String, dynamic> tournament,
  required List<Map<String, dynamic>> userTeams,
  required List<Map<String, dynamic>> availableTeams,
  required List<Map<String, dynamic>> enrolledTeams,
}) {
  final status = (tournament['status'] ?? 'draft').toString();
  if (status == 'draft') {
    return _TournamentEnrollmentState.draft;
  }

  if (status == 'inactive' || !_isRegistrationOpen(tournament)) {
    return _TournamentEnrollmentState.closed;
  }

  final teamsCount = int.tryParse(tournament['teams_count']?.toString() ?? '');
  final maxTeams = int.tryParse(tournament['max_teams']?.toString() ?? '');
  if (teamsCount != null && maxTeams != null && teamsCount >= maxTeams) {
    return _TournamentEnrollmentState.closed;
  }

  final rawDeadline = tournament['registration_deadline'];
  final parsedDeadline = rawDeadline == null ? null : DateTime.tryParse(rawDeadline.toString());
  if (parsedDeadline != null && DateTime.now().isAfter(parsedDeadline)) {
    return _TournamentEnrollmentState.closed;
  }

  if (userTeams.isEmpty) {
    return _TournamentEnrollmentState.needTeam;
  }

  if (availableTeams.isEmpty && enrolledTeams.isNotEmpty) {
    return _TournamentEnrollmentState.allEnrolled;
  }

  if (availableTeams.isNotEmpty) {
    return _TournamentEnrollmentState.ready;
  }

  return _TournamentEnrollmentState.needTeam;
}

_EnrollmentStateInfo _enrollmentStateInfo(
  _TournamentEnrollmentState state,
  LocalizationService loc,
  Map<String, dynamic> tournament,
) {
  switch (state) {
    case _TournamentEnrollmentState.draft:
      return _EnrollmentStateInfo(
        title: loc.t('tournaments_registration_not_open', fallback: 'Tournament not open yet'),
        message: loc.t(
          'tournaments_registration_not_open_help',
          fallback: 'This tournament is still in draft. It must be opened before teams can enroll.',
        ),
        icon: Icons.schedule_outlined,
      );
    case _TournamentEnrollmentState.closed:
      return _EnrollmentStateInfo(
        title: loc.t('tournaments_registration_closed', fallback: 'Registration closed'),
        message: _registrationClosedReason(tournament, loc),
        icon: Icons.lock_outline,
      );
    case _TournamentEnrollmentState.needTeam:
      return _EnrollmentStateInfo(
        title: loc.t('tournaments_registration_no_teams', fallback: 'You need a team to enroll'),
        message: loc.t(
          'tournaments_registration_no_teams_help',
          fallback: 'You need to own or manage a team before enrolling in a tournament.',
        ),
        icon: Icons.groups_outlined,
      );
    case _TournamentEnrollmentState.allEnrolled:
      return _EnrollmentStateInfo(
        title: loc.t('tournaments_registration_all_enrolled', fallback: 'All your teams are already enrolled'),
        message: loc.t(
          'tournaments_registration_all_enrolled_help',
          fallback: 'None of your manageable teams are available for this tournament.',
        ),
        icon: Icons.verified_outlined,
      );
    case _TournamentEnrollmentState.ready:
      return _EnrollmentStateInfo(
        title: loc.t('tournaments_registration_ready', fallback: 'You can enroll now'),
        message: loc.t(
          'tournaments_registration_choose_team',
          fallback: 'Choose one of your teams to enroll.',
        ),
        icon: Icons.how_to_reg_outlined,
      );
  }
}

String _enrollmentStatusLabel(String status, LocalizationService loc) {
  switch (status) {
    case 'approved':
      return loc.t('tournaments_registration_status_approved', fallback: 'Approved');
    case 'rejected':
      return loc.t('tournaments_registration_status_rejected', fallback: 'Rejected');
    case 'withdrawn':
      return loc.t('tournaments_registration_status_withdrawn', fallback: 'Withdrawn');
    case 'pending':
    default:
      return loc.t('tournaments_registration_status_pending', fallback: 'Pending');
  }
}

bool _isRegistrationOpen(Map<String, dynamic> tournament) {
  final status = (tournament['status'] ?? 'draft').toString();
  if (status != 'active') {
    return false;
  }

  final rawDeadline = tournament['registration_deadline'];
  if (rawDeadline == null) {
    return true;
  }

  final parsed = DateTime.tryParse(rawDeadline.toString());
  if (parsed == null) {
    return true;
  }

  return DateTime.now().isBefore(parsed);
}

String _registrationClosedReason(Map<String, dynamic> tournament, LocalizationService loc) {
  final status = (tournament['status'] ?? 'draft').toString();
  if (status == 'draft') {
    return loc.t(
      'tournaments_registration_not_open_help',
      fallback: 'This tournament is still in draft. It must be opened before teams can enroll.',
    );
  }
  if (status == 'inactive') {
    return loc.t('tournaments_registration_closed', fallback: 'This tournament is closed for enrollment.');
  }

  final teamsCount = int.tryParse((tournament['teams_count'] ?? '').toString());
  final maxTeams = int.tryParse((tournament['max_teams'] ?? '').toString());
  if (teamsCount != null && maxTeams != null && teamsCount >= maxTeams) {
    return loc.t('tournaments_registration_full', fallback: 'This tournament is full.');
  }

  final rawDeadline = tournament['registration_deadline'];
  final parsed = rawDeadline == null ? null : DateTime.tryParse(rawDeadline.toString());
  if (parsed != null && DateTime.now().isAfter(parsed)) {
    return loc.t('tournaments_registration_deadline', fallback: 'The registration deadline has passed.');
  }

  return loc.t('tournaments_registration_closed', fallback: 'This tournament is closed for enrollment.');
}

String _friendlyEnrollmentError(String raw, LocalizationService loc) {
  final lower = raw.toLowerCase();
  if (lower.contains('already enrolled')) {
    return loc.t('tournaments_registration_already_enrolled', fallback: 'This team is already enrolled in the tournament.');
  }
  if (lower.contains('tournament is full')) {
    return loc.t('tournaments_registration_full', fallback: 'This tournament is full.');
  }
  if (lower.contains('tournament is closed')) {
    return loc.t('tournaments_registration_closed', fallback: 'This tournament is closed for enrollment.');
  }
  if (lower.contains('forbidden')) {
    return loc.t('tournaments_registration_failed', fallback: 'Could not enroll the team');
  }
  return loc.t('tournaments_registration_failed', fallback: 'Could not enroll the team');
}

String _formatDate(dynamic raw, LocalizationService loc) {
  if (raw == null) return loc.t('tournaments_no_date', fallback: '—');
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return raw.toString();
  return DateFormat('d MMM yyyy, h:mm a').format(parsed);
}

String _money(dynamic value, LocalizationService loc) {
  final num? parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (parsed == null || parsed <= 0) return loc.t('tournaments_free', fallback: 'Free');
  return '\$${parsed.toStringAsFixed(2)}';
}

String _formatLabel(String? raw, LocalizationService loc) {
  switch (raw) {
    case 'single_elimination':
      return loc.t('tournaments_format_single_elimination', fallback: 'Single elimination');
    case 'double_elimination':
      return loc.t('tournaments_format_double_elimination', fallback: 'Double elimination');
    case 'round_robin':
      return loc.t('tournaments_format_round_robin', fallback: 'Round robin');
    default:
      return loc.t('tournaments_format_unknown', fallback: 'Format');
  }
}
