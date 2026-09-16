import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/booking/payment_page.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test for the stuck "Procesando..." bug: when a barber was
/// selected but its id came back null, _confirm() showed an error and
/// returned before reaching the `loading = false` reset that only lived
/// in the try/finally around the network call — leaving the confirm
/// button permanently disabled. The fix moved everything after
/// `loading = true` inside a single try/finally so every exit path
/// (this early return included) resets it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPaymentPage(
    WidgetTester tester, {
    required Map<String, dynamic> args,
    ApiClient? api,
  }) async {
    final auth = AuthProvider(
      api ?? ApiClient(baseUrl: 'http://localhost/api/v1'),
    );
    // AuthProvider restores its token from SharedPreferences asynchronously
    // in the constructor; wait for that to finish before overriding it,
    // or the restore (finding nothing in the mocked empty prefs) clobbers
    // the value set below back to null.
    await auth.ready;
    auth.user = {'id': 1, 'name': 'Cliente Demo', 'email': 'demo@example.com'};
    auth.token = 'token';
    auth.api.token = 'token';

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
        child: MaterialApp(home: PaymentPage(args: args)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'invalid staff selection clears the loading state instead of getting stuck on Procesando...',
    (tester) async {
      await pumpPaymentPage(
        tester,
        args: {
          'resource': {'id': 1, 'name': 'Corte Clásico'},
          'iso': '2026-09-01T10:00:00.000',
          'slot': '10:00 AM to 11:00 AM',
          'duration': 1,
          // A staff map with no 'id' and no separate 'staff_id': selectedBarber
          // ends up non-null while _selectedStaffId() resolves to null —
          // exactly the originally-reported failure condition.
          'staff': {'name': 'Carlos Ramírez'},
        },
      );

      // Sanity check on the pre-tap state: button reads "Continuar" and is
      // enabled, not already stuck.
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Procesando...'), findsNothing);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
      await tester.pump();

      // The specific validation error was shown...
      expect(
        find.text('La selección de barbero no es válida. Elegí uno de nuevo.'),
        findsOneWidget,
      );

      // ...and, critically, the button is not left stuck on "Procesando...":
      // the loading state cleared and it's tappable again.
      expect(find.text('Procesando...'), findsNothing);
      expect(find.text('Continuar'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(
        button.onPressed,
        isNotNull,
        reason:
            'Confirm button must be re-enabled after the failed validation.',
      );
    },
  );

  testWidgets(
    'a malformed booking arg (missing iso) also clears loading instead of leaving it stuck',
    (tester) async {
      // Covers the second early-exit path found alongside the reported one:
      // `widget.args['iso'] as String` throws before the try block used to
      // start, which had the identical stuck-loading symptom under a
      // different trigger.
      await pumpPaymentPage(
        tester,
        args: {
          'resource': {'id': 1, 'name': 'Corte Clásico'},
          'slot': '10:00 AM to 11:00 AM',
          'duration': 1,
          // 'iso' deliberately omitted.
        },
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
      await tester.pump();

      expect(find.text('Procesando...'), findsNothing);
      expect(find.text('Continuar'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continuar'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'a creation response without a persisted ID never opens the success screen',
    (tester) async {
      await pumpPaymentPage(
        tester,
        api: _MissingIdReservationApiClient(),
        args: {
          'resource': {'id': 1, 'name': 'Corte Clásico'},
          'iso': '2026-09-01T10:00:00.000',
          'slot': '10:00 AM to 11:00 AM',
          'duration': 1,
        },
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continuar'));
      await tester.pump();

      expect(find.text('Cita confirmada'), findsNothing);
      expect(
        find.textContaining('Reservation was not persisted'),
        findsOneWidget,
      );
      expect(find.text('Continuar'), findsOneWidget);
    },
  );
}

class _MissingIdReservationApiClient extends ApiClient {
  _MissingIdReservationApiClient() : super(baseUrl: 'http://localhost/api/v1');

  @override
  Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> data,
  ) async => <String, dynamic>{};
}
