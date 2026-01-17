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
    // Show GIF ~3s then route
    Future<void>.delayed(const Duration(seconds: 3)).then((_) async {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      // give a tiny moment for auth restore
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
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
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Image.asset(
          'assets/splash/branding.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
