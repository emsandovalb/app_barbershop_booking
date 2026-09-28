import 'dart:async';

import 'package:flutter/material.dart';

class LiveQueueSnapshot<T> {
  final T? data;
  final Object? error;
  final bool loading;
  final DateTime? lastUpdated;

  const LiveQueueSnapshot({
    required this.data,
    required this.error,
    required this.loading,
    required this.lastUpdated,
  });

  const LiveQueueSnapshot.loading()
    : data = null,
      error = null,
      loading = true,
      lastUpdated = null;
}

class LiveQueue<T> extends StatefulWidget {
  final Future<T> Function() loader;
  final Duration refreshInterval;
  final Widget Function(BuildContext context, LiveQueueSnapshot<T> snapshot)
  builder;

  const LiveQueue({
    super.key,
    required this.loader,
    required this.builder,
    this.refreshInterval = const Duration(seconds: 8),
  });

  @override
  State<LiveQueue<T>> createState() => _LiveQueueState<T>();
}

class _LiveQueueState<T> extends State<LiveQueue<T>> {
  Timer? _timer;
  LiveQueueSnapshot<T> _snapshot = const LiveQueueSnapshot.loading();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
  }

  @override
  void didUpdateWidget(covariant LiveQueue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      _timer?.cancel();
      _timer = Timer.periodic(widget.refreshInterval, (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (_loading) return;
    _loading = true;
    if (mounted) {
      setState(() {
        _snapshot = LiveQueueSnapshot<T>(
          data: _snapshot.data,
          error: null,
          loading: true,
          lastUpdated: _snapshot.lastUpdated,
        );
      });
    }

    try {
      final data = await widget.loader();
      if (!mounted) return;
      setState(() {
        _snapshot = LiveQueueSnapshot<T>(
          data: data,
          error: null,
          loading: false,
          lastUpdated: DateTime.now(),
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _snapshot = LiveQueueSnapshot<T>(
          data: _snapshot.data,
          error: error,
          loading: false,
          lastUpdated: _snapshot.lastUpdated,
        );
      });
    } finally {
      _loading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _snapshot);
  }
}
