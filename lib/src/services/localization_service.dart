import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Translates [key] with the active [LocalizationService], for code that has
/// no BuildContext (formatters, helpers called from build methods). Widgets
/// should keep using `context.watch<LocalizationService>().t` so they rebuild
/// when the language changes.
String tr(String key, {Map<String, Object?> args = const {}}) =>
    LocalizationService._active?.t(key, args: args) ?? key;

/// UI strings bundled with the app as JSON, one file per language:
///
/// * `assets/i18n/<lang>.json` holds every key the app uses.
/// * `assets/i18n/brands/<slug>/<lang>.json` optionally overrides some keys
///   for one brand (e.g. "estilista" instead of "barbero").
///
/// Strings load from the app bundle, so changing language is instant and
/// works offline. The chosen language is remembered across launches.
class LocalizationService extends ChangeNotifier {
  LocalizationService({this.brandSlug, AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle {
    _active = this;
  }

  /// Starts with [strings] already loaded, for tests and previews.
  @visibleForTesting
  LocalizationService.withStrings(
    Map<String, String> strings, {
    Locale locale = const Locale('es'),
    this.brandSlug,
  }) : _bundle = rootBundle,
       _strings = Map.of(strings),
       _locale = locale,
       _isLoading = false {
    _active = this;
  }

  static const supportedLanguages = ['es', 'en'];
  static const defaultLanguage = 'es';
  static const _prefsLanguageKey = 'language_code';

  static LocalizationService? _active;

  /// Language code of the active service, for date/number formatting.
  static String get activeLanguage =>
      _active?._locale.languageCode ?? defaultLanguage;

  final String? brandSlug;
  final AssetBundle _bundle;

  Locale _locale = const Locale(defaultLanguage);
  Map<String, String> _strings = const {};
  bool _isLoading = true;

  Locale get locale => _locale;
  bool get isLoading => _isLoading;

  Future<void> init({Locale? systemLocale}) async {
    String? saved;
    try {
      final prefs = await SharedPreferences.getInstance();
      saved = prefs.getString(_prefsLanguageKey);
    } catch (_) {
      // Fall back to the device language when storage is unavailable.
    }
    await _load(
      _normalize(saved) ??
          _normalize(systemLocale?.languageCode) ??
          defaultLanguage,
      remember: false,
    );
  }

  Future<void> changeLanguage(String languageCode) =>
      _load(_normalize(languageCode) ?? defaultLanguage, remember: true);

  /// The string for [key] in the current language. `{name}` placeholders are
  /// replaced from [args]. A missing key returns [fallback] or the key itself
  /// (a test keeps every key used in code present in every language file).
  String t(
    String key, {
    String? fallback,
    Map<String, Object?> args = const {},
  }) {
    var value = _strings[key] ?? fallback ?? key;
    args.forEach((name, replacement) {
      value = value.replaceAll('{$name}', '${replacement ?? ''}');
    });
    return value;
  }

  Future<void> _load(String language, {required bool remember}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final strings = await _readStrings('assets/i18n/$language.json');
      final slug = brandSlug?.trim();
      if (slug != null && slug.isNotEmpty) {
        strings.addAll(
          await _readStrings(
            'assets/i18n/brands/$slug/$language.json',
            optional: true,
          ),
        );
      }
      _strings = strings;
      _locale = Locale(language);
      if (remember) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsLanguageKey, language);
        } catch (_) {
          // The language still changes for this session.
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> _readStrings(
    String path, {
    bool optional = false,
  }) async {
    final String raw;
    try {
      raw = await _bundle.loadString(path);
    } catch (_) {
      if (optional) return <String, String>{};
      rethrow;
    }
    final decoded = json.decode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(key, value.toString()));
  }

  String? _normalize(String? code) {
    final trimmed = code?.trim().toLowerCase();
    return supportedLanguages.contains(trimmed) ? trimmed : null;
  }
}
