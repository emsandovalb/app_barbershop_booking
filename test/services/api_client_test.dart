import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'normalizeEmailInput removes only surrounding whitespace and invisible separators',
    () {
      expect(
        normalizeEmailInput(' \u200Bcliente.jc@example.com\uFEFF '),
        'cliente.jc@example.com',
      );
      expect(
        normalizeEmailInput('cliente jc@example.com'),
        'cliente jc@example.com',
      );
    },
  );

  test('resolveAssetUrl keeps absolute URLs unchanged', () {
    final api = ApiClient(baseUrl: 'http://localhost/api/v1');

    expect(
      api.resolveAssetUrl('https://cdn.example.com/image.jpg'),
      'https://cdn.example.com/image.jpg',
    );
  });

  test('resolveAssetUrl converts storage paths through the media endpoint', () {
    final api = ApiClient(baseUrl: 'http://localhost/api/v1');

    final resolved = api.resolveAssetUrl('/storage/services/image.jpg');

    expect(resolved, startsWith('http://localhost/api/v1/media?path='));
    expect(
      Uri.parse(resolved).queryParameters['path'],
      '/storage/services/image.jpg',
    );
    expect(resolved.contains('/api/v1/api/v1/'), isFalse);
  });

  test('resolveAssetUrl encodes spaces and special characters safely', () {
    final api = ApiClient(baseUrl: 'http://localhost/api/v1');

    final resolved = api.resolveAssetUrl(
      '/storage/services/servicio especial #1 ñ.png',
    );

    expect(
      Uri.parse(resolved).queryParameters['path'],
      '/storage/services/servicio especial #1 ñ.png',
    );
  });

  test('resolveAssetUrl returns an empty string for null or empty values', () {
    final api = ApiClient(baseUrl: 'http://localhost/api/v1');

    expect(api.resolveAssetUrl(null), '');
    expect(api.resolveAssetUrl(''), '');
  });
}
