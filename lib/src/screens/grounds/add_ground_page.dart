import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ground_form_provider.dart';
import '../../services/localization_service.dart';

class AddGroundPage extends StatefulWidget {
  const AddGroundPage({super.key});

  @override
  State<AddGroundPage> createState() => _AddGroundPageState();
}

class _AddGroundPageState extends State<AddGroundPage> {
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  TimeOfDay openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay closeTime = const TimeOfDay(hour: 22, minute: 0);
  int durationHours = 1; // allowed booking duration per slot

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.t('grounds_add_title', fallback: 'Add ground')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: nameCtrl, decoration: InputDecoration(hintText: loc.t('form_name', fallback: 'Name'))),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: InputDecoration(hintText: loc.t('form_email', fallback: 'Email address'))),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: InputDecoration(hintText: loc.t('form_phone', fallback: 'Phone'))),
          const SizedBox(height: 12),
          TextField(controller: addressCtrl, decoration: InputDecoration(hintText: loc.t('form_address', fallback: 'Address'))),
          const SizedBox(height: 24),
          Text(loc.t('grounds_operating_hours', fallback: 'Operating hours'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
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
                child: _TimeTile(
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
          const SizedBox(height: 16),
          Text(loc.t('grounds_duration_label', fallback: 'Duration per booking'),
              style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              _DurationPill(
                label: loc.t('grounds_duration_one', fallback: '1 Hour'),
                selected: durationHours == 1,
                onTap: () => setState(() => durationHours = 1),
              ),
              const SizedBox(width: 8),
              _DurationPill(
                label: loc.t('grounds_duration_two', fallback: '2 Hours'),
                selected: durationHours == 2,
                onTap: () => setState(() => durationHours = 2),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            if (nameCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(loc.t('grounds_name_required', fallback: 'Name and Address are required'))));
              return;
            }
            context.read<GroundFormProvider>().setAll({
              'name': nameCtrl.text.trim(),
              'contact_email': emailCtrl.text.trim(),
              'contact_phone': phoneCtrl.text.trim(),
              'address': addressCtrl.text.trim(),
              'open_hour': _fmt24(openTime),
              'close_hour': _fmt24(closeTime),
              'duration_hours': durationHours,
            });
            Navigator.of(context).pushNamed(AppRoutes.categoryGround);
          },
          child: Text(loc.t('btn_continue', fallback: 'Continue')),
        ),
      ),
    );
  }
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

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeTile({required this.label, required this.value, required this.onTap});

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

class _DurationPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DurationPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF282828),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white : Colors.transparent),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
