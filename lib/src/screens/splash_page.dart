import 'dart:async';
import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 1), () async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      // wait a tick for restore
      await Future.delayed(const Duration(milliseconds: 200));
      if (auth.isLoggedIn) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.sports_soccer, size: 72, color: AppColors.primary),
            SizedBox(height: 12),
            Text('Playground Booking', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
