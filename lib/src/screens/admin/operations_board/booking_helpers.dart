part of '../operations_board.dart';

String operationsBookingIdentity(Map<String, dynamic> booking) {
  final code = booking['booking_code']?.toString().trim() ?? '';
  if (code.isNotEmpty) return code;
  final id = booking['id'];
  if (id != null) return id.toString();
  return '${booking['date'] ?? ''}-${booking['time_slot'] ?? ''}';
}

String operationsCustomerName(Map<String, dynamic> booking) {
  final user =
      (booking['user'] as Map?) ?? (booking['client'] as Map?) ?? const {};
  final name = user['name']?.toString().trim() ?? '';
  if (name.isNotEmpty) return name;
  final first = user['first_name']?.toString().trim() ?? '';
  final last = user['last_name']?.toString().trim() ?? '';
  final combined = '$first $last'.trim();
  if (combined.isNotEmpty) return combined;
  return booking['customer_name']?.toString().trim().isNotEmpty == true
      ? booking['customer_name'].toString()
      : tr('ops_client');
}

String operationsChannelKey(Map<String, dynamic> booking) {
  final raw = booking['channel'] ?? booking['source'] ?? booking['origin'];
  final value = raw?.toString().trim().toLowerCase() ?? '';
  if (value.isEmpty) return 'direct';
  if (value.contains('whatsapp')) return 'whatsapp';
  if (value.contains('instagram')) return 'instagram';
  if (value.contains('facebook')) return 'facebook';
  if (value.contains('web') || value.contains('site')) return 'web';
  if (value.contains('phone') || value.contains('call')) return 'phone';
  return value;
}

String operationsChannelName(Map<String, dynamic> booking) {
  switch (operationsChannelKey(booking)) {
    case 'whatsapp':
      return 'WhatsApp';
    case 'instagram':
      return 'Instagram';
    case 'facebook':
      return 'Facebook';
    case 'web':
      return 'Web';
    case 'phone':
      return tr('ops_channel_phone');
    default:
      return tr('ops_channel_direct');
  }
}

IconData operationsChannelIcon(Map<String, dynamic> booking) {
  switch (operationsChannelKey(booking)) {
    case 'whatsapp':
      return Icons.chat_bubble_rounded;
    case 'instagram':
      return Icons.camera_alt_rounded;
    case 'facebook':
      return Icons.facebook_rounded;
    case 'web':
      return Icons.language_rounded;
    case 'phone':
      return Icons.call_rounded;
    default:
      return Icons.storefront_rounded;
  }
}

bool operationsIsVip(Map<String, dynamic> booking) {
  final raw = booking['vip'] ?? booking['is_vip'] ?? booking['priority_tier'];
  if (raw is bool) return raw;
  final value = raw?.toString().toLowerCase() ?? '';
  return value.contains('vip') || value.contains('premium');
}

bool operationsIsDuplicate(Map<String, dynamic> booking) {
  final raw =
      booking['duplicate'] ??
      booking['is_duplicate'] ??
      booking['duplicate_count'];
  if (raw is bool) return raw;
  if (raw is num) return raw > 0;
  final value = raw?.toString().toLowerCase() ?? '';
  return value == 'true' || value == 'yes';
}

bool operationsIsPriority(Map<String, dynamic> booking) {
  final raw =
      booking['priority'] ??
      booking['priority_level'] ??
      booking['high_priority'];
  if (raw is bool) return raw;
  if (raw is num) return raw > 0;
  final value = raw?.toString().toLowerCase() ?? '';
  return value.contains('high') || value.contains('urgent') || value == 'true';
}

double? operationsParserConfidence(Map<String, dynamic> booking) {
  final raw = booking['parser_confidence'] ?? booking['confidence'];
  if (raw is num) {
    final number = raw.toDouble();
    return number <= 1 ? number * 100 : number;
  }
  return double.tryParse(raw?.toString() ?? '');
}

String operationsConfidenceLabel(Map<String, dynamic> booking) {
  final confidence = operationsParserConfidence(booking);
  if (confidence == null) return 'n/a';
  return '${confidence.clamp(0, 100).round()}%';
}

int operationsItemCount(Map<String, dynamic> booking) {
  for (final key in const ['items_count', 'item_count']) {
    final raw = booking[key];
    if (raw is num && raw > 0) return raw.toInt();
    final parsed = int.tryParse(raw?.toString() ?? '');
    if (parsed != null && parsed > 0) return parsed;
  }
  for (final key in const ['items', 'line_items', 'services']) {
    final raw = booking[key];
    if (raw is List && raw.isNotEmpty) return raw.length;
  }
  return 1;
}

DateTime? operationsCreatedAt(Map<String, dynamic> booking) {
  final raw = booking['created_at'] ?? booking['updated_at'];
  final created = DateTime.tryParse(raw?.toString() ?? '');
  if (created != null) return created;

  final date = booking['date'];
  final day = date is DateTime
      ? date
      : DateTime.tryParse(date?.toString() ?? '');
  if (day == null) return null;
  final time = booking['time_slot']?.toString().trim() ?? '';
  if (time.isEmpty) return day;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return day;
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

DateTime? operationsScheduledAt(Map<String, dynamic> booking) {
  final date = booking['date'];
  final day = date is DateTime
      ? date
      : DateTime.tryParse(date?.toString() ?? '');
  if (day == null) return null;
  final time = booking['time_slot']?.toString().trim() ?? '';
  if (time.isEmpty) return day;
  final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(time);
  if (match == null) return day;
  return DateTime(
    day.year,
    day.month,
    day.day,
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
  );
}

int operationsAgeMinutes(Map<String, dynamic> booking) {
  final reference =
      operationsCreatedAt(booking) ?? operationsScheduledAt(booking);
  if (reference == null) return 0;
  final delta = DateTime.now().difference(reference);
  return delta.inMinutes < 0 ? 0 : delta.inMinutes;
}

String operationsWaitLabel(int minutes) {
  if (minutes <= 0) return '0 min';
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  if (remaining == 0) {
    return hours == 1 ? '1 h' : '$hours h';
  }
  return hours == 1 ? '1 h $remaining min' : '$hours h $remaining min';
}

String operationsElapsedLabel(Map<String, dynamic> booking) {
  return operationsWaitLabel(operationsAgeMinutes(booking));
}

String operationsTimeLabel(Map<String, dynamic> booking) {
  final raw = (booking['time_slot'] ?? booking['time'] ?? '').toString().trim();
  if (raw.isEmpty) return tr('admin_time_pending');
  return raw;
}

String operationsCreatedLabel(Map<String, dynamic> booking) {
  final created = operationsCreatedAt(booking);
  if (created == null) return 'n/a';
  return DateFormat('yyyy-MM-dd HH:mm').format(created.toLocal());
}

String operationsUpdatedLabel(Map<String, dynamic> booking) {
  final updated = DateTime.tryParse((booking['updated_at'] ?? '').toString());
  if (updated == null) return operationsCreatedLabel(booking);
  return DateFormat('yyyy-MM-dd HH:mm').format(updated.toLocal());
}

String operationsOrganizationLabel(Map<String, dynamic> booking) {
  final raw = booking['business_id'] ?? booking['organization_id'];
  if (raw == null) return tr('ops_current_business');
  return raw.toString();
}

String operationsStatusLabel(Map<String, dynamic> booking) {
  final raw = (booking['status'] ?? '').toString().trim().toLowerCase();
  if (raw.isEmpty) return tr('status_pending');
  if (raw.contains('cancel')) return tr('status_cancelled');
  if (raw.contains('complete') ||
      raw.contains('done') ||
      raw.contains('finish')) {
    return tr('status_completed');
  }
  if (raw.contains('prepare')) return tr('ops_status_in_service');
  if (raw.contains('ready')) return tr('ops_status_to_close');
  if (raw.contains('pending') || raw.contains('confirm')) {
    return tr('status_pending');
  }
  return raw;
}

List<Map<String, dynamic>> operationsSortBookings(
  List<Map<String, dynamic>> bookings,
) {
  final items = bookings.toList(growable: false);
  items.sort((a, b) {
    final at =
        operationsCreatedAt(a) ?? operationsScheduledAt(a) ?? DateTime(1970);
    final bt =
        operationsCreatedAt(b) ?? operationsScheduledAt(b) ?? DateTime(1970);
    final diff = at.compareTo(bt);
    if (diff != 0) return diff;
    return operationsBookingIdentity(a).compareTo(operationsBookingIdentity(b));
  });
  return items;
}

double operationsAverageWaitMinutes(List<Map<String, dynamic>> bookings) {
  if (bookings.isEmpty) return 0;
  final total = bookings.fold<int>(
    0,
    (sum, booking) => sum + operationsAgeMinutes(booking),
  );
  return total / bookings.length;
}
