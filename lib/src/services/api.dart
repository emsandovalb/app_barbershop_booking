import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

/// Removes only whitespace and invisible separators around an address. It
/// deliberately does not alter the address itself: malformed email remains a
/// validation error rather than being silently rewritten.
String normalizeEmailInput(String value) => value
    .replaceAll(RegExp(r'^[\s\u200B\u200C\u200D\uFEFF]+'), '')
    .replaceAll(RegExp(r'[\s\u200B\u200C\u200D\uFEFF]+$'), '');

class ApiClient {
  final String baseUrl;
  final String resourceEndpoint;
  final String reservationEndpoint;
  final String myResourcesEndpoint;
  final String? businessSlug;
  String? _token;

  ApiClient({
    required String baseUrl,
    String resourceEndpointValue = 'resources',
    String reservationEndpointValue = 'reservations',
    String myResourcesEndpointValue = 'my/resources',
    String? businessSlug,
  }) : baseUrl = _cleanBase(baseUrl),
       resourceEndpoint = resourceEndpointValue,
       reservationEndpoint = reservationEndpointValue,
       myResourcesEndpoint = myResourcesEndpointValue,
       businessSlug = _cleanBusinessSlug(businessSlug);

  set token(String? t) => _token = t;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    if (businessSlug != null) 'X-Business-Slug': businessSlug!,
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _apiUri(String path, {Map<String, String?>? queryParameters}) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$baseUrl/$cleaned');
    final filtered = <String, String>{};
    if (queryParameters != null) {
      for (final entry in queryParameters.entries) {
        final value = entry.value;
        if (value != null && value.isNotEmpty) {
          filtered[entry.key] = value;
        }
      }
    }
    return filtered.isEmpty ? uri : uri.replace(queryParameters: filtered);
  }

  Map<String, dynamic> _normalizeResource(Map<String, dynamic> input) {
    final data = Map<String, dynamic>.from(input);
    final court = data['court'];
    final resource = data['resource'];
    if (resource is Map) {
      data['resource'] = Map<String, dynamic>.from(resource);
    } else if (court is Map) {
      data['resource'] = Map<String, dynamic>.from(court);
    }
    if (court is Map) {
      data['court'] = Map<String, dynamic>.from(court);
    } else if (resource is Map) {
      data['court'] = Map<String, dynamic>.from(resource);
    }
    if (data['resource_id'] == null && data['court_id'] != null) {
      data['resource_id'] = data['court_id'];
    }
    if (data['court_id'] == null && data['resource_id'] != null) {
      data['court_id'] = data['resource_id'];
    }
    return data;
  }

  Map<String, dynamic> _normalizeReservation(Map<String, dynamic> input) {
    final data = Map<String, dynamic>.from(input);
    final booking = data['booking'];
    final reservation = data['reservation'];
    if (reservation is Map) {
      data['reservation'] = Map<String, dynamic>.from(reservation);
    } else if (booking is Map) {
      data['reservation'] = Map<String, dynamic>.from(booking);
    }
    if (booking is Map) {
      data['booking'] = Map<String, dynamic>.from(booking);
    } else if (reservation is Map) {
      data['booking'] = Map<String, dynamic>.from(reservation);
    }
    if (data['reservation_id'] == null && data['booking_id'] != null) {
      data['reservation_id'] = data['booking_id'];
    }
    if (data['booking_id'] == null && data['reservation_id'] != null) {
      data['booking_id'] = data['reservation_id'];
    }
    if (data['resource_id'] == null && data['court_id'] != null) {
      data['resource_id'] = data['court_id'];
    }
    if (data['court_id'] == null && data['resource_id'] != null) {
      data['court_id'] = data['resource_id'];
    }
    return data;
  }

  Map<String, dynamic> _normalizeResponse(
    Map<String, dynamic> json, {
    bool reservation = false,
  }) {
    final data = Map<String, dynamic>.from(json);
    final items = data['data'];
    if (items is List) {
      data['data'] = items
          .map((item) {
            if (item is Map<String, dynamic>) {
              return reservation
                  ? _normalizeReservation(item)
                  : _normalizeResource(item);
            }
            if (item is Map) {
              return reservation
                  ? _normalizeReservation(Map<String, dynamic>.from(item))
                  : _normalizeResource(Map<String, dynamic>.from(item));
            }
            return item;
          })
          .toList(growable: false);
    }
    return reservation ? _normalizeReservation(data) : _normalizeResource(data);
  }

  Future<Map<String, dynamic>> _resourcePayload(
    Map<String, dynamic> data,
  ) async {
    final payload = Map<String, dynamic>.from(data);
    if (payload['court_id'] == null && payload['resource_id'] != null) {
      payload['court_id'] = payload['resource_id'];
    }
    if (payload['resource_id'] == null && payload['court_id'] != null) {
      payload['resource_id'] = payload['court_id'];
    }
    if (payload['price_per_hour'] == null && payload['price'] != null) {
      payload['price_per_hour'] = payload['price'];
    }
    if (payload['duration_minutes'] == null &&
        payload['durationMinutes'] != null) {
      payload['duration_minutes'] = payload['durationMinutes'];
    }
    if (payload['duration_hours'] == null && payload['duration'] != null) {
      payload['duration_hours'] = payload['duration'];
    }
    if (payload['duration_hours'] == null) {
      final minutes = _intValue(
        payload['duration_minutes'] ?? payload['durationMinutes'],
      );
      if (minutes != null && minutes > 0) {
        payload['duration_hours'] = (minutes / 60).ceil().clamp(1, 9999);
      }
    }
    if (payload['facilities'] == null && payload['amenities'] != null) {
      payload['facilities'] = payload['amenities'];
    }
    if (payload['address'] == null ||
        payload['address'].toString().trim().isEmpty) {
      final fallbackAddress = payload['name']?.toString().trim();
      if (fallbackAddress != null && fallbackAddress.isNotEmpty) {
        payload['address'] = fallbackAddress;
      } else if (payload['category']?.toString().trim().isNotEmpty == true) {
        payload['address'] = payload['category'];
      } else {
        payload['address'] = 'Business location';
      }
    }

    final images = <dynamic>[];
    final rawImages = payload.remove('images');
    if (rawImages is List) {
      images.addAll(rawImages);
    } else if (rawImages is String && rawImages.trim().isNotEmpty) {
      images.add(rawImages);
    }
    for (final key in const [
      'image_url',
      'image_path',
      'service_image',
      'image',
    ]) {
      final value = payload.remove(key);
      if (value is String && value.trim().isNotEmpty) {
        images.add(value);
      }
    }
    if (images.isNotEmpty) {
      payload['images'] = await _prepareResourceImages(images);
    }
    return payload;
  }

  Map<String, dynamic> _reservationPayload(Map<String, dynamic> data) {
    final payload = Map<String, dynamic>.from(data);
    if (payload['court_id'] == null && payload['resource_id'] != null) {
      payload['court_id'] = payload['resource_id'];
    }
    if (payload['resource_id'] == null && payload['court_id'] != null) {
      payload['resource_id'] = payload['court_id'];
    }
    if (payload['duration_hours'] == null && payload['duration'] != null) {
      payload['duration_hours'] = payload['duration'];
    }
    if (payload['time_slot'] == null && payload['slot'] != null) {
      payload['time_slot'] = payload['slot'];
    }
    return payload;
  }

  Future<Map<String, dynamic>> _getJson(
    Uri uri, {
    bool reservation = false,
  }) async {
    final res = await http.get(uri, headers: _headers);
    _ensureOk(res);
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    return _normalizeResponse(decoded, reservation: reservation);
  }

  Future<Map<String, dynamic>> _postJson(
    Uri uri,
    Map<String, dynamic> body, {
    bool expectCreated = false,
    bool reservation = false,
  }) async {
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.post(uri, headers: headers, body: json.encode(body));
    _ensureOk(res, expectCreated: expectCreated);
    return _normalizeResponse(
      json.decode(res.body) as Map<String, dynamic>,
      reservation: reservation,
    );
  }

  Future<Map<String, dynamic>> _putJson(
    Uri uri,
    Map<String, dynamic> body, {
    bool reservation = false,
  }) async {
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.put(uri, headers: headers, body: json.encode(body));
    _ensureOk(res);
    return _normalizeResponse(
      json.decode(res.body) as Map<String, dynamic>,
      reservation: reservation,
    );
  }

  Future<Map<String, dynamic>> _patchJson(
    Uri uri,
    Map<String, dynamic> body, {
    bool reservation = false,
  }) async {
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.patch(
      uri,
      headers: headers,
      body: json.encode(body),
    );
    _ensureOk(res);
    return _normalizeResponse(
      json.decode(res.body) as Map<String, dynamic>,
      reservation: reservation,
    );
  }

  Future<Map<String, dynamic>> _deleteJson(
    Uri uri, {
    bool reservation = false,
  }) async {
    final res = await http.delete(uri, headers: _headers);
    _ensureOk(res);
    return _normalizeResponse(
      json.decode(res.body) as Map<String, dynamic>,
      reservation: reservation,
    );
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: {'email': email, 'password': password},
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final normalizedEmail = normalizeEmailInput(email);
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: {
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
      },
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getAppConfig() async {
    return _getJson(_apiUri('app-config'));
  }

  Future<void> logout() async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/logout'),
      headers: _headers,
    );
    // Accept 200 OK, ignore others silently when token is already invalid
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // no-op
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? avatarPath,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/profile');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    if (firstName != null) req.fields['first_name'] = firstName;
    if (lastName != null) req.fields['last_name'] = lastName;
    if (name != null) req.fields['name'] = name;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      final avatarFile = await _optimizeImageUpload(
        avatarPath,
        fieldName: 'avatar',
      );
      if (avatarFile != null) {
        req.files.add(avatarFile);
      }
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getResources({
    String? q,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? category,
    int? durationHours,
    int page = 1,
    int? perPage,
  }) async {
    final uri = _apiUri(
      resourceEndpoint,
      queryParameters: {
        if (q != null && q.isNotEmpty) 'q': q,
        if (minPrice != null) 'min_price': '$minPrice',
        if (maxPrice != null) 'max_price': '$maxPrice',
        if (sort != null) 'sort': sort,
        if (category != null && category.isNotEmpty) 'category': category,
        if (durationHours != null) 'duration': '$durationHours',
        if (page > 1) 'page': '$page',
        if (perPage != null) 'per_page': '$perPage',
      },
    );
    return _getJson(uri);
  }

  Future<Map<String, dynamic>> getResource(int id) async {
    return _getJson(_apiUri('$resourceEndpoint/$id'));
  }

  Future<Map<String, dynamic>> getResourceAvailability({
    required int id,
    required int staffId,
    required String date,
  }) async {
    return _getJson(
      _apiUri(
        '$resourceEndpoint/$id/availability',
        queryParameters: {'date': date, 'staff_id': '$staffId'},
      ),
    );
  }

  Future<Map<String, dynamic>> getStaff({int page = 1, int? perPage}) async {
    return _getJson(
      _apiUri(
        'staff',
        queryParameters: {
          if (page > 1) 'page': '$page',
          if (perPage != null) 'per_page': '$perPage',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getStaffById(int id) async {
    return _getJson(_apiUri('staff/$id'));
  }

  Future<Map<String, dynamic>> getStaffRoles() async {
    return _getJson(_apiUri('staff/roles'));
  }

  Future<Map<String, dynamic>> createStaff(Map<String, dynamic> data) async {
    return _postJson(_apiUri('staff'), data, expectCreated: true);
  }

  Future<Map<String, dynamic>> updateStaff(
    int id,
    Map<String, dynamic> data,
  ) async {
    return _patchJson(_apiUri('staff/$id'), data);
  }

  Future<Map<String, dynamic>> deactivateStaff(int id) async {
    return _patchJson(_apiUri('staff/$id/deactivate'), const {});
  }

  Future<Map<String, dynamic>> assignStaffToResource(
    int staffId,
    int resourceId, {
    bool? isPrimary,
  }) async {
    return _postJson(_apiUri('staff/$staffId/services'), {
      'resource_id': resourceId,
      if (isPrimary != null) 'is_primary': isPrimary,
    });
  }

  Future<Map<String, dynamic>> removeStaffFromResource(
    int staffId,
    int resourceId,
  ) async {
    return _deleteJson(_apiUri('staff/$staffId/services/$resourceId'));
  }

  Future<Map<String, dynamic>> getResourceStaff(int id) async {
    return _getJson(_apiUri('resources/$id/staff'));
  }

  Future<Map<String, dynamic>> getMyResources({
    int page = 1,
    int? perPage,
  }) async {
    return _getJson(
      _apiUri(
        myResourcesEndpoint,
        queryParameters: {
          if (page > 1) 'page': '$page',
          if (perPage != null) 'per_page': '$perPage',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> createResource(
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (imageBytes != null) {
      return _createResourceMultipart(
        data,
        imageBytes: imageBytes,
        imageName: imageName,
      );
    }
    final payload = await _resourcePayload(data);
    return _postJson(_apiUri(resourceEndpoint), payload, expectCreated: true);
  }

  Future<Map<String, dynamic>> updateResource(
    int id,
    Map<String, dynamic> data, {
    Uint8List? imageBytes,
    String? imageName,
  }) async {
    if (imageBytes != null) {
      return _updateResourceMultipart(
        id,
        data,
        imageBytes: imageBytes,
        imageName: imageName,
      );
    }
    final payload = await _resourcePayload(data);
    return _putJson(_apiUri('$resourceEndpoint/$id'), payload);
  }

  Future<Map<String, dynamic>> deleteResource(int id) async {
    return _deleteJson(_apiUri('$resourceEndpoint/$id'));
  }

  Future<Map<String, dynamic>> getReservations({
    String? status,
    int? page,
    int? perPage,
  }) async {
    return _getJson(
      _apiUri(
        reservationEndpoint,
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (page != null && page > 1) 'page': '$page',
          if (perPage != null) 'per_page': '$perPage',
        },
      ),
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> createReservation(
    Map<String, dynamic> data,
  ) async {
    final reservation = await _postJson(
      _apiUri(reservationEndpoint),
      _reservationPayload(data),
      expectCreated: true,
      reservation: true,
    );

    // A 201 without a server-generated primary key is not evidence that the
    // reservation was persisted.  Keep the success path closed until the
    // booking contract has supplied that identifier.
    final id =
        _positiveInt(reservation['id']) ??
        _positiveInt(reservation['reservation_id']) ??
        _positiveInt(reservation['booking_id']);
    if (id == null) {
      throw ApiException(
        'The reservation response did not include a valid persisted ID.',
      );
    }
    return reservation;
  }

  Future<Map<String, dynamic>> getReservation(int id) async {
    return _getJson(_apiUri('$reservationEndpoint/$id'), reservation: true);
  }

  Future<Map<String, dynamic>> cancelReservation(int id) async {
    return _postJson(
      _apiUri('$reservationEndpoint/$id/cancel'),
      const {},
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> confirmReservation(int id) async {
    return _postJson(
      _apiUri('$reservationEndpoint/$id/confirm'),
      const {},
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> rejectReservation(int id) async {
    return _postJson(
      _apiUri('$reservationEndpoint/$id/reject'),
      const {},
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> completeReservation(int id) async {
    return _postJson(
      _apiUri('$reservationEndpoint/$id/complete'),
      const {},
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> markReservationPaid(int id) async {
    return _patchJson(
      _apiUri('$reservationEndpoint/$id/payment-status'),
      const {},
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> rebookReservation(
    int id,
    Map<String, dynamic> data,
  ) async {
    return _postJson(
      _apiUri('$reservationEndpoint/$id/rebook'),
      _reservationPayload(data),
      expectCreated: true,
      reservation: true,
    );
  }

  Future<Map<String, dynamic>> _createResourceMultipart(
    Map<String, dynamic> data, {
    required Uint8List imageBytes,
    String? imageName,
  }) async {
    final req = http.MultipartRequest('POST', _apiUri(resourceEndpoint));
    req.headers.addAll(_headers);
    final payload = await _resourcePayload(data);
    payload.remove('images');
    _appendFields(req.fields, payload);
    final imageFile = await _optimizeImageBytes(
      imageBytes,
      fieldName: 'image',
      filename: imageName ?? 'service.jpg',
    );
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _updateResourceMultipart(
    int id,
    Map<String, dynamic> data, {
    required Uint8List imageBytes,
    String? imageName,
  }) async {
    final req = http.MultipartRequest('POST', _apiUri('$resourceEndpoint/$id'));
    req.headers.addAll(_headers);
    req.fields['_method'] = 'PUT';
    final payload = await _resourcePayload(data);
    payload.remove('images');
    _appendFields(req.fields, payload);
    final imageFile = await _optimizeImageBytes(
      imageBytes,
      fieldName: 'image',
      filename: imageName ?? 'service.jpg',
    );
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }


  Future<Map<String, dynamic>> getReservationsForDay(String day) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/reservations?day=$day'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/password/forgot'),
      headers: _headers,
      body: {'email': email},
    );
    _ensureOk(res);
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/password/reset'),
      headers: _headers,
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    _ensureOk(res);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/password/change'),
      headers: _headers,
      body: {'current_password': currentPassword, 'new_password': newPassword},
    );
    _ensureOk(res);
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  static String? _cleanBusinessSlug(String? slug) {
    final trimmed = slug?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  void _ensureOk(http.Response res, {bool expectCreated = false}) {
    final ok = expectCreated
        ? res.statusCode == 201
        : (res.statusCode >= 200 && res.statusCode < 300);
    if (!ok) {
      Map<String, List<String>> fieldErrors = const {};
      var message = 'HTTP ${res.statusCode}';
      try {
        final decoded = json.decode(res.body);
        if (decoded is Map) {
          final rawMessage = decoded['message']?.toString().trim();
          if (rawMessage != null && rawMessage.isNotEmpty) {
            message = rawMessage;
          }
          final rawErrors = decoded['errors'];
          if (rawErrors is Map) {
            fieldErrors = rawErrors.map((key, value) {
              final messages = value is List
                  ? value.map((entry) => entry.toString()).toList()
                  : [value.toString()];
              return MapEntry(key.toString(), messages);
            });
          }
        }
      } catch (_) {
        // Preserve the status-only error for non-JSON responses.
      }
      throw ApiException(
        message,
        statusCode: res.statusCode,
        errors: fieldErrors,
      );
    }
  }

  int? _positiveInt(dynamic value) {
    final parsed = value is int
        ? value
        : value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    return parsed != null && parsed > 0 ? parsed : null;
  }

  void _appendFields(Map<String, String> fields, Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final value = entry.value;
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      fields[entry.key] = value.toString();
    }
  }

  Future<http.MultipartFile?> _optimizeImageUpload(
    String path, {
    required String fieldName,
  }) async {
    try {
      final data = await _readEncodedImageBytes(path);
      if (data == null || data.isEmpty) return null;
      final decoded = img.decodeImage(data);
      if (decoded == null) return null;
      const maxSide = 600;
      img.Image result = decoded;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        final longest = decoded.width > decoded.height
            ? decoded.width
            : decoded.height;
        final scale = longest / maxSide;
        final targetWidth = (decoded.width / scale).round();
        final targetHeight = (decoded.height / scale).round();
        result = img.copyResize(
          decoded,
          width: targetWidth,
          height: targetHeight,
        );
      }
      final encoded = img.encodeJpg(result, quality: 80);
      return http.MultipartFile.fromBytes(
        fieldName,
        encoded,
        filename: '$fieldName.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  Future<http.MultipartFile?> _optimizeImageBytes(
    Uint8List bytes, {
    required String fieldName,
    String? filename,
  }) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;
      const maxSide = 1200;
      img.Image result = decoded;
      if (decoded.width > maxSide || decoded.height > maxSide) {
        final longest = decoded.width > decoded.height
            ? decoded.width
            : decoded.height;
        final scale = longest / maxSide;
        final targetWidth = (decoded.width / scale).round();
        final targetHeight = (decoded.height / scale).round();
        result = img.copyResize(
          decoded,
          width: targetWidth,
          height: targetHeight,
        );
      }
      final encoded = img.encodeJpg(result, quality: 82);
      return http.MultipartFile.fromBytes(
        fieldName,
        encoded,
        filename: filename ?? '$fieldName.jpg',
      );
    } catch (_) {
      return null;
    }
  }

  int? _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Future<List<String>> _prepareResourceImages(List<dynamic> images) async {
    final prepared = <String>[];
    for (final value in images) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) continue;
      final image = await _prepareResourceImage(raw);
      if (image != null && image.isNotEmpty) {
        prepared.add(image);
      }
    }
    return prepared;
  }

  Future<String?> _prepareResourceImage(String value) async {
    if (value.startsWith('data:image')) {
      return value;
    }
    if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value) && value.length > 120) {
      return value;
    }
    if (value.startsWith('/storage/')) {
      return value;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      final response = await http.get(
        Uri.parse(value),
        headers: const {'Accept': 'image/*'},
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final mime = _guessImageMime(
        value,
        contentType: response.headers['content-type'],
      );
      return 'data:$mime;base64,${base64Encode(response.bodyBytes)}';
    }
    if (value.startsWith('asset:') || value.startsWith('assets/')) {
      final key = value.startsWith('asset:') ? value.substring(6) : value;
      final data = await rootBundle.load(key);
      final mime = _guessImageMime(value);
      return 'data:$mime;base64,${base64Encode(data.buffer.asUint8List())}';
    }
    return null;
  }

  Future<Uint8List?> _readEncodedImageBytes(String value) async {
    if (value.startsWith('data:image')) {
      final raw = value.split(',').last;
      return base64Decode(raw);
    }
    if (RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value) && value.length > 120) {
      return base64Decode(value);
    }
    if (value.startsWith('asset:') || value.startsWith('assets/')) {
      final key = value.startsWith('asset:') ? value.substring(6) : value;
      final data = await rootBundle.load(key);
      return data.buffer.asUint8List();
    }
    return null;
  }

  String _guessImageMime(String source, {String? contentType}) {
    final header = (contentType ?? '').toLowerCase();
    if (header.contains('png')) return 'image/png';
    if (header.contains('webp')) return 'image/webp';
    if (header.contains('gif')) return 'image/gif';
    if (header.contains('jpeg') || header.contains('jpg')) return 'image/jpeg';
    final lower = source.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String resolveAssetUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    if (normalized.startsWith('/storage/')) {
      return Uri.parse(
        '$baseUrl/media',
      ).replace(queryParameters: {'path': normalized}).toString();
    }
    final baseUri = Uri.parse(baseUrl);
    final origin = baseUri.replace(path: '', query: null, fragment: null);
    return origin.resolve(normalized).toString();
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>> errors;

  ApiException(this.message, {this.statusCode, this.errors = const {}});

  String? firstErrorFor(String field) => errors[field]?.first;

  @override
  String toString() => message;
}
