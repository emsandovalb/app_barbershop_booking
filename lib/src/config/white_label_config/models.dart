part of '../white_label_config.dart';

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
  final Color inputBackground;
  final Color placeholder;
  final Color disabledText;
  final Color disabledBackground;

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
    required this.inputBackground,
    required this.placeholder,
    required this.disabledText,
    required this.disabledBackground,
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
          inputBackground: Colors.black,
          placeholder: Colors.white,
          disabledText: Colors.white,
          disabledBackground: Colors.black,
        );
    final data = json ?? const <String, dynamic>{};
    return BrandColors(
      primaryGold: _colorValue(
        data['primary'] ?? data['primary_gold'],
        base.primaryGold,
      ),
      primaryGoldLight: _colorValue(
        data['primary_light'] ?? data['primary_gold_light'],
        base.primaryGoldLight,
      ),
      primaryGoldDark: _colorValue(
        data['primary_dark'] ?? data['primary_gold_dark'],
        base.primaryGoldDark,
      ),
      background: _colorValue(data['background'], base.background),
      surface: _colorValue(data['surface'], base.surface),
      card: _colorValue(data['card'], base.card),
      border: _colorValue(data['border'], base.border),
      textPrimary: _colorValue(data['text_primary'], base.textPrimary),
      textSecondary: _colorValue(data['text_secondary'], base.textSecondary),
      inputBackground: _colorValue(
        data['input_background'],
        base.inputBackground,
      ),
      placeholder: _colorValue(data['placeholder'], base.placeholder),
      disabledText: _colorValue(data['disabled_text'], base.disabledText),
      disabledBackground: _colorValue(
        data['disabled_background'],
        base.disabledBackground,
      ),
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
