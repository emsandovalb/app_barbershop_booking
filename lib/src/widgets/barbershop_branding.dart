import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/colors.dart';

class BarbershopPremiumBackdrop extends StatelessWidget {
  final Widget child;
  final String? backgroundAsset;
  final double backgroundOpacity;
  final double blurSigma;
  final bool topGlow;
  final bool bottomGlow;

  const BarbershopPremiumBackdrop({
    super.key,
    required this.child,
    this.backgroundAsset,
    this.backgroundOpacity = .30,
    this.blurSigma = 16,
    this.topGlow = true,
    this.bottomGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF050505),
            Color(0xFF0E0A08),
            Color(0xFF090909),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundAsset != null)
            Positioned.fill(
              child: Opacity(
                opacity: backgroundOpacity,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blurSigma,
                    sigmaY: blurSigma,
                  ),
                  child: Image.asset(
                    backgroundAsset!,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF050505).withOpacity(.94),
                    const Color(0xFF090909).withOpacity(.66),
                    const Color(0xFF090909).withOpacity(.94),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          if (topGlow)
            Positioned(
              top: -120,
              left: -80,
              child: _GlowBlob(
                size: 280,
                color: AppColors.primary.withOpacity(.18),
              ),
            ),
          if (topGlow)
            Positioned(
              top: 60,
              right: -90,
              child: _GlowBlob(
                size: 220,
                color: const Color(0xFFB77A3E).withOpacity(.14),
              ),
            ),
          if (bottomGlow)
            Positioned(
              bottom: -110,
              left: -120,
              child: _GlowBlob(
                size: 300,
                color: Colors.white.withOpacity(.05),
              ),
            ),
          if (bottomGlow)
            Positioned(
              bottom: 40,
              right: -100,
              child: _GlowBlob(
                size: 240,
                color: AppColors.primary.withOpacity(.12),
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _PremiumTexturePainter(),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class BarbershopCinematicPanel extends StatelessWidget {
  final String backgroundAsset;
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double opacity;
  final double blurSigma;

  const BarbershopCinematicPanel({
    super.key,
    required this.backgroundAsset,
    required this.child,
    this.radius = 28,
    this.padding = const EdgeInsets.all(18),
    this.opacity = .45,
    this.blurSigma = 4,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Image.asset(backgroundAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF070707).withOpacity(.92),
                    const Color(0xFF12100E).withOpacity(.82),
                    const Color(0xFF070707).withOpacity(.92),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(.40),
                  ],
                  radius: .92,
                  center: Alignment.center,
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class BarbershopLogoMark extends StatelessWidget {
  final String assetPath;
  final double size;
  final double glowSize;
  final Color glowColor;
  final bool showGlow;

  const BarbershopLogoMark({
    super.key,
    required this.assetPath,
    this.size = 160,
    this.glowSize = 1.0,
    this.glowColor = AppColors.primary,
    this.showGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.content_cut,
        color: Colors.white.withOpacity(.92),
        size: size * .30,
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showGlow)
            IgnorePointer(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 18 * glowSize,
                  sigmaY: 18 * glowSize,
                ),
                child: Opacity(
                  opacity: .18,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      glowColor.withOpacity(.65),
                      BlendMode.srcIn,
                    ),
                    child: SizedBox(
                      width: size * .96,
                      height: size * .96,
                      child: logo,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: size,
            height: size,
            child: logo,
          ),
        ],
      ),
    );
  }
}

class BarbershopPremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  const BarbershopPremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF120E0B),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? Colors.white.withOpacity(.06)),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
      ),
      child: child,
    );
  }
}

class PremiumBadge extends StatelessWidget {
  final String label;
  final bool compact;

  const PremiumBadge({
    super.key,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withOpacity(.30)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onTap;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: .2,
          ),
        ),
        if (actionLabel != null && onTap != null)
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: AppColors.secondary.withOpacity(.95),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _PremiumTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.025)
      ..strokeWidth = 1;
    const step = 34.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
