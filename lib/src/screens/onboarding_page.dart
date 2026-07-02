import 'package:flutter/material.dart';

import '../config/white_label_config.dart';
import '../navigation/app_router.dart';
import '../widgets/barbershop_branding.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final whiteLabel = WhiteLabelConfig.tresAmigos;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              whiteLabel.heroBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF050505).withValues(alpha: .18),
                    const Color(0xFF050505).withValues(alpha: .06),
                    const Color(0xFF050505).withValues(alpha: .72),
                  ],
                  stops: const [0.0, 0.46, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.10),
                  radius: .82,
                  colors: [
                    whiteLabel.primaryGold.withValues(alpha: .09),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF090909).withValues(alpha: .22),
                    const Color(0xFF090909).withValues(alpha: .52),
                  ],
                  stops: const [0.0, 0.38, 0.76, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          BarbershopLogoMark(
                            assetPath: whiteLabel.logoTransparent,
                            size: 232,
                            glowSize: .75,
                            glowColor: whiteLabel.primaryGold,
                            showGlow: true,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            whiteLabel.displayName.split(' ').first,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(
                                0xFFF5E9C8,
                              ).withValues(alpha: .92),
                              letterSpacing: 3.0,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            whiteLabel.shortName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.0,
                              height: .95,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            whiteLabel.tagline.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: whiteLabel.primaryGold,
                              letterSpacing: 2.4,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.login),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: whiteLabel.primaryGold,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            child: const Text('COMENZAR'),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.home),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF1E6D0),
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.8,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('OMITIR'),
                        ),
                      ],
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
