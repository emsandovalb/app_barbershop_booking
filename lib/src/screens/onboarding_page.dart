import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import '../services/localization_service.dart';
import 'package:provider/provider.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                'Bamos Al Fut',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                loc.t('onboarding_tagline', fallback: 'Reserva canchas y descubre eventos deportivos cercanos.'),
                style: TextStyle(
                  color: Colors.white.withOpacity(.75),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                child: Text(loc.t('onboarding_get_started', fallback: 'Get started')),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                child: Text(loc.t('onboarding_skip', fallback: 'Skip')),
              )
            ],
          ),
        ),
      ),
    );
  }
}
