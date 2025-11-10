import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Playground Booking',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Reserva canchas y descubre eventos deportivos cercanos.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: const Text('Get started'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: const Text('Skip'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

