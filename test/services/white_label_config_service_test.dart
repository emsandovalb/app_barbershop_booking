import 'dart:convert';

import 'package:app_barbershop_booking/src/services/white_label_config_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('jc-studio remote config overrides stale cached branding', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'white_label_config_cache_jc-studio',
      jsonEncode({
        'slug': 'jc-studio',
        'business_type': 'salon',
        'identity': {
          'app_name': 'JC Studio',
          'display_name': 'JC Studio Capilar',
          'short_name': 'JC',
        },
        'assets': {
          'logo_transparent': 'assets/branding/logo_transparent.png',
          'hero_background': 'assets/branding/barbershop_hero_bg.png',
        },
        'colors': {'primary_gold': '#030708', 'background': '#E0E0E0'},
        'appearance': {'theme_preset': 'elegant_light'},
        'terminology': {
          'staff_display_name': 'barbero',
          'business_profile': 'perfil de la barbería',
        },
      }),
    );

    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/public/businesses/jc-studio/config');
      return http.Response(
        jsonEncode({
          'slug': 'jc-studio',
          'business_type': 'salon',
          'identity': {
            'app_name': 'JC Studio',
            'display_name': 'JC Studio Capilar',
            'short_name': 'JC',
            'tagline': 'Cortes, asesorias y experiencias premium',
          },
          'assets': {
            'logo_transparent': '',
            'hero_background': '',
            'service_placeholder': '',
            'staff_placeholder': '',
          },
          'colors': {
            'primary_gold': '#C98F86',
            'primary_gold_light': '#E7C9C3',
            'primary_gold_dark': '#8D5A52',
            'background': '#FBF7F3',
            'surface': '#F4EDE8',
            'card': '#FFFFFF',
            'text_primary': '#1F1614',
            'text_secondary': '#6D5751',
            'text_on_primary': '#1F1614',
          },
          'appearance': {
            'theme_mode': 'light',
            'theme_preset': 'elegant_light',
          },
          'terminology': {
            'service': 'servicio',
            'services': 'servicios',
            'staff_display_name': 'estilista',
            'business_profile': 'perfil del salón',
          },
          'features': {'show_staff': true, 'show_admin_dashboard': true},
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = WhiteLabelConfigService(
      baseUrl: 'http://example.test/api/v1',
      businessSlug: 'jc-studio',
      client: client,
    );

    await service.initialize();

    expect(service.config.slug, 'jc-studio');
    expect(service.config.assets.logoTransparent, isEmpty);
    expect(service.config.assets.heroBackground, isEmpty);
    expect(service.config.staffDisplayName, 'estilista');
    expect(service.brandTheme.background.toARGB32(), 0xFFFBF7F3);

    final legacyCache =
        jsonDecode(prefs.getString('white_label_config_cache_jc-studio')!)
            as Map<String, dynamic>;
    expect(
      legacyCache['assets']['hero_background'],
      'assets/branding/barbershop_hero_bg.png',
    );

    final versionedKeys = prefs
        .getKeys()
        .where((key) => key.contains('white_label_config_cache_v3_jc-studio'))
        .toList();
    expect(versionedKeys, hasLength(1));

    final stored =
        jsonDecode(prefs.getString(versionedKeys.single)!)
            as Map<String, dynamic>;
    expect(stored['assets']['hero_background'], isEmpty);
    expect(stored['terminology']['staff_display_name'], 'estilista');
  });
}
