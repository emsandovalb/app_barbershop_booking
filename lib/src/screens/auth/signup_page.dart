import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';

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
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sign up',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Please enter your name, email address and password details to sign up',
                style: TextStyle(color: Colors.white.withOpacity(.75)),
              ),
              const SizedBox(height: 24),

              TextField(
                controller: firstNameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'First name',
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
                  hintText: 'Last name',
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
                  hintText: 'Email',
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
                  hintText: 'Password',
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
                  hintText: 'Confirm password',
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
                            const SnackBar(content: Text('Please complete all fields')),
                          );
                          return;
                        }
                        if (!isValid(passCtrl.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password must be at least 8 characters, include an uppercase letter and a number')),
                          );
                          return;
                        }
                        if (passCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Passwords do not match')),
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign up failed')),
                          );
                        }
                        setState(() => isBusy = false);
                      },
                child: const Text('Sign up'),
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                  child: const Text('Already have an account? Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
