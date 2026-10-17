import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/admin/admin_dashboard_page.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/services/localization_service.dart';
import 'package:app_barbershop_booking/src/theme/brand_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../support/i18n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Admin dashboard rejects a client membership', (tester) async {
    final auth = _authWithCapability(canManageBusiness: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AppConfig>.value(value: AppConfig.barbershop),
            Provider<BrandTheme>.value(value: BrandTheme.barbershop()),
          Provider<WhiteLabelConfig>.value(value: WhiteLabelConfig.tresAmigos),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
          ChangeNotifierProvider<LocalizationService>.value(
            value: testLocalization(),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardPage()),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Solo los administradores pueden acceder a esta secci\u00f3n'),
      findsOneWidget,
    );
  });
}

AuthProvider _authWithCapability({required bool canManageBusiness}) {
  final auth = AuthProvider(_FakeAdminApiClient());
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
    'business_role': canManageBusiness ? 'owner' : 'client',
    'business_status': 'active',
    'can_manage_business': canManageBusiness,
  };
  auth.token = 'token';
  auth.api.token = 'token';
  return auth;
}

class _FakeAdminApiClient extends ApiClient {
  _FakeAdminApiClient() : super(baseUrl: 'http://localhost/api/v1');

  @override
  Future<Map<String, dynamic>> getReservationsForDay(String day) async {
    return const {'data': []};
  }

  @override
  Future<Map<String, dynamic>> getStaff({int page = 1, int? perPage}) async {
    return const {'data': []};
  }

  @override
  Future<Map<String, dynamic>> getResources({
    String? q,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? category,
    int? durationHours,
    int page = 1,
    int? perPage,
  }) async {
    return const {'data': []};
  }
}
