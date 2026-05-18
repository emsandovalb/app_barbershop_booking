import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../navigation/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../widgets/court_image.dart';

class MyGroundsPage extends StatefulWidget {
  const MyGroundsPage({super.key});

  @override
  State<MyGroundsPage> createState() => _MyGroundsPageState();
}

class _MyGroundsPageState extends State<MyGroundsPage> {
  Future<Map<String, dynamic>>? _future;
  bool _actionInProgress = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final loc = context.watch<LocalizationService>();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';
    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton(), title: Text(loc.t('grounds_my_title', fallback: 'My services'))),
        body: Center(child: Text(loc.t('grounds_admin_only', fallback: 'Only administrators can access this section'))),
      );
    }
    _future ??= auth.api.getMyResources();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('grounds_my_title', fallback: 'My services')),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = (snap.data?['data'] as List?) ?? [];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.all(32),
                    children: [
                      Center(child: Text(loc.t('grounds_empty', fallback: 'No services yet'))),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final resource = items[i] as Map<String, dynamic>;
                      final status = (resource['status'] ?? 'active').toString();
                      final isInactive = status != 'active';
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF282828),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: CourtImage(
                                  images: resource['images'],
                                  height: 72,
                                  width: 72,
                                  radius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resource['name']?.toString() ?? 'Service',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        '${resource['duration_hours'] ?? 1} ${loc.t('grounds_hour', fallback: 'Hour')}',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: (isInactive ? Colors.red : Colors.green).withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: isInactive ? Colors.redAccent : Colors.greenAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEdit(resource);
                                } else if (value == 'toggle' && !_actionInProgress) {
                                  final newStatus = isInactive ? 'active' : 'inactive';
                                  _changeStatus(resource, newStatus);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(loc.t('grounds_edit', fallback: 'Edit')),
                                ),
                                PopupMenuItem(
                                  value: 'toggle',
                                  child: Text(
                                    isInactive
                                        ? loc.t('grounds_activate', fallback: 'Activate')
                                        : loc.t('grounds_deactivate', fallback: 'Deactivate'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).pushNamed(AppRoutes.addGround);
            if (mounted) _refresh();
          },
          child: Text(loc.t('btn_add', fallback: 'Add')),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
      setState(() {
        _future = auth.api.getMyResources();
      });
    await _future;
  }

  Future<void> _openEdit(Map<String, dynamic> court) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GroundEditSheet(court: court),
    );
    if (saved == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _changeStatus(Map<String, dynamic> court, String newStatus) async {
    setState(() => _actionInProgress = true);
    final auth = context.read<AuthProvider>();
    final loc = context.read<LocalizationService>();
    try {
      final id = court['id'] as int?;
      if (id == null) return;
      if (newStatus == 'inactive') {
        await auth.api.deleteResource(id);
      } else {
        await auth.api.updateResource(id, {'status': newStatus});
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.t('grounds_status_updated', fallback: 'Status updated'))),
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.t('grounds_update_failed', fallback: 'Failed to update')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }
}

class _GroundEditSheet extends StatefulWidget {
  final Map<String, dynamic> court;
  const _GroundEditSheet({required this.court});

  @override
  State<_GroundEditSheet> createState() => _GroundEditSheetState();
}

class _GroundEditSheetState extends State<_GroundEditSheet> {
  late final TextEditingController nameCtrl;
  late final TextEditingController emailCtrl;
  late final TextEditingController phoneCtrl;
  late final TextEditingController addressCtrl;
  late TimeOfDay openTime;
  late TimeOfDay closeTime;
  late int duration;
  late String status;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.court['name']?.toString() ?? '');
    emailCtrl = TextEditingController(text: widget.court['contact_email']?.toString() ?? '');
    phoneCtrl = TextEditingController(text: widget.court['contact_phone']?.toString() ?? '');
    addressCtrl = TextEditingController(text: widget.court['address']?.toString() ?? '');
    openTime = _parseToTimeOfDay(widget.court['open_hour']?.toString()) ?? const TimeOfDay(hour: 8, minute: 0);
    closeTime = _parseToTimeOfDay(widget.court['close_hour']?.toString()) ?? const TimeOfDay(hour: 22, minute: 0);
    duration = int.tryParse(widget.court['duration_hours']?.toString() ?? '1') ?? 1;
    status = (widget.court['status']?.toString() ?? 'active');
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom + 16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(loc.t('grounds_edit_details', fallback: 'Edit resource'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: InputDecoration(hintText: loc.t('form_name', fallback: 'Name'))),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: InputDecoration(hintText: loc.t('form_email', fallback: 'Email address'))),
            const SizedBox(height: 12),
            TextField(controller: phoneCtrl, decoration: InputDecoration(hintText: loc.t('form_phone', fallback: 'Phone'))),
            const SizedBox(height: 12),
            TextField(controller: addressCtrl, decoration: InputDecoration(hintText: loc.t('form_address', fallback: 'Address'))),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SheetTimeTile(
                    label: loc.t('grounds_opens', fallback: 'Opens'),
                    value: _fmt(openTime),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: openTime);
                      if (picked != null) setState(() => openTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SheetTimeTile(
                    label: loc.t('grounds_closes', fallback: 'Closes'),
                    value: _fmt(closeTime),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: closeTime);
                      if (picked != null) setState(() => closeTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: duration,
              decoration: InputDecoration(labelText: loc.t('grounds_duration_label', fallback: 'Duration per reservation')),
              items: [
                DropdownMenuItem(value: 1, child: Text(loc.t('grounds_duration_one', fallback: '1 Hour'))),
                DropdownMenuItem(value: 2, child: Text(loc.t('grounds_duration_two', fallback: '2 Hours'))),
                DropdownMenuItem(value: 3, child: Text(loc.t('grounds_duration_three', fallback: '3 Hours'))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => duration = val);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: status,
              decoration: InputDecoration(labelText: loc.t('grounds_status', fallback: 'Status')),
              items: [
                DropdownMenuItem(value: 'active', child: Text(loc.t('grounds_active', fallback: 'Active'))),
                DropdownMenuItem(value: 'inactive', child: Text(loc.t('grounds_inactive', fallback: 'Inactive'))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => status = val);
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saving ? null : _save,
              child: Text(saving ? loc.t('btn_saving', fallback: 'Saving...') : loc.t('btn_save', fallback: 'Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.read<LocalizationService>().t('grounds_name_required', fallback: 'Name and Address are required'))),
      );
      return;
    }
    setState(() => saving = true);
    final auth = context.read<AuthProvider>();
    final id = widget.court['id'] as int?;
    if (id == null) {
      setState(() => saving = false);
      Navigator.of(context).pop(false);
      return;
    }
    final payload = {
      'name': nameCtrl.text.trim(),
      'contact_email': emailCtrl.text.trim(),
      'contact_phone': phoneCtrl.text.trim(),
      'address': addressCtrl.text.trim(),
      'open_hour': _fmt24(openTime),
      'close_hour': _fmt24(closeTime),
      'duration_hours': duration,
      'status': status,
    };
    try {
      await auth.api.updateResource(id, payload);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.read<LocalizationService>().t('grounds_update_failed', fallback: 'Failed to update')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}

TimeOfDay? _parseToTimeOfDay(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
}

String _fmt(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final mm = t.minute.toString().padLeft(2, '0');
  final p = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$mm $p';
}

String _fmt24(TimeOfDay t) {
  final hh = t.hour.toString().padLeft(2, '0');
  final mm = t.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

class _SheetTimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _SheetTimeTile({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
