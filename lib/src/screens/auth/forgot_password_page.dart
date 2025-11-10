import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your email to receive reset instructions'),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Email address'),
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
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email for instructions')));
                        Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: Text(loading ? 'Sending...' : 'Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}

