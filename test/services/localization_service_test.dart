import 'dart:io';

import 'package:app_barbershop_booking/src/services/localization_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/i18n.dart';

/// Serves assets from the project folder, like the app bundle would.
class _DiskAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('Asset not found: $key');
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  }
}

Set<String> _placeholders(String value) =>
    RegExp(r'\{(\w+)\}').allMatches(value).map((m) => m.group(1)!).toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final languages = LocalizationService.supportedLanguages;
  final base = {
    for (final language in languages)
      language: readLanguageFile('assets/i18n/$language.json'),
  };

  group('language files', () {
    test('every language defines exactly the same keys', () {
      final reference = base['es']!.keys.toSet();
      for (final language in languages) {
        expect(
          base[language]!.keys.toSet().difference(reference),
          isEmpty,
          reason: '$language.json has keys es.json lacks',
        );
        expect(
          reference.difference(base[language]!.keys.toSet()),
          isEmpty,
          reason: '$language.json is missing keys',
        );
      }
    });

    test('every key used in lib/ exists in every language', () {
      final used = <String>{};
      final call = RegExp(r"\.t\(\s*'([a-z0-9_]+)'");
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          used.addAll(
            call.allMatches(file.readAsStringSync()).map((m) => m.group(1)!),
          );
        }
      }
      expect(used, isNotEmpty);
      for (final language in languages) {
        expect(
          used.difference(base[language]!.keys.toSet()),
          isEmpty,
          reason: 'keys used in code but missing from $language.json',
        );
      }
    });

    test('every key in the language files is used somewhere in lib/', () {
      final source = StringBuffer();
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          source.write(file.readAsStringSync());
        }
      }
      final used = RegExp(
        r"(?:\.t|\btr)\(\s*'([a-z0-9_]+)'",
      ).allMatches(source.toString()).map((m) => m.group(1)!).toSet();
      // The appointments board builds these as 'ops_<kind>_<status>'.
      final dynamicKey = RegExp(r'^ops_(title|question|button|done|failed)_');
      final unused = base['es']!.keys
          .where((key) => !used.contains(key) && !dynamicKey.hasMatch(key))
          .toList();
      expect(unused, isEmpty, reason: 'unused keys in es.json');
    });

    test('translations keep the same placeholders', () {
      for (final key in base['es']!.keys) {
        final expected = _placeholders(base['es']![key]!);
        for (final language in languages) {
          expect(
            _placeholders(base[language]![key]!),
            expected,
            reason: '$key in $language.json',
          );
        }
      }
    });

    test('no value is empty or mis-encoded', () {
      for (final language in languages) {
        base[language]!.forEach((key, value) {
          expect(value.trim(), isNotEmpty, reason: '$key in $language.json');
          expect(
            value,
            isNot(matches(RegExp('Ã|â€|�'))),
            reason: '$key in $language.json looks double-encoded',
          );
        });
      }
    });

    test('no Dart source contains double-encoded text', () {
      for (final file in Directory('lib').listSync(recursive: true)) {
        if (file is File && file.path.endsWith('.dart')) {
          expect(
            file.readAsStringSync(),
            isNot(matches(RegExp('Ã[\u0080-\u00BF]|â€'))),
            reason: file.path,
          );
        }
      }
    });

    test('brand overrides only replace keys that exist', () {
      final brands = Directory('assets/i18n/brands').listSync();
      expect(brands, isNotEmpty);
      for (final brand in brands.whereType<Directory>()) {
        for (final language in languages) {
          final overrides = readLanguageFile('${brand.path}/$language.json');
          expect(
            overrides.keys.toSet().difference(base[language]!.keys.toSet()),
            isEmpty,
            reason: '${brand.path}/$language.json',
          );
        }
      }
    });
  });

  group('LocalizationService', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('loads the device language and switches instantly', () async {
      final service = LocalizationService(bundle: _DiskAssetBundle());
      await service.init(systemLocale: const Locale('en'));
      expect(service.locale.languageCode, 'en');
      expect(service.t('profile_logout'), 'Log out');

      await service.changeLanguage('es');
      expect(service.locale.languageCode, 'es');
      expect(service.t('profile_logout'), 'Cerrar sesión');
    });

    test('remembers the chosen language over the device language', () async {
      final first = LocalizationService(bundle: _DiskAssetBundle());
      await first.init(systemLocale: const Locale('es'));
      await first.changeLanguage('en');

      final next = LocalizationService(bundle: _DiskAssetBundle());
      await next.init(systemLocale: const Locale('es'));
      expect(next.locale.languageCode, 'en');
    });

    test('unsupported languages fall back to Spanish', () async {
      final service = LocalizationService(bundle: _DiskAssetBundle());
      await service.init(systemLocale: const Locale('fr'));
      expect(service.locale.languageCode, 'es');
    });

    test('brand files override the base wording', () async {
      final service = LocalizationService(
        bundle: _DiskAssetBundle(),
        brandSlug: 'jc-studio',
      );
      await service.init(systemLocale: const Locale('es'));
      expect(service.t('staff_title'), 'Estilista');
      await service.changeLanguage('en');
      expect(service.t('staff_title'), 'Stylist');
      // Keys the brand doesn't override keep the base text.
      expect(service.t('profile_logout'), 'Log out');
    });

    test('a brand without override files uses the base wording', () async {
      final service = LocalizationService(
        bundle: _DiskAssetBundle(),
        brandSlug: 'barberia-tres-amigos',
      );
      await service.init(systemLocale: const Locale('es'));
      expect(service.t('staff_title'), 'Barbero');
    });

    test('placeholders are filled from args', () {
      final service = testLocalization(language: 'en');
      expect(
        service.t('filters_count', args: {'count': 3, 'total': 10}),
        'Showing 3 of 10',
      );
      expect(service.t('add_staff', args: {'staff': 'barber'}), 'Add barber');
    });
  });
}
