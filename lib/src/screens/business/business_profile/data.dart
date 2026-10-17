part of '../business_profile_page.dart';

class _BusinessProfileData {
  final List<Map<String, dynamic>> staff;
  final List<Map<String, dynamic>> resources;

  const _BusinessProfileData({required this.staff, required this.resources});
}

class _GalleryTileData {
  final String asset;
  final String label;

  const _GalleryTileData(this.asset, this.label);
}

const List<_GalleryTileData> _galleryTiles = [
  _GalleryTileData('', 'Ambiente premium'),
  _GalleryTileData('', 'Identidad del negocio'),
  _GalleryTileData('', 'Profesionales expertos'),
  _GalleryTileData('', 'Detalles de precisión'),
];

String _stringValue(
  Map<String, dynamic> map,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = map[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

List<String> _splitSpecialties(String raw) {
  final normalized = raw
      .replaceAll('\n', ' · ')
      .replaceAll('/', ' · ')
      .replaceAll(',', ' · ')
      .split('·')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
  return normalized;
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

String _durationLabel(dynamic hoursValue, dynamic minutesValue) {
  final minutes = minutesValue is num
      ? minutesValue.toInt()
      : int.tryParse(minutesValue?.toString() ?? '');
  if (minutes != null && minutes > 0) {
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    if (hours == 0) return '$remainder min';
    if (remainder == 0) return hours == 1 ? '1 h' : '$hours h';
    return '${hours == 1 ? '1' : hours} h $remainder min';
  }

  final hours = hoursValue is num
      ? hoursValue.toInt()
      : int.tryParse(hoursValue?.toString() ?? '1') ?? 1;
  return hours == 1 ? '1 h' : '$hours h';
}
