part of '../admin_dashboard_page.dart';

Map<String, int> _serviceCounts(List<Map<String, dynamic>> reservations) {
  final counts = <String, int>{};
  for (final booking in reservations) {
    final resource = appointmentResource(booking);
    final name = _serviceName(resource);
    counts[name] = (counts[name] ?? 0) + 1;
  }
  return counts;
}

Map<String, double> _estimatedRevenueByService(
  List<Map<String, dynamic>> reservations,
  List<Map<String, dynamic>> resources,
) {
  final lookup = <String, Map<String, dynamic>>{};
  for (final resource in resources) {
    final name = _serviceName(resource);
    lookup[name.toLowerCase()] = resource;
    lookup[_serviceKey(resource).toLowerCase()] = resource;
  }

  final result = <String, double>{};
  for (final booking in reservations) {
    final resource = appointmentResource(booking);
    final name = _serviceName(resource);
    final resourceInfo = lookup[name.toLowerCase()] ?? resource;
    final price = _bookingRevenue(
      booking,
      resources,
      fallbackResource: resourceInfo,
    );
    result[name] = (result[name] ?? 0) + price;
  }
  return result;
}

double _estimatedRevenue(
  List<Map<String, dynamic>> reservations,
  List<Map<String, dynamic>> resources,
) {
  return reservations.fold<double>(
    0,
    (sum, booking) => sum + _bookingRevenue(booking, resources),
  );
}

double _bookingRevenue(
  Map<String, dynamic> booking,
  List<Map<String, dynamic>> resources, {
  Map<String, dynamic>? fallbackResource,
}) {
  final resource = fallbackResource ?? appointmentResource(booking);
  final raw =
      booking['total_price'] ?? booking['price'] ?? resource['price_per_hour'];
  final number = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString() ?? '');
  if (number != null && number > 0) return number;
  final service = _servicePrice(resource);
  return service > 0 ? service : 72000;
}

double _servicePrice(Map<String, dynamic> resource) {
  final raw = resource['price_per_hour'] ?? resource['price'];
  if (raw is num) return raw.toDouble();
  return double.tryParse(raw?.toString() ?? '') ?? 0;
}

int _highestCount(Map<String, int> counts) {
  if (counts.isEmpty) return 1;
  return counts.values.reduce((a, b) => a > b ? a : b);
}

bool _isActive(Map<String, dynamic> staff) => staff['is_active'] != false;

String _staffName(Map<String, dynamic> staff) {
  final name = staff['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = staff['first_name']?.toString().trim() ?? '';
  final last = staff['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  return combined.isNotEmpty ? combined : 'Perfil';
}

String _staffAvatar(Map<String, dynamic> staff) {
  final raw =
      staff['avatar_url'] ??
      staff['avatar'] ??
      staff['photo_url'] ??
      staff['photo'] ??
      staff['image'];
  final value = raw?.toString() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('assets/')) return value;
  return value;
}

String _serviceName(Map<String, dynamic> resource) {
  final name = resource['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  return 'Servicio';
}

String _serviceKey(Map<String, dynamic> resource) {
  final id = resource['id'];
  if (id != null) return id.toString();
  return _serviceName(resource);
}

String _clientName(Map<String, dynamic> booking) {
  final user =
      (booking['user'] as Map?) ?? (booking['client'] as Map?) ?? const {};
  final name = user['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = user['first_name']?.toString().trim() ?? '';
  final last = user['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  if (combined.isNotEmpty) return combined;
  return booking['customer_name']?.toString().trim() ?? '';
}

String _statusText(Map<String, dynamic> booking) {
  return (booking['status'] ?? '').toString().toLowerCase();
}

String _timeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? booking['time'] ?? '').toString().trim();
  if (raw.isEmpty) return 'Hora pendiente';
  if (raw.contains(':')) return raw;
  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  }
  return raw;
}

String _bookingPriceLabel(
  Map<String, dynamic> booking,
  Map<String, dynamic> resource,
) {
  final raw =
      booking['price'] ?? booking['total_price'] ?? resource['price_per_hour'];
  final number = raw is num
      ? raw.toDouble()
      : double.tryParse(raw?.toString() ?? '');
  if (number == null || number <= 0) return '';
  return _formatCrc(number);
}

String _formatCrc(dynamic value) {
  final number = value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;
  return NumberFormat.currency(
    locale: 'es_CR',
    symbol: '₡',
    decimalDigits: 0,
  ).format(number);
}
