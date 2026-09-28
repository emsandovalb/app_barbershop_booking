import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:app_barbershop_booking/src/app.dart';
import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/screens/gallery/gallery_page.dart';
import 'package:app_barbershop_booking/src/theme/brand_theme.dart';

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

  testWidgets('Gallery page renders hero content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<WhiteLabelConfig>.value(value: WhiteLabelConfig.jcStudio),
          Provider<BrandTheme>.value(value: BrandTheme.jcStudio()),
        ],
        child: const MaterialApp(home: GalleryPage()),
      ),
    );

    expect(find.text('Conocé nuestro trabajo'), findsOneWidget);
    expect(find.text('Featured Work'), findsOneWidget);
  });
}
