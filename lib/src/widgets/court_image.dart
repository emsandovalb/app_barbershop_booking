import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class CourtImage extends StatelessWidget {
  final dynamic images; // can be List or String or null
  final double? height; // optional to allow fill by parent
  final double? width;
  final BorderRadius? radius;
  const CourtImage({super.key, this.images, this.height, this.width, this.radius});

  @override
  Widget build(BuildContext context) {
    final raw = _firstPath(images);
    final resolved = raw == null ? null : _resolveSource(context, raw);
    final child = resolved == null ? const _Placeholder() : _buildImage(resolved);
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(16),
      child: Container(
        height: height,
        width: width,
        color: Colors.black26,
        child: child,
      ),
    );
  }

  Widget _buildImage(String src) {
    if (src.startsWith('asset:')) {
      return Image.asset(src.substring(6), fit: BoxFit.cover);
    }
    if (_looksLikeBase64(src)) {
      try {
        final data = src.contains(',') ? src.split(',').last : src;
        return Image.memory(base64Decode(data), fit: BoxFit.cover);
      } catch (_) {
        return const _Placeholder();
      }
    }
    if (src.startsWith('http')) {
      return Image.network(
        src,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _Placeholder(),
      );
    }
    final file = File(src);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return const _Placeholder();
  }

  String? _firstPath(dynamic images) {
    if (images == null) return null;
    if (images is List && images.isNotEmpty) {
      for (final item in images) {
        final value = _extractString(item);
        if (value != null) return value;
      }
    }
    if (images is String && images.trim().isNotEmpty) {
      final s = images.trim();
      if (s.startsWith('[')) {
        try {
          final decoded = (const JsonDecoder()).convert(s);
          return _firstPath(decoded);
        } catch (_) {
          return s;
        }
      }
      return s;
    }
    return _extractString(images);
  }

  String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        final nested = _extractString(entry.value);
        if (nested != null) return nested;
      }
    }
    if (value is List) {
      for (final item in value) {
        final nested = _extractString(item);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  String? _resolveSource(BuildContext context, String src) {
    final trimmed = src.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('asset:')) return trimmed;
    if (trimmed.startsWith('assets/')) return 'asset:$trimmed';
    if (trimmed.startsWith('file://')) return trimmed.substring(7);
    if (trimmed.startsWith('http') || _looksLikeBase64(trimmed)) return trimmed;

    final file = File(trimmed);
    if (file.existsSync()) return trimmed;

    AuthProvider? auth;
    try {
      auth = context.read<AuthProvider>();
    } catch (_) {
      auth = null;
    }
    final base = auth?.api.baseUrl;
    if (base != null) {
      final uri = Uri.tryParse(base);
      if (uri != null) {
        final origin = _originFromUri(uri);
        if (origin != null) {
          final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
          return origin + path;
        }
      }
    }
    return trimmed;
  }

  bool _looksLikeBase64(String value) {
    return value.startsWith('data:image') || (value.length > 100 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(value));
  }

  String? _originFromUri(Uri uri) {
    if (!uri.hasScheme || uri.host.isEmpty) return null;
    final port = uri.hasPort ? ':${uri.port}' : '';
    return '${uri.scheme}://${uri.host}$port';
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_not_supported_outlined, color: Colors.white54, size: 36),
    );
  }
}
