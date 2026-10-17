import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_barbershop_booking/src/app.dart';
import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';

void main() {
  testWidgets('App bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const BarbershopBookingApp(
        config: AppConfig.barbershop,
        whiteLabelConfig: WhiteLabelConfig.generic,
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
