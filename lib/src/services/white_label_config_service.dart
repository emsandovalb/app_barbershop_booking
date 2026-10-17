import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/white_label_config.dart';
import '../theme/brand_theme.dart';
import 'resilient_http_client.dart';

class WhiteLabelConfigService extends ChangeNotifier {
  WhiteLabelConfigService({
    required String baseUrl,
    String? businessSlug,
    WhiteLabelConfig? fallback,
    http.Client? client,
  }) : _baseUrl = _cleanBase(baseUrl),
       _businessSlug = _cleanBusinessSlug(businessSlug),
       // Short deadline: the app waits for this on startup and falls back
       // to the cached config, so a slow network must not block launch.
       _client =
           client ??
           ResilientHttpClient(
             timeout: const Duration(seconds: 8),
             getRetries: 0,
           ),
       _fallback = fallback ?? WhiteLabelConfig.generic,
       _config = fallback ?? WhiteLabelConfig.generic,
       _brandTheme = BrandTheme.generic();

  static const int _cacheSchemaVersion = 3;
  static String get defaultCacheKey =>
      'white_label_config_cache_v${_cacheSchemaVersion}_default';

  final String _baseUrl;
  final String? _businessSlug;
  final http.Client _client;
  final WhiteLabelConfig _fallback;

  WhiteLabelConfig _config;
  BrandTheme _brandTheme;
  bool _isLoading = false;

  String get _cacheKey => _businessSlug == null
      ? defaultCacheKey
      : 'white_label_config_cache_v${_cacheSchemaVersion}_${_businessSlug}';

  WhiteLabelConfig get config => _config;
  BrandTheme get brandTheme => _brandTheme;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      if (_businessSlug != null) {
        final loadedRemote = await _loadRemoteConfig();
        if (!loadedRemote) {
          await _loadCachedConfig();
        }
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    if (_businessSlug == null) {
      return;
    }
    await _loadRemoteConfig();
  }

  Future<void> _loadCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final normalized = _normalizeMap(decoded);
        _config = WhiteLabelConfig.fromJson(normalized);
        _brandTheme = BrandTheme.fromJson(normalized, fallback: _brandTheme);
        notifyListeners();
      }
    } catch (_) {
      // Ignore corrupt cache and keep the current fallback config.
    }
  }

  Future<bool> _loadRemoteConfig() async {
    try {
      final uri = _businessSlug == null
          ? Uri.parse('$_baseUrl/app-config')
          : Uri.parse('$_baseUrl/public/businesses/$_businessSlug/config');
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
      _brandTheme = BrandTheme.fromJson(normalized, fallback: _brandTheme);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(normalized));
      notifyListeners();
      return true;
    } catch (_) {
      if (_config == _fallback) {
        // Leave the fallback config in place.
      }
      return false;
    }
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String? _cleanBusinessSlug(String? slug) {
    final trimmed = slug?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
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
