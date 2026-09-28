import 'package:app_barbershop_booking/src/config/app_config.dart';
import 'package:app_barbershop_booking/src/config/white_label_config.dart';
import 'package:app_barbershop_booking/src/navigation/app_router.dart';
import 'package:app_barbershop_booking/src/navigation/tenant_startup_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unauthenticated tenant boot stays in Flutter onboarding', () {
    expect(
      TenantStartupRoute.forAuthentication(isAuthenticated: false),
      AppRoutes.onboarding,
    );
    expect(TenantStartupRoute.afterOnboarding(), AppRoutes.login);
    expect(
      TenantStartupRoute.afterOnboarding(),
      isNot(contains('super-admin')),
    );
    expect(TenantStartupRoute.afterOnboarding(), isNot(contains('http')));
  });

  test('authenticated tenant boot enters Flutter home', () {
    expect(
      TenantStartupRoute.forAuthentication(isAuthenticated: true),
      AppRoutes.home,
    );
  });

  test(
    'tenant bootstrap presets remain separate before remote config loads',
    () {
      expect(WhiteLabelConfig.tresAmigos.slug, 'barberia-tres-amigos');
      expect(WhiteLabelConfig.jcStudio.slug, 'jc-studio');
      expect(WhiteLabelConfig.tresAmigos.displayName, contains('TRES AMIGOS'));
      expect(WhiteLabelConfig.jcStudio.displayName, 'JC STUDIO');
      expect(AppConfig.barbershop.terminology.staff, 'Barbero');
      expect(AppConfig.jcStudio.terminology.staff, 'Estilista');
    },
  );
}
