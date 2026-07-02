import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/white_label_config.dart';

class WhiteLabelConfigService extends ChangeNotifier {
  WhiteLabelConfigService({
    required String baseUrl,
    WhiteLabelConfig? fallback,
    http.Client? client,
  }) : _baseUrl = _cleanBase(baseUrl),
       _client = client ?? http.Client(),
       _fallback = fallback ?? WhiteLabelConfig.tresAmigos,
       _config = fallback ?? WhiteLabelConfig.tresAmigos;

  static const String cacheKey = 'white_label_config_cache';

  final String _baseUrl;
  final http.Client _client;
  final WhiteLabelConfig _fallback;

  WhiteLabelConfig _config;
  bool _isLoading = false;

  WhiteLabelConfig get config => _config;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadCachedConfig();
      await _loadRemoteConfig();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadRemoteConfig();
  }

  Future<void> _loadCachedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(cacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final normalized = _normalizeMap(decoded);
        _config = WhiteLabelConfig.fromJson(normalized);
        notifyListeners();
      }
    } catch (_) {
      // Ignore corrupt cache and keep the current fallback config.
    }
  }

  Future<void> _loadRemoteConfig() async {
    try {
      final uri = Uri.parse('$_baseUrl/app-config');
      final response = await _client.get(
        uri,
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const FormatException('Invalid app-config payload');
      }
      final normalized = _normalizeMap(decoded);
      final parsed = WhiteLabelConfig.fromJson(normalized);
      _config = parsed;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(cacheKey, jsonEncode(normalized));
      notifyListeners();
    } catch (_) {
      if (_config == _fallback) {
        // Leave the fallback config in place.
      }
    }
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  Map<String, dynamic> _normalizeMap(Map decoded) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
}

class HttpException implements Exception {
  HttpException(this.message);

  final String message;

  @override
  String toString() => message;
}
