import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';
import '../services/localization_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _rememberSessionKey = 'login_remember_session';
  static const String _rememberedEmailKey = 'login_remembered_email';

  final ApiClient api;
  late final Future<void> _initialization;
  bool _isReady = false;
  String? token;
  Map<String, dynamic>? user;
  String? registrationError;
  bool _rememberSession = true;
  String _rememberedEmail = '';
  bool get isLoggedIn => token != null;
  bool get isAdmin => (user?['role']?.toString() ?? '') == 'admin';
  bool get canManageBusiness {
    final explicit = user?['can_manage_business'];
    if (explicit is bool) {
      return explicit;
    }
    if (isAdmin) {
      return true;
    }
    final businessRole = currentBusinessRole;
    final businessStatus = currentBusinessStatus;
    return businessStatus == 'active' &&
        (businessRole == 'owner' || businessRole == 'admin');
  }

  String? get currentBusinessRole =>
      _stringValue(user?['business_role']) ??
      _currentBusinessPivotValue('role');

  String? get currentBusinessStatus =>
      _stringValue(user?['business_status']) ??
      _currentBusinessPivotValue('status');

  Map<String, dynamic>? get currentBusiness {
    final business = user?['business'];
    if (business is Map) {
      return Map<String, dynamic>.from(business);
    }
    final slug = _stringValue(user?['business_slug']);
    final id = _intValue(user?['business_id']);
    final businesses = (user?['businesses'] as List?) ?? const [];
    for (final entry in businesses) {
      if (entry is! Map) continue;
      final businessMap = Map<String, dynamic>.from(entry);
      final matchesSlug =
          slug != null && businessMap['slug']?.toString() == slug;
      final matchesId = id != null && _intValue(businessMap['id']) == id;
      if (matchesSlug || matchesId) {
        return businessMap;
      }
    }

    final businessCandidates = <Map<String, dynamic>>[];
    for (final entry in businesses) {
      if (entry is! Map) continue;
      final businessMap = Map<String, dynamic>.from(entry);
      final pivot = (businessMap['pivot'] as Map?) ?? const {};
      final role = pivot['role']?.toString() ?? '';
      final status = pivot['status']?.toString() ?? '';
      if (status == 'active' && (role == 'owner' || role == 'admin')) {
        businessCandidates.add(businessMap);
      }
    }
    if (businessCandidates.length == 1) {
      return businessCandidates.first;
    }

    return null;
  }

  bool get isReady => _isReady;
  bool get rememberSession => _rememberSession;
  String get rememberedEmail => _rememberedEmail;
  Future<void> get ready => _initialization;
  List<Map<String, dynamic>> get manageableTeams {
    final teams = (user?['teams'] as List?) ?? const [];
    final currentUserId = user?['id'];
    return teams
        .where((entry) {
          final team = Map<String, dynamic>.from(entry as Map);
          if (currentUserId != null &&
              team['user_id']?.toString() == currentUserId.toString()) {
            return true;
          }
          final pivot = (team['pivot'] as Map?) ?? const {};
          final role = pivot['role']?.toString() ?? '';
          return role == 'owner' || role == 'captain' || role == 'manager';
        })
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList(growable: false);
  }

  AuthProvider(this.api) {
    _initialization = _restore();
  }

  Future<void> _restore() async {
    try {
      final sp = await SharedPreferences.getInstance();
      _rememberSession = sp.getBool(_rememberSessionKey) ?? true;
      _rememberedEmail = sp.getString(_rememberedEmailKey) ?? '';
      token = sp.getString(_tokenKey);
      final u = sp.getString(_userKey);
      if (token != null) api.token = token;
      if (u != null) user = json.decode(u) as Map<String, dynamic>;
      if (token == null && sp.containsKey(_tokenKey)) {
        await sp.remove(_tokenKey);
      }
      if (token == null && sp.containsKey(_userKey)) {
        await sp.remove(_userKey);
      }
      if (token != null) {
        _rememberSession = true;
        await sp.setBool(_rememberSessionKey, true);
      }
      if (token != null) {
        try {
          await refreshUser();
        } catch (_) {
          // Keep restored state if the network request fails.
        }
      }
    } catch (_) {
      // Ignore storage failures on web and continue with a clean session.
      token = null;
      user = null;
    } finally {
      _isReady = true;
    }
    notifyListeners();
  }

  Future<bool> login(
    String email,
    String password, {
    bool rememberSession = true,
  }) async {
    try {
      final data = await api.login(email, password);
      if (data['token'] != null) {
        token = data['token'] as String;
        user = data['user'] is Map
            ? Map<String, dynamic>.from(data['user'] as Map)
            : null;
        api.token = token;
        _rememberSession = rememberSession;
        _rememberedEmail = email;
        await _storeSession(email: email, rememberSession: rememberSession);
        try {
          await refreshUser();
        } catch (_) {
          // Keep the authenticated session alive even if the follow-up
          // profile refresh fails. The login response already contains enough
          // state to route the user into the app.
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registrationError = null;
    try {
      final data = await api.register(name, email, password);
      if (data['token'] == null) {
        registrationError = tr('signup_incomplete');
        notifyListeners();
        return false;
      }
      token = data['token'] as String;
      user = data['user'] is Map
          ? Map<String, dynamic>.from(data['user'] as Map)
          : null;
      api.token = token;
      _rememberedEmail = email;
      await _storeSession(email: email, rememberSession: _rememberSession);
      try {
        await refreshUser();
      } catch (_) {
        // Keep the newly created session usable even if /auth/me is briefly
        // unavailable immediately after registration.
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      registrationError =
          e.firstErrorFor('email') ??
          e.firstErrorFor('password') ??
          e.firstErrorFor('name') ??
          e.message;
      notifyListeners();
      return false;
    } catch (_) {
      registrationError = tr('signup_incomplete_retry');
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshUser() async {
    if (token == null) return;
    final data = await api.me();
    final payload = data['user'];
    user = payload is Map
        ? Map<String, dynamic>.from(payload)
        : Map<String, dynamic>.from(data);
    final sp = await SharedPreferences.getInstance();
    if (_rememberSession) {
      await sp.setString(_userKey, json.encode(user));
    }
    notifyListeners();
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? name,
    String? avatarPath,
  }) async {
    final res = await api.updateProfile(
      firstName: firstName,
      lastName: lastName,
      name: name,
      avatarPath: avatarPath,
    );
    final updated = res['user'] as Map<String, dynamic>?;
    if (updated == null) {
      return false;
    }

    Map<String, dynamic> next = updated;
    // If backend response still lacks avatar_url, fallback to /auth/me
    if (updated['avatar_url'] == null && updated['avatar'] != null) {
      try {
        final refreshed = await api.me();
        final refreshedUser = refreshed['user'];
        if (refreshedUser is Map) {
          next = Map<String, dynamic>.from(refreshedUser);
        } else {
          next = Map<String, dynamic>.from(refreshed);
        }
      } catch (_) {
        // ignore refresh errors and fall back to original response
      }
    }

    user = next;
    final sp = await SharedPreferences.getInstance();
    if (_rememberSession) {
      await sp.setString(_userKey, json.encode(user));
    }
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    token = null;
    user = null;
    api.token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_tokenKey);
    await sp.remove(_userKey);
    await sp.setBool(_rememberSessionKey, _rememberSession);
    if (_rememberedEmail.isNotEmpty) {
      await sp.setString(_rememberedEmailKey, _rememberedEmail);
    }
    notifyListeners();
  }

  Future<void> _storeSession({
    required String email,
    required bool rememberSession,
  }) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_rememberSessionKey, rememberSession);
    await sp.setString(_rememberedEmailKey, email);
    if (rememberSession) {
      await sp.setString(_tokenKey, token!);
      await sp.setString(_userKey, json.encode(user));
      return;
    }

    await sp.remove(_tokenKey);
    await sp.remove(_userKey);
  }

  String? _stringValue(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }

  String? _currentBusinessPivotValue(String key) {
    final business = currentBusiness;
    final pivot = (business?['pivot'] as Map?) ?? const {};
    return _stringValue(pivot[key]);
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
