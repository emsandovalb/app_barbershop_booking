import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/navigation/app_router.dart';
import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/auth/login_page.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/services/localization_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test: the "Regístrate" text next to "¿No tienes cuenta?"
/// used to be plain, non-interactive RichText — no onTap, no
/// GestureDetector, nothing. Tapping it did nothing at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('tapping "Regístrate" navigates to the signup route', (
    tester,
  ) async {
    final auth = AuthProvider(ApiClient(baseUrl: 'http://localhost/api/v1'));
    await auth.ready;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: AppConfig.barbershop),
          Provider<WhiteLabelConfig>.value(value: WhiteLabelConfig.tresAmigos),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService(translationsBaseUrl: 'http://localhost'),
          ),
        ],
        child: MaterialApp(
          home: const LoginPage(),
          routes: {
            AppRoutes.signup: (_) =>
                const Scaffold(body: Text('Signup Probe')),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // "Regístrate" is one TextSpan inside a RichText that also contains
    // "¿No tienes cuenta? " — find.text() only matches a Text/RichText's
    // *entire* combined plain text, so it can't find this standalone
    // span, and pixel-offset tapping is flaky for inline spans. Instead,
    // find the specific TextSpan and invoke its recognizer directly —
    // the standard pattern for testing tappable RichText spans.
    final signupTextFinder = find.byWidgetPredicate(
      (widget) => widget is RichText && widget.text.toPlainText().contains('Regístrate'),
    );
    expect(signupTextFinder, findsOneWidget);

    final richText = tester.widget<RichText>(signupTextFinder);
    TapGestureRecognizer? recognizer;
    (richText.text as TextSpan).visitChildren((span) {
      if (span is TextSpan && span.text == 'Regístrate') {
        recognizer = span.recognizer as TapGestureRecognizer?;
      }
      return true;
    });
    expect(
      recognizer,
      isNotNull,
      reason: 'The "Regístrate" span must have a tap recognizer attached.',
    );
    recognizer!.onTap!();
    await tester.pumpAndSettle();

    expect(find.text('Signup Probe'), findsOneWidget);
  });
}
