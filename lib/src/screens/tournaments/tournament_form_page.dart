import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/court_image.dart';

class TournamentFormPage extends StatefulWidget {
  final Map<String, dynamic>? tournament;

  const TournamentFormPage({super.key, this.tournament});

  @override
  State<TournamentFormPage> createState() => _TournamentFormPageState();
}

class _TournamentFormPageState extends State<TournamentFormPage> {
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _entryFeeCtrl = TextEditingController();
  final _prizePoolCtrl = TextEditingController();
  final _maxTeamsCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _registrationDeadlineCtrl = TextEditingController();
  final _startsAtCtrl = TextEditingController();
  final _endsAtCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _saving = false;
  bool _loadingCourts = true;
  List<Map<String, dynamic>> _courts = [];
  int? _selectedCourtId;
  String _format = 'single_elimination';
  String? _coverImagePath;
  String? _existingCoverImage;

  @override
  void initState() {
    super.initState();
    final tournament = widget.tournament;
    if (tournament != null) {
      _nameCtrl.text = tournament['name']?.toString() ?? '';
      _descriptionCtrl.text = tournament['description']?.toString() ?? '';
      _entryFeeCtrl.text = _decimalToText(tournament['entry_fee']);
      _prizePoolCtrl.text = _decimalToText(tournament['prize_pool']);
      _maxTeamsCtrl.text = tournament['max_teams']?.toString() ?? '';
      _rulesCtrl.text = tournament['rules']?.toString() ?? '';
      _registrationDeadlineCtrl.text = _dateToText(tournament['registration_deadline']);
      _startsAtCtrl.text = _dateToText(tournament['starts_at']);
      _endsAtCtrl.text = _dateToText(tournament['ends_at']);
      _selectedCourtId = tournament['court_id'] as int?;
      _format = tournament['format']?.toString() ?? _format;
      _existingCoverImage = tournament['cover_image_url']?.toString() ?? tournament['cover_image']?.toString();
    }
    _loadCourts();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _entryFeeCtrl.dispose();
    _prizePoolCtrl.dispose();
    _maxTeamsCtrl.dispose();
    _rulesCtrl.dispose();
    _registrationDeadlineCtrl.dispose();
    _startsAtCtrl.dispose();
    _endsAtCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourts() async {
    try {
      final res = await context.read<AuthProvider>().api.getCourts(perPage: 100);
      final data = (res['data'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _courts = data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        if (_selectedCourtId == null && _courts.isNotEmpty) {
          _selectedCourtId = _courts.first['id'] as int?;
        }
        _loadingCourts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _courts = [];
        _loadingCourts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loc = context.watch<LocalizationService>();
    final isEdit = widget.tournament != null;

    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(isEdit ? loc.t('tournaments_edit', fallback: 'Edit tournament') : loc.t('tournaments_create', fallback: 'Create tournament')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.t('tournaments_login_required', fallback: 'Please log in to create or edit tournaments.'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
                  child: Text(loc.t('login_button', fallback: 'Log in')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          title: Text(isEdit ? loc.t('tournaments_edit', fallback: 'Edit tournament') : loc.t('tournaments_create', fallback: 'Create tournament')),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.admin_panel_settings_outlined, size: 48, color: Colors.white70),
                const SizedBox(height: 12),
                Text(
                  loc.t('tournaments_admin_only', fallback: 'Only administrators can create or edit tournaments.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(loc.t('btn_back_home', fallback: 'Back')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(isEdit
            ? loc.t('tournaments_edit', fallback: 'Edit tournament')
            : loc.t('tournaments_create', fallback: 'Create tournament')),
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(hintText: loc.t('tournaments_name_hint', fallback: 'Tournament name')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(hintText: loc.t('tournaments_description', fallback: 'Description')),
            ),
            const SizedBox(height: 12),
            _CoverImagePicker(
              existingImage: _existingCoverImage,
              selectedPath: _coverImagePath,
              onPick: _pickCoverImage,
            ),
            const SizedBox(height: 12),
            _CourtDropdown(
              loading: _loadingCourts,
              courts: _courts,
              selectedCourtId: _selectedCourtId,
              onChanged: (value) => setState(() => _selectedCourtId = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _format,
              decoration: InputDecoration(labelText: loc.t('tournaments_format', fallback: 'Format')),
              items: [
                DropdownMenuItem(value: 'single_elimination', child: Text(loc.t('tournaments_format_single_elimination', fallback: 'Single elimination'))),
                DropdownMenuItem(value: 'double_elimination', child: Text(loc.t('tournaments_format_double_elimination', fallback: 'Double elimination'))),
                DropdownMenuItem(value: 'round_robin', child: Text(loc.t('tournaments_format_round_robin', fallback: 'Round robin'))),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _format = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _entryFeeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: loc.t('tournaments_fee', fallback: 'Registration fee')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _prizePoolCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(hintText: loc.t('tournaments_prize_pool', fallback: 'Prize pool')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxTeamsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(hintText: loc.t('tournaments_max_teams', fallback: 'Max teams')),
            ),
            const SizedBox(height: 12),
            _DateField(
              controller: _registrationDeadlineCtrl,
              label: loc.t('tournaments_registration_deadline', fallback: 'Registration deadline'),
              onPick: () => _pickDate(_registrationDeadlineCtrl),
            ),
            const SizedBox(height: 12),
            _DateField(
              controller: _startsAtCtrl,
              label: loc.t('tournaments_starts', fallback: 'Starts at'),
              onPick: () => _pickDateTime(_startsAtCtrl),
            ),
            const SizedBox(height: 12),
            _DateField(
              controller: _endsAtCtrl,
              label: loc.t('tournaments_ends', fallback: 'Ends at'),
              onPick: () => _pickDateTime(_endsAtCtrl),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rulesCtrl,
              maxLines: 4,
              decoration: InputDecoration(hintText: loc.t('tournaments_rules', fallback: 'Rules')),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: Text(
                _saving
                    ? loc.t('btn_saving', fallback: 'Saving...')
                    : loc.t('btn_save', fallback: 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initialDate = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initialDate,
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  Future<void> _pickDateTime(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: initial,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    controller.text = DateTime(date.year, date.month, date.day, time.hour, time.minute).toIso8601String();
    setState(() {});
  }

  Future<void> _pickCoverImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() {
      _coverImagePath = image.path;
      _existingCoverImage = null;
    });
  }

  Future<void> _submit() async {
    final loc = context.read<LocalizationService>();
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('tournaments_name_required', fallback: 'Tournament name is required'))),
      );
      return;
    }

    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'name': name,
      'description': _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      'format': _format,
      'court_id': _selectedCourtId,
      'entry_fee': _numOrNull(_entryFeeCtrl.text),
      'prize_pool': _numOrNull(_prizePoolCtrl.text),
      'max_teams': _intOrNull(_maxTeamsCtrl.text),
      'registration_deadline': _registrationDeadlineCtrl.text.trim().isEmpty ? null : _registrationDeadlineCtrl.text.trim(),
      'starts_at': _startsAtCtrl.text.trim().isEmpty ? null : _startsAtCtrl.text.trim(),
      'ends_at': _endsAtCtrl.text.trim().isEmpty ? null : _endsAtCtrl.text.trim(),
      'rules': _rulesCtrl.text.trim().isEmpty ? null : _rulesCtrl.text.trim(),
    }..removeWhere((key, value) => value == null);

    try {
      final api = context.read<AuthProvider>().api;
      final saved = widget.tournament == null
          ? await api.createTournament(payload, coverImagePath: _coverImagePath)
          : await api.updateTournament(widget.tournament!['id'] as int, payload, coverImagePath: _coverImagePath);
      if (!mounted) return;
      Navigator.of(context).pop(saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.t('tournaments_save_failed', fallback: 'Failed to save tournament')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CourtDropdown extends StatelessWidget {
  final bool loading;
  final List<Map<String, dynamic>> courts;
  final int? selectedCourtId;
  final ValueChanged<int?> onChanged;

  const _CourtDropdown({
    required this.loading,
    required this.courts,
    required this.selectedCourtId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return DropdownButtonFormField<int?>(
      value: selectedCourtId,
      decoration: InputDecoration(labelText: loc.t('tournaments_court', fallback: 'Court')),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(loc.t('tournaments_no_court', fallback: 'No court')),
        ),
        ...courts.map(
          (court) => DropdownMenuItem<int?>(
            value: court['id'] as int?,
            child: Text(court['name']?.toString() ?? 'Court'),
          ),
        ),
      ],
      onChanged: loading ? null : onChanged,
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;

  const _DateField({
    required this.controller,
    required this.label,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: onPick,
        ),
      ),
      onTap: onPick,
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  final String? existingImage;
  final String? selectedPath;
  final VoidCallback onPick;

  const _CoverImagePicker({
    required this.existingImage,
    required this.selectedPath,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final source = selectedPath ?? existingImage;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF282828),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  loc.t('tournaments_cover_image', fallback: 'Banner image'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.photo_library_outlined),
                label: Text(loc.t('btn_choose', fallback: 'Choose')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CourtImage(
                images: source,
                height: 160,
                width: double.infinity,
                radius: BorderRadius.zero,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.t(
              'tournaments_cover_helper',
              fallback: 'This image is used as the tournament banner in the list, detail, and home preview.',
            ),
            style: TextStyle(color: Colors.white.withValues(alpha: 0.68), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

String _decimalToText(dynamic value) {
  final num? parsed = value is num ? value : num.tryParse(value?.toString() ?? '');
  if (parsed == null) return '';
  return parsed.toString();
}

String _dateToText(dynamic raw) {
  if (raw == null) return '';
  return raw.toString().replaceFirst('Z', '');
}

num? _numOrNull(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return num.tryParse(trimmed);
}

int? _intOrNull(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return int.tryParse(trimmed);
}
