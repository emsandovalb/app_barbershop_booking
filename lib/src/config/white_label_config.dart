import 'package:flutter/material.dart';

part 'white_label_config/models.dart';
part 'white_label_config/parsing.dart';
part 'white_label_config/presets.dart';

/// WhiteLabelConfig owns business-facing branding and copy.
///
/// Use this for the identity, visual language, assets, contact information,
/// business hours, policies, terminology, and feature toggles that should vary
/// per tenant or brand.
class WhiteLabelConfig {
  final int? businessId;
  final String? slug;
  final String? apiBaseUrl;
  final String? logoUrl;
  final BusinessIdentity identity;
  final BrandAssets assets;
  final BrandColors colors;
  final BusinessContact contact;
  final BusinessHours hours;
  final BusinessPolicies policies;
  final Terminology terminology;
  final FeatureConfig features;

  const WhiteLabelConfig({
    this.businessId,
    this.slug,
    this.apiBaseUrl,
    this.logoUrl,
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
    final fallback = WhiteLabelConfig.presetForBusinessType(
      json['business_type']?.toString(),
      slug: json['slug']?.toString(),
    );
    return WhiteLabelConfig(
      businessId: _nullableInt(json['business_id']),
      slug: _nullableString(json['slug']),
      apiBaseUrl: _nullableString(json['api_base_url']),
      logoUrl: _nullableString(json['logo_url']),
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

  static WhiteLabelConfig presetForBusinessType(
    String? businessType, {
    String? slug,
  }) {
    final normalizedSlug = slug?.trim().toLowerCase();
    if (normalizedSlug == 'barberia-tres-amigos') {
      return tresAmigos;
    }
    if (normalizedSlug == 'jc-studio') {
      return jcStudio;
    }

    switch (_normalizedBusinessType(businessType)) {
      case 'barbershop':
        return barbershop;
      case 'salon':
        return salon;
      case 'spa':
        return spa;
      case 'clinic':
        return clinic;
      default:
        return generic;
    }
  }

  static String _normalizedBusinessType(String? businessType) {
    final value = businessType?.trim().toLowerCase();
    if (value == null || value.isEmpty) return 'generic';
    return value;
  }

  String get appName => identity.appName;
  String get legalName => identity.legalName ?? identity.displayName;
  String get displayName => identity.displayName;
  String get shortName => identity.shortName;
  String get contactPhone => contact.phone;
  String get tagline => identity.tagline;
  String get subtitle => identity.subtitle;
  String get locationShort => identity.locationShort;
  String get locationFull => identity.locationFull;
  double get rating => identity.rating;
  int get reviewCount => identity.reviewCount;
  String get logoTransparent => assets.logoTransparent;
  String get heroBackground => assets.heroBackground;
  String get appIcon => assets.appIcon;
  String get resolvedLogoUrl => logoUrl?.isNotEmpty == true
      ? logoUrl!
      : (assets.logoTransparent.isNotEmpty
            ? assets.logoTransparent
            : assets.appIcon);
  String get servicePlaceholder => assets.servicePlaceholder;
  String get premiumServicePlaceholder => assets.premiumServicePlaceholder;
  String get staffPlaceholder => assets.staffPlaceholder;
  String get profilePlaceholder => assets.profilePlaceholder;
  Color get primaryGold => colors.primaryGold;
  Color get primaryGoldLight => colors.primaryGoldLight;
  Color get primaryGoldDark => colors.primaryGoldDark;
  Color get backgroundColor => colors.background;
  Color get surfaceColor => colors.surface;
  Color get inputBackgroundColor => colors.inputBackground;
  Color get placeholderColor => colors.placeholder;
  Color get disabledTextColor => colors.disabledText;
  Color get disabledBackgroundColor => colors.disabledBackground;
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

  static const generic = _genericPreset;

  static const barbershop = _barbershopPreset;

  static const salon = _salonPreset;

  static const jcStudio = _jcStudioPreset;

  static const spa = _spaPreset;

  static const clinic = _clinicPreset;

  static const tresAmigos = _tresAmigosPreset;

  static const demoSalon = _demoSalonPreset;
}
