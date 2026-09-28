import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login with remember session stores token, user, and email', () async {
    final api = _FakeApiClient();
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login(
      'client@example.com',
      'secret123',
      rememberSession: true,
    );

    expect(ok, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.rememberSession, isTrue);
    expect(auth.rememberedEmail, 'client@example.com');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'token-123');
    expect(prefs.getString('auth_user'), isNotNull);
    expect(prefs.getBool('login_remember_session'), isTrue);
    expect(prefs.getString('login_remembered_email'), 'client@example.com');

    final restored = AuthProvider(api);
    await restored.ready;
    expect(restored.isLoggedIn, isTrue);
    expect(restored.token, 'token-123');
    expect(restored.rememberedEmail, 'client@example.com');
  });

  test(
    'login without remember session keeps the session in memory only',
    () async {
      final api = _FakeApiClient();
      final auth = AuthProvider(api);
      await auth.ready;

      final ok = await auth.login(
        'temp@example.com',
        'secret123',
        rememberSession: false,
      );

      expect(ok, isTrue);
      expect(auth.isLoggedIn, isTrue);
      expect(auth.rememberSession, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user'), isNull);
      expect(prefs.getBool('login_remember_session'), isFalse);
      expect(prefs.getString('login_remembered_email'), 'temp@example.com');

      final restored = AuthProvider(api);
      await restored.ready;
      expect(restored.isLoggedIn, isFalse);
      expect(restored.token, isNull);
      expect(restored.rememberedEmail, 'temp@example.com');
    },
  );

  test(
    'logout removes the persisted token and user but preserves preferences',
    () async {
      final api = _FakeApiClient();
      final auth = AuthProvider(api);
      await auth.ready;

      await auth.login(
        'logout@example.com',
        'secret123',
        rememberSession: true,
      );
      await auth.logout();

      expect(auth.isLoggedIn, isFalse);
      expect(auth.token, isNull);
      expect(api.logoutCalls, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(prefs.getString('auth_user'), isNull);
      expect(prefs.getBool('login_remember_session'), isTrue);
      expect(prefs.getString('login_remembered_email'), 'logout@example.com');
      expect(
        prefs.getKeys().any((key) => key.toLowerCase().contains('password')),
        isFalse,
      );
    },
  );

  test('owner response maps to admin capability', () async {
    final api = _FakeApiClient(
      loginUser: _businessMember(
        role: 'user',
        businessRole: 'owner',
        businessStatus: 'active',
        canManageBusiness: true,
      ),
      meUser: _businessMember(
        role: 'user',
        businessRole: 'owner',
        businessStatus: 'active',
        canManageBusiness: true,
      ),
    );
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login('owner@example.com', 'secret123');

    expect(ok, isTrue);
    expect(auth.canManageBusiness, isTrue);
    expect(auth.currentBusinessRole, 'owner');
    expect(auth.currentBusinessStatus, 'active');
  });

  test('admin response maps to admin capability', () async {
    final api = _FakeApiClient(
      loginUser: _businessMember(
        role: 'user',
        businessRole: 'admin',
        businessStatus: 'active',
        canManageBusiness: true,
      ),
      meUser: _businessMember(
        role: 'user',
        businessRole: 'admin',
        businessStatus: 'active',
        canManageBusiness: true,
      ),
    );
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login('admin@example.com', 'secret123');

    expect(ok, isTrue);
    expect(auth.canManageBusiness, isTrue);
    expect(auth.currentBusinessRole, 'admin');
    expect(auth.currentBusinessStatus, 'active');
  });

  test('client response does not map to admin capability', () async {
    final api = _FakeApiClient(
      loginUser: _businessMember(
        role: 'user',
        businessRole: 'client',
        businessStatus: 'active',
        canManageBusiness: false,
      ),
      meUser: _businessMember(
        role: 'user',
        businessRole: 'client',
        businessStatus: 'active',
        canManageBusiness: false,
      ),
    );
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login('client@example.com', 'secret123');

    expect(ok, isTrue);
    expect(auth.canManageBusiness, isFalse);
    expect(auth.currentBusinessRole, 'client');
    expect(auth.currentBusinessStatus, 'active');
  });

  test('global admin keeps admin capability without a business slug', () async {
    final api = _FakeApiClient(
      loginUser: {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'role': 'admin',
        'can_manage_business': true,
      },
      meUser: {
        'id': 1,
        'name': 'Super Admin',
        'email': 'admin@example.com',
        'role': 'admin',
        'can_manage_business': true,
      },
    );
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login('admin@example.com', 'secret123');

    expect(ok, isTrue);
    expect(auth.isAdmin, isTrue);
    expect(auth.canManageBusiness, isTrue);
    expect(auth.currentBusiness, isNull);
  });

  test('login succeeds even if the post-login refresh fails', () async {
    final api = _FakeApiClient(
      loginUser: _businessMember(
        role: 'user',
        businessRole: 'owner',
        businessStatus: 'active',
        canManageBusiness: true,
      ),
      refreshShouldFail: true,
    );
    final auth = AuthProvider(api);
    await auth.ready;

    final ok = await auth.login('owner@example.com', 'secret123');

    expect(ok, isTrue);
    expect(auth.isLoggedIn, isTrue);
    expect(auth.canManageBusiness, isTrue);
    expect(auth.currentBusinessRole, 'owner');
    expect(auth.currentBusinessStatus, 'active');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('auth_token'), 'token-123');
    expect(prefs.getString('auth_user'), isNotNull);
  });

  test(
    'registration validation failures stay in the app and expose the field error',
    () async {
      final auth = AuthProvider(
        _FakeApiClient(
          registrationError: ApiException(
            'The email field must be a valid email address.',
            statusCode: 422,
            errors: const {
              'email': ['The email field must be a valid email address.'],
            },
          ),
        ),
      );
      await auth.ready;

      final ok = await auth.register(
        name: 'Cliente QA JC',
        email: 'not-an-email',
        password: 'Password123!',
      );

      expect(ok, isFalse);
      expect(auth.isLoggedIn, isFalse);
      expect(
        auth.registrationError,
        'The email field must be a valid email address.',
      );
    },
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    Map<String, dynamic>? loginUser,
    Map<String, dynamic>? meUser,
    bool refreshShouldFail = false,
    ApiException? registrationError,
  }) : _loginUser = loginUser,
       _meUser = meUser,
       _refreshShouldFail = refreshShouldFail,
       _registrationError = registrationError,
       super(baseUrl: 'http://localhost/api/v1');

  int logoutCalls = 0;
  final Map<String, dynamic>? _loginUser;
  final Map<String, dynamic>? _meUser;
  final bool _refreshShouldFail;
  final ApiException? _registrationError;

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    return {
      'token': 'token-123',
      'user':
          _loginUser ??
          {'id': 1, 'name': 'Client Demo', 'email': email, 'role': 'user'},
    };
  }

  @override
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    if (_registrationError != null) throw _registrationError;
    return {
      'token': 'token-123',
      'user': {'id': 1, 'name': name, 'email': email, 'role': 'user'},
    };
  }

  @override
  Future<Map<String, dynamic>> me() async {
    if (_refreshShouldFail) {
      throw Exception('refresh failed');
    }
    return {
      'user':
          _meUser ??
          {
            'id': 1,
            'name': 'Client Demo',
            'email': 'client@example.com',
            'role': 'user',
          },
    };
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}

Map<String, dynamic> _businessMember({
  required String role,
  required String businessRole,
  required String businessStatus,
  required bool canManageBusiness,
}) {
  return {
    'id': 1,
    'name': 'Member Demo',
    'email': 'member@example.com',
    'role': role,
    'business': {
      'id': 7,
      'name': 'JC Studio',
      'slug': 'jc-studio',
      'status': 'active',
    },
    'business_id': 7,
    'business_slug': 'jc-studio',
    'business_role': businessRole,
    'business_status': businessStatus,
    'can_manage_business': canManageBusiness,
  };
}
