import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/profile/profile_tab.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/services/localization_service.dart';
import 'package:app_barbershop_booking/src/theme/brand_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('profile shows Centro Administrativo for owner memberships', (
    tester,
  ) async {
    final auth = _authWithBusinessCapability(
      canManageBusiness: true,
      businessRole: 'owner',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: AppConfig.barbershop),
          Provider<BrandTheme>.value(value: BrandTheme.barbershop()),
          Provider<WhiteLabelConfig>.value(value: WhiteLabelConfig.tresAmigos),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService(translationsBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dashboard_outlined), findsOneWidget);
    expect(find.textContaining('administrativo'), findsOneWidget);
  });

  testWidgets('profile hides Centro Administrativo for client memberships', (
    tester,
  ) async {
    final auth = _authWithBusinessCapability(
      canManageBusiness: false,
      businessRole: 'client',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: AppConfig.barbershop),
          Provider<BrandTheme>.value(value: BrandTheme.barbershop()),
          Provider<WhiteLabelConfig>.value(value: WhiteLabelConfig.tresAmigos),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocalizationService>.value(
            value: LocalizationService(translationsBaseUrl: 'http://localhost'),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileTab())),
      ),
    );

    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dashboard_outlined), findsNothing);
  });
}

AuthProvider _authWithBusinessCapability({
  required bool canManageBusiness,
  required String businessRole,
}) {
  final auth = AuthProvider(ApiClient(baseUrl: 'http://localhost/api/v1'));
  auth.user = {
    'id': 7,
    'name': 'Member Demo',
    'email': 'member@example.com',
    'role': 'user',
    'business': {
      'id': 7,
      'name': 'JC Studio',
      'slug': 'jc-studio',
      'status': 'active',
    },
    'business_id': 7,
    'business_slug': 'jc-studio',
    'business_role': businessRole,
    'business_status': 'active',
    'can_manage_business': canManageBusiness,
  };
  auth.token = 'token';
  auth.api.token = 'token';
  return auth;
}
