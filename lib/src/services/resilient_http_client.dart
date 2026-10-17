import 'dart:async';

import 'package:http/http.dart' as http;

import 'api.dart' show ApiException;

/// Message shown when the server can't be reached or takes too long.
const String networkErrorMessage =
    'No pudimos conectar con el servidor. Revisá tu conexión e intentá de nuevo.';

/// Wraps an [http.Client] so no request can hang forever.
///
/// Every request gets a deadline ([timeout], or [uploadTimeout] for
/// multipart uploads). GET requests are retried [getRetries] times after a
/// timeout or connection error, since repeating a read is safe; writes are
/// never retried so a booking can't be created twice. When all attempts
/// fail the caller gets an [ApiException] with a readable message instead
/// of a raw socket or timeout error.
class ResilientHttpClient extends http.BaseClient {
  ResilientHttpClient({
    http.Client? inner,
    this.timeout = const Duration(seconds: 20),
    this.uploadTimeout = const Duration(seconds: 60),
    this.getRetries = 1,
    this.retryDelay = const Duration(milliseconds: 500),
  }) : _inner = inner ?? http.Client();

  final http.Client _inner;
  final Duration timeout;
  final Duration uploadTimeout;
  final int getRetries;
  final Duration retryDelay;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final deadline = request is http.MultipartRequest ? uploadTimeout : timeout;
    final canRetry = request.method == 'GET' && request is http.Request;
    var attempt = 0;
    var current = request;
    while (true) {
      try {
        return await _inner.send(current).timeout(deadline);
      } on TimeoutException {
        if (!canRetry || attempt >= getRetries) {
          throw ApiException(networkErrorMessage);
        }
      } on http.ClientException {
        if (!canRetry || attempt >= getRetries) {
          throw ApiException(networkErrorMessage);
        }
      }
      attempt++;
      await Future<void>.delayed(retryDelay);
      // A request can only be sent once, so retries send a copy.
      current = _copyGet(request);
    }
  }

  http.Request _copyGet(http.Request original) {
    return http.Request(original.method, original.url)
      ..headers.addAll(original.headers)
      ..followRedirects = original.followRedirects
      ..maxRedirects = original.maxRedirects
      ..persistentConnection = original.persistentConnection;
  }

  @override
  void close() => _inner.close();
}
