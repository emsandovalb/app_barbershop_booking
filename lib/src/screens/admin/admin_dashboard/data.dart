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

const List<_QuickActionData> _quickActions = [
  _QuickActionData(
    id: 'new_appointment',
    icon: Icons.event_available_rounded,
    label: 'Nueva cita',
    description: 'Atajo premium para comenzar una reserva.',
  ),
  _QuickActionData(
    id: 'new_barber',
    icon: Icons.person_add_alt_1_rounded,
    label: 'Nuevo perfil',
    description: 'Sumá un perfil al equipo.',
  ),
  _QuickActionData(
    id: 'new_service',
    icon: Icons.content_cut_rounded,
    label: 'Nuevo servicio',
    description: 'Creá un servicio con tarifa y duración.',
  ),
  _QuickActionData(
    id: 'schedule',
    icon: Icons.calendar_month_rounded,
    label: 'Ver agenda',
    description: 'Abrí las citas del día en una vista rápida.',
  ),
];

const List<Map<String, dynamic>> _fallbackReservations = [
  {
    'id': 901,
    'date': '2026-06-30',
    'time_slot': '09:00',
    'status': 'upcoming',
    'price': 12000,
    'booking_code': 'TA-901',
    'user': {'name': 'Carlos Méndez'},
    'resource': {
      'id': 11,
      'name': 'Corte y Barba',
      'price_per_hour': 12000,
      'images': [''],
    },
    'staff': {'id': 3, 'name': 'Luis Herrera', 'is_active': true},
  },
  {
    'id': 902,
    'date': '2026-06-30',
    'time_slot': '10:30',
    'status': 'completed',
    'price': 9000,
    'booking_code': 'TA-902',
    'user': {'name': 'Andrés Ruiz'},
    'resource': {
      'id': 12,
      'name': 'Fade Signature',
      'price_per_hour': 9000,
      'images': [''],
    },
    'staff': {'id': 2, 'name': 'Marcos Solís', 'is_active': true},
  },
  {
    'id': 903,
    'date': '2026-06-30',
    'time_slot': '12:00',
    'status': 'upcoming',
    'price': 15000,
    'booking_code': 'TA-903',
    'user': {'name': 'Gabriel Pérez'},
    'resource': {
      'id': 13,
      'name': 'Experiencia Completa',
      'price_per_hour': 15000,
      'images': [''],
    },
    'staff': {'id': 4, 'name': 'José Vargas', 'is_active': true},
  },
  {
    'id': 904,
    'date': '2026-06-30',
    'time_slot': '14:00',
    'status': 'pending',
    'price': 7000,
    'booking_code': 'TA-904',
    'user': {'name': 'Ricardo León'},
    'resource': {
      'id': 14,
      'name': 'Perfilado Premium',
      'price_per_hour': 7000,
      'images': [''],
    },
    'staff': {'id': 1, 'name': 'Daniel Mora', 'is_active': true},
  },
];

const List<Map<String, dynamic>> _fallbackStaff = [
  {
    'id': 1,
    'name': 'Daniel Mora',
    'is_active': true,
    'avatar': '',
    'services': [
      {
        'resource': {'name': 'Corte y Barba'},
      },
      {
        'resource': {'name': 'Fade Signature'},
      },
    ],
  },
  {
    'id': 2,
    'name': 'Marcos Solís',
    'is_active': true,
    'avatar': '',
    'services': [
      {
        'resource': {'name': 'Perfilado Premium'},
      },
    ],
  },
  {
    'id': 3,
    'name': 'Luis Herrera',
    'is_active': true,
    'avatar': '',
    'services': [
      {
        'resource': {'name': 'Corte Clásico'},
      },
      {
        'resource': {'name': 'Barba Deluxe'},
      },
    ],
  },
  {
    'id': 4,
    'name': 'José Vargas',
    'is_active': false,
    'avatar': '',
    'services': [
      {
        'resource': {'name': 'Experiencia Completa'},
      },
    ],
  },
];

const List<Map<String, dynamic>> _fallbackResources = [
  {
    'id': 11,
    'name': 'Corte y Barba',
    'price_per_hour': 12000,
    'duration_hours': 1,
  },
  {
    'id': 12,
    'name': 'Fade Signature',
    'price_per_hour': 9000,
    'duration_hours': 1,
  },
  {
    'id': 13,
    'name': 'Experiencia Completa',
    'price_per_hour': 15000,
    'duration_hours': 2,
  },
  {
    'id': 14,
    'name': 'Perfilado Premium',
    'price_per_hour': 7000,
    'duration_hours': 1,
  },
];

const List<_PerformanceData> _fallbackPerformance = [
  _PerformanceData(
    avatar: '',
    name: 'Daniel Mora',
    appointments: 4,
    revenue: 42000,
    active: true,
  ),
  _PerformanceData(
    avatar: '',
    name: 'Marcos Solís',
    appointments: 3,
    revenue: 33000,
    active: true,
  ),
  _PerformanceData(
    avatar: '',
    name: 'Luis Herrera',
    appointments: 2,
    revenue: 21000,
    active: true,
  ),
  _PerformanceData(
    avatar: '',
    name: 'José Vargas',
    appointments: 1,
    revenue: 12000,
    active: false,
  ),
];

const List<_TopServiceData> _fallbackTopServices = [
  _TopServiceData(
    name: 'Corte y Barba',
    reservations: 5,
    revenue: 60000,
    progress: .95,
  ),
  _TopServiceData(
    name: 'Fade Signature',
    reservations: 4,
    revenue: 36000,
    progress: .75,
  ),
  _TopServiceData(
    name: 'Experiencia Completa',
    reservations: 2,
    revenue: 30000,
    progress: .48,
  ),
  _TopServiceData(
    name: 'Perfilado Premium',
    reservations: 1,
    revenue: 7000,
    progress: .28,
  ),
];

Map<String, dynamic> get _fallbackReservationsResponse => {
  'data': _fallbackReservations,
};

Map<String, dynamic> get _fallbackStaffResponse => {'data': _fallbackStaff};

Map<String, dynamic> get _fallbackResourcesResponse => {
  'data': _fallbackResources,
};
