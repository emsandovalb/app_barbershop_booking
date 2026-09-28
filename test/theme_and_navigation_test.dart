import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/screens/admin/admin_page_scaffold.dart';
import 'package:app_barbershop_booking/src/theme/brand_theme.dart';
import 'package:app_barbershop_booking/src/widgets/barbershop_branding.dart';
import 'package:app_barbershop_booking/src/services/salon_fallbacks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

double _contrastRatio(Color foreground, Color background) {
  final l1 = foreground.computeLuminance();
  final l2 = background.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test(
    'JC Studio preset uses salon-safe defaults and no Tres Amigos assets',
    () {
      expect(WhiteLabelConfig.jcStudio.slug, 'jc-studio');
      expect(WhiteLabelConfig.jcStudio.shortName, 'JC');
      expect(WhiteLabelConfig.jcStudio.logoTransparent, isEmpty);
      expect(WhiteLabelConfig.jcStudio.heroBackground, isEmpty);
      expect(WhiteLabelConfig.jcStudio.staffDisplayName, 'estilista');
      expect(
        WhiteLabelConfig.jcStudio.businessProfileLabel,
        'perfil del salón',
      );
      expect(salonFallbacks['booking_barber_choose'], 'Elegir estilista');
    },
  );

  test(
    'BrandTheme.jcStudio keeps button and placeholder contrast readable',
    () {
      final theme = BrandTheme.jcStudio();
      final data = theme.buildThemeData();
      expect(
        _contrastRatio(data.colorScheme.onPrimary, data.colorScheme.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrastRatio(
          data.inputDecorationTheme.hintStyle!.color!,
          data.inputDecorationTheme.fillColor!,
        ),
        greaterThanOrEqualTo(3.0),
      );
      expect(
        _contrastRatio(data.colorScheme.onSurface, data.colorScheme.surface),
        greaterThanOrEqualTo(4.5),
      );
    },
  );

  testWidgets('Missing logo renders initials fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Provider<BrandTheme>.value(
          value: BrandTheme.jcStudio(),
          child: const Scaffold(
            body: Center(
              child: BarbershopLogoMark(
                assetPath: '',
                fallbackLabel: 'JC',
                size: 120,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('JC'), findsWidgets);
  });

  testWidgets('Admin back action returns to the previous route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/': (_) => const _HomeProbe(),
          '/admin': (_) => const _AdminProbe(),
        },
        initialRoute: '/',
      ),
    );

    await tester.tap(find.text('Open admin'));
    await tester.pumpAndSettle();

    expect(find.text('Admin probe'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Open admin'), findsWidgets);
  });
}

class _HomeProbe extends StatelessWidget {
  const _HomeProbe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pushNamed('/admin'),
          child: const Text('Open admin'),
        ),
      ),
    );
  }
}

class _AdminProbe extends StatelessWidget {
  const _AdminProbe();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAdminAppBar(context, title: 'Admin probe'),
      body: const Center(child: Text('Admin probe')),
    );
  }
}
