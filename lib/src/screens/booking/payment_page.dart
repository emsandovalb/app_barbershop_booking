import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _tile('Google pay', 'gpay'),
          const Divider(height: 1, color: Colors.white24),
          _tile('Paypal', 'paypal'),
          const Divider(height: 1, color: Colors.white24),
          _tile('Cash', 'cash'),
          const SizedBox(height: 16),
          Row(children: const [
            Icon(Icons.add, color: Colors.white),
            SizedBox(width: 8),
            Text('Add new card', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ])
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: loading ? null : _confirm,
          child: Text(loading ? 'Processing...' : 'Continue'),
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
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in to complete booking')));
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
      await auth.api.createBookingWithDuration(
        courtId: court['id'] as int,
        date: iso,
        timeSlot: slot,
        durationHours: duration,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.orderPlaced,
        arguments: {
          'title': 'Booking Successful',
          'subtitle': 'Your booking was placed successfully. Note: Cancellations must be made at least 24 hours before the start time.',
          'buttonText': 'Back to home',
          'backRoute': AppRoutes.home,
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}
