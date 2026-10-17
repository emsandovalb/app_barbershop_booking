/// The business's wall clock, independent of the device's timezone.
///
/// The API stores appointment times as the business's local wall-clock time
/// and serializes them with a `Z` suffix, so a parsed booking date carries the
/// business's hour/minute in a UTC-labelled [DateTime]. [now] returns the
/// business's current time in the same shape, so comparisons between the two
/// are correct no matter where the phone is.
class BusinessClock {
  BusinessClock._();

  static Duration? _utcOffset;
  static DateTime Function() _utcNow = () => DateTime.now().toUtc();

  /// Reads `utc_offset_minutes` from an app-config payload. Without it the
  /// device's own offset is used, which matches the old behaviour.
  static void configureFrom(Map<String, dynamic> config) {
    final raw = config['utc_offset_minutes'];
    final minutes = raw is num ? raw.toInt() : int.tryParse('$raw');
    _utcOffset = minutes == null ? null : Duration(minutes: minutes);
  }

  static Duration get utcOffset =>
      _utcOffset ?? _utcNow().toLocal().timeZoneOffset;

  /// Business wall-clock "now" as a UTC-labelled [DateTime].
  static DateTime now() => _utcNow().add(utcOffset);

  /// The business's current calendar day as a local date-only [DateTime],
  /// suitable for date pickers.
  static DateTime today() {
    final current = now();
    return DateTime(current.year, current.month, current.day);
  }

  /// Parses an API appointment date into the same shape as [now]. Values
  /// without an offset are read as business wall-clock time.
  static DateTime? parseAppointment(Object? raw) {
    final parsed = DateTime.tryParse('${raw ?? ''}'.trim());
    if (parsed == null || parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  static void debugOverride({Duration? utcOffset, DateTime? utcNow}) {
    _utcOffset = utcOffset;
    if (utcNow != null) _utcNow = () => utcNow;
  }

  static void debugReset() {
    _utcOffset = null;
    _utcNow = () => DateTime.now().toUtc();
  }
}
