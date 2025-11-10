import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  String? _token;

  ApiClient({required String baseUrl}) : baseUrl = _cleanBase(baseUrl);

  set token(String? t) => _token = t;

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: {'email': email, 'password': password},
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: {'name': name, 'email': email, 'password': password},
    );
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final res = await http.post(Uri.parse('$baseUrl/auth/logout'), headers: _headers);
    // Accept 200 OK, ignore others silently when token is already invalid
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // no-op
    }
  }

  Future<Map<String, dynamic>> updateProfile({String? firstName, String? lastName, String? name, String? email, String? avatarPath}) async {
    final uri = Uri.parse('$baseUrl/auth/profile');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(_headers);
    if (firstName != null) req.fields['first_name'] = firstName;
    if (lastName != null) req.fields['last_name'] = lastName;
    if (name != null) req.fields['name'] = name;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('avatar', avatarPath));
    }
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCourts({String? q, double? minPrice, double? maxPrice, String? sort, String? category, int? durationHours}) async {
    final uri = Uri.parse('$baseUrl/courts').replace(queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (minPrice != null) 'min_price': '$minPrice',
      if (maxPrice != null) 'max_price': '$maxPrice',
      if (sort != null) 'sort': sort,
      if (category != null && category.isNotEmpty) 'category': category,
      if (durationHours != null) 'duration': '$durationHours',
    });
    final res = await http.get(uri, headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getEvents() async {
    final res = await http.get(Uri.parse('$baseUrl/events'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBookings(String status) async {
    final res = await http.get(Uri.parse('$baseUrl/bookings?status=$status'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBooking({required int courtId, required String date, required String timeSlot}) async {
    final res = await http.post(Uri.parse('$baseUrl/bookings'), headers: _headers, body: {
      'court_id': '$courtId',
      'date': date,
      'time_slot': timeSlot,
    });
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createBookingWithDuration({
    required int courtId,
    required String date,
    required String timeSlot,
    required int durationHours,
  }) async {
    final res = await http.post(Uri.parse('$baseUrl/bookings'), headers: _headers, body: {
      'court_id': '$courtId',
      'date': date,
      'time_slot': timeSlot,
      'duration_hours': '$durationHours',
    });
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getCourtAvailability({required int courtId, required String day}) async {
    final uri = Uri.parse('$baseUrl/courts/$courtId/availability').replace(queryParameters: {'date': day});
    final res = await http.get(uri, headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> rebook(int bookingId, {required String date, required String timeSlot}) async {
    final res = await http.post(Uri.parse('$baseUrl/bookings/$bookingId/rebook'), headers: _headers, body: {
      'date': date,
      'time_slot': timeSlot,
    });
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    final res = await http.post(Uri.parse('$baseUrl/bookings/$bookingId/cancel'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<void> forgotPassword(String email) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/password/forgot'), headers: _headers, body: {
      'email': email,
    });
    _ensureOk(res);
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final res = await http.post(Uri.parse('$baseUrl/auth/password/change'), headers: _headers, body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
    _ensureOk(res);
  }

  // Grounds (admin)
  Future<Map<String, dynamic>> getMyGrounds() async {
    final res = await http.get(Uri.parse('$baseUrl/my/grounds'), headers: _headers);
    _ensureOk(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGround(Map<String, dynamic> data) async {
    // Send JSON because payload may contain arrays (e.g., images)
    final headers = {
      ..._headers,
      'Content-Type': 'application/json',
    };
    final res = await http.post(
      Uri.parse('$baseUrl/courts'),
      headers: headers,
      body: json.encode(data),
    );
    _ensureOk(res, expectCreated: true);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static String _cleanBase(String url) {
    var result = url.trim();
    while (result.endsWith('/')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  void _ensureOk(http.Response res, {bool expectCreated = false}) {
    final ok = expectCreated ? res.statusCode == 201 : (res.statusCode >= 200 && res.statusCode < 300);
    if (!ok) {
      throw ApiException('HTTP ${res.statusCode}: ${res.body}');
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}





