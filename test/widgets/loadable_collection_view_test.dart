import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_barbershop_booking/src/widgets/loadable_collection_view.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: child,
    ),
  );
}

void main() {
  testWidgets('shows loaded items when the request succeeds', (tester) async {
    final controller = LoadableController<List<String>>(
      () async => ['one', 'two'],
    );

    await tester.pumpWidget(
      _wrap(
        LoadableCollectionView<List<String>>(
          controller: controller,
          isEmpty: (items) => items.isEmpty,
          loadingBuilder: (_, __) => const Text('loading'),
          errorBuilder: (_, __, ___) => const Text('error'),
          emptyBuilder: (_, __) => const Text('empty'),
          dataBuilder: (_, data, __, ___) => Text('items: ${data.length}'),
        ),
      ),
    );

    expect(find.text('loading'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('items: 2'), findsOneWidget);
    expect(find.text('empty'), findsNothing);
    expect(find.text('error'), findsNothing);
  });

  testWidgets('shows the empty state when the request succeeds without items',
      (tester) async {
    final controller = LoadableController<List<String>>(
      () async => <String>[],
    );

    await tester.pumpWidget(
      _wrap(
        LoadableCollectionView<List<String>>(
          controller: controller,
          isEmpty: (items) => items.isEmpty,
          loadingBuilder: (_, __) => const Text('loading'),
          errorBuilder: (_, __, ___) => const Text('error'),
          emptyBuilder: (_, __) => const Text('empty'),
          dataBuilder: (_, data, __, ___) => Text('items: ${data.length}'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('empty'), findsOneWidget);
    expect(find.text('error'), findsNothing);
    expect(find.text('items: 0'), findsNothing);
  });

  testWidgets('shows the error state when the request fails', (tester) async {
    final controller = LoadableController<List<String>>(
      () async {
        throw Exception('network');
      },
    );

    await tester.pumpWidget(
      _wrap(
        LoadableCollectionView<List<String>>(
          controller: controller,
          isEmpty: (items) => items.isEmpty,
          loadingBuilder: (_, __) => const Text('loading'),
          errorBuilder: (_, __, ___) => const Text('error'),
          emptyBuilder: (_, __) => const Text('empty'),
          dataBuilder: (_, data, __, ___) => Text('items: ${data.length}'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('error'), findsOneWidget);
    expect(find.text('empty'), findsNothing);
    expect(find.text('items: 0'), findsNothing);
  });

  testWidgets('retries successfully after an initial error', (tester) async {
    var attempts = 0;
    final controller = LoadableController<List<String>>(
      () async {
        attempts += 1;
        if (attempts == 1) {
          throw Exception('network');
        }
        return ['recovered'];
      },
    );

    await tester.pumpWidget(
      _wrap(
        LoadableCollectionView<List<String>>(
          controller: controller,
          isEmpty: (items) => items.isEmpty,
          loadingBuilder: (_, __) => const Text('loading'),
          errorBuilder: (context, error, retry) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('error'),
                TextButton(
                  onPressed: () => retry(),
                  child: const Text('retry'),
                ),
              ],
            );
          },
          emptyBuilder: (_, __) => const Text('empty'),
          dataBuilder: (_, data, __, ___) => Text('items: ${data.length}'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('error'), findsOneWidget);
    expect(find.text('retry'), findsOneWidget);

    await tester.tap(find.text('retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('items: 1'), findsOneWidget);
    expect(find.text('error'), findsNothing);
  });
}
