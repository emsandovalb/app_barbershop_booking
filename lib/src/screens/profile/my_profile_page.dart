import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final firstName = TextEditingController(text: (auth.user?['first_name'] ?? _splitFirst(auth.user?['name'] ?? '')).toString());
    final lastName = TextEditingController(text: (auth.user?['last_name'] ?? _splitLast(auth.user?['name'] ?? '')).toString());
    final email = auth.user?['email']?.toString() ?? '';
    final picker = ImagePicker();
    String? avatarPath;

    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                if (x != null) {
                  avatarPath = x.path;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image selected')));
                }
              },
              child: const CircleAvatar(radius: 36, child: Icon(Icons.person)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(controller: firstName, decoration: const InputDecoration(hintText: 'First name')),
          const SizedBox(height: 12),
          TextField(controller: lastName, decoration: const InputDecoration(hintText: 'Last name')),
          const SizedBox(height: 12),
          TextField(readOnly: true, decoration: InputDecoration(hintText: 'Email address', helperText: email)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final ok = await context.read<AuthProvider>().updateProfile(
                  firstName: firstName.text.trim(),
                  lastName: lastName.text.trim(),
                  name: '${firstName.text.trim()} ${lastName.text.trim()}'.trim(),
                  avatarPath: avatarPath);
              if (!context.mounted) return;
              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update')));
              }
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }
}

String _splitFirst(String name) => (name.split(' ')..removeWhere((e) => e.isEmpty)).isNotEmpty ? name.split(' ').first : '';
String _splitLast(String name) => (name.split(' ')..removeWhere((e) => e.isEmpty)).length > 1 ? name.split(' ').sublist(1).join(' ') : '';
