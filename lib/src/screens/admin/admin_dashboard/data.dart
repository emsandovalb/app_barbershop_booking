part of '../admin_dashboard_page.dart';

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final String footnote;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.footnote,
  });
}

class _PerformanceData {
  final String avatar;
  final String name;
  final int appointments;
  final double revenue;
  final bool active;

  const _PerformanceData({
    required this.avatar,
    required this.name,
    required this.appointments,
    required this.revenue,
    required this.active,
  });
}

class _TopServiceData {
  final String name;
  final int reservations;
  final double revenue;
  final double progress;

  const _TopServiceData({
    required this.name,
    required this.reservations,
    required this.revenue,
    required this.progress,
  });
}

class _AdminModuleData {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;

  const _AdminModuleData({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

class _QuickActionData {
  final String id;
  final IconData icon;
  final String label;
  final String description;

  const _QuickActionData({
    required this.id,
    required this.icon,
    required this.label,
    required this.description,
  });
}

class _AdminDashboardData {
  final List<Map<String, dynamic>> reservations;
  final List<Map<String, dynamic>> staff;
  final List<Map<String, dynamic>> resources;

  const _AdminDashboardData({
    required this.reservations,
    required this.staff,
    required this.resources,
  });

  static const empty = _AdminDashboardData(
    reservations: [],
    staff: [],
    resources: [],
  );
}

List<_QuickActionData> get _quickActions => [
  _QuickActionData(
    id: 'new_appointment',
    icon: Icons.event_available_rounded,
    label: tr('admin_qa_new_appointment'),
    description: tr('admin_qa_new_appointment_body'),
  ),
  _QuickActionData(
    id: 'new_barber',
    icon: Icons.person_add_alt_1_rounded,
    label: tr('admin_qa_new_profile'),
    description: tr('admin_qa_new_profile_body'),
  ),
  _QuickActionData(
    id: 'new_service',
    icon: Icons.content_cut_rounded,
    label: tr('admin_qa_new_service'),
    description: tr('admin_qa_new_service_body'),
  ),
  _QuickActionData(
    id: 'schedule',
    icon: Icons.calendar_month_rounded,
    label: tr('admin_view_schedule'),
    description: tr('admin_qa_schedule_body'),
  ),
];
