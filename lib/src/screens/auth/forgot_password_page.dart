import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailCtrl = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('forgot_title', fallback: 'Forgot password'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.t('forgot_subtitle', fallback: 'Enter your email to receive reset instructions')),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: loc.t('form_email', fallback: 'Email address')),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      if (email.isEmpty) return;
                      setState(() => loading = true);
                      try {
                        await context.read<AuthProvider>().api.forgotPassword(email);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(loc.t('forgot_success', fallback: 'Check your email for instructions'))));
                        Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('${loc.t('forgot_failed', fallback: 'Failed')}: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: Text(loading ? loc.t('forgot_sending', fallback: 'Sending...') : loc.t('forgot_button', fallback: 'Send reset link')),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.resetPassword);
              },
              child: const Text('I already have a reset token'),
            ),
          ],
        ),
      ),
    );
  }
}
