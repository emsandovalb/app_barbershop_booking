import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';
import '../ground/select_date_time_page.dart';
import 'appointment_helpers.dart';

class BookingsTab extends StatefulWidget {
  final int initialIndex;
  const BookingsTab({super.key, this.initialIndex = 0});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  late Future<Map<String, dynamic>> _future;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
    _future = _loadReservations();
  }

  Future<Map<String, dynamic>> _loadReservations() {
    return context.read<AuthProvider>().api.getReservations();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: _currentIndex,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis citas'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF141110),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
                ),
                child: TabBar(
                  onTap: (index) => _currentIndex = index,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFC9A56A), Color(0xFFE8D8B8)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3DC9A56A),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: const Color(0xFF090909),
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: .1,
                  ),
                  tabs: const [
                    Tab(text: 'Próximas'),
                    Tab(text: 'Completadas'),
                    Tab(text: 'Canceladas'),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return _StatePanel(
                title: 'No fue posible cargar tus citas',
                subtitle: 'Revisá tu conexión e intentá de nuevo.',
                icon: Icons.error_outline,
                actionLabel: 'Reintentar',
                onAction: _refresh,
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final rawItems = (snap.data?['data'] as List?) ?? const [];
            final upcoming = filterAppointments(rawItems, AppointmentStatusBucket.upcoming);
            final completed = filterAppointments(rawItems, AppointmentStatusBucket.completed);
            final cancelled = filterAppointments(rawItems, AppointmentStatusBucket.cancelled);

            return TabBarView(
              children: [
                _AppointmentList(
                  title: 'No tienes citas próximas',
                  items: upcoming,
                  onRefresh: _refresh,
                ),
                _AppointmentList(
                  title: 'No tienes citas completadas',
                  items: completed,
                  onRefresh: _refresh,
                ),
                _AppointmentList(
                  title: 'No tienes citas canceladas',
                  items: cancelled,
                  onRefresh: _refresh,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AppointmentList extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final Future<void> Function() onRefresh;

  const _AppointmentList({
    required this.title,
    required this.items,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationService>();

    if (!auth.isLoggedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, color: AppColors.primary, size: 44),
              const SizedBox(height: 14),
              const Text(
                'Iniciá sesión para ver tus citas',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed('/login'),
                child: Text(loc.t('login_button', fallback: 'Iniciar sesión')),
              ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _StatePanel(
            title: title,
            subtitle: 'Deslizá para refrescar cuando tengas nuevas citas.',
            icon: Icons.event_busy_outlined,
            actionLabel: 'Actualizar',
            onAction: onRefresh,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: const Color(0xFF141110),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final booking = items[index];
          return _AppointmentCard(
            booking: booking,
            onRefresh: onRefresh,
          );
        },
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Future<void> Function() onRefresh;

  const _AppointmentCard({
    required this.booking,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final status = appointmentStatusBucket(booking);
    final canCancel = canCancelAppointment(booking);
    final canRebook = canRebookAppointment(booking);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151110),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: .08)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CourtImage(
                        images: appointmentImageSource(booking),
                        width: 92,
                        height: 104,
                        radius: BorderRadius.circular(20),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: _Badge(
                        label: appointmentStatusLabel(status),
                        foreground: appointmentStatusForeground(status),
                        background: appointmentStatusBackground(status),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointmentServiceName(booking),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.content_cut_outlined, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              appointmentBarberName(booking),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _DetailRow(
                        icon: Icons.calendar_month_outlined,
                        label: appointmentDateLabel(booking),
                      ),
                      const SizedBox(height: 6),
                      _DetailRow(
                        icon: Icons.schedule_outlined,
                        label: appointmentTimeLabel(booking),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _PriceChip(label: appointmentPriceLabel(booking)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0x26FFFFFF)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ActionButton(
                  label: 'Ver detalle',
                  icon: Icons.visibility_outlined,
                  onPressed: () async {
                    final result = await Navigator.of(context).pushNamed(
                      AppRoutes.bookingShow,
                      arguments: {'booking': booking},
                    );
                    if (result == true) {
                      await onRefresh();
                    }
                  },
                ),
                if (canRebook)
                  _ActionButton(
                    label: 'Reagendar',
                    icon: Icons.autorenew_outlined,
                    highlight: true,
                    onPressed: () => _rebook(context),
                  ),
                if (canCancel)
                  _ActionButton(
                    label: 'Cancelar',
                    icon: Icons.close_outlined,
                    danger: true,
                    onPressed: () => _cancel(context),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final loc = context.read<LocalizationService>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!canCancelAppointment(booking)) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.t(
              'booking_cancel_limit',
              fallback: 'No se puede cancelar dentro de las 4 horas previas al inicio.',
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161110),
        title: const Text(
          'Cancelar cita',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '¿Seguro que querés cancelar esta cita?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await auth.api.cancelReservation(_bookingId());
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cita cancelada')),
      );
      await onRefresh();
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo cancelar: $e')),
      );
    }
  }

  Future<void> _rebook(BuildContext context) async {
    final resource = appointmentResource(booking);
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => SelectDateTimePage(court: resource),
      ),
    );
    if (result == null || !navigator.mounted) return;

    try {
      await auth.api.rebookReservation(
        _bookingId(),
        {
          'date': result['iso'] as String,
          'time_slot': result['slot'] as String,
        },
      );
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cita reprogramada')),
      );
      await onRefresh();
    } catch (e) {
      if (!messenger.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo reprogramar: $e')),
      );
    }
  }

  int _bookingId() {
    final raw = booking['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color foreground;
  final Color background;

  const _Badge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: foreground.withValues(alpha: .28)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: .9,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;

  const _PriceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF221A12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: .24)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlight;
  final bool danger;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.highlight = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = danger
        ? const Color(0xFF7B3C3C)
        : highlight
            ? AppColors.primary
            : Colors.white24;
    final textColor = danger
        ? const Color(0xFFFF9D9D)
        : highlight
            ? AppColors.primary
            : Colors.white;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: danger
            ? const Color(0xFF231315)
            : highlight
                ? const Color(0xFF20180F)
                : const Color(0xFF191514),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _StatePanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF151110),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 42, color: AppColors.primary),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => onAction!.call(),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
