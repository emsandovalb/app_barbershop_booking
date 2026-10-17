import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'admin_page_scaffold.dart';
import 'operations_board.dart';
import '../../services/business_clock.dart';

class AdminReservationsPage extends StatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  State<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends State<AdminReservationsPage> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = BusinessClock.today();
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: BusinessClock.today().subtract(const Duration(days: 365)),
      lastDate: BusinessClock.today().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _selectedDay = _dateOnly(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<LocalizationService>();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.canManageBusiness;

    if (!isAdmin) {
      return Scaffold(
        appBar: buildAdminAppBar(
          context,
          title: loc.t('admin_reservations_title'),
        ),
        body: Center(child: Text(loc.t('grounds_admin_only'))),
      );
    }

    return Scaffold(
      appBar: buildAdminAppBar(
        context,
        title: loc.t('admin_reservations_title'),
        subtitle: formatDate('EEEE, MMM d', _selectedDay),
        actions: [
          IconButton(
            onPressed: _pickDay,
            icon: const Icon(Icons.calendar_month_rounded),
            tooltip: tr('admin_pick_day'),
          ),
        ],
      ),
      body: OperationsBoard(selectedDay: _selectedDay),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickDay,
        backgroundColor: const Color(0xFF141110),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_rounded),
        label: Text(formatDate('MM/dd', _selectedDay)),
      ),
    );
  }
}

DateTime _dateOnly(DateTime input) =>
    DateTime(input.year, input.month, input.day);
