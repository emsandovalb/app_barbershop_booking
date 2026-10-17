import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/business_clock.dart';
import '../../services/localization_service.dart';

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
  return BusinessClock.parseAppointment(booking['date']);
}

String appointmentServiceName(Map<String, dynamic> booking) {
  final resource = appointmentResource(booking);
  return resource['name']?.toString().trim().isNotEmpty == true
      ? resource['name'].toString()
      : tr('appointment_default_service');
}

String appointmentBarberName(Map<String, dynamic> booking) {
  final barber = appointmentBarber(booking);
  final name = barber['name']?.toString().trim() ?? '';
  return name.isNotEmpty ? name : tr('appointment_unassigned');
}

String appointmentCode(Map<String, dynamic> booking) {
  return (booking['booking_code'] ?? '—').toString();
}

String appointmentDateLabel(Map<String, dynamic> booking) {
  final date = appointmentDate(booking);
  if (date == null) return tr('appointment_date_tbd');
  // "20 de octubre de 2026" / "October 20, 2026".
  return formatDate('yMMMMd', date);
}

String appointmentTimeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? '').toString().trim();
  if (raw.isEmpty) return tr('appointment_time_tbd');
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
  final value =
      booking['total_price'] ?? booking['price'] ?? resource['price_per_hour'];
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
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
  if (rawStatus.contains('cancel') ||
      rawStatus.contains('anul') ||
      rawStatus.contains('reject')) {
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
  return date.isBefore(BusinessClock.now())
      ? AppointmentStatusBucket.completed
      : AppointmentStatusBucket.upcoming;
}

String appointmentStatusLabel(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return tr('status_upcoming');
    case AppointmentStatusBucket.completed:
      return tr('status_completed');
    case AppointmentStatusBucket.cancelled:
      return tr('status_cancelled');
  }
}

String appointmentStatusLabelForBooking(Map<String, dynamic> booking) {
  switch ((booking['status'] ?? '').toString().trim().toLowerCase()) {
    case 'pending':
      return tr('status_pending');
    case 'confirmed':
      return tr('status_confirmed');
    case 'completed':
      return tr('status_completed');
    case 'rejected':
      return tr('status_rejected');
    case 'cancelled':
      return tr('status_cancelled');
    default:
      return appointmentStatusLabel(appointmentStatusBucket(booking));
  }
}

String appointmentPaymentLabel(Map<String, dynamic> booking) =>
    (booking['payment_status'] ?? '').toString().toLowerCase() == 'paid'
    ? tr('payment_paid')
    : tr('payment_unpaid');

String appointmentTabLabel(AppointmentStatusBucket bucket) {
  switch (bucket) {
    case AppointmentStatusBucket.upcoming:
      return tr('bookings_tab_upcoming');
    case AppointmentStatusBucket.completed:
      return tr('bookings_tab_completed');
    case AppointmentStatusBucket.cancelled:
      return tr('bookings_tab_cancelled');
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

/// Whether the customer may still cancel: [windowHours] is the business's
/// cancellation window (WhiteLabelConfig.cancellationWindowHours), the same
/// rule the API enforces.
bool canCancelAppointment(
  Map<String, dynamic> booking, {
  required int windowHours,
}) {
  final bucket = appointmentStatusBucket(booking);
  if (bucket != AppointmentStatusBucket.upcoming) return false;
  final date = appointmentDate(booking);
  if (date == null) return false;
  return date.difference(BusinessClock.now()).inHours >= windowHours;
}

bool canRebookAppointment(Map<String, dynamic> booking) {
  return (booking['status'] ?? '').toString().toLowerCase() == 'pending';
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
