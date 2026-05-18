import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../services/localization_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final emailCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool loading = false;
  bool obscurePassword = true;
  bool obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.t('reset_password_title', fallback: 'Reset password')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t(
                'reset_password_subtitle',
                fallback: 'Enter your email, the reset token from your email, and a new password.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: loc.t('form_email', fallback: 'Email address'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: tokenCtrl,
              decoration: InputDecoration(
                hintText: loc.t('reset_password_token', fallback: 'Reset token'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordCtrl,
              obscureText: obscurePassword,
              decoration: InputDecoration(
                hintText: loc.t('reset_password_new', fallback: 'New password'),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: obscureConfirm,
              decoration: InputDecoration(
                hintText: loc.t('reset_password_confirm', fallback: 'Confirm new password'),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                  icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final email = emailCtrl.text.trim();
                      final token = tokenCtrl.text.trim();
                      final password = passwordCtrl.text;
                      final confirm = confirmCtrl.text;

                      if (!email.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.t(
                                'reset_password_invalid_email',
                                fallback: 'Please enter a valid email address.',
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (token.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.t(
                                'reset_password_token_required',
                                fallback: 'Reset token is required.',
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (password.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.t(
                                'reset_password_too_short',
                                fallback: 'Password must be at least 6 characters.',
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      if (password != confirm) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.t(
                                'reset_password_mismatch',
                                fallback: 'Passwords do not match.',
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      setState(() => loading = true);
                      try {
                        await context.read<AuthProvider>().api.resetPassword(
                              email: email,
                              token: token,
                              password: password,
                              passwordConfirmation: confirm,
                            );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc.t(
                                'reset_password_success',
                                fallback: 'Password reset successfully. You can now log in with your new password.',
                              ),
                            ),
                          ),
                        );
                        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                      } on ApiException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${loc.t('reset_password_failed', fallback: 'Failed to reset password')}: ${e.message}',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${loc.t('reset_password_failed', fallback: 'Failed to reset password')}: $e',
                            ),
                          ),
                        );
                      } finally {
                        if (mounted) {
                          setState(() => loading = false);
                        }
                      }
                    },
              child: Text(
                loading
                    ? loc.t('reset_password_submitting', fallback: 'Resetting...')
                    : loc.t('reset_password_submit', fallback: 'Reset password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
