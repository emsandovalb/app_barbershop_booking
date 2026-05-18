import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_router.dart';
import '../../navigation/nav_key.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> with RouteAware {
  Future<Map<String, dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthProvider>().api.getTournaments();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.unsubscribe(this);
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = context.read<AuthProvider>().api.getTournaments();
    });
    await _future;
  }

  @override
  void didPopNext() {
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('tournaments_title', fallback: 'Tournaments')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: loc.t('btn_refresh', fallback: 'Refresh'),
          ),
        ],
      ),
      floatingActionButton: auth.isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                final result = await Navigator.of(context).pushNamed(AppRoutes.tournamentForm);
                if (result is Map<String, dynamic>) {
                  await _refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(loc.t('tournaments_create', fallback: 'Create tournament')),
            )
          : null,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    loc.t('tournaments_error', fallback: 'Could not load tournaments. Please try again later.'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          }

          final items = (snap.data?['data'] as List?) ?? [];
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
                        const Icon(Icons.emoji_events_outlined, color: Colors.white70, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          loc.t('tournaments_empty', fallback: 'No tournaments available yet.'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.t('tournaments_empty_subtitle', fallback: 'Check back later for upcoming competitions.'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white.withOpacity(.72)),
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
              itemBuilder: (_, i) {
                final tournament = Map<String, dynamic>.from(items[i] as Map);
                return _TournamentCard(
                  tournament: tournament,
                  onTap: () => Navigator.of(context).pushNamed(
                    AppRoutes.tournamentDetail,
                    arguments: {
                      'id': tournament['id'] as int,
                      'tournament': tournament,
                    },
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
          );
        },
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final Map<String, dynamic> tournament;
  final VoidCallback onTap;

  const _TournamentCard({
    required this.tournament,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final court = (tournament['court'] as Map<String, dynamic>?) ?? {};
    final organizer = (tournament['organizer'] as Map<String, dynamic>?) ?? {};
    final teamsCount = tournament['teams_count'];
    final status = (tournament['status'] ?? 'draft').toString();
    final fee = _money(tournament['entry_fee'], loc);
    final maxTeams = tournament['max_teams'];
    final dateLabel = _dateLabel(tournament, loc);
    final cover = tournament['cover_image_url']?.toString() ?? tournament['cover_image']?.toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.black30,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: CourtImage(
                images: cover,
                height: 160,
                width: double.infinity,
                radius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
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
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tournament['description']?.toString().isNotEmpty == true
                                  ? tournament['description'].toString()
                                  : loc.t('tournaments_no_description', fallback: 'No description provided.'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_month_outlined,
                        label: dateLabel,
                      ),
                      _MetaChip(
                        icon: Icons.sports_soccer_outlined,
                        label: _formatTournamentFormat(tournament['format']?.toString(), loc),
                      ),
                      _MetaChip(
                        icon: Icons.person_outline,
                        label: organizer['name']?.toString().isNotEmpty == true
                            ? organizer['name'].toString()
                            : loc.t('tournaments_organizer', fallback: 'Organizer'),
                      ),
                      _MetaChip(
                        icon: Icons.place_outlined,
                        label: court['name']?.toString().isNotEmpty == true
                            ? court['name'].toString()
                            : loc.t('tournaments_court', fallback: 'Court'),
                      ),
                      _MetaChip(
                        icon: Icons.groups_outlined,
                        label: teamsCount == null
                          ? loc.t('tournaments_team_count_zero', fallback: '0 teams')
                            : '$teamsCount ${loc.t('tournaments_team_count_suffix', fallback: 'teams')}',
                      ),
                      if (maxTeams != null)
                        _MetaChip(
                          icon: Icons.people_alt_outlined,
                          label: loc.t('tournaments_max_prefix', fallback: 'Max') + ' $maxTeams',
                        ),
                      _MetaChip(
                        icon: Icons.payments_outlined,
                        label: fee,
                      ),
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

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
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

String _money(dynamic value, LocalizationService loc) {
  final num? parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (parsed == null) return loc.t('tournaments_free', fallback: 'Free');
  if (parsed <= 0) return loc.t('tournaments_free', fallback: 'Free');
  return '\$${parsed.toStringAsFixed(2)}';
}

String _dateLabel(Map<String, dynamic> tournament, LocalizationService loc) {
  final raw = tournament['starts_at'] ?? tournament['registration_deadline'] ?? tournament['ends_at'];
  if (raw == null) return loc.t('tournaments_no_dates', fallback: 'No dates');
  final parsed = DateTime.tryParse(raw.toString());
  if (parsed == null) return raw.toString();
  return DateFormat('d MMM').format(parsed);
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

String _formatTournamentFormat(String? raw, LocalizationService loc) {
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
