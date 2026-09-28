import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'barbershop_fallbacks.dart';
import 'app_translations.dart';

/// Handles downloading and caching UI translations from the backend.
/// Flow:
/// 1. Detect system locale on first run.
/// 2. Fetch strings from `/api/translations?lang=xx`.
/// 3. Allow the user to override the language (Profile screen) and persist it.
class LocalizationService extends ChangeNotifier {
  LocalizationService({
    required this.translationsBaseUrl,
    Map<String, String> fallbackOverrides = const {},
  }) : _fallbackOverrides = fallbackOverrides;

  final String translationsBaseUrl;
  final Map<String, String> _fallbackOverrides;

  static const _prefsLanguageKey = 'language_code';
  static const _prefsStringsPrefix = 'translation_strings_';
  static const _prefsVersionPrefix = 'translation_version_';
  static const _supported = ['es', 'en'];

  Locale _locale = const Locale('es');
  AppTranslations _translations = const AppTranslations({});
  bool _isLoading = true;

  Locale get locale => _locale;
  AppTranslations get tr => _translations;
  bool get isLoading => _isLoading;

  Future<void> init({Locale? systemLocale}) async {
    String? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(_prefsLanguageKey);
    } catch (_) {
      // Continue with the detected locale when storage is unavailable.
    }
    final normalizedSaved = _normalize(saved);
    final detected = _normalize(systemLocale?.languageCode);
    await load(normalizedSaved ?? detected ?? 'es');
  }

  Future<void> load(String languageCode) async {
    final normalized = _normalize(languageCode) ?? 'es';
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_prefsStringsPrefix$normalized');
      if (cached != null) {
        _translations = AppTranslations(_decodeStrings(cached));
        _locale = Locale(normalized);
        notifyListeners();
      }
      final uri = Uri.parse(
        '$translationsBaseUrl/translations',
      ).replace(queryParameters: {'lang': normalized});
      final res = await http.get(uri);
      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('Failed to load translations ${res.statusCode}');
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final lang = _normalize(data['lang']?.toString()) ?? normalized;
      final strings =
          (data['strings'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          <String, String>{};
      _translations = AppTranslations(strings);
      _locale = Locale(lang);
      await prefs.setString(_prefsLanguageKey, lang);
      await prefs.setString('$_prefsStringsPrefix$lang', json.encode(strings));
      if (data['version'] != null) {
        await prefs.setInt(
          '$_prefsVersionPrefix$lang',
          int.tryParse(data['version'].toString()) ?? 0,
        );
      }
    } catch (_) {
      // Keep previously loaded translations if request fails.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changeLanguage(String languageCode) => load(languageCode);

  String t(String key, {String? fallback}) => _translations.t(
    key,
    fallback:
        fallback ??
        _fallbackOverrides[key] ??
        (_locale.languageCode == 'es' ? barbershopFallbacks[key] : null),
  );

  Map<String, String> _decodeStrings(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is Map) {
        return decoded.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    } catch (_) {
      // A corrupt cache is ignored; the network response or fallback map wins.
    }
    return const <String, String>{};
  }

  String? _normalize(String? code) {
    if (code == null) return null;
    final trimmed = code.trim().toLowerCase();
    return _supported.contains(trimmed) ? trimmed : null;
  }
}
