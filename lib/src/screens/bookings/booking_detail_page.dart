import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';
import '../ground/select_date_time_page.dart';
import 'appointment_helpers.dart';

class BookingDetailPage extends StatefulWidget {
  final Map<String, dynamic> booking;
  const BookingDetailPage({super.key, required this.booking});

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final resource = appointmentResource(booking);
    final status = appointmentStatusBucket(booking);
    final date = appointmentDate(booking);
    final isUpcoming = date != null ? date.isAfter(DateTime.now()) : false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Detalle de la cita'),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0C0908),
              Color(0xFF13100F),
              Color(0xFF090909),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 110, 16, 16),
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.primary.withValues(alpha: .18)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 26,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 250,
                      width: double.infinity,
                      child: CourtImage(
                        images: appointmentImageSource(booking),
                        height: 250,
                        radius: BorderRadius.circular(28),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              const Color(0xCC090909),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Badge(
                            label: appointmentStatusLabel(status),
                            foreground: appointmentStatusForeground(status),
                            background: appointmentStatusBackground(status),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            appointmentServiceName(booking),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.content_cut_outlined,
                                color: AppColors.secondary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  appointmentBarberName(booking),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _InfoCard(
              title: 'Resumen de la cita',
              children: [
                _kv('Servicio', appointmentServiceName(booking)),
                _kv('Código de cita', appointmentCode(booking)),
                _kv('Fecha', appointmentDateLabel(booking)),
                _kv('Hora', appointmentTimeLabel(booking)),
                _kv('Barbero', appointmentBarberName(booking)),
                _kv('Precio', appointmentPriceLabel(booking)),
                _kv(
                  'Estado',
                  appointmentStatusLabel(status),
                  valueHighlight: true,
                ),
              ],
            ),
            const SizedBox(height: 14),
            _InfoCard(
              title: 'Detalles rápidos',
              children: [
                _kv(
                  'Duración',
                  _durationLabel(
                    booking['duration_hours'] ?? resource['duration_hours'],
                    resource['duration_minutes'],
                  ),
                ),
                _kv(
                  'Local',
                  resource['address']?.toString().isNotEmpty == true
                      ? resource['address'].toString()
                      : 'Sin dirección disponible',
                ),
                _kv(
                  'Código interno',
                  '#${booking['id']?.toString() ?? '—'}',
                  valueHighlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (isUpcoming) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _cancel,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.close_outlined),
                  label: Text(
                    loading ? 'Cancelando...' : 'Cancelar cita',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF231315),
                    foregroundColor: const Color(0xFFFF9D9D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: ElevatedButton.icon(
                onPressed: loading ? null : _rebook,
                icon: loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.autorenew_outlined),
                label: Text(
                  loading ? 'Reprogramando...' : 'Reagendar',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: const Color(0xFF090909),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final loc = context.read<LocalizationService>();
    final booking = widget.booking;
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    if (!canCancelAppointment(booking)) {
      if (!mounted) return;
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

    setState(() => loading = true);
    try {
      await auth.api.cancelReservation(_bookingId());
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Cita cancelada')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo cancelar: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _rebook() async {
    final loc = context.read<LocalizationService>();
    final booking = widget.booking;
    final resource = appointmentResource(booking);
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => SelectDateTimePage(court: resource)),
    );
    if (result == null) return;

    setState(() => loading = true);
    try {
      await auth.api.rebookReservation(
        _bookingId(),
        {
          'date': result['iso'] as String,
          'time_slot': result['slot'] as String,
        },
      );
      if (!mounted) return;
      navigator.pushReplacementNamed(
        AppRoutes.orderPlaced,
        arguments: {
          'title': loc.t(
            'booking_rebook_success_title',
            fallback: 'Cita reprogramada',
          ),
          'subtitle': loc.t(
            'booking_rebook_success_subtitle',
            fallback: 'Tu cita fue reprogramada correctamente.',
          ),
          'buttonText': loc.t('btn_back_home', fallback: 'Volver al inicio'),
          'backRoute': AppRoutes.home,
        },
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${loc.t('booking_rebook_failed', fallback: 'No se pudo reprogramar')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int _bookingId() {
    final raw = widget.booking['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Widget _kv(
    String key,
    String value, {
    bool valueHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueHighlight ? AppColors.primary : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151110),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
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

String _durationLabel(dynamic durationHours, dynamic durationMinutes) {
  final minutes = durationMinutes is num
      ? durationMinutes.toInt()
      : int.tryParse(durationMinutes?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    if (minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return hours == 1 ? '1 hora' : '$hours horas';
    }
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    return '${hours}h ${remainder}m';
  }
  final hours = durationHours is num
      ? durationHours.toInt()
      : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 hora' : '$hours horas';
}
