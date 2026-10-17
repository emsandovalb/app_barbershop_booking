import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/keyboard_aware_list_view.dart';

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
    final loc = context.watch<LocalizationService>();
    bool isValid(String p) => RegExp(r'^(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(p);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(loc.t('change_password_title'))),
      body: KeyboardAwareListView(
        padding: const EdgeInsets.all(16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: currentCtrl,
                obscureText: obscure1,
                decoration: InputDecoration(
                  hintText: loc.t('change_password_current'),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure1 = !obscure1),
                    icon: Icon(
                      obscure1 ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newCtrl,
                obscureText: obscure2,
                decoration: InputDecoration(
                  hintText: loc.t('change_password_new'),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure2 = !obscure2),
                    icon: Icon(
                      obscure2 ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: obscure3,
                decoration: InputDecoration(
                  hintText: loc.t('change_password_confirm'),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure3 = !obscure3),
                    icon: Icon(
                      obscure3 ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.t('change_password_mismatch')),
                            ),
                          );
                          return;
                        }
                        if (!isValid(newCtrl.text)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc.t('change_password_requirements'),
                              ),
                            ),
                          );
                          return;
                        }
                        setState(() => loading = true);
                        try {
                          await context.read<AuthProvider>().api.changePassword(
                            currentPassword: currentCtrl.text,
                            newPassword: newCtrl.text,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.t('change_password_success')),
                            ),
                          );
                          Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${loc.t('change_password_failed')}: $e',
                                ),
                              ),
                            );
                          }
                        } finally {
                          if (context.mounted) setState(() => loading = false);
                        }
                      },
                child: Text(
                  loading
                      ? loc.t('change_password_updating')
                      : loc.t('change_password_submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
