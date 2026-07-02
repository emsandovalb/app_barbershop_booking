import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/barbershop_branding.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isBusy = false;
  bool _obscure = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  void _notImplemented(BuildContext context, String what) {
    final loc = context.read<LocalizationService>();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loc.t(
            'feature_not_implemented',
            fallback: '{feature} not implemented yet',
          ).replaceFirst('{feature}', what),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, size: 22),
      prefixIconConstraints: const BoxConstraints(minWidth: 54),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final whiteLabel = context.watch<WhiteLabelConfig>();
    final colors = whiteLabel.colors;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1),
            child: Image.asset(
              whiteLabel.heroBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050505).withOpacity(.42),
                  const Color(0xFF090909).withOpacity(.30),
                  const Color(0xFF050505).withOpacity(.62),
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -90,
            child: _GlowOrb(color: colors.primaryGold.withOpacity(.18), size: 240),
          ),
          Positioned(
            top: 80,
            right: -80,
            child: _GlowOrb(
              color: colors.primaryGoldDark.withOpacity(.14),
              size: 180,
            ),
          ),
          Positioned(
            bottom: -110,
            left: -110,
            child: _GlowOrb(color: Colors.white.withOpacity(.05), size: 260),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.home),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primaryGoldLight,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      child: const Text('Omitir'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        BarbershopLogoMark(
                          assetPath: whiteLabel.logoTransparent,
                          size: 172,
                          glowColor: colors.primaryGold,
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(.34),
                                    Colors.black.withOpacity(.22),
                                    Colors.black.withOpacity(.32),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    whiteLabel.displayName.split(' ').first,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: colors.primaryGold,
                                      height: 1.0,
                                      letterSpacing: .7,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    whiteLabel.shortName.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 31,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      height: 1.0,
                                      letterSpacing: .8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                colors.primaryGold.withOpacity(.72),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          whiteLabel.subtitle.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: colors.primaryGoldLight,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.15,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colors.primaryGold.withOpacity(.72),
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  BarbershopPremiumCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                    radius: 30,
                    backgroundColor: const Color(0xFF120E0B).withOpacity(.92),
                    borderColor: colors.primaryGoldDark.withOpacity(.45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.34),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Bienvenido de nuevo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.primaryGoldLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration(
                            hintText: 'Correo electrónico',
                            prefixIcon: Icons.alternate_email_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passCtrl,
                          obscureText: _obscure,
                          decoration: _inputDecoration(
                            hintText: 'Contraseña',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.forgot),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: colors.primaryGoldLight,
                            ),
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),
                        const SizedBox(height: 0),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isBusy
                                ? null
                                : () async {
                                    setState(() => isBusy = true);
                                    final ok = await context.read<AuthProvider>().login(
                                      emailCtrl.text.trim(),
                                      passCtrl.text,
                                    );
                                    if (!mounted) return;
                                    if (ok) {
                                      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Correo o contraseña incorrectos'),
                                        ),
                                      );
                                    }
                                    setState(() => isBusy = false);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primaryGoldLight,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .8,
                              ),
                            ),
                            child: Text(isBusy ? 'INICIANDO...' : 'INICIAR SESIÓN'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _SocialDivider(
                          label: 'O CONTINUAR CON',
                          lineColor: colors.primaryGoldDark,
                          textColor: colors.primaryGoldLight,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _SocialButton(
                                label: 'Google',
                                icon: const _GoogleBrandIcon(),
                                borderColor: colors.primaryGold.withOpacity(.52),
                                onTap: () => _notImplemented(context, 'Google Sign-In'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SocialButton(
                                label: 'Facebook',
                                icon: const FaIcon(
                                  FontAwesomeIcons.facebookF,
                                  color: Color(0xFF1877F2),
                                  size: 20,
                                ),
                                borderColor: colors.primaryGold.withOpacity(.52),
                                onTap: () => _notImplemented(context, 'Facebook Login'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _SocialButton(
                                label: 'Apple',
                                icon: const FaIcon(
                                  FontAwesomeIcons.apple,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                borderColor: colors.primaryGold.withOpacity(.52),
                                onTap: () => _notImplemented(context, 'Apple / Face ID'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withOpacity(.88),
                                fontSize: 14,
                              ),
                              children: [
                                const TextSpan(text: '¿No tienes cuenta? '),
                                TextSpan(
                                  text: 'Regístrate',
                                  style: TextStyle(
                                    color: colors.primaryGoldLight,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  final Color borderColor;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFF15100D),
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: Center(child: icon)),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialDivider extends StatelessWidget {
  final String label;
  final Color lineColor;
  final Color textColor;

  const _SocialDivider({
    required this.label,
    required this.lineColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  lineColor.withOpacity(.55),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
              fontSize: 11,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  lineColor.withOpacity(.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleBrandIcon extends StatelessWidget {
  const _GoogleBrandIcon();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/social/google.svg',
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
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
