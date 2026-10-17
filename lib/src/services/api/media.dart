part of '../api.dart';

/// Image optimization and multipart uploads for resource create/update.
extension _ApiMedia on ApiClient {
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
}
