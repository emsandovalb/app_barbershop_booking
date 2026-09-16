import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'barber_picker_bottom_sheet.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> args;
  const PaymentPage({super.key, required this.args});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = 'card';
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
    final config = context.watch<AppConfig>();
    final whiteLabel = context.watch<WhiteLabelConfig>();
    final service = Map<String, dynamic>.from(
      (widget.args['resource'] as Map<String, dynamic>?) ??
          (widget.args['court'] as Map<String, dynamic>?) ??
          const {},
    );
    final showBarberSelection =
        config.features.reservationStaffSelection && service['id'] != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('payment_title', fallback: 'Confirmar cita')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(loc.t('payment_method_card', fallback: 'Tarjeta'), 'card'),
          const Divider(height: 1, color: Colors.white24),
          _tile('PayPal', 'paypal'),
          const Divider(height: 1, color: Colors.white24),
          _tile(loc.t('payment_method_cash', fallback: 'Efectivo'), 'cash'),
          if (showBarberSelection) ...[
            const SizedBox(height: 16),
            _BarberSection(
              title: loc.t('booking_barber_title', fallback: 'Barber'),
              subtitle: selectedBarber == null
                  ? loc.t(
                      'booking_barber_optional',
                      fallback:
                          'Sin ${whiteLabel.staffDisplayName} seleccionado',
                    )
                  : (selectedBarber?['name']?.toString() ??
                        loc.t(
                          'booking_barber_selected',
                          fallback:
                              '${whiteLabel.staffDisplayName} seleccionado',
                        )),
              actionLabel: loc.t(
                'booking_barber_choose',
                fallback: 'Elegir ${whiteLabel.staffDisplayName}',
              ),
              onTap: loading ? null : () => _pickBarber(service),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.add, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                loc.t('payment_add_card', fallback: 'Add new card'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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

  Widget _tile(String title, String value) {
    final selected = method == value;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.payment),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? Colors.white : Colors.white54,
      ),
      onTap: () => setState(() => method = value),
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
      final duration =
          widget.args['duration'] as int? ??
          widget.args['duration_hours'] as int? ??
          1;
      final staffId = _selectedStaffId();

      // A staff map without an id must never silently become an unassigned
      // reservation after crossing the booking routes.
      if (selectedBarber != null && staffId == null) {
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
        'duration': duration,
        if (staffId != null) 'staff_id': staffId,
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

  Future<void> _pickBarber(Map<String, dynamic> service) async {
    final serviceId = service['id'] as int?;
    if (serviceId == null) return;

    final picked = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BarberPickerBottomSheet(serviceId: serviceId),
    );

    if (!mounted) return;
    setState(() {
      selectedBarber = picked == null
          ? null
          : Map<String, dynamic>.from(picked);
    });
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
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onTap, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
