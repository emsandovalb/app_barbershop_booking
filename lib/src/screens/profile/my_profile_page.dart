import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/keyboard_aware_list_view.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late String _email;
  String? _avatarDataUri;
  String? _existingAvatar;
  bool _saving = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _firstName = TextEditingController(
      text: (auth.user?['first_name'] ?? _splitFirst(auth.user?['name'] ?? ''))
          .toString(),
    );
    _lastName = TextEditingController(
      text: (auth.user?['last_name'] ?? _splitLast(auth.user?['name'] ?? ''))
          .toString(),
    );
    _email = auth.user?['email']?.toString() ?? '';
    final rawAvatar = (auth.user?['avatar_url'] ?? auth.user?['avatar'])
        ?.toString();
    _existingAvatar = auth.api.resolveAssetUrl(rawAvatar);
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final imageProvider = _avatarDataUri != null
        ? MemoryImage(base64Decode(_avatarDataUri!.split(',').last))
              as ImageProvider
        : (_existingAvatar != null && _existingAvatar!.isNotEmpty
              ? NetworkImage(_existingAvatar!)
              : null);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(loc.t('profile_my_profile', fallback: 'My profile')),
      ),
      body: KeyboardAwareListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: CircleAvatar(
                radius: 42,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.content_cut_outlined, size: 36)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _firstName,
            decoration: InputDecoration(
              hintText: loc.t('profile_first_name', fallback: 'First name'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _lastName,
            decoration: InputDecoration(
              hintText: loc.t('profile_last_name', fallback: 'Last name'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            readOnly: true,
            decoration: InputDecoration(
              hintText: loc.t('profile_email', fallback: 'Email address'),
              helperText: _email,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saving ? null : () => _save(loc),
            child: Text(
              _saving
                  ? loc.t('btn_saving', fallback: 'Saving...')
                  : loc.t('btn_save', fallback: 'Save'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final loc = context.read<LocalizationService>();
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (!mounted) return;
    if (x != null) {
      final bytes = await x.readAsBytes();
      final mime = x.name.toLowerCase().endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      setState(
        () => _avatarDataUri = 'data:$mime;base64,${base64Encode(bytes)}',
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.t('profile_image_selected', fallback: 'Image selected'),
          ),
        ),
      );
    }
  }

  Future<void> _save(LocalizationService loc) async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final ok = await context.read<AuthProvider>().updateProfile(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        name: '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
        avatarPath: _avatarDataUri,
      );
      debugPrint('updateProfile result: $ok');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? loc.t('profile_update_success', fallback: 'Profile updated')
                : loc.t('profile_update_error', fallback: 'Failed to update'),
          ),
        ),
      );
      if (ok) navigator.pop();
    } catch (e, st) {
      debugPrint('updateProfile error: $e');
      debugPrintStack(stackTrace: st);
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            loc.t('profile_update_error', fallback: 'Failed to update'),
          ),
        ),
      );
    }
  }

  // Future<void> _save(LocalizationService loc) async {
  //   setState(() => _saving = true);
  //   final ok = await context.read<AuthProvider>().updateProfile(
  //         firstName: _firstName.text.trim(),
  //         lastName: _lastName.text.trim(),
  //         name: '${_firstName.text.trim()} ${_lastName.text.trim()}'.trim(),
  //         avatarPath: _avatarDataUri,
  //       );
  //   if (!mounted) return;
  //   setState(() => _saving = false);
  //   if (ok) {
  //     Navigator.pop(context);
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('profile_update_success', fallback: 'Profile updated'))));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.t('profile_update_error', fallback: 'Failed to update'))));
  //   }
  // }
}

String _splitFirst(String name) =>
    (name.split(' ')..removeWhere((e) => e.isEmpty)).isNotEmpty
    ? name.split(' ').first
    : '';
String _splitLast(String name) =>
    (name.split(' ')..removeWhere((e) => e.isEmpty)).length > 1
    ? name.split(' ').sublist(1).join(' ')
    : '';
