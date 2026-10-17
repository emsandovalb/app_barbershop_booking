import 'dart:async';

import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/services/resilient_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('a request that never answers fails with a readable error', () async {
    final client = ResilientHttpClient(
      inner: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 50),
      getRetries: 0,
    );

    await expectLater(
      client.get(Uri.parse('https://api.example.com/resources')),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          networkErrorMessage,
        ),
      ),
    );
  });

  test('a GET is retried once after a connection error', () async {
    var calls = 0;
    final client = ResilientHttpClient(
      inner: MockClient((_) async {
        calls++;
        if (calls == 1) throw http.ClientException('connection reset');
        return http.Response('{"ok":true}', 200);
      }),
      retryDelay: Duration.zero,
    );

    final res = await client.get(Uri.parse('https://api.example.com/x'));

    expect(res.statusCode, 200);
    expect(calls, 2);
  });

  test('a POST is never retried, so a booking is not created twice', () async {
    var calls = 0;
    final client = ResilientHttpClient(
      inner: MockClient((_) async {
        calls++;
        throw http.ClientException('connection reset');
      }),
      retryDelay: Duration.zero,
    );

    await expectLater(
      client.post(Uri.parse('https://api.example.com/reservations')),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 1);
  });

  test(
    'ApiClient uses the injected client and surfaces network errors',
    () async {
      final api = ApiClient(
        baseUrl: 'https://api.example.com/api/v1',
        httpClient: ResilientHttpClient(
          inner: MockClient((_) async => throw http.ClientException('offline')),
          retryDelay: Duration.zero,
        ),
      );

      await expectLater(api.getAppConfig(), throwsA(isA<ApiException>()));
    },
  );
}
