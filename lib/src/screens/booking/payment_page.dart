import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> args;
  const PaymentPage({super.key, required this.args});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool loading = false;
  Map<String, dynamic>? selectedBarber;

  @override
  void initState() {
    super.initState();
    final initial = widget.args['staff'];
    if (initial is Map) {
      selectedBarber = Map<String, dynamic>.from(initial);
      final explicitStaffId = widget.args['staff_id'];
      if (selectedBarber!['id'] == null && explicitStaffId != null) {
        selectedBarber!['id'] = explicitStaffId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final whiteLabel = context.watch<WhiteLabelConfig>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('payment_title', fallback: 'Confirmar cita')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _BarberSection(
            title: whiteLabel.staffDisplayName,
            subtitle:
                selectedBarber?['name']?.toString() ??
                loc.t(
                  'booking_barber_required',
                  fallback: 'Profesional pendiente',
                ),
            actionLabel: '',
            onTap: null,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.payments_outlined, color: Colors.white70),
            title: Text(
              loc.t('booking_payment_pending', fallback: 'Pago pendiente'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              loc.t(
                'booking_payment_pending_hint',
                fallback: 'El negocio registrará el pago cuando corresponda.',
              ),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: loading ? null : _confirm,
          child: Text(
            loading
                ? loc.t('payment_processing', fallback: 'Procesando...')
                : loc.t('btn_continue', fallback: 'Continuar'),
          ),
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    final loc = context.read<LocalizationService>();
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.t(
                'payment_login_required',
                fallback: 'Please log in to complete the appointment',
              ),
            ),
          ),
        );
        Navigator.of(context).pushNamed(AppRoutes.login);
      }
      return;
    }

    setState(() => loading = true);
    // Everything from here on runs inside try/finally: an early return
    // (invalid staff selection) and an early throw (a malformed arg cast)
    // both still hit `finally`, so `loading` can never get stuck true no
    // matter which exit path this method takes.
    try {
      final Map<String, dynamic> service = Map<String, dynamic>.from(
        (widget.args['resource'] as Map<String, dynamic>?) ??
            (widget.args['court'] as Map<String, dynamic>?) ??
            const {},
      );
      final iso = widget.args['iso'] as String;
      final slot = widget.args['slot'] as String;
      final staffId = _selectedStaffId();

      // A staff map without an id must never silently become an unassigned
      // reservation after crossing the booking routes.
      if (staffId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.t(
                  'booking_barber_selection_invalid',
                  fallback:
                      'La selección de barbero no es válida. Elegí uno de nuevo.',
                ),
              ),
            ),
          );
        }
        return;
      }

      final reservation = await auth.api.createReservation({
        'resource_id': service['id'],
        'date': iso,
        'time_slot': slot,
        'staff_id': staffId,
      });

      // ApiClient rejects malformed success responses, but retain this guard
      // at the UI boundary so this route can never show a confirmation for a
      // response that does not identify the persisted reservation.
      final bookingId = _persistedReservationId(reservation);
      if (bookingId == null) {
        throw StateError('Reservation was not persisted by the server.');
      }

      // Client-side WhatsApp/Kapso notification hook was removed: it read
      // KAPSO_API_KEY via --dart-define, which compiles as a plain string
      // into main.dart.js and is trivially recoverable via view-source on
      // a deployed PWA. It was never actually configured for any business
      // (nothing sets KAPSO_BASE/KAPSO_API_KEY) and the deployment
      // checklist already warned never to set the key. If admin
      // notifications on new bookings become a real requirement, add a
      // backend endpoint that holds the Kapso secret server-side and have
      // the client call that instead — never call a third-party
      // notification API directly from client code with an embedded key.

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderPlaced,
        arguments: {
          'title': loc.t(
            'booking_success_title',
            fallback: 'Appointment confirmed',
          ),
          'subtitle': loc.t(
            'booking_success_subtitle',
            fallback: 'Your appointment was placed successfully.',
          ),
          'buttonText': loc.t('btn_back_home', fallback: 'Back to home'),
          'backRoute': AppRoutes.home,
          'reservationId': bookingId,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc.t('booking_failed', fallback: 'Appointment failed')}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int? _persistedReservationId(Map<String, dynamic> reservation) {
    for (final key in const ['id', 'reservation_id', 'booking_id']) {
      final value = reservation[key];
      final id = value is int
          ? value
          : value is num
          ? value.toInt()
          : int.tryParse(value?.toString() ?? '');
      if (id != null && id > 0) return id;
    }
    return null;
  }

  int? _selectedStaffId() {
    final value = selectedBarber?['id'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _BarberSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback? onTap;

  const _BarberSection({
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          if (actionLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onTap, child: Text(actionLabel)),
            ),
          ],
        ],
      ),
    );
  }
}
