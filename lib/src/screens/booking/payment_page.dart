import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/kapso_notifier.dart';
import '../../navigation/app_router.dart';
import '../../services/localization_service.dart';

class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> args;
  const PaymentPage({super.key, required this.args});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String method = 'gpay';
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('payment_title', fallback: 'Payment'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile(loc.t('payment_method_gpay', fallback: 'Google Pay'), 'gpay'),
          const Divider(height: 1, color: Colors.white24),
          _tile('Paypal', 'paypal'),
          const Divider(height: 1, color: Colors.white24),
          _tile(loc.t('payment_method_cash', fallback: 'Cash'), 'cash'),
          const SizedBox(height: 16),
          Row(children: [
            const Icon(Icons.add, color: Colors.white),
            const SizedBox(width: 8),
            Text(loc.t('payment_add_card', fallback: 'Add new card'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ])
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: loading ? null : _confirm,
          child: Text(loading ? loc.t('payment_processing', fallback: 'Processing...') : loc.t('btn_continue', fallback: 'Continue')),
        ),
      ),
    );
  }

  Widget _tile(String title, String value) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF282828), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.payment)),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      trailing: Radio<String>(value: value, groupValue: method, onChanged: (v) => setState(() => method = v!)),
      onTap: () => setState(() => method = value),
    );
  }

  Future<void> _confirm() async {
    final loc = context.read<LocalizationService>();
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loc.t('payment_login_required', fallback: 'Please log in to complete booking'))));
        Navigator.of(context).pushNamed(AppRoutes.login);
      }
      return;
    }
    setState(() => loading = true);
    final court = widget.args['court'] as Map<String, dynamic>;
    final iso = widget.args['iso'] as String;
    final slot = widget.args['slot'] as String;
    final duration = widget.args['duration_hours'] as int? ?? 1;
    try {
      final created = await auth.api.createBookingWithDuration(
        courtId: court['id'] as int,
        date: iso,
        timeSlot: slot,
        durationHours: duration,
      );
      // Fire-and-forget admin notification (if Kapso env is configured)
      try {
        const admin = String.fromEnvironment('ADMIN_CONTACT');
        final kapso = KapsoNotifier.fromEnv();
        if (kapso != null && admin.isNotEmpty) {
          final user = auth.user ?? const {};
          kapso
              .sendReservation(
            adminRecipient: admin,
            payload: {
              'court_id': court['id'],
              'court_name': court['name'],
              'date': iso,
              'time_slot': slot,
              'duration_hours': duration,
              'user_id': user['id'],
              'user_name': user['name'],
              'user_email': user['email'],
              'booking': created,
            },
          )
              .catchError((_) {});
        } else {
          // ignore: avoid_print
          assert(() { print('[Kapso] Not configured or missing ADMIN_CONTACT.'); return true; }());
        }
      } catch (_) {
        // ignore notification errors
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderPlaced,
        arguments: {
          'title': loc.t('booking_success_title', fallback: 'Booking Successful'),
          'subtitle': loc.t(
            'booking_success_subtitle',
            fallback: 'Your booking was placed successfully. Note: Cancellations must be made at least 24 hours before the start time.',
          ),
          'buttonText': loc.t('btn_back_home', fallback: 'Back to home'),
          'backRoute': AppRoutes.home,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('${loc.t('booking_failed', fallback: 'Booking failed')}: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
