import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/kapso_notifier.dart';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final config = context.watch<AppConfig>();
    final service = Map<String, dynamic>.from(
      (widget.args['resource'] as Map<String, dynamic>?) ??
          (widget.args['court'] as Map<String, dynamic>?) ??
          const {},
    );
    final showBarberSelection =
        config.features.reservationStaffSelection && service['id'] != null;

    return Scaffold(
      appBar: AppBar(title: Text(loc.t('payment_title', fallback: 'Payment'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(loc.t('payment_method_card', fallback: 'Card'), 'card'),
          const Divider(height: 1, color: Colors.white24),
          _tile('PayPal', 'paypal'),
          const Divider(height: 1, color: Colors.white24),
          _tile(loc.t('payment_method_cash', fallback: 'Cash'), 'cash'),
          if (showBarberSelection) ...[
            const SizedBox(height: 16),
            _BarberSection(
              title: loc.t('booking_barber_title', fallback: 'Barber'),
              subtitle: selectedBarber == null
                  ? loc.t(
                      'booking_barber_optional',
                      fallback: 'No barber selected',
                    )
                  : (selectedBarber?['name']?.toString() ??
                        loc.t(
                          'booking_barber_selected',
                          fallback: 'Barber selected',
                        )),
              actionLabel: loc.t(
                'booking_barber_choose',
                fallback: 'Choose barber',
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
                ? loc.t('payment_processing', fallback: 'Processing...')
                : loc.t('btn_continue', fallback: 'Continue'),
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

    try {
      final created = await auth.api.createReservation({
        'resource_id': service['id'],
        'date': iso,
        'time_slot': slot,
        'duration': duration,
        if (selectedBarber != null) 'staff_id': selectedBarber?['id'],
      });

      // Legacy notification hook stays in place while the generic backend contract is still in use.
      try {
        const admin = String.fromEnvironment('ADMIN_CONTACT');
        final kapso = KapsoNotifier.fromEnv();
        if (kapso != null && admin.isNotEmpty) {
          final user = auth.user ?? const {};
          kapso
              .sendReservation(
                adminRecipient: admin,
                payload: {
                  'court_id': service['id'],
                  'resource_id': service['id'],
                  'court_name': service['name'],
                  'resource_name': service['name'],
                  'date': iso,
                  'time_slot': slot,
                  'duration_hours': duration,
                  if (selectedBarber != null) 'staff_id': selectedBarber?['id'],
                  if (selectedBarber != null) 'staff': selectedBarber,
                  'user_id': user['id'],
                  'user_name': user['name'],
                  'user_email': user['email'],
                  'booking': created,
                  'reservation': created,
                },
              )
              .catchError((_) {});
        }
      } catch (_) {
        // Ignore notification errors in the base app.
      }

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
