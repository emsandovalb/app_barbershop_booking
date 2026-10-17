import 'package:url_launcher/url_launcher.dart';

/// Builds the links behind the business's contact buttons. Each returns null
/// when the business hasn't configured that channel, so the button can be
/// hidden instead of doing nothing.
class ContactLinks {
  ContactLinks._();

  static Uri? whatsapp(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    // Local Costa Rican numbers (8 digits) need the country code.
    final international = digits.length == 8 ? '506$digits' : digits;
    return Uri.parse('https://wa.me/$international');
  }

  static Uri? phone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.replaceAll('+', '').isEmpty) return null;
    return Uri(scheme: 'tel', path: cleaned);
  }

  static Uri? maps(String address) {
    final query = address.trim();
    if (query.isEmpty) return null;
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': query,
    });
  }

  static Uri? instagram(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Uri.tryParse(value);
    }
    final handle = value
        .replaceFirst(RegExp(r'^@'), '')
        .replaceFirst(RegExp(r'^(www\.)?instagram\.com/'), '')
        .split('/')
        .first;
    if (handle.isEmpty) return null;
    return Uri.https('www.instagram.com', '/$handle');
  }

  /// Opens [uri] in the matching app (WhatsApp, dialer, Maps, Instagram) or
  /// the browser. Returns false when nothing on the device could open it.
  static Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
