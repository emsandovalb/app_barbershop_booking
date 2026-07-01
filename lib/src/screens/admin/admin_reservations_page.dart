import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../theme/colors.dart';
import '../../widgets/court_image.dart';
import '../bookings/appointment_helpers.dart';
import '../bookings/booking_detail_page.dart';
import '../ground/select_date_time_page.dart';
import 'admin_page_scaffold.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  late DateTime _selectedDay;
  late Future<_ReservationsLoadResult> _future;
  _AgendaStatusFilter _statusFilter = _AgendaStatusFilter.all;
  String _barberFilter = _AgendaBarberFilter.allKey;

  @override
  void initState() {
    super.initState();
    _selectedDay = _dateOnly(DateTime.now());
    _future = _load();
  }

  Future<_ReservationsLoadResult> _load() async {
    final auth = context.read<AuthProvider>();
    final iso = DateFormat('yyyy-MM-dd').format(_selectedDay);
    try {
      final response = await auth.api.getReservationsForDay(iso);
      return _ReservationsLoadResult(bookings: _extractBookings(response));
    } catch (e) {
      return _ReservationsLoadResult(
        bookings: const [],
        errorMessage: e.toString(),
      );
    }
  }

  List<Map<String, dynamic>> _extractBookings(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (data is Map) {
      return [Map<String, dynamic>.from(data)];
    }
    return const [];
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDay = _dateOnly(picked);
      _future = _load();
    });
  }

  void _jumpToDay(DateTime day) {
    final next = _dateOnly(day);
    if (_sameDay(next, _selectedDay)) return;
    setState(() {
      _selectedDay = next;
      _future = _load();
    });
  }

  void _setStatusFilter(_AgendaStatusFilter filter) {
    if (_statusFilter == filter) return;
    setState(() => _statusFilter = filter);
  }

  void _setBarberFilter(String barberKey) {
    if (_barberFilter == barberKey) return;
    setState(() => _barberFilter = barberKey);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A1512),
      ),
    );
  }

  Future<void> _openBookingDetail(Map<String, dynamic> booking) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => BookingDetailPage(booking: booking)),
    );
    if (result == true) {
      await _reload();
    }
  }

  Future<void> _rebookBooking(Map<String, dynamic> booking) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final resource = appointmentResource(booking);
    final bookingId = _bookingId(booking);

    final result = await navigator.push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => SelectDateTimePage(court: resource)),
    );
    if (result == null) return;

    try {
      await auth.api.rebookReservation(bookingId, {
        'date': result['iso'] as String,
        'time_slot': result['slot'] as String,
      });
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cita reprogramada'),
          backgroundColor: Color(0xFF132018),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo reprogramar: $e')),
      );
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final canCancel = canCancelAppointment(booking);
    if (!canCancel) {
      _showSnack(
        'No se puede cancelar dentro de las 4 horas previas al inicio.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161110),
        title: const Text(
          'Cancelar cita',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          '¿Seguro que querés cancelar esta cita?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await auth.api.cancelReservation(_bookingId(booking));
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Cita cancelada'),
          backgroundColor: Color(0xFF231315),
        ),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo cancelar: $e')),
      );
    }
  }

  void _markCompleted(Map<String, dynamic> booking) {
    final label = appointmentServiceName(booking);
    _showSnack(
      'No existe un flujo para marcar "$label" como completada desde esta pantalla todavía.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = (auth.user?['role']?.toString() ?? '') == 'admin';

    if (!isAdmin) {
      return Scaffold(
        appBar: buildAdminAppBar(
          context,
          title: loc.t('admin_reservations_title', fallback: 'Appointments'),
        ),
        body: Center(
          child: Text(
            loc.t(
              'grounds_admin_only',
              fallback: 'Only administrators can access this section',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: loc.t('admin_reservations_title', fallback: 'Agenda'),
        subtitle: _selectedDayShortLabel(_selectedDay),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: 'Elegir fecha',
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF090909), Color(0xFF0E0C0B), Color(0xFF0A0909)],
          ),
        ),
        child: FutureBuilder<_ReservationsLoadResult>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const _LoadingState();
            }

            final result = snapshot.data!;
            final allBookings = result.bookings;
            final filtered = _visibleBookings(allBookings);
            final grouped = _groupAppointments(filtered);
            final barberOptions = _buildBarberOptions(allBookings);
            final metrics = _buildMetrics(allBookings);
            final summary = _buildSummary(allBookings);
            final hasError = result.errorMessage != null;

            return RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: const Color(0xFF121010),
              onRefresh: _reload,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      child: _PremiumHeader(
                        title: 'AGENDA',
                        dayLabel: _selectedDayHeaderLabel(_selectedDay),
                        subtitle: 'Resumen del día',
                        summaryHint: _summaryHint(filtered, allBookings),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _KpiStrip(metrics: metrics),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _PinnedFiltersDelegate(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0A0A).withValues(alpha: .92),
                          border: Border(
                            top: BorderSide(
                              color: AppColors.primary.withValues(alpha: .12),
                            ),
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: .06),
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel(
                              label: 'Filtros de estado',
                              icon: Icons.tune_rounded,
                            ),
                            const SizedBox(height: 10),
                            _HorizontalChipStrip(
                              chips: [
                                _ChipSpec(
                                  label: 'Todos',
                                  selected:
                                      _statusFilter == _AgendaStatusFilter.all,
                                  onTap: () =>
                                      _setStatusFilter(_AgendaStatusFilter.all),
                                ),
                                _ChipSpec(
                                  label: 'Pendientes',
                                  selected:
                                      _statusFilter ==
                                      _AgendaStatusFilter.pending,
                                  onTap: () => _setStatusFilter(
                                    _AgendaStatusFilter.pending,
                                  ),
                                ),
                                _ChipSpec(
                                  label: 'Confirmadas',
                                  selected:
                                      _statusFilter ==
                                      _AgendaStatusFilter.confirmed,
                                  onTap: () => _setStatusFilter(
                                    _AgendaStatusFilter.confirmed,
                                  ),
                                ),
                                _ChipSpec(
                                  label: 'Completadas',
                                  selected:
                                      _statusFilter ==
                                      _AgendaStatusFilter.completed,
                                  onTap: () => _setStatusFilter(
                                    _AgendaStatusFilter.completed,
                                  ),
                                ),
                                _ChipSpec(
                                  label: 'Canceladas',
                                  selected:
                                      _statusFilter ==
                                      _AgendaStatusFilter.cancelled,
                                  onTap: () => _setStatusFilter(
                                    _AgendaStatusFilter.cancelled,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SectionLabel(
                              label: 'Saltos rápidos',
                              icon: Icons.bolt_rounded,
                            ),
                            const SizedBox(height: 10),
                            _HorizontalChipStrip(
                              chips: [
                                _ChipSpec(
                                  label: 'Hoy',
                                  selected: _sameDay(
                                    _selectedDay,
                                    DateTime.now(),
                                  ),
                                  onTap: () => _jumpToDay(DateTime.now()),
                                  compact: true,
                                ),
                                _ChipSpec(
                                  label: 'Mañana',
                                  selected: _sameDay(
                                    _selectedDay,
                                    DateTime.now().add(const Duration(days: 1)),
                                  ),
                                  onTap: () => _jumpToDay(
                                    DateTime.now().add(const Duration(days: 1)),
                                  ),
                                  compact: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel(
                            label: 'Barberos',
                            icon: Icons.content_cut_rounded,
                          ),
                          const SizedBox(height: 10),
                          _HorizontalChipStrip(
                            chips: [
                              _ChipSpec(
                                label: 'Todos',
                                selected:
                                    _barberFilter == _AgendaBarberFilter.allKey,
                                onTap: () => _setBarberFilter(
                                  _AgendaBarberFilter.allKey,
                                ),
                              ),
                              ...barberOptions.map(
                                (option) => _ChipSpec(
                                  label: option.label,
                                  selected: _barberFilter == option.key,
                                  onTap: () => _setBarberFilter(option.key),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: _PremiumStateCard(
                          icon: Icons.wifi_off_rounded,
                          title: 'No fue posible cargar la agenda',
                          subtitle:
                              'Revisá la conexión y volvé a intentar sin perder la vista premium.',
                          actionLabel: 'Reintentar',
                          onAction: _reload,
                        ),
                      ),
                    ),
                  if (!hasError && filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: _PremiumStateCard(
                          icon: Icons.event_busy_rounded,
                          title: 'No hay citas para este filtro.',
                          subtitle:
                              'Probá con otro estado, otro barbero o mové la fecha usando Hoy/Mañana.',
                          actionLabel: 'Actualizar',
                          onAction: _reload,
                        ),
                      ),
                    )
                  else if (!hasError)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: _TimelineSection(
                          groups: grouped,
                          onOpenDetail: _openBookingDetail,
                          onRebook: _rebookBooking,
                          onCancel: _cancelBooking,
                          onMarkCompleted: _markCompleted,
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: _TodaySummaryCard(summary: summary),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDay,
        backgroundColor: const Color(0xFF141110),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_rounded),
        label: Text(_selectedDayButtonLabel(_selectedDay)),
      ),
    );
  }

  List<_BarberOption> _buildBarberOptions(List<Map<String, dynamic>> bookings) {
    final map = <String, String>{};
    for (final booking in bookings) {
      final barber = appointmentBarber(booking);
      final name = barber['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      final key = _barberKey(booking);
      if (key == _AgendaBarberFilter.allKey) continue;
      map.putIfAbsent(key, () => name);
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));
    return entries
        .map((entry) => _BarberOption(key: entry.key, label: entry.value))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _visibleBookings(List<Map<String, dynamic>> all) {
    return all
        .where((booking) {
          final statusOk =
              _statusFilter == _AgendaStatusFilter.all ||
              _matchesStatusFilter(booking, _statusFilter);
          final barberOk =
              _barberFilter == _AgendaBarberFilter.allKey ||
              _barberKey(booking) == _barberFilter;
          return statusOk && barberOk;
        })
        .toList(growable: false)
      ..sort((a, b) => _compareBookings(a, b));
  }

  int _compareBookings(Map<String, dynamic> a, Map<String, dynamic> b) {
    final left = _startMinutes(a);
    final right = _startMinutes(b);
    if (left != right) return left.compareTo(right);
    return _bookingId(a).compareTo(_bookingId(b));
  }

  List<_TimelineGroup> _groupAppointments(List<Map<String, dynamic>> bookings) {
    final map = <int, List<Map<String, dynamic>>>{};
    for (final booking in bookings) {
      map
          .putIfAbsent(_startMinutes(booking), () => <Map<String, dynamic>>[])
          .add(booking);
    }

    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (entry) => _TimelineGroup(
            minutes: entry.key,
            items: entry.value..sort((a, b) => _compareBookings(a, b)),
          ),
        )
        .toList(growable: false);
  }

  List<_KpiMetric> _buildMetrics(List<Map<String, dynamic>> bookings) {
    final pending = bookings
        .where((b) => _statusTag(b) == _AgendaStatusTag.pending)
        .length;
    final confirmed = bookings
        .where((b) => _statusTag(b) == _AgendaStatusTag.confirmed)
        .length;
    final cancelled = bookings
        .where((b) => _statusTag(b) == _AgendaStatusTag.cancelled)
        .length;
    final totalRevenue = bookings.fold<double>(
      0,
      (sum, booking) => sum + _bookingPrice(booking),
    );

    return [
      _KpiMetric(
        label: 'Citas hoy',
        value: bookings.length.toString(),
        icon: Icons.calendar_today_rounded,
      ),
      _KpiMetric(
        label: 'Pendientes',
        value: pending.toString(),
        icon: Icons.schedule_rounded,
      ),
      _KpiMetric(
        label: 'Confirmadas',
        value: confirmed.toString(),
        icon: Icons.verified_rounded,
      ),
      _KpiMetric(
        label: 'Canceladas',
        value: cancelled.toString(),
        icon: Icons.cancel_rounded,
      ),
      _KpiMetric(
        label: 'Ingresos estimados',
        value: NumberFormat.currency(
          locale: 'es_CR',
          symbol: 'CRC ',
          decimalDigits: 0,
        ).format(totalRevenue),
        icon: Icons.payments_rounded,
      ),
    ];
  }

  _TodaySummaryData _buildSummary(List<Map<String, dynamic>> bookings) {
    final uniqueBarbers = <String>{};
    final occupiedSlots = <_Interval>[];

    for (final booking in bookings) {
      final barberName = appointmentBarberName(booking);
      if (barberName.trim().isNotEmpty && barberName != 'Sin asignar') {
        uniqueBarbers.add(barberName);
      }
      final interval = _bookingInterval(booking);
      if (interval != null) {
        occupiedSlots.add(interval);
      }
    }

    occupiedSlots.sort((a, b) => a.start.compareTo(b.start));
    final freeSlots = _estimateFreeSlots(occupiedSlots);

    final totalRevenue = bookings.fold<double>(
      0,
      (sum, booking) => sum + _bookingPrice(booking),
    );

    return _TodaySummaryData(
      appointments: bookings.length,
      revenue: totalRevenue,
      activeBarbers: uniqueBarbers.length,
      freeSlots: freeSlots,
    );
  }

  String _summaryHint(
    List<Map<String, dynamic>> visible,
    List<Map<String, dynamic>> all,
  ) {
    if (visible.isEmpty && all.isNotEmpty) {
      return 'Hay ${all.length} citas cargadas en total, pero ningún resultado coincide con este filtro.';
    }
    return '${visible.length} resultados visibles en la agenda de ${_selectedDayLabel(_selectedDay)}.';
  }

  String _selectedDayHeaderLabel(DateTime day) {
    final dayName = _weekdayNameEs(day.weekday);
    final monthName = _monthNameEs(day.month);
    return '${_capitalize(dayName)} ${day.day} de ${_capitalize(monthName)}';
  }

  String _selectedDayShortLabel(DateTime day) {
    if (_sameDay(day, DateTime.now())) return 'Hoy';
    if (_sameDay(day, DateTime.now().add(const Duration(days: 1)))) {
      return 'Mañana';
    }
    return _selectedDayHeaderLabel(day);
  }

  String _selectedDayButtonLabel(DateTime day) {
    if (_sameDay(day, DateTime.now())) return 'Hoy';
    return '${day.day} ${_shortMonthNameEs(day.month)}';
  }

  String _selectedDayLabel(DateTime day) {
    if (_sameDay(day, DateTime.now())) return 'Hoy';
    if (_sameDay(day, DateTime.now().add(const Duration(days: 1)))) {
      return 'Mañana';
    }
    return _selectedDayHeaderLabel(day);
  }

  String _barberKey(Map<String, dynamic> booking) {
    final barber = appointmentBarber(booking);
    final rawId = barber['id'];
    if (rawId != null && rawId.toString().trim().isNotEmpty) {
      return rawId.toString();
    }
    final name = barber['name']?.toString().trim() ?? '';
    return name.isNotEmpty ? name.toLowerCase() : _AgendaBarberFilter.allKey;
  }

  int _startMinutes(Map<String, dynamic> booking) {
    final raw = (booking['time_slot'] ?? '').toString().trim();
    if (raw.isEmpty) return 24 * 60;

    final parsed = DateTime.tryParse(raw);
    if (parsed != null && raw.contains('T')) {
      return parsed.hour * 60 + parsed.minute;
    }

    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match != null) {
      final hour = int.tryParse(match.group(1) ?? '') ?? 0;
      final minute = int.tryParse(match.group(2) ?? '') ?? 0;
      return hour * 60 + minute;
    }

    return 24 * 60;
  }

  _AgendaStatusTag _statusTag(Map<String, dynamic> booking) {
    final rawStatus = (booking['status'] ?? '').toString().trim().toLowerCase();
    if (rawStatus.contains('cancel') || rawStatus.contains('anul')) {
      return _AgendaStatusTag.cancelled;
    }
    if (rawStatus.contains('complete') ||
        rawStatus.contains('done') ||
        rawStatus.contains('finish') ||
        rawStatus.contains('final') ||
        rawStatus.contains('hist')) {
      return _AgendaStatusTag.completed;
    }
    if (rawStatus.contains('confirm') || rawStatus.contains('approve')) {
      return _AgendaStatusTag.confirmed;
    }
    if (rawStatus.contains('pending') ||
        rawStatus.contains('pendient') ||
        rawStatus.contains('wait')) {
      return _AgendaStatusTag.pending;
    }

    final date = appointmentDate(booking);
    if (date == null) return _AgendaStatusTag.pending;
    if (date.isBefore(DateTime.now())) return _AgendaStatusTag.completed;
    return _AgendaStatusTag.confirmed;
  }

  bool _matchesStatusFilter(
    Map<String, dynamic> booking,
    _AgendaStatusFilter filter,
  ) {
    final tag = _statusTag(booking);
    switch (filter) {
      case _AgendaStatusFilter.all:
        return true;
      case _AgendaStatusFilter.pending:
        return tag == _AgendaStatusTag.pending;
      case _AgendaStatusFilter.confirmed:
        return tag == _AgendaStatusTag.confirmed;
      case _AgendaStatusFilter.completed:
        return tag == _AgendaStatusTag.completed;
      case _AgendaStatusFilter.cancelled:
        return tag == _AgendaStatusTag.cancelled;
    }
  }

  double _bookingPrice(Map<String, dynamic> booking) {
    final resource = appointmentResource(booking);
    final value =
        booking['total_price'] ??
        booking['price'] ??
        resource['price_per_hour'] ??
        resource['price'];
    if (value is num) return value.toDouble();
    final raw = (value?.toString() ?? '').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(raw) ?? 0;
  }

  _Interval? _bookingInterval(Map<String, dynamic> booking) {
    final minutes = _startMinutes(booking);
    if (minutes >= 24 * 60) return null;

    final duration = _durationMinutes(booking);
    if (duration <= 0) return null;
    return _Interval(start: minutes, end: minutes + duration);
  }

  int _durationMinutes(Map<String, dynamic> booking) {
    final resource = appointmentResource(booking);
    final durationMinutes =
        booking['duration_minutes'] ?? resource['duration_minutes'];
    final durationHours =
        booking['duration_hours'] ?? resource['duration_hours'];

    final minutes = durationMinutes is num
        ? durationMinutes.toInt()
        : int.tryParse(durationMinutes?.toString() ?? '');
    if (minutes != null && minutes > 0) return minutes;

    final hours = durationHours is num
        ? durationHours.toInt()
        : int.tryParse(durationHours?.toString() ?? '');
    if (hours != null && hours > 0) return hours * 60;

    return 60;
  }

  int _estimateFreeSlots(List<_Interval> occupied) {
    const workStart = 9 * 60;
    const workEnd = 19 * 60;
    const slot = 30;
    if (occupied.isEmpty) {
      return ((workEnd - workStart) / slot).floor();
    }

    var free = 0;
    var cursor = workStart;
    for (final block in occupied) {
      final start = block.start.clamp(workStart, workEnd);
      final end = block.end.clamp(workStart, workEnd);
      if (end <= workStart || start >= workEnd) continue;
      if (start > cursor) {
        free += ((start - cursor) / slot).floor();
      }
      cursor = math.max(cursor, end);
    }
    if (cursor < workEnd) {
      free += ((workEnd - cursor) / slot).floor();
    }
    return math.max(0, free);
  }

  int _bookingId(Map<String, dynamic> booking) {
    final raw = booking['id'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _weekdayNameEs(int weekday) {
    const weekdays = <String>[
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    if (weekday < 1 || weekday > weekdays.length) return '';
    return weekdays[weekday - 1];
  }

  String _monthNameEs(int month) {
    const months = <String>[
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    if (month < 1 || month > months.length) return '';
    return months[month - 1];
  }

  String _shortMonthNameEs(int month) {
    final monthName = _monthNameEs(month);
    if (monthName.length <= 3) return monthName;
    return monthName.substring(0, 3);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

class _PremiumHeader extends StatelessWidget {
  final String title;
  final String dayLabel;
  final String subtitle;
  final String summaryHint;

  const _PremiumHeader({
    required this.title,
    required this.dayLabel,
    required this.subtitle,
    required this.summaryHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171311), Color(0xFF10100F), Color(0xFF0A0909)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: .22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dayLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF221A12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: .22),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Executive',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Schedule Center',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  summaryHint,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final List<_KpiMetric> metrics;

  const _KpiStrip({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: metrics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return _KpiCard(metric: metric);
        },
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final _KpiMetric metric;

  const _KpiCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 164,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161110),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withValues(alpha: .16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, size: 18, color: AppColors.primary),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedFiltersDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _PinnedFiltersDelegate({required this.child});

  @override
  double get minExtent => 172;

  @override
  double get maxExtent => 172;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedFiltersDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
      ],
    );
  }
}

class _HorizontalChipStrip extends StatelessWidget {
  final List<_ChipSpec> chips;

  const _HorizontalChipStrip({required this.chips});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _PremiumChip(spec: chips[index]),
      ),
    );
  }
}

class _PremiumChip extends StatelessWidget {
  final _ChipSpec spec;

  const _PremiumChip({required this.spec});

  @override
  Widget build(BuildContext context) {
    final selected = spec.selected;
    return InkWell(
      onTap: spec.onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: spec.compact ? 14 : 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : const Color(0xFF181411),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.secondary
                : Colors.white.withValues(alpha: .08),
          ),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x33C9A56A),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          spec.label,
          style: TextStyle(
            color: selected ? const Color(0xFF090909) : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  final List<_TimelineGroup> groups;
  final Future<void> Function(Map<String, dynamic> booking) onOpenDetail;
  final Future<void> Function(Map<String, dynamic> booking) onRebook;
  final Future<void> Function(Map<String, dynamic> booking) onCancel;
  final void Function(Map<String, dynamic> booking) onMarkCompleted;

  const _TimelineSection({
    required this.groups,
    required this.onOpenDetail,
    required this.onRebook,
    required this.onCancel,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in groups) ...[
          _TimelineGroupTile(
            group: group,
            onOpenDetail: onOpenDetail,
            onRebook: onRebook,
            onCancel: onCancel,
            onMarkCompleted: onMarkCompleted,
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _TimelineGroupTile extends StatelessWidget {
  final _TimelineGroup group;
  final Future<void> Function(Map<String, dynamic> booking) onOpenDetail;
  final Future<void> Function(Map<String, dynamic> booking) onRebook;
  final Future<void> Function(Map<String, dynamic> booking) onCancel;
  final void Function(Map<String, dynamic> booking) onMarkCompleted;

  const _TimelineGroupTile({
    required this.group,
    required this.onOpenDetail,
    required this.onRebook,
    required this.onCancel,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 620;
    final timeLabel = _formatTime(group.minutes);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: compact ? 56 : 72,
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeLabel,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'h',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .42),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55C9A56A),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: .8),
                        AppColors.primary.withValues(alpha: .18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              children: [
                for (final booking in group.items) ...[
                  _AppointmentTimelineCard(
                    booking: booking,
                    compact: compact,
                    onOpenDetail: onOpenDetail,
                    onRebook: onRebook,
                    onCancel: onCancel,
                    onMarkCompleted: onMarkCompleted,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentTimelineCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final bool compact;
  final Future<void> Function(Map<String, dynamic> booking) onOpenDetail;
  final Future<void> Function(Map<String, dynamic> booking) onRebook;
  final Future<void> Function(Map<String, dynamic> booking) onCancel;
  final void Function(Map<String, dynamic> booking) onMarkCompleted;

  const _AppointmentTimelineCard({
    required this.booking,
    required this.compact,
    required this.onOpenDetail,
    required this.onRebook,
    required this.onCancel,
    required this.onMarkCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final status = _statusTagStatic(booking);
    final premium = _isPremium(booking);
    final time = appointmentTimeLabel(booking);
    final duration = _durationLabel(booking);
    final price = appointmentPriceLabel(booking);
    final barberName = appointmentBarberName(booking);
    final clientName = _clientNameStatic(booking);
    final serviceName = appointmentServiceName(booking);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x46000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171311), Color(0xFF11100F)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -38,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: .12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (compact)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardImage(images: appointmentImageSource(booking)),
                        const SizedBox(height: 12),
                        _CardHeader(
                          serviceName: serviceName,
                          clientName: clientName,
                          barberName: barberName,
                          status: status,
                          premium: premium,
                          bookingCode: appointmentCode(booking),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CardImage(images: appointmentImageSource(booking)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _CardHeader(
                            serviceName: serviceName,
                            clientName: clientName,
                            barberName: barberName,
                            status: status,
                            premium: premium,
                            bookingCode: appointmentCode(booking),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MetaChip(icon: Icons.schedule_rounded, label: time),
                      _MetaChip(icon: Icons.timelapse_rounded, label: duration),
                      _MetaChip(icon: Icons.payments_rounded, label: price),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ActionRow(
                    onDetail: () => onOpenDetail(booking),
                    onRebook: () => onRebook(booking),
                    onCancel: () => onCancel(booking),
                    onComplete: () => onMarkCompleted(booking),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _AgendaStatusTag _statusTagStatic(Map<String, dynamic> booking) {
    final rawStatus = (booking['status'] ?? '').toString().trim().toLowerCase();
    if (rawStatus.contains('cancel') || rawStatus.contains('anul')) {
      return _AgendaStatusTag.cancelled;
    }
    if (rawStatus.contains('complete') ||
        rawStatus.contains('done') ||
        rawStatus.contains('finish') ||
        rawStatus.contains('final') ||
        rawStatus.contains('hist')) {
      return _AgendaStatusTag.completed;
    }
    if (rawStatus.contains('confirm') || rawStatus.contains('approve')) {
      return _AgendaStatusTag.confirmed;
    }
    if (rawStatus.contains('pending') ||
        rawStatus.contains('pendient') ||
        rawStatus.contains('wait')) {
      return _AgendaStatusTag.pending;
    }
    final date = appointmentDate(booking);
    if (date == null) return _AgendaStatusTag.pending;
    if (date.isBefore(DateTime.now())) return _AgendaStatusTag.completed;
    return _AgendaStatusTag.confirmed;
  }

  static String _clientNameStatic(Map<String, dynamic> booking) {
    final user = (booking['user'] as Map<String, dynamic>?) ?? const {};
    final direct =
        user['name']?.toString().trim() ??
        booking['client_name']?.toString().trim() ??
        booking['customer_name']?.toString().trim() ??
        '';
    if (direct.isNotEmpty) return direct;
    final email = user['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return email;
    return 'Sin cliente';
  }

  static bool _isPremium(Map<String, dynamic> booking) {
    final resource = appointmentResource(booking);
    final raw = [
      booking['premium'],
      booking['is_premium'],
      booking['vip'],
      resource['premium'],
      resource['is_premium'],
      resource['vip'],
    ].any((value) => value == true);
    if (raw) return true;
    final name = appointmentServiceName(booking).toLowerCase();
    return name.contains('premium');
  }

  static String _durationLabel(Map<String, dynamic> booking) {
    final resource = appointmentResource(booking);
    final durationMinutes =
        booking['duration_minutes'] ?? resource['duration_minutes'];
    final durationHours =
        booking['duration_hours'] ?? resource['duration_hours'];

    final minutes = durationMinutes is num
        ? durationMinutes.toInt()
        : int.tryParse(durationMinutes?.toString() ?? '');
    if (minutes != null && minutes > 0) {
      if (minutes % 60 == 0) {
        final hours = minutes ~/ 60;
        return hours == 1 ? '1 hora' : '$hours horas';
      }
      final hours = minutes ~/ 60;
      final remainder = minutes % 60;
      if (hours == 0) return '$remainder min';
      return '${hours}h ${remainder}m';
    }

    final hours = durationHours is num
        ? durationHours.toInt()
        : int.tryParse(durationHours?.toString() ?? '1') ?? 1;
    return hours == 1 ? '1 hora' : '$hours horas';
  }
}

class _CardImage extends StatelessWidget {
  final dynamic images;

  const _CardImage({required this.images});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 110,
      child: CourtImage(images: images, radius: BorderRadius.circular(22)),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String serviceName;
  final String clientName;
  final String barberName;
  final _AgendaStatusTag status;
  final bool premium;
  final String bookingCode;

  const _CardHeader({
    required this.serviceName,
    required this.clientName,
    required this.barberName,
    required this.status,
    required this.premium,
    required this.bookingCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                serviceName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            if (premium) ...[const SizedBox(width: 8), const _PremiumBadge()],
          ],
        ),
        const SizedBox(height: 10),
        _InlineRow(icon: Icons.person_rounded, text: clientName),
        const SizedBox(height: 6),
        _InlineRow(
          icon: Icons.content_cut_rounded,
          text: barberName,
          iconColor: AppColors.secondary,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatusBadge(status: status),
            _BookingCodeChip(label: bookingCode),
          ],
        ),
      ],
    );
  }
}

class _InlineRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _InlineRow({
    required this.icon,
    required this.text,
    this.iconColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: .22)),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _AgendaStatusTag status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bg = _statusBackground(status);
    final fg = _statusForeground(status);
    final label = _statusLabel(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: .25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: .9,
        ),
      ),
    );
  }
}

class _BookingCodeChip extends StatelessWidget {
  final String label;

  const _BookingCodeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1712),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1411),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onDetail;
  final VoidCallback onRebook;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const _ActionRow({
    required this.onDetail,
    required this.onRebook,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final children = [
          _ActionButton(
            label: 'Ver detalle',
            icon: Icons.visibility_rounded,
            onTap: onDetail,
          ),
          _ActionButton(
            label: 'Reagendar',
            icon: Icons.autorenew_rounded,
            onTap: onRebook,
            accent: true,
          ),
          _ActionButton(
            label: 'Cancelar',
            icon: Icons.close_rounded,
            onTap: onCancel,
            danger: true,
          ),
          _ActionButton(
            label: 'Marcar completada',
            icon: Icons.task_alt_rounded,
            onTap: onComplete,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (final child in children) ...[
                SizedBox(width: double.infinity, child: child),
                const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Wrap(spacing: 10, runSpacing: 10, children: children);
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;
  final bool danger;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.accent = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = danger
        ? const Color(0xFF281416)
        : accent
        ? AppColors.primary
        : const Color(0xFF1A1411);
    final foreground = danger
        ? const Color(0xFFFFA2A2)
        : accent
        ? const Color(0xFF090909)
        : Colors.white;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodaySummaryCard extends StatelessWidget {
  final _TodaySummaryData summary;

  const _TodaySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'es_CR',
      symbol: 'CRC ',
      decimalDigits: 0,
    ).format(summary.revenue);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF151110),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x54000000),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Resumen del día',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              final tiles = [
                _SummaryTile(
                  label: 'Citas',
                  value: summary.appointments.toString(),
                  icon: Icons.calendar_today_rounded,
                  width: compact ? constraints.maxWidth : 160,
                ),
                _SummaryTile(
                  label: 'Estimados',
                  value: currency,
                  icon: Icons.payments_rounded,
                  width: compact ? constraints.maxWidth : 160,
                ),
                _SummaryTile(
                  label: 'Barberos activos',
                  value: summary.activeBarbers.toString(),
                  icon: Icons.content_cut_rounded,
                  width: compact ? constraints.maxWidth : 160,
                ),
                _SummaryTile(
                  label: 'Espacios libres',
                  value: summary.freeSlots.toString(),
                  icon: Icons.event_available_rounded,
                  width: compact ? constraints.maxWidth : 160,
                ),
              ];

              if (compact) {
                return Column(
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      const SizedBox(height: 10),
                    ],
                  ],
                );
              }

              return Wrap(spacing: 12, runSpacing: 12, children: tiles);
            },
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final double width;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0E0D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final Future<void> Function() onAction;

  const _PremiumStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF151110),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: .14)),
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: .14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: .18),
              ),
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => onAction(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF090909),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _TimelineGroup {
  final int minutes;
  final List<Map<String, dynamic>> items;

  const _TimelineGroup({required this.minutes, required this.items});
}

class _Interval {
  final int start;
  final int end;

  const _Interval({required this.start, required this.end});
}

class _KpiMetric {
  final String label;
  final String value;
  final IconData icon;

  const _KpiMetric({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _TodaySummaryData {
  final int appointments;
  final double revenue;
  final int activeBarbers;
  final int freeSlots;

  const _TodaySummaryData({
    required this.appointments,
    required this.revenue,
    required this.activeBarbers,
    required this.freeSlots,
  });
}

class _ReservationsLoadResult {
  final List<Map<String, dynamic>> bookings;
  final String? errorMessage;

  const _ReservationsLoadResult({required this.bookings, this.errorMessage});
}

class _ChipSpec {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  const _ChipSpec({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
}

class _BarberOption {
  final String key;
  final String label;

  const _BarberOption({required this.key, required this.label});
}

enum _AgendaStatusFilter { all, pending, confirmed, completed, cancelled }

enum _AgendaStatusTag { pending, confirmed, completed, cancelled }

class _AgendaBarberFilter {
  static const allKey = 'all';
}

String _statusLabel(_AgendaStatusTag status) {
  switch (status) {
    case _AgendaStatusTag.pending:
      return 'PENDIENTE';
    case _AgendaStatusTag.confirmed:
      return 'CONFIRMADA';
    case _AgendaStatusTag.completed:
      return 'COMPLETADA';
    case _AgendaStatusTag.cancelled:
      return 'CANCELADA';
  }
}

Color _statusBackground(_AgendaStatusTag status) {
  switch (status) {
    case _AgendaStatusTag.pending:
      return const Color(0xFF2E2315);
    case _AgendaStatusTag.confirmed:
      return const Color(0xFF1B271E);
    case _AgendaStatusTag.completed:
      return const Color(0xFF18231D);
    case _AgendaStatusTag.cancelled:
      return const Color(0xFF301B1C);
  }
}

Color _statusForeground(_AgendaStatusTag status) {
  switch (status) {
    case _AgendaStatusTag.pending:
      return const Color(0xFFC9A56A);
    case _AgendaStatusTag.confirmed:
      return const Color(0xFFB9E2C0);
    case _AgendaStatusTag.completed:
      return const Color(0xFFE8D8B8);
    case _AgendaStatusTag.cancelled:
      return const Color(0xFFFF9D9D);
  }
}

String _formatTime(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}
