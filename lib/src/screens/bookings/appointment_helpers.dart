import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum AppointmentStatusBucket { upcoming, completed, cancelled }

Map<String, dynamic> appointmentResource(Map<String, dynamic> booking) {
  return (booking['resource'] as Map<String, dynamic>?) ??
      (booking['court'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
}

Map<String, dynamic> appointmentBarber(Map<String, dynamic> booking) {
  return (booking['staff'] as Map<String, dynamic>?) ??
      (booking['barber'] as Map<String, dynamic>?) ??
      (booking['provider'] as Map<String, dynamic>?) ??
      const <String, dynamic>{};
}

DateTime? appointmentDate(Map<String, dynamic> booking) {
  return DateTime.tryParse((booking['date'] ?? '').toString());
}

String appointmentServiceName(Map<String, dynamic> booking) {
  final resource = appointmentResource(booking);
  return resource['name']?.toString().trim().isNotEmpty == true
      ? resource['name'].toString()
      : 'Servicio';
}

String appointmentBarberName(Map<String, dynamic> booking) {
  final barber = appointmentBarber(booking);
  final name = barber['name']?.toString().trim() ?? '';
  return name.isNotEmpty ? name : 'Sin asignar';
}

String appointmentCode(Map<String, dynamic> booking) {
  return (booking['booking_code'] ?? '—').toString();
}

String appointmentDateLabel(Map<String, dynamic> booking) {
  final date = appointmentDate(booking);
  if (date == null) return 'Fecha por confirmar';
  return '${date.day} ${_monthNameEs(date.month)} ${date.year}';
}

String appointmentTimeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Hora por confirmar';
  final parsed = DateTime.tryParse(raw);
  if (parsed != null && raw.contains('T')) {
    final hour = parsed.hour.toString().padLeft(2, '0');
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
  return raw;
}

String appointmentPriceLabel(Map<String, dynamic> booking) {
  final resource = appointmentResource(booking);
  final value = booking['total_price'] ?? booking['price'] ?? resource['price_per_hour'];
  final number = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: 'CRC ',
    decimalDigits: 0,
  ).format(number);
}

dynamic appointmentImageSource(Map<String, dynamic> booking) {
  final resource = appointmentResource(booking);
  return booking['service_image'] ??
      booking['image'] ??
      booking['images'] ??
      resource['service_image'] ??
      resource['image'] ??
      resource['images'] ??
      resource['cover_image_url'] ??
      resource['cover_image'] ??
      resource['image_url'];
}

AppointmentStatusBucket appointmentStatusBucket(Map<String, dynamic> booking) {
  final rawStatus = (booking['status'] ?? '').toString().trim().toLowerCase();
  if (rawStatus.contains('cancel') || rawStatus.contains('anul')) {
    return AppointmentStatusBucket.cancelled;
  }
  if (rawStatus.contains('complete') ||
      rawStatus.contains('done') ||
      rawStatus.contains('finish') ||
      rawStatus.contains('final') ||
      rawStatus.contains('hist')) {
    return AppointmentStatusBucket.completed;
  }
  if (rawStatus.contains('upcoming') ||
      rawStatus.contains('active') ||
      rawStatus.contains('pending') ||
      rawStatus.contains('scheduled') ||
      rawStatus.contains('prog')) {
    return AppointmentStatusBucket.upcoming;
  }

  final date = appointmentDate(booking);
  if (date == null) {
    return AppointmentStatusBucket.upcoming;
  }
  return date.isBefore(DateTime.now())
      ? AppointmentStatusBucket.completed
      : AppointmentStatusBucket.upcoming;
}

String appointmentStatusLabel(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return 'Próxima';
    case AppointmentStatusBucket.completed:
      return 'Completada';
    case AppointmentStatusBucket.cancelled:
      return 'Cancelada';
  }
}

String appointmentTabLabel(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return 'Próximas';
    case AppointmentStatusBucket.completed:
      return 'Completadas';
    case AppointmentStatusBucket.cancelled:
      return 'Canceladas';
  }
}

Color appointmentStatusBackground(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return const Color(0xFF2E2315);
    case AppointmentStatusBucket.completed:
      return const Color(0xFF16261F);
    case AppointmentStatusBucket.cancelled:
      return const Color(0xFF301B1C);
  }
}

Color appointmentStatusForeground(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return const Color(0xFFC9A56A);
    case AppointmentStatusBucket.completed:
      return const Color(0xFFE8D8B8);
    case AppointmentStatusBucket.cancelled:
      return const Color(0xFFFF9D9D);
  }
}

bool canCancelAppointment(Map<String, dynamic> booking) {
  final bucket = appointmentStatusBucket(booking);
  if (bucket != AppointmentStatusBucket.upcoming) return false;
  final date = appointmentDate(booking);
  if (date == null) return false;
  return date.difference(DateTime.now()).inHours >= 4;
}

bool canRebookAppointment(Map<String, dynamic> booking) {
  return appointmentStatusBucket(booking) != AppointmentStatusBucket.upcoming
      ? true
      : true;
}

List<Map<String, dynamic>> filterAppointments(
  List<dynamic> items,
  AppointmentStatusBucket bucket,
) {
  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .where((booking) => appointmentStatusBucket(booking) == bucket)
      .toList(growable: false);
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
