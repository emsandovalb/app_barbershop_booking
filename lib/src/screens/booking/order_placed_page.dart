import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

class OrderPlacedPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String backRoute;
  const OrderPlacedPage({
    super.key,
    this.title = 'Booking Successful',
    this.subtitle = 'Congratulations, your booking for service has been successful comfortably at your home',
    this.buttonText = 'Back to home',
    this.backRoute = AppRoutes.home,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('order_placed_title', fallback: 'Order placed'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFF0e795d),
              child: Icon(Icons.check, size: 42, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(title.isNotEmpty ? title : loc.t('booking_success_title', fallback: 'Booking Successful'),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle.isNotEmpty
                    ? subtitle
                    : loc.t(
                        'booking_success_subtitle',
                        fallback: 'Your booking was placed successfully. Note: Cancellations must be made at least 24 hours before the start time.',
                      ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () => _handleAction(context),
          child: Text(buttonText.isNotEmpty ? buttonText : loc.t('btn_back_home', fallback: 'Back to home')),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context) {
    final navigator = Navigator.of(context);
    var found = false;
    navigator.popUntil((route) {
      final match = route.settings.name == backRoute;
      if (match) {
        found = true;
      }
      return match || route.isFirst;
    });
    if (!found) {
      navigator.pushReplacementNamed(backRoute);
    }
  }
}
