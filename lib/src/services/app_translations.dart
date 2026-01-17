class AppTranslations {
  final Map<String, String> _strings;

  const AppTranslations(this._strings);

  /// Returns the translated value for [key] or the provided [fallback].
  /// If no fallback is supplied, the key itself is returned to make
  /// spotting missing translations easier during development.
  String t(String key, {String? fallback}) {
    if (_strings.containsKey(key)) {
      return _strings[key]!;
    }
    return fallback ?? key;
  }
}
