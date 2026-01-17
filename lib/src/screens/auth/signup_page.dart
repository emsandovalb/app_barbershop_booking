import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';
import '../../services/localization_service.dart';

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
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.t('signup_title', fallback: 'Sign up'),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                loc.t('signup_subtitle', fallback: 'Please enter your name, email address and password details to sign up'),
                style: TextStyle(color: Colors.white.withOpacity(.75)),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: firstNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: loc.t('profile_first_name', fallback: 'First name'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: lastNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: loc.t('profile_last_name', fallback: 'Last name'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: loc.t('login_email', fallback: 'Email'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: loc.t('login_password', fallback: 'Password'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: _confirmObscure,
                decoration: InputDecoration(
                  hintText: loc.t('signup_confirm_password', fallback: 'Confirm password'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _confirmObscure = !_confirmObscure),
                    icon: Icon(_confirmObscure ? Icons.visibility_off : Icons.visibility),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.transparent),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () async {
                        bool isValid(String p) => RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(p);
                        final name = '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}'.trim();
                        if (name.isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.t('signup_complete_fields', fallback: 'Please complete all fields'))),
                          );
                          return;
                        }
                        if (!isValid(passCtrl.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(loc.t('change_password_requirements',
                                    fallback: 'Password must be at least 8 characters, include an uppercase letter and a number'))),
                          );
                          return;
                        }
                        if (passCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(loc.t('change_password_mismatch', fallback: 'Passwords do not match'))),
                          );
                          return;
                        }
                        setState(() => isBusy = true);
                        final ok = await context.read<AuthProvider>().register(
                              name: name,
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text,
                            );
                        if (!mounted) return;
                        if (ok) {
                          Navigator.of(context).pushReplacementNamed(AppRoutes.home);
                        } else {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(loc.t('signup_failed', fallback: 'Sign up failed'))));
                        }
                        setState(() => isBusy = false);
                      },
                child: Text(loc.t('signup_button', fallback: 'Sign up')),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                  child: Text(loc.t('signup_have_account', fallback: 'Already have an account? Log in')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
