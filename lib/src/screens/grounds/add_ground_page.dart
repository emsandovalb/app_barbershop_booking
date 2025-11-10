import 'package:flutter/material.dart';
import '../../navigation/app_router.dart';
import 'package:provider/provider.dart';
import '../../providers/ground_form_provider.dart';

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
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Add ground'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'Email address')),
          const SizedBox(height: 12),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(hintText: 'Phone')),
          const SizedBox(height: 12),
          TextField(controller: addressCtrl, decoration: const InputDecoration(hintText: 'Address')),
          const SizedBox(height: 24),
          const Text('Operating hours', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TimeTile(
                  label: 'Opens',
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
                  label: 'Closes',
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
          const Text('Duration per booking', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              _DurationPill(
                label: '1 Hour',
                selected: durationHours == 1,
                onTap: () => setState(() => durationHours = 1),
              ),
              const SizedBox(width: 8),
              _DurationPill(
                label: '2 Hours',
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
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Address are required')));
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
          child: const Text('Continue'),
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
