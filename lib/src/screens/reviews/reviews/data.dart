part of '../reviews_page.dart';

enum ReviewFilter { all, fiveStars, premium, corte, barba }

extension on ReviewFilter {
  String get label {
    switch (this) {
      case ReviewFilter.all:
        return 'Todas';
      case ReviewFilter.fiveStars:
        return '5 estrellas';
      case ReviewFilter.premium:
        return 'Premium';
      case ReviewFilter.corte:
        return 'Corte';
      case ReviewFilter.barba:
        return 'Barba';
    }
  }
}

class ReviewEntry {
  final String customerName;
  final double rating;
  final String dateLabel;
  final String text;
  final String? serviceName;
  final String? barberName;
  final String? avatarUrl;
  final bool isPremium;

  const ReviewEntry({
    required this.customerName,
    required this.rating,
    required this.dateLabel,
    required this.text,
    this.serviceName,
    this.barberName,
    this.avatarUrl,
    this.isPremium = false,
  });

  factory ReviewEntry.fromMap(Map<String, dynamic> map) {
    return ReviewEntry(
      customerName: _text(map, ['customerName', 'name']),
      rating: _number(map, ['rating'], fallback: 5),
      dateLabel: _text(map, ['dateLabel', 'date']),
      text: _text(map, ['text', 'comment', 'review']),
      serviceName: _optionalText(map, ['serviceName', 'service']),
      barberName: _optionalText(map, ['barberName', 'barber']),
      avatarUrl: _optionalText(map, ['avatarUrl', 'avatar']),
      isPremium: _bool(map, ['isPremium', 'premium']),
    );
  }

  String get initials {
    final parts = customerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final letters = parts.map((part) => part.substring(0, 1)).take(2).join();
    return letters.isEmpty ? 'R' : letters.toUpperCase();
  }

  bool matches(ReviewFilter filter) {
    switch (filter) {
      case ReviewFilter.all:
        return true;
      case ReviewFilter.fiveStars:
        return rating >= 4.95;
      case ReviewFilter.premium:
        return isPremium;
      case ReviewFilter.corte:
        return _contains(serviceName, 'corte') ||
            _contains(serviceName, 'experiencia premium');
      case ReviewFilter.barba:
        return _contains(serviceName, 'barba');
    }
  }
}

const double _summaryRating = 4.9;

const Map<int, int> _ratingDistribution = {5: 98, 4: 18, 3: 7, 2: 3, 1: 2};

final ReviewEntry _featuredReview = ReviewEntry.fromMap(const {
  'customerName': 'Andrés Mora',
  'rating': 5.0,
  'dateLabel': '14 jun 2026',
  'text':
      'La experiencia premium vale totalmente la pena. El ambiente, la atención y el acabado se sienten de primer nivel.',
  'serviceName': 'Experiencia Premium Completa',
  'barberName': 'Diego Morales',
  'isPremium': true,
});

final List<ReviewEntry> _demoReviews = [
  ReviewEntry.fromMap(const {
    'customerName': 'Juan Carlos',
    'rating': 5.0,
    'dateLabel': '18 jun 2026',
    'text': 'Excelente atención y muy buen ambiente. El corte quedó perfecto.',
    'serviceName': 'Corte de cabello',
    'barberName': 'Carlos Ramirez',
    'isPremium': false,
  }),
  ReviewEntry.fromMap(const {
    'customerName': 'Andrés Mora',
    'rating': 5.0,
    'dateLabel': '14 jun 2026',
    'text': 'Muy recomendado. La experiencia premium vale totalmente la pena.',
    'serviceName': 'Experiencia Premium Completa',
    'barberName': 'Diego Morales',
    'isPremium': true,
  }),
  ReviewEntry.fromMap(const {
    'customerName': 'Felipe Solís',
    'rating': 4.9,
    'dateLabel': '11 jun 2026',
    'text': 'El perfilado de barba quedó limpio y profesional.',
    'serviceName': 'Recorte de barba',
    'barberName': 'Andres Vega',
    'isPremium': false,
  }),
  ReviewEntry.fromMap(const {
    'customerName': 'Daniel Rojas',
    'rating': 5.0,
    'dateLabel': '9 jun 2026',
    'text': 'Buen trato, puntualidad y excelente acabado.',
    'serviceName': 'Corte y Barba',
    'barberName': 'Luis Fernandez',
    'isPremium': false,
  }),
  ReviewEntry.fromMap(const {
    'customerName': 'Mauricio Vargas',
    'rating': 4.8,
    'dateLabel': '5 jun 2026',
    'text': 'Ambiente cómodo, buena música y atención de primera.',
    'serviceName': 'Corte a Tijera / Cabello Largo',
    'barberName': 'Carlos Ramirez',
    'isPremium': false,
  }),
];

bool _contains(String? value, String needle) {
  return value != null && value.toLowerCase().contains(needle.toLowerCase());
}

String _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

String? _optionalText(Map<String, dynamic> map, List<String> keys) {
  final text = _text(map, keys);
  return text.isEmpty ? null : text;
}

double _number(
  Map<String, dynamic> map,
  List<String> keys, {
  required double fallback,
}) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool _bool(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return false;
}
