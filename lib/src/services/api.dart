import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

class ApiClient {
  final String baseUrl;
  final String resourceEndpoint;
  final String reservationEndpoint;
  final String myResourcesEndpoint;
  String? _token;

  ApiClient({
    required String baseUrl,
    String resourceEndpointValue = 'resources',
    String reservationEndpointValue = 'reservations',
    String myResourcesEndpointValue = 'my/resources',
  }) : baseUrl = _cleanBase(baseUrl),
       resourceEndpoint = resourceEndpointValue,
       reservationEndpoint = reservationEndpointValue,
       myResourcesEndpoint = myResourcesEndpointValue;

  set token(String? t) => _token = t;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
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
        payload['address'] = 'Barbería Tres Amigos';
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
    return _normalizeResponse(
      json.decode(res.body) as Map<String, dynamic>,
      reservation: reservation,
    );
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
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: {'name': name, 'email': email, 'password': password},
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
    required String date,
  }) async {
    return _getJson(
      _apiUri(
        '$resourceEndpoint/$id/availability',
        queryParameters: {'date': date},
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

  Future<Map<String, dynamic>> createResource(Map<String, dynamic> data) async {
    final payload = await _resourcePayload(data);
    return _postJson(_apiUri(resourceEndpoint), payload, expectCreated: true);
  }

  Future<Map<String, dynamic>> updateResource(
    int id,
    Map<String, dynamic> data,
  ) async {
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
    return _postJson(
      _apiUri(reservationEndpoint),
      _reservationPayload(data),
      expectCreated: true,
      reservation: true,
    );
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

  Future<Map<String, dynamic>> getCourts({
    String? q,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? category,
    int? durationHours,
    int page = 1,
    int? perPage,
  }) async {
    return getResources(
      q: q,
      minPrice: minPrice,
      maxPrice: maxPrice,
      sort: sort,
      category: category,
      durationHours: durationHours,
      page: page,
      perPage: perPage,
    );
  }

  Future<Map<String, dynamic>> getEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/events'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTournaments({
    int page = 1,
    int? perPage,
  }) async {
    final uri = Uri.parse('$baseUrl/tournaments').replace(
      queryParameters: {
        if (page > 1) 'page': '$page',
        if (perPage != null) 'per_page': '$perPage',
      },
    );
    final res = await http.get(uri, headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTournament(int id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tournaments/$id'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTournamentTeams(int tournamentId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tournaments/$tournamentId/teams'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getMyTeams() async {
    final res = await http.get(
      Uri.parse('$baseUrl/my/teams'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTournament(
    Map<String, dynamic> data, {
    String? coverImagePath,
  }) async {
    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      return _createTournamentMultipart(data, coverImagePath: coverImagePath);
    }
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments'),
      headers: headers,
      body: json.encode(data),
    );
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTournament(
    int id,
    Map<String, dynamic> data, {
    String? coverImagePath,
  }) async {
    if (coverImagePath != null && coverImagePath.isNotEmpty) {
      return _updateTournamentMultipart(
        id,
        data,
        coverImagePath: coverImagePath,
      );
    }
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.put(
      Uri.parse('$baseUrl/tournaments/$id'),
      headers: headers,
      body: json.encode(data),
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> enrollTournamentTeam({
    required int tournamentId,
    required int teamId,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tournaments/$tournamentId/teams'),
      headers: _headers,
      body: {'team_id': '$teamId'},
    );
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createTeam(
    Map<String, dynamic> data, {
    String? logoPath,
  }) async {
    if (logoPath != null && logoPath.isNotEmpty) {
      return _createTeamMultipart(data, logoPath: logoPath);
    }
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.post(
      Uri.parse('$baseUrl/my/teams'),
      headers: headers,
      body: json.encode(data),
    );
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateTeam(
    int id,
    Map<String, dynamic> data, {
    String? logoPath,
  }) async {
    if (logoPath != null && logoPath.isNotEmpty) {
      return _updateTeamMultipart(id, data, logoPath: logoPath);
    }
    final headers = {..._headers, 'Content-Type': 'application/json'};
    final res = await http.put(
      Uri.parse('$baseUrl/my/teams/$id'),
      headers: headers,
      body: json.encode(data),
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _createTournamentMultipart(
    Map<String, dynamic> data, {
    required String coverImagePath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tournaments'),
    );
    req.headers.addAll(_headers);
    _appendFields(req.fields, data);
    final imageFile = await _optimizeImageUpload(
      coverImagePath,
      fieldName: 'cover_image',
    );
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _updateTournamentMultipart(
    int id,
    Map<String, dynamic> data, {
    required String coverImagePath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/tournaments/$id'),
    );
    req.headers.addAll(_headers);
    req.fields['_method'] = 'PUT';
    _appendFields(req.fields, data);
    final imageFile = await _optimizeImageUpload(
      coverImagePath,
      fieldName: 'cover_image',
    );
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _createTeamMultipart(
    Map<String, dynamic> data, {
    required String logoPath,
  }) async {
    final req = http.MultipartRequest('POST', Uri.parse('$baseUrl/my/teams'));
    req.headers.addAll(_headers);
    _appendFields(req.fields, data);
    final imageFile = await _optimizeImageUpload(logoPath, fieldName: 'logo');
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _updateTeamMultipart(
    int id,
    Map<String, dynamic> data, {
    required String logoPath,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/my/teams/$id'),
    );
    req.headers.addAll(_headers);
    req.fields['_method'] = 'PUT';
    _appendFields(req.fields, data);
    final imageFile = await _optimizeImageUpload(logoPath, fieldName: 'logo');
    if (imageFile != null) {
      req.files.add(imageFile);
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> closeTournament(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/tournaments/$id'),
      headers: _headers,
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBookings(String status) async {
    return getReservations(status: status);
  }

  Future<Map<String, dynamic>> createBooking({
    required int courtId,
    required String date,
    required String timeSlot,
    int? staffId,
  }) async {
    return createReservation({
      'court_id': courtId,
      'date': date,
      'time_slot': timeSlot,
      if (staffId != null) 'staff_id': staffId,
    });
  }

  Future<Map<String, dynamic>> createBookingWithDuration({
    required int courtId,
    required String date,
    required String timeSlot,
    required int durationHours,
    int? staffId,
  }) async {
    return createReservation({
      'court_id': courtId,
      'date': date,
      'time_slot': timeSlot,
      'duration_hours': durationHours,
      if (staffId != null) 'staff_id': staffId,
    });
  }

  Future<Map<String, dynamic>> getCourtAvailability({
    required int courtId,
    required String day,
  }) async {
    return getResourceAvailability(id: courtId, date: day);
  }

  Future<Map<String, dynamic>> rebook(
    int bookingId, {
    required String date,
    required String timeSlot,
  }) async {
    return rebookReservation(bookingId, {'date': date, 'time_slot': timeSlot});
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    return cancelReservation(bookingId);
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

  // Grounds (admin)
  Future<Map<String, dynamic>> getMyGrounds() async {
    return getMyResources();
  }

  Future<Map<String, dynamic>> createGround(Map<String, dynamic> data) async {
    return createResource(data);
  }

  Future<Map<String, dynamic>> updateGround(
    int id,
    Map<String, dynamic> data,
  ) async {
    return updateResource(id, data);
  }

  Future<Map<String, dynamic>> deactivateGround(int id) async {
    return deleteResource(id);
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  void _ensureOk(http.Response res, {bool expectCreated = false}) {
    final ok = expectCreated
        ? res.statusCode == 201
        : (res.statusCode >= 200 && res.statusCode < 300);
    if (!ok) {
      throw ApiException('HTTP ${res.statusCode}: ${res.body}');
    }
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
      final file = File(path);
      if (!await file.exists()) return null;
      final data = await file.readAsBytes();
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
      final filename = '${p.basenameWithoutExtension(path)}.jpg';
      return http.MultipartFile.fromBytes(
        fieldName,
        encoded,
        filename: filename,
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
    final file = File(value);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final mime = _guessImageMime(value);
      return 'data:$mime;base64,${base64Encode(bytes)}';
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
    final baseUri = Uri.parse(baseUrl);
    final origin = baseUri.replace(path: '', query: null, fragment: null);
    final normalized = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return origin.resolve(normalized).toString();
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
