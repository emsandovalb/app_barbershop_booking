part of '../white_label_config.dart';

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return null;
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _nullableString(dynamic value, {String? fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _intValue(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _doubleValue(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(dynamic value, bool fallback) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> _stringListValue(dynamic value, List<String> fallback) {
  if (value is List) {
    final items = value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (items.isNotEmpty) return items;
  }
  return fallback;
}

Color _colorValue(dynamic value, Color fallback) {
  if (value is int) return Color(value);
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  var hex = text.replaceAll('#', '').replaceAll('0x', '');
  if (hex.length == 3) {
    hex = hex.split('').map((part) => '$part$part').join();
  } else if (hex.length == 4) {
    hex = hex.split('').map((part) => '$part$part').join();
  } else if (hex.length == 6) {
    hex = 'FF$hex';
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}
