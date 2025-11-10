import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class CourtImage extends StatelessWidget {
  final dynamic images; // can be List or String or null
  final double? height; // optional to allow fill by parent
  final double? width;
  final BorderRadius? radius;
  const CourtImage({super.key, this.images, this.height, this.width, this.radius});

  @override
  Widget build(BuildContext context) {
    final src = _firstPath(images);
    final child = src == null
        ? const Icon(Icons.image, color: Colors.white54, size: 40)
        : _buildImage(src);
    return ClipRRect(
      borderRadius: radius ?? BorderRadius.circular(16),
      child: Container(
        height: height,
        width: width,
        color: Colors.black26,
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.center,
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );
  }

  Widget _buildImage(String src) {
    if (src.startsWith('http')) {
      return Image.network(src, fit: BoxFit.cover);
    }
    return Image.file(File(src), fit: BoxFit.cover);
  }

  String? _firstPath(dynamic images) {
    if (images == null) return null;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      return first?.toString();
    }
    if (images is String && images.trim().isNotEmpty) {
      final s = images.trim();
      // Handle JSON-encoded array stored as a string
      if (s.startsWith('[')) {
        try {
          final decoded = List.from((const JsonDecoder()).convert(s));
          if (decoded.isNotEmpty) return decoded.first.toString();
        } catch (_) {}
      }
      return s;
    }
    return null;
  }
}
