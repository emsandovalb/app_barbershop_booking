import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/navigation/app_router.dart';
import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/admin/admin_staff_page.dart';
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

  testWidgets(
    'Owner business member sees empty state, can create staff, and the list refreshes',
    (tester) async {
      final api = _FakeStaffApiClient(
        staff: const [],
        roles: [
          {'id': 1, 'name': 'Barber'},
        ],
      );
      final auth = AuthProvider(api);
      await auth.ready;
      auth.user = {
        'id': 7,
        'role': 'user',
        'businesses': [
          {
            'id': 1,
            'slug': 'barberia-tres-amigos',
            'pivot': {'role': 'owner', 'status': 'active'},
          },
        ],
      };
      auth.token = 'token';
      auth.api.token = 'token';

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AppConfig>.value(value: AppConfig.barbershop),
            Provider<BrandTheme>.value(value: BrandTheme.barbershop()),
            Provider<WhiteLabelConfig>.value(
              value: WhiteLabelConfig.tresAmigos,
            ),
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<LocalizationService>.value(
              value: testLocalization(),
            ),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const AdminStaffPage(),
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('miembros del equipo'), findsOneWidget);
      expect(find.textContaining('primer miembro'), findsOneWidget);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(TextFormField), findsWidgets);

      await tester.enterText(find.byType(TextFormField).first, 'Owner Barber');
      await tester.tap(find.text('Guardar'), warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Owner Barber'), findsOneWidget);
      expect(find.textContaining('miembros del equipo'), findsNothing);
    },
  );

  testWidgets('Staff screen shows error and retries after a failed load', (
    tester,
  ) async {
    final api = _FakeStaffApiClient(
      staff: [_staffRecord(1, 'Carlos Barber')],
      roles: const [],
      failFirstLoad: true,
    );
    final auth = AuthProvider(api);
    await auth.ready;
    auth.user = {'id': 7, 'role': 'admin'};
    auth.token = 'token';
    auth.api.token = 'token';

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
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: const AdminStaffPage(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('cargar el equipo'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Carlos Barber'), findsOneWidget);
    expect(find.textContaining('cargar el equipo'), findsNothing);
  });
}

Map<String, dynamic> _staffRecord(int id, String name) {
  return {
    'id': id,
    'name': name,
    'email': '$id@example.com',
    'phone': '',
    'avatar_url': '',
    'is_active': true,
    'role': {'id': 1, 'name': 'Barber'},
    'services': const [],
  };
}

class _FakeStaffApiClient extends ApiClient {
  _FakeStaffApiClient({
    required List<Map<String, dynamic>> staff,
    required List<Map<String, dynamic>> roles,
    this.failFirstLoad = false,
  }) : _staff = [...staff],
       _roles = [...roles],
       super(baseUrl: 'http://localhost/api/v1');

  final List<Map<String, dynamic>> _staff;
  final List<Map<String, dynamic>> _roles;
  final bool failFirstLoad;
  var _loadCalls = 0;

  @override
  Future<Map<String, dynamic>> getStaff({int page = 1, int? perPage}) async {
    _loadCalls += 1;
    if (failFirstLoad && _loadCalls == 1) {
      throw Exception('HTTP 500: Server error');
    }
    return {
      'data': _staff.map((item) => Map<String, dynamic>.from(item)).toList(),
      'meta': {'total': _staff.length},
    };
  }

  @override
  Future<Map<String, dynamic>> getStaffRoles() async {
    return {
      'data': _roles.map((item) => Map<String, dynamic>.from(item)).toList(),
    };
  }

  @override
  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    final next = _staffRecord(
      _staff.isEmpty ? 1 : (_staff.last['id'] as int) + 1,
      data['name']?.toString() ?? 'Staff',
    );
    next['email'] = data['email']?.toString() ?? '';
    next['phone'] = data['phone']?.toString() ?? '';
    next['is_active'] = data['is_active'] == true;
    _staff.add(next);
    return next;
  }

  @override
  Future<Map<String, dynamic>> updateStaff(
    int id,
    Map<String, dynamic> data,
  ) async {
    final index = _staff.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _staff[index] = {..._staff[index], ...data};
    }
    return _staff.firstWhere((item) => item['id'] == id);
  }

  @override
  Future<Map<String, dynamic>> deactivateStaff(int id) async {
    final index = _staff.indexWhere((item) => item['id'] == id);
    if (index != -1) {
      _staff[index] = {..._staff[index], 'is_active': false};
    }
    return _staff.firstWhere((item) => item['id'] == id);
  }
}
