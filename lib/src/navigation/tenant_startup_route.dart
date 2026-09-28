import 'app_router.dart';

/// Owns the Flutter-only boot decision.
///
/// `AppRoutes.login` is an in-process Flutter route. It intentionally has no
/// relationship to Laravel's web `/login` route, and this class never returns
/// a URL or a Super Admin route.
abstract final class TenantStartupRoute {
  static String forAuthentication({required bool isAuthenticated}) =>
      isAuthenticated ? AppRoutes.home : AppRoutes.onboarding;

  static String afterOnboarding() => AppRoutes.login;
}
