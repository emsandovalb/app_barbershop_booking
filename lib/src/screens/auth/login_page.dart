import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../theme/colors.dart';

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

  void _notImplemented(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what not implemented yet')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.home),
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Log in',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // App logo (shows your PNG without extra background)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c2, e2, s2) => Container(
                          color: AppColors.black30,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.calendar_month,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Text(
                'Please enter your email address and password details to login',
                style: TextStyle(color: Colors.white.withOpacity(.75)),
              ),
              const SizedBox(height: 24),

              // Email
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
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
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Password
              TextField(
                controller: passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Password',
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
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.forgot),
                  child: const Text('Forgot password?'),
                ),
              ),

              const SizedBox(height: 6),
              // Login button (email/password)
              ElevatedButton(
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
                          Navigator.of(
                            context,
                          ).pushReplacementNamed(AppRoutes.home);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incorrect email or password')),
                          );
                        }
                        setState(() => isBusy = false);
                      },
                child: const Text('Log in'),
              ),

              const SizedBox(height: 16),

              // Divider: or continue with
              Row(
                children: [
                  Expanded(child: Container(height: 1, color: AppColors.black30)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or continue with', style: TextStyle(color: Colors.white.withOpacity(.7))),
                  ),
                  Expanded(child: Container(height: 1, color: AppColors.black30)),
                ],
              ),
              const SizedBox(height: 12),

              // Social sign-in buttons (placeholders)
              Column(
                children: [
                  _SocialButton(
                    label: 'Continue with Google',
                    assetPath: 'assets/icons/google.png',
                    onTap: () => _notImplemented(context, 'Google Sign-In'),
                  ),
                  const SizedBox(height: 8),
                  _SocialButton(
                    label: 'Continue with Facebook',
                    assetPath: 'assets/icons/facebook.png',
                    onTap: () => _notImplemented(context, 'Facebook Login'),
                  ),
                  const SizedBox(height: 8),
                  _SocialButton(
                    label: 'Continue with Apple / Face ID',
                    assetPath: 'assets/icons/apple.png',
                    onTap: () => _notImplemented(context, 'Apple / Face ID'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.signup),
                  child: const Text("Don't have an account? Sign up"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String assetPath;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.assetPath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        minimumSize: const Size.fromHeight(48),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Image.asset(
              assetPath,
              width: 20,
              height: 20,
              errorBuilder: (c, e, s) => const Icon(Icons.login, size: 20),
            ),
          ),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}
