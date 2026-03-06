import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../navigation/app_router.dart';
import '../providers/auth_provider.dart';
import '../theme/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _AnimatedBall extends StatelessWidget {
  const _AnimatedBall({
    required this.verticalOffset,
    required this.baseRotation,
    required this.rollShift,
    required this.rollSpin,
    required this.size,
    required this.image,
  });

  final Animation<double> verticalOffset;
  final Animation<double> baseRotation;
  final Animation<double> rollShift;
  final Animation<double> rollSpin;
  final double size;
  final ImageProvider image;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([verticalOffset, baseRotation, rollShift, rollSpin]),
      builder: (context, child) {
        final turns = baseRotation.value + rollSpin.value;
        return Transform.translate(
          offset: Offset(rollShift.value, verticalOffset.value),
          child: Transform.rotate(
            angle: turns * 2 * math.pi,
            child: child,
          ),
        );
      },
      child: Image(
        image: image,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _verticalOffset;
  late final Animation<double> _rotationTurns;
  late final Animation<double> _rollShift;
  late final Animation<double> _rollSpin;
  final AssetImage _grassTexture = const AssetImage('assets/images/grass.png');
  final AssetImage _ballImage = const AssetImage('assets/images/ball_logo.png');
  bool _assetsReady = false;

  static const _totalDuration = Duration(milliseconds: 2300);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);
    _verticalOffset = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -220, end: 0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -60).chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -60, end: 0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 12,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -25).chain(CurveTween(curve: Curves.easeOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -25, end: 0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 6,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(0), weight: 19),
    ]).animate(_controller);

    _rotationTurns = Tween<double>(begin: -0.12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    final rollInterval = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.82, 1.0, curve: Curves.easeOut),
    );

    _rollSpin = Tween<double>(begin: 0, end: 1).animate(rollInterval);
    _rollShift = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 18).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: 0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(rollInterval);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        precacheImage(_grassTexture, context),
        precacheImage(_ballImage, context),
      ]);
      FlutterNativeSplash.remove();
      if (!mounted) return;
      setState(() {
        _assetsReady = true;
      });
      _controller.forward();
    });
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed && mounted) {
        final auth = context.read<AuthProvider>();
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        final target = auth.isLoggedIn ? AppRoutes.home : AppRoutes.onboarding;
        Navigator.of(context).pushReplacementNamed(target);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ballSize = size.width * 0.22;
    final headingStyle = const TextStyle(
      fontSize: 52,
      fontWeight: FontWeight.w800,
      letterSpacing: 6,
      color: Colors.white,
    );

    if (!_assetsReady) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox.expand(),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image(
              image: _grassTexture,
              fit: BoxFit.cover,
              colorBlendMode: BlendMode.multiply,
              color: Colors.black.withOpacity(0.22),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.45),
                    AppColors.primary.withOpacity(0.25),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('BAM', style: headingStyle),
                    SizedBox(width: ballSize * 0.15),
                    SizedBox(
                      width: ballSize,
                      height: ballSize,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            bottom: -ballSize * 0.28,
                            child: Container(
                              width: ballSize * 0.9,
                              height: ballSize * 0.25,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(ballSize),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.45),
                                    blurRadius: 30,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _AnimatedBall(
                            verticalOffset: _verticalOffset,
                            baseRotation: _rotationTurns,
                            rollShift: _rollShift,
                            rollSpin: _rollSpin,
                            size: ballSize,
                            image: _ballImage,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('S', style: headingStyle),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'AL FUT',
                  style: headingStyle.copyWith(fontSize: 44, letterSpacing: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
