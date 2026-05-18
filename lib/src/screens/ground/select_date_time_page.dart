import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

class SelectDateTimePage extends StatefulWidget {
  final Map<String, dynamic> court;
  const SelectDateTimePage({super.key, required this.court});

  @override
  State<SelectDateTimePage> createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends State<SelectDateTimePage> {
  DateTime date = DateTime.now().add(const Duration(days: 1));
  late int durationHours;
  late TimeOfDay openTime;
  late TimeOfDay closeTime;
  List<_Slot> slots = [];
  _Slot? selected;
  List<_Range> booked = [];

  @override
  void initState() {
    super.initState();
    final resourceDuration = _parseInt(widget.court['duration_hours'], 1);
    durationHours = resourceDuration >= 2 ? 1 : resourceDuration;
    openTime = _parseTime(widget.court['open_hour']) ?? const TimeOfDay(hour: 8, minute: 0);
    closeTime = _parseTime(widget.court['close_hour']) ?? const TimeOfDay(hour: 22, minute: 0);
    _rebuildSlots();
  }

  void _rebuildSlots() {
    if (durationHours <= 0) durationHours = 1;
    if (!_validRange(openTime, closeTime)) {
      openTime = const TimeOfDay(hour: 8, minute: 0);
      closeTime = const TimeOfDay(hour: 22, minute: 0);
    }
    slots = _generateSlots(openTime, closeTime, durationHours);
    selected = slots.isNotEmpty ? slots.first : null;
    setState(() {});
    _loadAvailability();
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    return Scaffold(
      appBar: AppBar(title: Text(loc.t('select_date_time_title', fallback: 'Select appointment time'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CalendarDatePicker(
                initialDate: date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                onDateChanged: (d) {
                  setState(() => date = d);
                  _loadAvailability();
                },
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loc.t('select_time', fallback: 'Select time'), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  Row(
                    children: [
                      _DurChip(
                        label: loc.t('select_duration_1h', fallback: '1h'),
                        selected: durationHours == 1,
                        onTap: () {
                          durationHours = 1;
                          _rebuildSlots();
                        },
                      ),
                      const SizedBox(width: 8),
                      _DurChip(
                        label: loc.t('select_duration_2h', fallback: '2h'),
                        selected: durationHours == 2,
                        onTap: () {
                          durationHours = 2;
                          _rebuildSlots();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 12.0;
                  final columns = 2;
                  final maxW = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width - 32;
                  final chipWidth = (maxW - spacing) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      if (slots.isEmpty)
                        Text(loc.t('select_no_slots', fallback: 'No available appointment slots'), style: const TextStyle(color: Colors.white70)),
                      for (final s in slots)
                        SizedBox(
                          width: chipWidth,
                          child: _TimeChip(
                            label: s.label,
                            selected: selected == s,
                            disabled: _isBooked(s),
                            onTap: _isBooked(s) ? null : () => setState(() => selected = s),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            if (selected == null || _isBooked(selected!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.t('select_choose_slot', fallback: 'Please choose an available appointment slot'))),
              );
              return;
            }
            final start = DateTime(date.year, date.month, date.day, selected!.start.hour, selected!.start.minute);
            Navigator.pop(context, {
              'iso': start.toIso8601String(),
              'slot': selected!.label,
              'duration_hours': durationHours,
            });
          },
          child: Text(loc.t('btn_continue', fallback: 'Continue')),
        ),
      ),
    );
  }

  Future<void> _loadAvailability() async {
    final api = context.read<AuthProvider>().api;
    final id = widget.court['id'] as int?;
    if (id == null) return;
    final day = DateFormat('yyyy-MM-dd').format(date);
    try {
      final res = await api.getResourceAvailability(id: id, date: day);
      final items = (res['booked'] as List?) ?? [];
      booked = items.map((e) => _Range.fromMap(e as Map<String, dynamic>)).toList();
      setState(() {});
    } catch (_) {
      booked = [];
      setState(() {});
    }
  }

  bool _isBooked(_Slot s) {
    final sStart = s.start.hour * 60 + s.start.minute;
    final sEnd = s.end.hour * 60 + s.end.minute;
    for (final r in booked) {
      if (sStart < r.end && sEnd > r.start) return true;
    }
    return false;
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = disabled ? .35 : 1.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.white.withOpacity(.85) : Colors.transparent, width: 1),
        ),
        child: Opacity(
          opacity: opacity,
          child: Text(
            label.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, height: 1.2),
          ),
        ),
      ),
    );
  }
}

class _DurChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  const _DurChip({required this.label, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.white : Colors.transparent),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _Slot {
  final TimeOfDay start;
  final TimeOfDay end;
  final String label;
  const _Slot(this.start, this.end, this.label);
}

List<_Slot> _generateSlots(TimeOfDay open, TimeOfDay close, int stepHours) {
  final list = <_Slot>[];
  var current = open.hour * 60 + open.minute;
  final end = close.hour * 60 + close.minute;
  final step = stepHours * 60;
  while (current + step <= end) {
    final s = _fromMinutes(current);
    final e = _fromMinutes(current + step);
    list.add(_Slot(s, e, '${_fmt12(s)} to ${_fmt12(e)}'));
    current += step;
  }
  return list;
}

TimeOfDay _fromMinutes(int m) => TimeOfDay(hour: m ~/ 60, minute: m % 60);

String _fmt12(TimeOfDay t) {
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final mm = t.minute.toString().padLeft(2, '0');
  final p = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$mm $p';
}

TimeOfDay? _parseTime(dynamic v) {
  if (v is String && v.contains(':')) {
    final parts = v.split(':');
    final hh = int.tryParse(parts[0]) ?? 0;
    final mm = int.tryParse(parts[1]) ?? 0;
    return TimeOfDay(hour: hh, minute: mm);
  }
  return null;
}

int _parseInt(dynamic v, int fallback) {
  if (v is int) return v;
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

bool _validRange(TimeOfDay a, TimeOfDay b) {
  final am = a.hour * 60 + a.minute;
  final bm = b.hour * 60 + b.minute;
  return bm > am;
}

class _Range {
  final int start;
  final int end;
  _Range(this.start, this.end);

  factory _Range.fromMap(Map<String, dynamic> m) {
    final s = _parseHHmm(m['start'] as String? ?? '00:00');
    final e = _parseHHmm(m['end'] as String? ?? '00:00');
    return _Range(s.hour * 60 + s.minute, e.hour * 60 + e.minute);
  }
}

TimeOfDay _parseHHmm(String s) {
  final parts = s.split(':');
  final hh = int.tryParse(parts[0]) ?? 0;
  final mm = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hh, minute: mm);
}
