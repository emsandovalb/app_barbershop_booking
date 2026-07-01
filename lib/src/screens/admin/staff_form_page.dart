import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'admin_page_scaffold.dart';

class StaffFormPage extends StatefulWidget {
  final Map<String, dynamic>? staff;
  final bool createMode;

  const StaffFormPage({
    super.key,
    this.staff,
    this.createMode = false,
  });

  @override
  State<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;
  late final TextEditingController _avatarController;
  bool _isActive = true;
  bool _loadingRoles = true;
  bool _saving = false;
  List<Map<String, dynamic>> _roles = [];
  int? _selectedRoleId;

  bool get _isCreating => widget.createMode || widget.staff == null;

  @override
  void initState() {
    super.initState();
    final staff = widget.staff ?? const <String, dynamic>{};
    _nameController = TextEditingController(text: staff['name']?.toString() ?? '');
    _emailController = TextEditingController(text: staff['email']?.toString() ?? '');
    _phoneController = TextEditingController(text: staff['phone']?.toString() ?? '');
    _bioController = TextEditingController(text: staff['bio']?.toString() ?? '');
    _avatarController = TextEditingController(text: staff['avatar']?.toString() ?? '');
    _isActive = staff['is_active'] != false;
    final role = staff['role'];
    if (role is Map && role['id'] != null) {
      _selectedRoleId = role['id'] as int?;
    } else if (staff['staff_role_id'] != null) {
      _selectedRoleId = staff['staff_role_id'] as int?;
    }
    _loadRoles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final res = await context.read<AuthProvider>().api.getStaffRoles();
      final data = (res['data'] as List?) ?? const [];
      _roles = data
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      if (_selectedRoleId == null && _roles.isNotEmpty) {
        _selectedRoleId = _roles.first['id'] as int?;
      }
    } catch (_) {
      _roles = [];
    } finally {
      if (mounted) {
        setState(() => _loadingRoles = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) return;

    setState(() => _saving = true);
    try {
      final api = context.read<AuthProvider>().api;
      final payload = <String, dynamic>{
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        'avatar': _avatarController.text.trim().isEmpty ? null : _avatarController.text.trim(),
        'staff_role_id': _selectedRoleId,
        'is_active': _isActive,
      };

      if (_isCreating) {
        await api.createStaff(payload);
      } else {
        await api.updateStaff(widget.staff!['id'] as int, payload);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();
    final loc = context.watch<LocalizationService>();
    final title = _isCreating
        ? loc.t('add_staff', fallback: 'Add barber')
        : loc.t('edit_staff', fallback: 'Edit barber');

    return Scaffold(
      appBar: buildAdminAppBar(context, title: title),
      body: _loadingRoles
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: loc.t('name', fallback: config.terminology.staff),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? loc.t('required', fallback: 'Required') : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: loc.t('email', fallback: 'Email'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: loc.t('phone', fallback: 'Phone'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: loc.t('bio', fallback: 'Bio'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _avatarController,
                        decoration: InputDecoration(
                          labelText: loc.t('avatar', fallback: 'Avatar URL or path'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _selectedRoleId,
                        items: _roles
                            .map(
                              (role) => DropdownMenuItem<int>(
                                value: role['id'] as int?,
                                child: Text(role['name']?.toString() ?? ''),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) => setState(() => _selectedRoleId = value),
                        decoration: InputDecoration(
                          labelText: loc.t('staff_role', fallback: 'Staff role'),
                        ),
                        validator: (value) => value == null ? loc.t('required', fallback: 'Required') : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        title: Text(loc.t('active', fallback: 'Active')),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(loc.t('save', fallback: 'Save')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
