import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import '../config/white_label_config.dart';
import '../navigation/tenant_startup_route.dart';
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
      if (!kIsWeb) {
        FlutterNativeSplash.remove();
      }
      final auth = context.read<AuthProvider>();
      await auth.ready;
      if (!mounted) return;
      final target = TenantStartupRoute.forAuthentication(
        isAuthenticated: auth.isLoggedIn,
      );
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
    final whiteLabel = context.watch<WhiteLabelConfig>();

    return Scaffold(
      body: BarbershopPremiumBackdrop(
        backgroundAsset: whiteLabel.heroBackground,
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
                    assetPath: whiteLabel.logoTransparent,
                    fallbackLabel: whiteLabel.shortName,
                    size: 200,
                    glowColor: whiteLabel.primaryGold,
                  ),
                  const SizedBox(height: 18),
                  if (whiteLabel.displayName.split(' ').first.toUpperCase() !=
                      whiteLabel.shortName.toUpperCase()) ...[
                    Text(
                      whiteLabel.displayName.split(' ').first,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: .88),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    whiteLabel.shortName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: .45,
                      height: .95,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    whiteLabel.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: Colors.white.withValues(alpha: .78),
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
