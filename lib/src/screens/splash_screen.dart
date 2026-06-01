import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../navigation/app_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/barbershop_branding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FlutterNativeSplash.remove();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final target = auth.isLoggedIn ? AppRoutes.home : AppRoutes.onboarding;
      Navigator.of(context).pushReplacementNamed(target);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final brand = config.brand;
    final logo = brand.splashAsset?.isNotEmpty == true
        ? brand.splashAsset!
        : brand.logoAsset ?? 'assets/branding/logo_transparent.png';

    return Scaffold(
      body: BarbershopPremiumBackdrop(
        backgroundAsset: 'assets/branding/barbershop_hero_bg.png',
        backgroundOpacity: .24,
        blurSigma: 20,
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final scale = 1.0 + (_controller.value * 0.022);
                return Transform.scale(scale: scale, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BarbershopLogoMark(
                    assetPath: logo,
                    size: 200,
                    glowColor: brand.primaryColor,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'BARBERÍA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(.88),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'TRES AMIGOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .45,
                      height: .95,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cortes, barba y experiencias premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: Colors.white.withOpacity(.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

