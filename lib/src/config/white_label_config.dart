import 'package:flutter/material.dart';

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return null;
}

String _stringValue(dynamic value, String fallback) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

String? _nullableString(dynamic value, {String? fallback}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  return text;
}

int _intValue(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _doubleValue(dynamic value, double fallback) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _boolValue(dynamic value, bool fallback) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  if (text == 'true' || text == '1' || text == 'yes') return true;
  if (text == 'false' || text == '0' || text == 'no') return false;
  return fallback;
}

List<String> _stringListValue(dynamic value, List<String> fallback) {
  if (value is List) {
    final items = value
        .map((entry) => entry?.toString().trim() ?? '')
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
    if (items.isNotEmpty) return items;
  }
  return fallback;
}

Color _colorValue(dynamic value, Color fallback) {
  if (value is int) return Color(value);
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return fallback;
  var hex = text.replaceAll('#', '').replaceAll('0x', '');
  if (hex.length == 3) {
    hex = hex.split('').map((part) => '$part$part').join();
  } else if (hex.length == 4) {
    hex = hex.split('').map((part) => '$part$part').join();
  } else if (hex.length == 6) {
    hex = 'FF$hex';
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return fallback;
  return Color(parsed);
}

class BusinessIdentity {
  final String appName;
  final String? legalName;
  final String displayName;
  final String shortName;
  final String tagline;
  final String subtitle;
  final String locationShort;
  final String locationFull;
  final double rating;
  final int reviewCount;
  final int? foundedYear;

  const BusinessIdentity({
    required this.appName,
    this.legalName,
    required this.displayName,
    required this.shortName,
    required this.tagline,
    required this.subtitle,
    required this.locationShort,
    required this.locationFull,
    required this.rating,
    required this.reviewCount,
    this.foundedYear,
  });

  factory BusinessIdentity.fromJson(
    Map<String, dynamic>? json, {
    BusinessIdentity? fallback,
  }) {
    final base =
        fallback ??
        const BusinessIdentity(
          appName: '',
          displayName: '',
          shortName: '',
          tagline: '',
          subtitle: '',
          locationShort: '',
          locationFull: '',
          rating: 0,
          reviewCount: 0,
        );
    final data = json ?? const <String, dynamic>{};
    return BusinessIdentity(
      appName: _stringValue(data['app_name'], base.appName),
      legalName: _nullableString(data['legal_name'], fallback: base.legalName),
      displayName: _stringValue(data['display_name'], base.displayName),
      shortName: _stringValue(data['short_name'], base.shortName),
      tagline: _stringValue(data['tagline'], base.tagline),
      subtitle: _stringValue(data['subtitle'], base.subtitle),
      locationShort: _stringValue(data['location_short'], base.locationShort),
      locationFull: _stringValue(data['location_full'], base.locationFull),
      rating: _doubleValue(data['rating'], base.rating),
      reviewCount: _intValue(data['review_count'], base.reviewCount),
      foundedYear: data.containsKey('founded_year')
          ? _intValue(data['founded_year'], base.foundedYear ?? 0)
          : base.foundedYear,
    );
  }
}

class BrandAssets {
  final String logoTransparent;
  final String appIcon;
  final String heroBackground;
  final String servicePlaceholder;
  final String premiumServicePlaceholder;
  final String staffPlaceholder;
  final String profilePlaceholder;

  const BrandAssets({
    required this.logoTransparent,
    required this.appIcon,
    required this.heroBackground,
    required this.servicePlaceholder,
    required this.premiumServicePlaceholder,
    required this.staffPlaceholder,
    required this.profilePlaceholder,
  });

  factory BrandAssets.fromJson(
    Map<String, dynamic>? json, {
    BrandAssets? fallback,
  }) {
    final base =
        fallback ??
        const BrandAssets(
          logoTransparent: '',
          appIcon: '',
          heroBackground: '',
          servicePlaceholder: '',
          premiumServicePlaceholder: '',
          staffPlaceholder: '',
          profilePlaceholder: '',
        );
    final data = json ?? const <String, dynamic>{};
    return BrandAssets(
      logoTransparent: _stringValue(
        data['logo_transparent'],
        base.logoTransparent,
      ),
      appIcon: _stringValue(data['app_icon'], base.appIcon),
      heroBackground: _stringValue(
        data['hero_background'],
        base.heroBackground,
      ),
      servicePlaceholder: _stringValue(
        data['service_placeholder'],
        base.servicePlaceholder,
      ),
      premiumServicePlaceholder: _stringValue(
        data['premium_service_placeholder'],
        base.premiumServicePlaceholder,
      ),
      staffPlaceholder: _stringValue(
        data['staff_placeholder'],
        base.staffPlaceholder,
      ),
      profilePlaceholder: _stringValue(
        data['profile_placeholder'],
        base.profilePlaceholder,
      ),
    );
  }
}

class BrandColors {
  final Color primaryGold;
  final Color primaryGoldLight;
  final Color primaryGoldDark;
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const BrandColors({
    required this.primaryGold,
    required this.primaryGoldLight,
    required this.primaryGoldDark,
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  factory BrandColors.fromJson(
    Map<String, dynamic>? json, {
    BrandColors? fallback,
  }) {
    final base =
        fallback ??
        const BrandColors(
          primaryGold: Colors.white,
          primaryGoldLight: Colors.white,
          primaryGoldDark: Colors.white,
          background: Colors.black,
          surface: Colors.black,
          card: Colors.black,
          border: Colors.transparent,
          textPrimary: Colors.white,
          textSecondary: Colors.white,
        );
    final data = json ?? const <String, dynamic>{};
    return BrandColors(
      primaryGold: _colorValue(data['primary_gold'], base.primaryGold),
      primaryGoldLight: _colorValue(
        data['primary_gold_light'],
        base.primaryGoldLight,
      ),
      primaryGoldDark: _colorValue(
        data['primary_gold_dark'],
        base.primaryGoldDark,
      ),
      background: _colorValue(data['background'], base.background),
      surface: _colorValue(data['surface'], base.surface),
      card: _colorValue(data['card'], base.card),
      border: _colorValue(data['border'], base.border),
      textPrimary: _colorValue(data['text_primary'], base.textPrimary),
      textSecondary: _colorValue(data['text_secondary'], base.textSecondary),
    );
  }
}

class BusinessContact {
  final String phone;
  final String whatsapp;
  final String email;
  final String instagram;
  final String facebook;
  final String website;
  final String address;

  const BusinessContact({
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.instagram,
    required this.facebook,
    required this.website,
    required this.address,
  });

  factory BusinessContact.fromJson(
    Map<String, dynamic>? json, {
    BusinessContact? fallback,
  }) {
    final base =
        fallback ??
        const BusinessContact(
          phone: '',
          whatsapp: '',
          email: '',
          instagram: '',
          facebook: '',
          website: '',
          address: '',
        );
    final data = json ?? const <String, dynamic>{};
    return BusinessContact(
      phone: _stringValue(data['phone'], base.phone),
      whatsapp: _stringValue(data['whatsapp'], base.whatsapp),
      email: _stringValue(data['email'], base.email),
      instagram: _stringValue(data['instagram'], base.instagram),
      facebook: _stringValue(data['facebook'], base.facebook),
      website: _stringValue(data['website'], base.website),
      address: _stringValue(data['address'], base.address),
    );
  }
}

class BusinessHours {
  final String label;
  final String weeklySummary;
  final List<String> detailedHours;

  const BusinessHours({
    required this.label,
    required this.weeklySummary,
    required this.detailedHours,
  });

  factory BusinessHours.fromJson(
    Map<String, dynamic>? json, {
    BusinessHours? fallback,
  }) {
    final base =
        fallback ??
        const BusinessHours(
          label: '',
          weeklySummary: '',
          detailedHours: <String>[],
        );
    final data = json ?? const <String, dynamic>{};
    return BusinessHours(
      label: _stringValue(data['label'], base.label),
      weeklySummary: _stringValue(data['weekly_summary'], base.weeklySummary),
      detailedHours: _stringListValue(
        data['detailed_hours'],
        base.detailedHours,
      ),
    );
  }
}

class BusinessPolicies {
  final String cancellationPolicyText;
  final int cancellationWindowHours;

  const BusinessPolicies({
    required this.cancellationPolicyText,
    required this.cancellationWindowHours,
  });

  factory BusinessPolicies.fromJson(
    Map<String, dynamic>? json, {
    BusinessPolicies? fallback,
  }) {
    final base =
        fallback ??
        const BusinessPolicies(
          cancellationPolicyText: '',
          cancellationWindowHours: 0,
        );
    final data = json ?? const <String, dynamic>{};
    return BusinessPolicies(
      cancellationPolicyText: _stringValue(
        data['cancellation_policy_text'],
        base.cancellationPolicyText,
      ),
      cancellationWindowHours: _intValue(
        data['cancellation_window_hours'],
        base.cancellationWindowHours,
      ),
    );
  }
}

class Terminology {
  final String service;
  final String services;
  final String appointment;
  final String appointments;
  final String staff;
  final String staffPlural;
  final String staffDisplayName;
  final String manager;
  final String businessProfile;
  final String gallery;
  final String reviews;

  const Terminology({
    required this.service,
    required this.services,
    required this.appointment,
    required this.appointments,
    required this.staff,
    required this.staffPlural,
    required this.staffDisplayName,
    required this.manager,
    required this.businessProfile,
    required this.gallery,
    required this.reviews,
  });

  factory Terminology.fromJson(
    Map<String, dynamic>? json, {
    Terminology? fallback,
  }) {
    final base =
        fallback ??
        const Terminology(
          service: '',
          services: '',
          appointment: '',
          appointments: '',
          staff: '',
          staffPlural: '',
          staffDisplayName: '',
          manager: '',
          businessProfile: '',
          gallery: '',
          reviews: '',
        );
    final data = json ?? const <String, dynamic>{};
    return Terminology(
      service: _stringValue(data['service'], base.service),
      services: _stringValue(data['services'], base.services),
      appointment: _stringValue(data['appointment'], base.appointment),
      appointments: _stringValue(data['appointments'], base.appointments),
      staff: _stringValue(data['staff'], base.staff),
      staffPlural: _stringValue(data['staff_plural'], base.staffPlural),
      staffDisplayName: _stringValue(
        data['staff_display_name'],
        base.staffDisplayName,
      ),
      manager: _stringValue(data['manager'], base.manager),
      businessProfile: _stringValue(
        data['business_profile'],
        base.businessProfile,
      ),
      gallery: _stringValue(data['gallery'], base.gallery),
      reviews: _stringValue(data['reviews'], base.reviews),
    );
  }
}

class FeatureConfig {
  final bool showStaff;
  final bool reservationStaffSelection;
  final bool adminStaffManagement;
  final bool showGallery;
  final bool showReviews;
  final bool showBusinessProfile;
  final bool showAdminDashboard;

  const FeatureConfig({
    required this.showStaff,
    required this.reservationStaffSelection,
    required this.adminStaffManagement,
    required this.showGallery,
    required this.showReviews,
    required this.showBusinessProfile,
    required this.showAdminDashboard,
  });

  factory FeatureConfig.fromJson(
    Map<String, dynamic>? json, {
    FeatureConfig? fallback,
  }) {
    final base =
        fallback ??
        const FeatureConfig(
          showStaff: false,
          reservationStaffSelection: false,
          adminStaffManagement: false,
          showGallery: false,
          showReviews: false,
          showBusinessProfile: false,
          showAdminDashboard: false,
        );
    final data = json ?? const <String, dynamic>{};
    return FeatureConfig(
      showStaff: _boolValue(data['show_staff'], base.showStaff),
      reservationStaffSelection: _boolValue(
        data['reservation_staff_selection'],
        base.reservationStaffSelection,
      ),
      adminStaffManagement: _boolValue(
        data['admin_staff_management'],
        base.adminStaffManagement,
      ),
      showGallery: _boolValue(data['show_gallery'], base.showGallery),
      showReviews: _boolValue(data['show_reviews'], base.showReviews),
      showBusinessProfile: _boolValue(
        data['show_business_profile'],
        base.showBusinessProfile,
      ),
      showAdminDashboard: _boolValue(
        data['show_admin_dashboard'],
        base.showAdminDashboard,
      ),
    );
  }
}

/// WhiteLabelConfig owns business-facing branding and copy.
///
/// Use this for the identity, visual language, assets, contact information,
/// business hours, policies, terminology, and feature toggles that should vary
/// per tenant or brand.
class WhiteLabelConfig {
  final BusinessIdentity identity;
  final BrandAssets assets;
  final BrandColors colors;
  final BusinessContact contact;
  final BusinessHours hours;
  final BusinessPolicies policies;
  final Terminology terminology;
  final FeatureConfig features;

  const WhiteLabelConfig({
    required this.identity,
    required this.assets,
    required this.colors,
    required this.contact,
    required this.hours,
    required this.policies,
    required this.terminology,
    required this.features,
  });

  factory WhiteLabelConfig.fromJson(Map<String, dynamic> json) {
    final fallback = WhiteLabelConfig.tresAmigos;
    return WhiteLabelConfig(
      identity: BusinessIdentity.fromJson(
        _asMap(json['identity']),
        fallback: fallback.identity,
      ),
      assets: BrandAssets.fromJson(
        _asMap(json['assets']),
        fallback: fallback.assets,
      ),
      colors: BrandColors.fromJson(
        _asMap(json['colors']),
        fallback: fallback.colors,
      ),
      contact: BusinessContact.fromJson(
        _asMap(json['contact']),
        fallback: fallback.contact,
      ),
      hours: BusinessHours.fromJson(
        _asMap(json['hours']),
        fallback: fallback.hours,
      ),
      policies: BusinessPolicies.fromJson(
        _asMap(json['policies']),
        fallback: fallback.policies,
      ),
      terminology: Terminology.fromJson(
        _asMap(json['terminology']),
        fallback: fallback.terminology,
      ),
      features: FeatureConfig.fromJson(
        _asMap(json['features']),
        fallback: fallback.features,
      ),
    );
  }

  String get appName => identity.appName;
  String get legalName => identity.legalName ?? identity.displayName;
  String get displayName => identity.displayName;
  String get shortName => identity.shortName;
  String get tagline => identity.tagline;
  String get subtitle => identity.subtitle;
  String get locationShort => identity.locationShort;
  String get locationFull => identity.locationFull;
  double get rating => identity.rating;
  int get reviewCount => identity.reviewCount;
  String get logoTransparent => assets.logoTransparent;
  String get heroBackground => assets.heroBackground;
  String get appIcon => assets.appIcon;
  String get servicePlaceholder => assets.servicePlaceholder;
  String get premiumServicePlaceholder => assets.premiumServicePlaceholder;
  String get staffPlaceholder => assets.staffPlaceholder;
  String get profilePlaceholder => assets.profilePlaceholder;
  Color get primaryGold => colors.primaryGold;
  Color get primaryGoldLight => colors.primaryGoldLight;
  Color get primaryGoldDark => colors.primaryGoldDark;
  Color get backgroundColor => colors.background;
  Color get surfaceColor => colors.surface;
  String get phone => contact.phone;
  String get whatsapp => contact.whatsapp;
  String get email => contact.email;
  String get instagram => contact.instagram;
  String get facebook => contact.facebook;
  String get website => contact.website;
  String get address => contact.address;
  String get hoursLabel => hours.label;
  String get hoursSummary => hours.weeklySummary;
  List<String> get detailedHours => hours.detailedHours;
  String get cancellationPolicyText => policies.cancellationPolicyText;
  int get cancellationWindowHours => policies.cancellationWindowHours;
  String get serviceLabel => terminology.service;
  String get servicesLabel => terminology.services;
  String get appointmentLabel => terminology.appointment;
  String get appointmentsLabel => terminology.appointments;
  String get staffLabel => terminology.staff;
  String get staffPluralLabel => terminology.staffPlural;
  String get staffDisplayName => terminology.staffDisplayName;
  String get managerLabel => terminology.manager;
  String get businessProfileLabel => terminology.businessProfile;
  String get galleryLabel => terminology.gallery;
  String get reviewsLabel => terminology.reviews;

  static const tresAmigos = WhiteLabelConfig(
    identity: BusinessIdentity(
      appName: 'Barbería Tres Amigos',
      legalName: 'Barbería Tres Amigos S.A.',
      displayName: 'BARBERÍA TRES AMIGOS',
      shortName: 'Tres Amigos',
      tagline: 'Cortes, barba y experiencias premium',
      subtitle: 'Tu estilo, tu experiencia',
      locationShort: 'Puntarenas, Costa Rica',
      locationFull: 'Puntarenas, El Roble, Costa Rica',
      rating: 4.9,
      reviewCount: 128,
    ),
    assets: BrandAssets(
      logoTransparent: 'assets/branding/logo_transparent.png',
      appIcon: 'assets/branding/app_icon.png',
      heroBackground: 'assets/branding/barbershop_hero_bg.png',
      servicePlaceholder: 'assets/branding/service_placeholder.png',
      premiumServicePlaceholder:
          'assets/branding/service_placeholder_premium.png',
      staffPlaceholder: 'assets/branding/barber_placeholder.png',
      profilePlaceholder: 'assets/branding/profile_placeholder.png',
    ),
    colors: BrandColors(
      primaryGold: Color(0xFFD4A84F),
      primaryGoldLight: Color(0xFFE8C36A),
      primaryGoldDark: Color(0xFF9B6F24),
      background: Color(0xFF090909),
      surface: Color(0xFF1A1512),
      card: Color(0xFF120E0B),
      border: Color(0x22FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB9AFA5),
    ),
    contact: BusinessContact(
      phone: '+506 8888-3366',
      whatsapp: '+506 8888-3366',
      email: 'hola@barberiatresamigos.com',
      instagram: '@barberiatresamigos',
      facebook: 'Barbería Tres Amigos',
      website: 'https://barberiatresamigos.com',
      address: 'Puntarenas, El Roble, Costa Rica',
    ),
    hours: BusinessHours(
      label: 'Horario de atención',
      weeklySummary:
          'Lun - Vie 10:00 AM - 7:00 PM · Sáb 10:00 AM - 5:00 PM · Dom cerrado',
      detailedHours: [
        'Lun 10:00 AM - 7:00 PM',
        'Mar - Jue 10:00 AM - 12:00 PM / 2:00 PM - 8:00 PM',
        'Vie - Sáb 10:00 AM - 7:00 PM',
        'Domingo cerrado',
      ],
    ),
    policies: BusinessPolicies(
      cancellationPolicyText:
          'Podés cancelar o reprogramar hasta 4 horas antes de tu cita.',
      cancellationWindowHours: 4,
    ),
    terminology: Terminology(
      service: 'servicio',
      services: 'servicios',
      appointment: 'cita',
      appointments: 'citas',
      staff: 'barbero',
      staffPlural: 'barberos',
      staffDisplayName: 'barbero',
      manager: 'administrador',
      businessProfile: 'perfil de la barbería',
      gallery: 'galería',
      reviews: 'opiniones',
    ),
    features: FeatureConfig(
      showStaff: true,
      reservationStaffSelection: true,
      adminStaffManagement: true,
      showGallery: true,
      showReviews: true,
      showBusinessProfile: true,
      showAdminDashboard: true,
    ),
  );

  static const demoSalon = WhiteLabelConfig(
    identity: BusinessIdentity(
      appName: 'Salón Aurora',
      displayName: 'SALÓN AURORA',
      shortName: 'Aurora',
      tagline: 'Belleza, estilo y cuidado personal',
      subtitle: 'Tu momento, tu estilo',
      locationShort: 'San José, Costa Rica',
      locationFull: 'San José, Costa Rica',
      rating: 4.8,
      reviewCount: 96,
    ),
    assets: BrandAssets(
      logoTransparent: 'assets/branding/logo_transparent.png',
      appIcon: 'assets/branding/app_icon.png',
      heroBackground: 'assets/branding/barbershop_hero_bg.png',
      servicePlaceholder: 'assets/branding/service_placeholder.png',
      premiumServicePlaceholder:
          'assets/branding/service_placeholder_premium.png',
      staffPlaceholder: 'assets/branding/barber_placeholder.png',
      profilePlaceholder: 'assets/branding/profile_placeholder.png',
    ),
    colors: BrandColors(
      primaryGold: Color(0xFFE6B7A9),
      primaryGoldLight: Color(0xFFF3D4CC),
      primaryGoldDark: Color(0xFFA66A5E),
      background: Color(0xFF090909),
      surface: Color(0xFF1A1512),
      card: Color(0xFF120E0B),
      border: Color(0x22FFFFFF),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB9AFA5),
    ),
    contact: BusinessContact(
      phone: '+506 7000-0000',
      whatsapp: '+506 7000-0000',
      email: 'hola@salonaurora.com',
      instagram: '@salonaurora',
      facebook: 'Salón Aurora',
      website: 'https://salonaurora.com',
      address: 'San José, Costa Rica',
    ),
    hours: BusinessHours(
      label: 'Horario de atención',
      weeklySummary:
          'Lun - Vie 9:00 AM - 6:00 PM · Sáb 9:00 AM - 3:00 PM · Dom cerrado',
      detailedHours: [
        'Lun 9:00 AM - 6:00 PM',
        'Mar - Jue 9:00 AM - 6:00 PM',
        'Vie 9:00 AM - 6:00 PM',
        'Sáb 9:00 AM - 3:00 PM',
        'Domingo cerrado',
      ],
    ),
    policies: BusinessPolicies(
      cancellationPolicyText:
          'Podés cancelar o reprogramar hasta 6 horas antes de tu cita.',
      cancellationWindowHours: 6,
    ),
    terminology: Terminology(
      service: 'tratamiento',
      services: 'tratamientos',
      appointment: 'cita',
      appointments: 'citas',
      staff: 'estilista',
      staffPlural: 'estilistas',
      staffDisplayName: 'estilista',
      manager: 'administradora',
      businessProfile: 'perfil del salón',
      gallery: 'galería',
      reviews: 'opiniones',
    ),
    features: FeatureConfig(
      showStaff: true,
      reservationStaffSelection: true,
      adminStaffManagement: true,
      showGallery: true,
      showReviews: true,
      showBusinessProfile: true,
      showAdminDashboard: true,
    ),
  );
}
