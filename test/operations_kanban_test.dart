import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/screens/admin/operations_board.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
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

  test('OperationsKanbanTest: board logic maps statuses to lanes', () {
    expect(
      operationsLaneFromStatus('pending_review'),
      OperationsLane.newOrders,
    );
    expect(operationsLaneFromStatus('confirmed'), OperationsLane.newOrders);
    expect(operationsLaneFromStatus('preparing'), OperationsLane.preparing);
    expect(
      operationsLaneFromStatus('ready_for_dispatch'),
      OperationsLane.ready,
    );
    expect(operationsLaneFromStatus('dispatched'), OperationsLane.dispatched);
  });

  testWidgets(
    'OperationsKanbanTest: board renders and isolates organizations',
    (tester) async {
      await _pumpBoard(tester);

      expect(find.byType(OperationsColumnHeader), findsNWidgets(4));
      expect(
        find.widgetWithText(OperationsColumnHeader, 'Pendientes'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OperationsColumnHeader, 'En atención'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OperationsColumnHeader, 'Por cerrar'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(OperationsColumnHeader, 'Completadas'),
        findsOneWidget,
      );

      expect(find.text('Alice Gomez'), findsOneWidget);
      expect(find.text('Bob Marin'), findsOneWidget);
      expect(find.text('Carla Rios'), findsOneWidget);
      expect(find.text('Diego Perez'), findsOneWidget);
      expect(find.text('External Client'), findsNothing);
    },
  );

  testWidgets(
    'OperationsKanbanTest: renders representative admin reservation XDTB9E',
    (tester) async {
      await _pumpBoard(
        tester,
        bookings: [
          {
            'id': 1,
            'status': 'pending',
            'created_at': '2026-07-20T23:25:05.000000Z',
            'booking_code': 'XDTB9E',
            'total_price': 0,
            'duration_hours': 1,
            'staff_id': 1,
            'business_id': 7,
            'court_id': 1,
            'date': '2026-07-20T00:00:00.000000Z',
            'time_slot': '10:00 AM to 11:00 AM',
            'user': {
              'id': 2,
              'name': 'Client Demo',
              'email': 'client@example.com',
            },
            'court': {
              'id': 1,
              'name': 'Corte de cabello',
              'address': 'Puntarenas, El Roble, Costa Rica',
              'price_per_hour': 6000,
              'rating': 4.9,
              'images': ['assets/branding/service_placeholder.png'],
              'duration_minutes': 45,
              'status': 'active',
              'business_id': 7,
            },
            'staff': {
              'id': 1,
              'name': 'Carlos Ramirez',
              'email': 'carlos@barberiatresamigos.com',
              'phone': '+506 8888-1001',
              'business_id': 7,
            },
          },
        ],
      );

      expect(find.text('XDTB9E'), findsOneWidget);
      expect(find.text('Client Demo'), findsOneWidget);
      expect(find.textContaining('10:00 AM'), findsOneWidget);

      await tester.tap(find.text('XDTB9E'));
      await tester.pumpAndSettle();

      expect(find.text('Acciones'), findsOneWidget);
      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('Corte de cabello'), findsOneWidget);
      expect(find.text('Client Demo'), findsWidgets);
      expect(find.text('XDTB9E'), findsWidgets);
    },
  );

  testWidgets('OperationsKanbanTest: slide-over opens from the board', (
    tester,
  ) async {
    await _pumpBoard(tester);

    await tester.tap(find.text('Alice Gomez'));
    await tester.pumpAndSettle();

    expect(find.text('Acciones'), findsOneWidget);
    expect(find.text('Cliente'), findsOneWidget);
    expect(find.text('Confirmar'), findsOneWidget);
  });

  testWidgets('OperationsKanbanTest: status transitions move cards', (
    tester,
  ) async {
    await _pumpBoard(tester);

    final newLane = find.byType(OperationsColumn).at(0);
    expect(
      find.descendant(of: newLane, matching: find.text('Alice Gomez')),
      findsOneWidget,
    );

    await tester.tap(find.text('Alice Gomez'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirmar'));
    await tester.pumpAndSettle();
    expect(find.text('confirmar cita'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'confirmar'));
    await tester.pumpAndSettle();

    expect(_lastApi!.bookings.first['status'], 'confirmed');
    expect(
      find.descendant(of: newLane, matching: find.text('Alice Gomez')),
      findsOneWidget,
    );
  });

  testWidgets(
    'OperationsKanbanTest: pending appointments expose reject and cancel actions',
    (tester) async {
      await _pumpBoard(tester);

      await tester.tap(find.text('Alice Gomez'));
      await tester.pumpAndSettle();

      expect(find.text('Rechazar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    },
  );

  test('OperationsKanbanTest: counters are computed from visible cards', () {
    final bookings = _sampleBookings().take(4).toList(growable: false);
    final grouped = bookings.groupBy(
      (item) => operationsLaneFromStatus(item['status']?.toString()),
    );
    expect(grouped[OperationsLane.newOrders]!.length, 1);
    expect(grouped[OperationsLane.preparing]!.length, 1);
    expect(grouped[OperationsLane.ready]!.length, 1);
    expect(grouped[OperationsLane.dispatched]!.length, 1);
  });
}

Future<void> _pumpBoard(
  WidgetTester tester, {
  List<Map<String, dynamic>>? bookings,
}) async {
  await _pumpBoardWithBookings(tester, bookings ?? _sampleBookings());
}

Future<void> _pumpBoardWithBookings(
  WidgetTester tester,
  List<Map<String, dynamic>> bookings,
) async {
  tester.view.physicalSize = const Size(1600, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final api = _FakeApiClient(bookings);
  _lastApi = api;
  final auth = AuthProvider(api);
  await auth.ready;
  auth.user = {'id': 42, 'role': 'admin', 'business_id': 7};
  auth.token = 'token';
  auth.api.token = 'token';

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<BrandTheme>.value(value: BrandTheme.barbershop()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OperationsBoard(selectedDay: DateTime(2026, 7, 7)),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pumpAndSettle();
}

List<Map<String, dynamic>> _sampleBookings() {
  final now = DateTime.now();
  return [
    {
      'id': 1,
      'status': 'pending_review',
      'created_at': now.subtract(const Duration(minutes: 45)).toIso8601String(),
      'booking_code': 'OC-001',
      'user': {'name': 'Alice Gomez'},
      'channel': 'web',
      'items_count': 2,
      'vip': true,
      'priority': 1,
      'parser_confidence': 0.91,
      'business_id': 7,
      'organization_id': 7,
      'date': now.toIso8601String(),
      'time_slot': '09:00',
    },
    {
      'id': 2,
      'status': 'preparing',
      'created_at': now.subtract(const Duration(minutes: 30)).toIso8601String(),
      'booking_code': 'OC-002',
      'user': {'name': 'Bob Marin'},
      'channel': 'whatsapp',
      'items': const [
        {'sku': 'A1'},
      ],
      'duplicate': true,
      'business_id': 7,
      'organization_id': 7,
      'date': now.toIso8601String(),
      'time_slot': '09:15',
    },
    {
      'id': 3,
      'status': 'ready_for_dispatch',
      'created_at': now.subtract(const Duration(minutes: 20)).toIso8601String(),
      'booking_code': 'OC-003',
      'user': {'name': 'Carla Rios'},
      'channel': 'phone',
      'priority': true,
      'business_id': 7,
      'organization_id': 7,
      'date': now.toIso8601String(),
      'time_slot': '09:30',
    },
    {
      'id': 4,
      'status': 'dispatched',
      'created_at': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      'booking_code': 'OC-004',
      'user': {'name': 'Diego Perez'},
      'channel': 'instagram',
      'business_id': 7,
      'organization_id': 7,
      'date': now.toIso8601String(),
      'time_slot': '09:45',
    },
    {
      'id': 5,
      'status': 'confirmed',
      'created_at': now.subtract(const Duration(minutes: 5)).toIso8601String(),
      'booking_code': 'OC-005',
      'user': {'name': 'External Client'},
      'channel': 'web',
      'business_id': 99,
      'organization_id': 99,
      'date': now.toIso8601String(),
      'time_slot': '10:00',
    },
  ];
}

class _FakeApiClient extends ApiClient {
  final List<Map<String, dynamic>> bookings;

  _FakeApiClient(this.bookings) : super(baseUrl: 'http://localhost/api/v1');

  @override
  Future<Map<String, dynamic>> getReservationsForDay(String day) async {
    return {'data': bookings};
  }

  @override
  Future<Map<String, dynamic>> confirmReservation(int id) async =>
      _setStatus(id, 'confirmed');

  @override
  Future<Map<String, dynamic>> rejectReservation(int id) async =>
      _setStatus(id, 'rejected');

  @override
  Future<Map<String, dynamic>> cancelReservation(int id) async =>
      _setStatus(id, 'cancelled');

  Future<Map<String, dynamic>> _setStatus(int id, String status) async {
    final booking = bookings.firstWhere((item) => item['id'] == id);
    booking['status'] = status;
    return Map<String, dynamic>.from(booking);
  }
}

_FakeApiClient? _lastApi;

extension _GroupByExtension<T> on Iterable<T> {
  Map<K, List<T>> groupBy<K>(K Function(T item) keyOf) {
    final result = <K, List<T>>{};
    for (final item in this) {
      final key = keyOf(item);
      result.putIfAbsent(key, () => <T>[]).add(item);
    }
    return result;
  }
}
