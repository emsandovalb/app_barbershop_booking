import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final currentCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  bool obscure1 = true;
  bool obscure2 = true;
  bool obscure3 = true;

  @override
  Widget build(BuildContext context) {
    bool isValid(String p) => RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(p);
    return Scaffold(
      appBar: AppBar(title: const Text('Change password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: obscure1,
              decoration: InputDecoration(
                hintText: 'Current password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure1 = !obscure1),
                  icon: Icon(obscure1 ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: obscure2,
              decoration: InputDecoration(
                hintText: 'New password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure2 = !obscure2),
                  icon: Icon(obscure2 ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmCtrl,
              obscureText: obscure3,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure3 = !obscure3),
                  icon: Icon(obscure3 ? Icons.visibility_off : Icons.visibility),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (newCtrl.text != confirmCtrl.text) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                        return;
                      }
                      if (!isValid(newCtrl.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password must be at least 8 characters, include an uppercase letter and a number')),
                        );
                        return;
                      }
                      setState(() => loading = true);
                      try {
                        await context.read<AuthProvider>().api.changePassword(
                              currentPassword: currentCtrl.text,
                              newPassword: newCtrl.text,
                            );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated')));
                        Navigator.pop(context);
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      } finally {
                        if (mounted) setState(() => loading = false);
                      }
                    },
              child: Text(loading ? 'Updating...' : 'Update password'),
            ),
          ],
        ),
      ),
    );
  }
}
