import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/court_image.dart';

class TeamFormPage extends StatefulWidget {
  final Map<String, dynamic>? team;
  const TeamFormPage({super.key, this.team});

  @override
  State<TeamFormPage> createState() => _TeamFormPageState();
}

class _TeamFormPageState extends State<TeamFormPage> {
  final _picker = ImagePicker();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _cityCtrl;
  String? _logoPath;
  bool _saving = false;

  bool get isEdit => widget.team != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team?['name']?.toString() ?? '');
    _descriptionCtrl = TextEditingController(text: widget.team?['description']?.toString() ?? '');
    _cityCtrl = TextEditingController(text: widget.team?['city']?.toString() ?? '');
    _logoPath = widget.team?['logo']?.toString() ?? widget.team?['logo_url']?.toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final preview = _logoPath;
    final title = isEdit ? loc.t('teams_edit', fallback: 'Edit team') : loc.t('teams_create', fallback: 'Create team');

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF282828),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.t('teams_logo', fallback: 'Team logo'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 140,
                        height: 140,
                        child: preview == null || preview.isEmpty
                            ? const CourtImage(images: null, height: 140, width: 140, radius: BorderRadius.zero)
                            : CourtImage(images: preview, height: 140, width: 140, radius: BorderRadius.zero),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickLogo,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(loc.t('btn_add', fallback: 'Add')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(hintText: loc.t('teams_name', fallback: 'Team name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(hintText: loc.t('teams_description', fallback: 'Description')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityCtrl,
              decoration: InputDecoration(hintText: loc.t('teams_city', fallback: 'City')),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : () async => _save(context),
              child: Text(_saving ? loc.t('btn_saving', fallback: 'Saving...') : loc.t('teams_save', fallback: 'Save team')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLogo() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() {
      _logoPath = image.path;
    });
  }

  Future<void> _save(BuildContext context) async {
    final loc = context.read<LocalizationService>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('teams_name', fallback: 'Team name'))),
      );
      return;
    }

    setState(() => _saving = true);
    final auth = context.read<AuthProvider>();
    final payload = {
      'name': name,
      'description': _descriptionCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
    };

    try {
      if (isEdit) {
        final id = widget.team?['id'] as int?;
        if (id == null) return;
        await auth.api.updateTeam(
          id,
          payload,
          logoPath: _logoPath != (widget.team?['logo']?.toString() ?? widget.team?['logo_url']?.toString()) ? _logoPath : null,
        );
      } else {
        await auth.api.createTeam(
          payload,
          logoPath: _logoPath,
        );
      }
      await auth.refreshUser();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit
                ? loc.t('teams_update_success', fallback: 'Team updated')
                : loc.t('teams_create_success', fallback: 'Team created'),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.t('teams_update_failed', fallback: 'Could not save the team')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
