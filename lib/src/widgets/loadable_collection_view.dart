import 'package:flutter/material.dart';

class LoadableState<T> {
  final T? data;
  final Object? error;
  final bool isLoading;

  LoadableState({this.data, this.error, this.isLoading = false});

  bool get hasData => data != null;
  bool get hasError => error != null;
}

class LoadableController<T> extends ChangeNotifier {
  final Future<T> Function() loader;
  final bool preserveDataOnError;

  LoadableState<T> _state = LoadableState<T>(isLoading: true);
  Future<void>? _activeLoad;
  bool _disposed = false;

  LoadableController(this.loader, {this.preserveDataOnError = false});

  LoadableState<T> get state => _state;

  Future<void> load({bool clearData = true}) {
    if (_disposed) {
      return Future<void>.value();
    }
    if (_activeLoad != null) {
      return _activeLoad!;
    }

    final previousData = _state.data;
    _setState(
      LoadableState<T>(
        data: clearData ? null : previousData,
        error: null,
        isLoading: true,
      ),
    );

    final future = _performLoad(previousData);
    _activeLoad = future;
    return future.whenComplete(() {
      if (_activeLoad == future) {
        _activeLoad = null;
      }
    });
  }

  Future<void> _performLoad(T? previousData) async {
    try {
      final data = await loader();
      if (_disposed) return;
      _setState(LoadableState<T>(data: data));
    } catch (error) {
      if (_disposed) return;
      _setState(
        LoadableState<T>(
          data: preserveDataOnError ? previousData : null,
          error: error,
        ),
      );
    }
  }

  void _setState(LoadableState<T> next) {
    _state = next;
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

typedef LoadableLoadingBuilder =
    Widget Function(BuildContext context, Future<void> Function() retry);

typedef LoadableErrorBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      Future<void> Function() retry,
    );

typedef LoadableEmptyBuilder =
    Widget Function(BuildContext context, Future<void> Function() retry);

typedef LoadableDataBuilder<T> =
    Widget Function(
      BuildContext context,
      T data,
      Future<void> Function() retry,
      bool isLoading,
    );

class LoadableCollectionView<T> extends StatefulWidget {
  final LoadableController<T> controller;
  final bool Function(T data) isEmpty;
  final LoadableLoadingBuilder loadingBuilder;
  final LoadableErrorBuilder errorBuilder;
  final LoadableEmptyBuilder emptyBuilder;
  final LoadableDataBuilder<T> dataBuilder;

  const LoadableCollectionView({
    super.key,
    required this.controller,
    required this.isEmpty,
    required this.loadingBuilder,
    required this.errorBuilder,
    required this.emptyBuilder,
    required this.dataBuilder,
  });

  @override
  State<LoadableCollectionView<T>> createState() =>
      _LoadableCollectionViewState<T>();
}

class _LoadableCollectionViewState<T> extends State<LoadableCollectionView<T>> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final retry = widget.controller.load;

        if (state.isLoading && !state.hasData) {
          return widget.loadingBuilder(context, retry);
        }

        if (state.hasError && !state.hasData) {
          return widget.errorBuilder(context, state.error!, retry);
        }

        final data = state.data;
        if (data != null && widget.isEmpty(data)) {
          return widget.emptyBuilder(context, retry);
        }

        if (data == null) {
          return widget.loadingBuilder(context, retry);
        }

        return widget.dataBuilder(context, data, retry, state.isLoading);
      },
    );
  }
}
