import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/brand_theme.dart';
import '../../services/localization_service.dart';
import '../../services/api.dart';
import '../../widgets/keyboard_aware_list_view.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool isBusy = false;
  bool _obscure = true;
  bool _confirmObscure = true;
  final confirmCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<BrandTheme>();
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(),
      body: SafeArea(
        child: KeyboardAwareListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('signup_title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.t('signup_subtitle'),
                  style: TextStyle(color: Colors.white.withValues(alpha: .75)),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: firstNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: loc.t('profile_first_name'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: loc.t('profile_last_name'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: loc.t('login_email'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: loc.t('login_password'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: _confirmObscure,
                  decoration: InputDecoration(
                    hintText: loc.t('signup_confirm_password'),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _confirmObscure = !_confirmObscure),
                      icon: Icon(
                        _confirmObscure
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: const BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isBusy
                      ? null
                      : () async {
                          bool isValid(String p) =>
                              RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(p);
                          final name =
                              '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'
                                  .trim();
                          final email = normalizeEmailInput(emailCtrl.text);
                          if (name.isEmpty ||
                              email.isEmpty ||
                              passCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(loc.t('signup_complete_fields')),
                              ),
                            );
                            return;
                          }
                          if (!RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ingresa un correo electrónico válido',
                                ),
                              ),
                            );
                            return;
                          }
                          if (!isValid(passCtrl.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.t('change_password_requirements'),
                                ),
                              ),
                            );
                            return;
                          }
                          if (passCtrl.text != confirmCtrl.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  loc.t('change_password_mismatch'),
                                ),
                              ),
                            );
                            return;
                          }
                          setState(() => isBusy = true);
                          final auth = context.read<AuthProvider>();
                          final ok = await auth.register(
                            name: name,
                            email: email,
                            password: passCtrl.text,
                          );
                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.of(
                              context,
                            ).pushReplacementNamed(AppRoutes.home);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _signupErrorMessage(
                                    auth.registrationError,
                                    loc,
                                  ),
                                ),
                              ),
                            );
                          }
                          setState(() => isBusy = false);
                        },
                  child: Text(loc.t('signup_button')),
                ),

                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(
                      context,
                    ).pushReplacementNamed(AppRoutes.login),
                    child: Text(loc.t('signup_have_account')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _signupErrorMessage(String? error, LocalizationService loc) {
  final text = error?.trim() ?? '';
  final normalized = text.toLowerCase();
  if (normalized.contains('valid email')) {
    return 'Ingresa un correo electrónico válido';
  }
  if (normalized.contains('already been taken') ||
      normalized.contains('unique')) {
    return 'Ya existe una cuenta con este correo electrónico';
  }
  if (text.isNotEmpty) return text;
  return loc.t('signup_failed');
}
