import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  String? token;
  Map<String, dynamic>? user;
  bool get isLoggedIn => token != null;
  bool get isAdmin => (user?['role']?.toString() ?? '') == 'admin';
  List<Map<String, dynamic>> get manageableTeams {
    final teams = (user?['teams'] as List?) ?? const [];
    final currentUserId = user?['id'];
    return teams
        .where((entry) {
          final team = Map<String, dynamic>.from(entry as Map);
          if (currentUserId != null && team['user_id']?.toString() == currentUserId.toString()) {
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
    _restore();
  }

  Future<void> _restore() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString('auth_token');
    final u = sp.getString('auth_user');
    if (token != null) api.token = token;
    if (u != null) user = json.decode(u) as Map<String, dynamic>;
    if (token != null) {
      try {
        await refreshUser();
      } catch (_) {
        // Keep restored state if the network request fails.
      }
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final data = await api.login(email, password);
      if (data['token'] != null) {
        token = data['token'] as String;
        user = data['user'] as Map<String, dynamic>;
        api.token = token;
        final sp = await SharedPreferences.getInstance();
        await sp.setString('auth_token', token!);
        await sp.setString('auth_user', json.encode(user));
        await refreshUser();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> register({required String name, required String email, required String password}) async {
    final data = await api.register(name, email, password);
    if (data['token'] != null) {
      token = data['token'] as String;
      user = data['user'] as Map<String, dynamic>;
      api.token = token;
      final sp = await SharedPreferences.getInstance();
      await sp.setString('auth_token', token!);
      await sp.setString('auth_user', json.encode(user));
      await refreshUser();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> refreshUser() async {
    if (token == null) return;
    final data = await api.me();
    user = data is Map<String, dynamic> && data['user'] != null ? Map<String,dynamic>.from(data['user']) : Map<String,dynamic>.from(data);
    final sp = await SharedPreferences.getInstance();
    await sp.setString('auth_user', json.encode(user));
    notifyListeners();
  }

  Future<bool> updateProfile({String? firstName, String? lastName, String? name, String? avatarPath}) async {
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
        if (refreshed is Map<String, dynamic>) {
          next = refreshed;
        }
      } catch (_) {
        // ignore refresh errors and fall back to original response
      }
    }

    user = next;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('auth_user', json.encode(user));
    notifyListeners();
    return true;
  }
  Future<void> logout() async {
    try { await api.logout(); } catch (_) {}
    token = null;
    user = null;
    api.token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove('auth_token');
    await sp.remove('auth_user');
    notifyListeners();
  }
}
