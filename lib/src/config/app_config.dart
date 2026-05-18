import 'package:flutter/material.dart';

class BrandConfig {
  final String appName;
  final String? logoAsset;
  final String? splashAsset;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;

  const BrandConfig({
    required this.appName,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    this.logoAsset,
    this.splashAsset,
  });
}

class FeatureFlags {
  final bool showResources;
  final bool showReservations;
  final bool showAdminReservations;
  final bool showResourceCategories;
  final bool showPayments;
  final bool showPromotions;
  final bool showTeams;
  final bool showTournaments;
  final bool showStaff;
  final bool reservationStaffSelection;

  const FeatureFlags({
    this.showResources = true,
    this.showReservations = true,
    this.showAdminReservations = true,
    this.showResourceCategories = false,
    this.showPayments = true,
    this.showPromotions = false,
    this.showTeams = false,
    this.showTournaments = false,
    this.showStaff = false,
    this.reservationStaffSelection = false,
  });
}

class TerminologyMap {
  final Map<String, String> labels;

  const TerminologyMap({required this.labels});

  String text(String key, {String? fallback}) {
    return labels[key] ?? fallback ?? key;
  }

  String get resource => text('resource', fallback: 'Resource');
  String get resources => text('resources', fallback: 'Resources');
  String get reservation => text('reservation', fallback: 'Reservation');
  String get reservations => text('reservations', fallback: 'Reservations');
  String get service => text('service', fallback: 'Service');
  String get services => text('services', fallback: 'Services');
  String get appointment => text('appointment', fallback: 'Appointment');
  String get appointments => text('appointments', fallback: 'Appointments');
  String get shopManager => text('shop_manager', fallback: 'Shop manager');
  String get shopAmenities =>
      text('shop_amenities', fallback: 'Shop amenities');
  String get barber => text('barber', fallback: 'Barber');
  String get barbers => text('barbers', fallback: 'Barbers');
  String get serviceDetail =>
      text('service_detail', fallback: 'Service detail');
  String get amenity => text('amenity', fallback: 'Amenity');
  String get amenities => text('amenities', fallback: 'Amenities');
  String get myResources => text('my_resources', fallback: 'My resources');
  String get availability => text('availability', fallback: 'Availability');
  String get availabilitySlot =>
      text('availability_slot', fallback: 'Availability slot');
}

class AppConfig {
  final BrandConfig brand;
  final FeatureFlags features;
  final TerminologyMap terminology;
  final String resourceEndpoint;
  final String reservationEndpoint;
  final String myResourcesEndpoint;

  const AppConfig({
    required this.brand,
    required this.features,
    required this.terminology,
    this.resourceEndpoint = 'resources',
    this.reservationEndpoint = 'reservations',
    this.myResourcesEndpoint = 'my/resources',
  });

  static const generic = AppConfig(
    brand: BrandConfig(
      appName: 'Booking Base',
      primaryColor: Color(0xFF2563EB),
      secondaryColor: Color(0xFFEFF6FF),
      backgroundColor: Color(0xFF0B1020),
      surfaceColor: Color(0xFF172033),
    ),
    features: FeatureFlags(
      showResources: true,
      showReservations: true,
      showAdminReservations: true,
      showResourceCategories: false,
      showPayments: true,
      showPromotions: false,
      showTeams: false,
      showTournaments: false,
      showStaff: false,
      reservationStaffSelection: false,
    ),
    resourceEndpoint: 'resources',
    reservationEndpoint: 'reservations',
    myResourcesEndpoint: 'my/resources',
    terminology: TerminologyMap(
      labels: {
        'resource': 'Resource',
        'resources': 'Resources',
        'reservation': 'Reservation',
        'reservations': 'Reservations',
        'amenity': 'Amenity',
        'amenities': 'Amenities',
        'my_resources': 'My resources',
        'availability': 'Availability',
        'availability_slot': 'Availability slot',
      },
    ),
  );

  static const barbershop = AppConfig(
    brand: BrandConfig(
      appName: 'Barbershop Booking',
      logoAsset: 'assets/icons/barbershop_logo.png',
      splashAsset: 'assets/splash/barbershop_splash.png',
      primaryColor: Color(0xFFC9A56A),
      secondaryColor: Color(0xFFE8D8B8),
      backgroundColor: Color(0xFF070707),
      surfaceColor: Color(0xFF171411),
    ),
    features: FeatureFlags(
      showResources: true,
      showReservations: true,
      showAdminReservations: true,
      showResourceCategories: false,
      showPayments: true,
      showPromotions: false,
      showTeams: false,
      showTournaments: false,
      showStaff: true,
      reservationStaffSelection: true,
    ),
    resourceEndpoint: 'resources',
    reservationEndpoint: 'reservations',
    myResourcesEndpoint: 'my/resources',
    terminology: TerminologyMap(
      labels: {
        'resource': 'Service',
        'resources': 'Services',
        'reservation': 'Appointment',
        'reservations': 'Appointments',
        'service': 'Service',
        'services': 'Services',
        'appointment': 'Appointment',
        'appointments': 'Appointments',
        'shop_manager': 'Shop manager',
        'shop_amenities': 'Shop amenities',
        'barber': 'Barber',
        'barbers': 'Barbers',
        'service_detail': 'Service detail',
        'amenity': 'Amenity',
        'amenities': 'Amenities',
        'my_resources': 'My services',
        'availability': 'Availability',
        'availability_slot': 'Availability slot',
      },
    ),
  );
}
