import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../navigation/app_router.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);

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

    return Scaffold(
      backgroundColor: brand.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  brand.backgroundColor,
                  brand.primaryColor.withOpacity(0.28),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final scale = 1.0 + (_controller.value * 0.04);
                return Transform.scale(scale: scale, child: child);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _BrandMark(brand: brand),
                  const SizedBox(height: 16),
                  Text(
                    brand.appName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Premium barbershop appointments',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.78),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  final BrandConfig brand;

  const _BrandMark({required this.brand});

  @override
  Widget build(BuildContext context) {
    final asset = brand.splashAsset?.isNotEmpty == true ? brand.splashAsset : brand.logoAsset;
    if (asset != null && asset.isNotEmpty) {
      return Image.asset(
        asset,
        width: 120,
        height: 120,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _FallbackMark(color: brand.primaryColor),
      );
    }
    return _FallbackMark(color: brand.primaryColor);
  }
}

class _FallbackMark extends StatelessWidget {
  final Color color;

  const _FallbackMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.95),
                  color.withOpacity(0.3),
                ],
              ),
            ),
          ),
          const Icon(Icons.content_cut, color: Colors.white, size: 48),
        ],
      ),
    );
  }
}
