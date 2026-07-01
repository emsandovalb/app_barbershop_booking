import 'package:intl/intl.dart';

String serviceName(Map<String, dynamic> service) {
  final name = service['name']?.toString().trim() ?? '';
  return name.isNotEmpty ? name : 'Servicio';
}

String serviceCategory(Map<String, dynamic> service) {
  final value = service['category']?.toString().trim() ?? '';
  return value.isNotEmpty ? value : 'General';
}

bool serviceIsActive(Map<String, dynamic> service) {
  final raw = service['status']?.toString().toLowerCase().trim();
  return raw != 'inactive' && raw != 'disabled';
}

double servicePrice(Map<String, dynamic> service) {
  final raw = service['price_per_hour'] ?? service['price'];
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

int serviceDurationMinutes(Map<String, dynamic> service) {
  final direct = _intValue(service['duration_minutes']);
  if (direct != null && direct > 0) return direct;
  final hours = _intValue(service['duration_hours']) ?? _intValue(service['duration']);
  if (hours != null && hours > 0) return hours * 60;
  return 60;
}

String serviceDurationLabel(Map<String, dynamic> service) {
  final minutes = serviceDurationMinutes(service);
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  if (hours <= 0) {
    return '$minutes min';
  }
  if (remainder == 0) {
    return hours == 1 ? '1 h' : '$hours h';
  }
  return hours == 1 ? '1 h $remainder min' : '$hours h $remainder min';
}

String serviceImage(Map<String, dynamic> service) {
  final candidates = [
    service['service_image'],
    service['image_url'],
    service['image_path'],
    service['image'],
    service['cover_image_url'],
    service['cover_image'],
    service['avatar'],
  ];
  for (final candidate in candidates) {
    final value = candidate?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  final images = service['images'];
  if (images is List && images.isNotEmpty) {
    for (final item in images) {
      final value = item?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
  }
  if (images is String && images.trim().isNotEmpty) {
    return images.trim();
  }
  return '';
}

int serviceStaffCount(Map<String, dynamic> service) {
  final count = _intValue(service['staff_count']);
  if (count != null) return count;
  final staff = service['staff'];
  if (staff is List) return staff.length;
  return 0;
}

Map<String, dynamic> serviceStaffEntry(Map<String, dynamic> staff) {
  final role = (staff['role'] as Map?) ?? const {};
  return Map<String, dynamic>.from(staff)..['role'] = Map<String, dynamic>.from(role);
}

String staffDisplayName(Map<String, dynamic> staff) {
  final name = staff['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = staff['first_name']?.toString().trim() ?? '';
  final last = staff['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  return combined.isNotEmpty ? combined : 'Barbero';
}

String staffRoleLabel(Map<String, dynamic> staff) {
  final role = (staff['role'] as Map?) ?? const {};
  final name = role['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final slug = role['slug']?.toString().trim() ?? '';
  if (slug.isNotEmpty) return slug;
  return 'Barbero';
}

bool staffIsBarber(Map<String, dynamic> staff) {
  final role = (staff['role'] as Map?) ?? const {};
  final values = [
    role['slug'],
    role['name'],
    staff['role_slug'],
    staff['role_name'],
  ];
  for (final value in values) {
    final text = value?.toString().toLowerCase().trim() ?? '';
    if (text.contains('barber') || text.contains('barbero')) {
      return true;
    }
  }
  return staff['is_active'] == true;
}

String formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}

int? _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
