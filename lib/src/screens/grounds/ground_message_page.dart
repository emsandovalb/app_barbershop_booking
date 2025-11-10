import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';

class OrderPlacedPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final String backRoute;
  const OrderPlacedPage({
    super.key,
    this.title = 'Creation Successful',
    this.subtitle = 'Congratulations, your court creation has been successful.',
    this.buttonText = 'Back to home',
    this.backRoute = AppRoutes.home,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Courts Created')),
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
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
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
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(backRoute, (r) => false),
          child: Text(buttonText),
        ),
      ),
    );
  }
}
