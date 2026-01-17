import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class KapsoNotifier {
  final String baseUrl;
  final String apiKey;
  final String path;
  final String authHeader;
  final String authScheme;

  KapsoNotifier({
    required this.baseUrl,
    required this.apiKey,
    this.path = '/notifications',
    this.authHeader = 'Authorization',
    this.authScheme = 'Bearer',
  });

  static KapsoNotifier? fromEnv() {
    const base = String.fromEnvironment('KAPSO_BASE');
    const key = String.fromEnvironment('KAPSO_API_KEY');
    const path = String.fromEnvironment('KAPSO_PATH');
    const header = String.fromEnvironment('KAPSO_AUTH_HEADER');
    const scheme = String.fromEnvironment('KAPSO_AUTH_SCHEME');
    if (base.isEmpty || key.isEmpty) return null;
    // Skip if placeholders are still present
    if (base.contains('YOUR_') || key.contains('YOUR_')) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Kapso] Skipping send: placeholders detected.');
      }
      return null;
    }
    return KapsoNotifier(
      baseUrl: _cleanBase(base),
      apiKey: key,
      path: path.isNotEmpty ? path : '/notifications',
      authHeader: header.isNotEmpty ? header : 'Authorization',
      authScheme: scheme.isNotEmpty ? scheme : 'Bearer',
    );
  }

  Future<void> sendReservation({
    required String adminRecipient,
    required Map<String, dynamic> payload,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      authHeader: authScheme.isNotEmpty ? '$authScheme $apiKey' : apiKey,
    };
    final body = json.encode({
      'type': 'booking_created',
      'recipient': adminRecipient,
      'data': payload,
    });
    if (kDebugMode) {
      final masked = apiKey.length > 8 ? '${apiKey.substring(0, 4)}...${apiKey.substring(apiKey.length - 4)}' : '***';
      // ignore: avoid_print
      print('[Kapso] POST $uri headers={${authHeader}: ${authScheme.isNotEmpty ? authScheme : ''} $masked}');
      // ignore: avoid_print
      print('[Kapso] Payload keys: ${payload.keys.toList()}');
    }
    final res = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[Kapso] Response ${res.statusCode}: ${res.body}');
      }
      throw Exception('Kapso error: HTTP ${res.statusCode}');
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Kapso] Sent successfully (${res.statusCode}).');
    }
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }
}
