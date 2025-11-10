import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../navigation/app_router.dart';
import '../navigation/nav_key.dart';

class InactivityListener extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  const InactivityListener({super.key, required this.child, this.timeout = const Duration(minutes: 5)});

  @override
  State<InactivityListener> createState() => _InactivityListenerState();
}

class _InactivityListenerState extends State<InactivityListener> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _onTimeout);
  }

  Future<void> _onTimeout() async {
    final auth = appNavigatorKey.currentContext?.read<AuthProvider>();
    if (auth == null || !auth.isLoggedIn) return;
    await auth.logout();
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _reset(),
      onPointerMove: (_) => _reset(),
      onPointerUp: (_) => _reset(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          _reset();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}

