import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../services/business_clock.dart';

class SelectDateTimePage extends StatefulWidget {
  final Map<String, dynamic> court;
  final Map<String, dynamic> preferredStaff;

  const SelectDateTimePage({
    super.key,
    required this.court,
    required this.preferredStaff,
  });

  @override
  State<SelectDateTimePage> createState() => _SelectDateTimePageState();
}

class _SelectDateTimePageState extends State<SelectDateTimePage> {
  DateTime _date = BusinessClock.today().add(const Duration(days: 1));
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _slots = const [];
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final serviceId = _asInt(widget.court['id']);
    final staffId = _asInt(widget.preferredStaff['id']);
    if (serviceId == null || staffId == null) {
      setState(() {
        _loading = false;
        _error = 'No se pudo identificar el servicio o el profesional.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _selected = null;
    });
    try {
      final response = await context
          .read<AuthProvider>()
          .api
          .getResourceAvailability(
            id: serviceId,
            staffId: staffId,
            date: DateFormat('yyyy-MM-dd').format(_date),
          );
      final slots = (response['slots'] as List? ?? const [])
          .whereType<Map>()
          .map((slot) => Map<String, dynamic>.from(slot))
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _slots = slots);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No pudimos cargar los horarios disponibles.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final staffName =
        widget.preferredStaff['name']?.toString() ??
        loc.t('booking_barber_label', fallback: 'Profesional');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.t('select_date_time_title', fallback: 'Elegí fecha y hora'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            staffName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          CalendarDatePicker(
            initialDate: _date,
            firstDate: BusinessClock.today(),
            lastDate: BusinessClock.today().add(const Duration(days: 365)),
            onDateChanged: (value) {
              _date = value;
              _loadAvailability();
            },
          ),
          const SizedBox(height: 12),
          Text(
            loc.t('select_time', fallback: 'Horarios disponibles'),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            _LoadState(message: _error!, onRetry: _loadAvailability),
          if (!_loading && _error == null && _slots.isEmpty)
            Text(
              loc.t(
                'select_no_slots',
                fallback: 'No hay horarios disponibles este día.',
              ),
              style: const TextStyle(color: Colors.white70),
            ),
          if (!_loading && _error == null)
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _slots
                  .map((slot) {
                    final selected = identical(slot, _selected);
                    return ChoiceChip(
                      label: Text(
                        slot['label']?.toString() ??
                            slot['value']?.toString() ??
                            '',
                      ),
                      selected: selected,
                      onSelected: (_) => setState(() => _selected = slot),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _selected == null ? null : _continue,
          child: Text(loc.t('btn_continue', fallback: 'Continuar')),
        ),
      ),
    );
  }

  void _continue() {
    final value = _selected!['value']?.toString();
    if (value == null || value.isEmpty) return;
    final start = DateTime(
      _date.year,
      _date.month,
      _date.day,
      int.parse(value.split(':')[0]),
      int.parse(value.split(':')[1]),
    );
    Navigator.pop(context, {
      'iso': start.toIso8601String(),
      'slot': _selected!['label']?.toString() ?? value,
      'staff': widget.preferredStaff,
      'staff_id': _asInt(widget.preferredStaff['id']),
    });
  }
}

class _LoadState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _LoadState({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message, style: const TextStyle(color: Colors.white70)),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}

int? _asInt(dynamic value) => value is int
    ? value
    : value is num
    ? value.toInt()
    : int.tryParse(value?.toString() ?? '');
