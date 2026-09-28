import 'package:flutter/material.dart';

class KeyboardAwareListView extends StatelessWidget {
  final Widget? child;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final ScrollController? controller;
  final bool primary;

  const KeyboardAwareListView({
    super.key,
    this.child,
    this.children = const [],
    this.padding = EdgeInsets.zero,
    this.controller,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final resolvedPadding = padding.resolve(Directionality.of(context));
    return ListView(
      controller: controller,
      primary: primary,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: resolvedPadding.copyWith(
        bottom: resolvedPadding.bottom + bottomInset + 24,
      ),
      children: child == null ? children : [child!],
    );
  }
}
