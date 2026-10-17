import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/white_label_config.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/barbershop_branding.dart';
import '../../widgets/keyboard_aware_list_view.dart';

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
  late final TapGestureRecognizer _signupTapRecognizer;

  @override
  void initState() {
    super.initState();
    _signupTapRecognizer = TapGestureRecognizer()
      ..onTap = () => Navigator.of(context).pushNamed(AppRoutes.signup);
  }

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    _signupTapRecognizer.dispose();
    super.dispose();
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
                  const Color(0xFF050505).withValues(alpha: .42),
                  const Color(0xFF090909).withValues(alpha: .30),
                  const Color(0xFF050505).withValues(alpha: .62),
                ],
              ),
            ),
          ),
          Positioned(
            top: -90,
            left: -90,
            child: _GlowOrb(
              color: colors.primaryGold.withValues(alpha: .18),
              size: 240,
            ),
          ),
          Positioned(
            top: 80,
            right: -80,
            child: _GlowOrb(
              color: colors.primaryGoldDark.withValues(alpha: .14),
              size: 180,
            ),
          ),
          Positioned(
            bottom: -110,
            left: -110,
            child: _GlowOrb(
              color: Colors.white.withValues(alpha: .05),
              size: 260,
            ),
          ),
          SafeArea(
            child: KeyboardAwareListView(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushReplacementNamed(AppRoutes.home),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.primaryGoldLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      child: Text(tr('btn_skip')),
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
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: .34),
                                    Colors.black.withValues(alpha: .22),
                                    Colors.black.withValues(alpha: .32),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Skip the small overline entirely when it
                                  // would just repeat the short name below
                                  // (e.g. a business whose display name's
                                  // first word already IS its short name,
                                  // like "JC" for "JC Studio") — showing it
                                  // anyway reads as a duplicated word, not
                                  // a two-line brand lockup.
                                  if (whiteLabel.displayName
                                          .split(' ')
                                          .first
                                          .toUpperCase() !=
                                      whiteLabel.shortName.toUpperCase()) ...[
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
                                  ],
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
                                                colors.primaryGold.withValues(
                                                  alpha: .72,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
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
                                                colors.primaryGold.withValues(
                                                  alpha: .72,
                                                ),
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
                    backgroundColor: const Color(
                      0xFF120E0B,
                    ).withValues(alpha: .92),
                    borderColor: colors.primaryGoldDark.withValues(alpha: .45),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .34),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          tr('login_welcome_back'),
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
                            hintText: tr('login_email'),
                            prefixIcon: Icons.alternate_email_rounded,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: passCtrl,
                          obscureText: _obscure,
                          decoration: _inputDecoration(
                            hintText: tr('login_password'),
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
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
                            onPressed: () => Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.forgot),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              foregroundColor: colors.primaryGoldLight,
                            ),
                            child: Text(tr('login_forgot_password')),
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
                                    final ok = await context
                                        .read<AuthProvider>()
                                        .login(
                                          emailCtrl.text.trim(),
                                          passCtrl.text,
                                        );
                                    if (!context.mounted) return;
                                    if (ok) {
                                      Navigator.of(
                                        context,
                                      ).pushReplacementNamed(AppRoutes.home);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            tr('login_invalid_credentials'),
                                          ),
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
                            child: Text(
                              isBusy
                                  ? tr('login_signing_in')
                                  : tr('login_button_caps'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Center(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .88),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(text: '${tr('login_no_account')} '),
                                TextSpan(
                                  text: tr('login_sign_up_link'),
                                  style: TextStyle(
                                    color: colors.primaryGoldLight,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: colors.primaryGoldLight,
                                  ),
                                  recognizer: _signupTapRecognizer,
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}
