import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:app_barbershop_booking/src/services/localization_service.dart';

/// Reads a bundled language file straight from disk (tests run from the
/// project root), so widgets render the same strings as the real app.
Map<String, String> readLanguageFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return <String, String>{};
  final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  return decoded.map((key, value) => MapEntry(key, value.toString()));
}

LocalizationService testLocalization({String language = 'es', String? brand}) {
  final strings = readLanguageFile('assets/i18n/$language.json');
  if (brand != null) {
    strings.addAll(readLanguageFile('assets/i18n/brands/$brand/$language.json'));
  }
  return LocalizationService.withStrings(
    strings,
    locale: Locale(language),
    brandSlug: brand,
  );
}
