import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/white_label_config.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'services/api.dart';
import 'services/localization_service.dart';
import 'services/salon_fallbacks.dart';
import 'services/white_label_config_service.dart';
import 'theme/brand_theme.dart';
import 'widgets/inactivity_listener.dart';
import 'navigation/nav_key.dart';

String resolveApiBaseUrl() {
  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  const legacyBase = String.fromEnvironment('API_BASE');
  if (apiBaseUrl.trim().isNotEmpty) {
    return apiBaseUrl.trim().replaceAll(RegExp(r'\/+$'), '');
  }
  if (legacyBase.trim().isNotEmpty) {
    return legacyBase.trim().replaceAll(RegExp(r'\/+$'), '');
  }
  if (kIsWeb) {
    return '${Uri.base.origin}/api/v1';
  }
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  return isAndroid
      ? 'http://10.0.2.2:8000/api/v1'
      : 'http://127.0.0.1:8000/api/v1';
}

class BarbershopBookingApp extends StatelessWidget {
  final AppConfig config;
  final WhiteLabelConfig whiteLabelConfig;
  final WhiteLabelConfigService? whiteLabelConfigService;
  final String? businessSlug;

  const BarbershopBookingApp({
    super.key,
    required this.config,
    required this.whiteLabelConfig,
    this.whiteLabelConfigService,
    this.businessSlug,
  });

  @override
  Widget build(BuildContext context) {
    final base = resolveApiBaseUrl();
    final translationsBase = _translationsBase(base);
    final fallbackBrandTheme = _brandThemeForConfig(whiteLabelConfig);

    return MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: config),
        if (whiteLabelConfigService != null) ...[
          ChangeNotifierProvider<WhiteLabelConfigService>.value(
            value: whiteLabelConfigService!,
          ),
          ProxyProvider<WhiteLabelConfigService, WhiteLabelConfig>(
            update: (_, service, __) => service.config,
          ),
          ProxyProvider<WhiteLabelConfigService, BrandTheme>(
            update: (_, service, __) => service.brandTheme,
          ),
        ] else ...[
          Provider<WhiteLabelConfig>.value(value: whiteLabelConfig),
          Provider<BrandTheme>.value(value: fallbackBrandTheme),
        ],
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            ApiClient(
              baseUrl: base,
              resourceEndpointValue: config.resourceEndpoint,
              reservationEndpointValue: config.reservationEndpoint,
              myResourcesEndpointValue: config.myResourcesEndpoint,
              businessSlug: businessSlug,
            ),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final service = LocalizationService(
              translationsBaseUrl: translationsBase,
              fallbackOverrides: whiteLabelConfig.slug == 'jc-studio'
                  ? salonFallbacks
                  : const {},
            );
            service.init(
              systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
            );
            return service;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final whiteLabel = context.watch<WhiteLabelConfig>();
          final brandTheme = context.watch<BrandTheme>();
          final theme = brandTheme.buildThemeData();
          final localization = context.watch<LocalizationService>();
          final overlayStyle = _overlayStyle(brandTheme);
          final app = InactivityListener(
            timeout: const Duration(minutes: 5),
            child: MaterialApp(
              title: whiteLabel.appName,
              debugShowCheckedModeBanner: false,
              theme: theme,
              navigatorKey: appNavigatorKey,
              navigatorObservers: [appRouteObserver],
              onGenerateRoute: AppRouter.onGenerateRoute,
              initialRoute: AppRoutes.splash,
              locale: localization.locale,
              supportedLocales: const [Locale('es'), Locale('en')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
          final wrappedApp = AnnotatedRegion<SystemUiOverlayStyle>(
            value: overlayStyle,
            child: app,
          );
          if (kIsWeb) {
            return wrappedApp;
          }
          if (localization.isLoading) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlayStyle,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: theme,
                home: const Scaffold(
                  backgroundColor: Color(0xFF0B1020),
                  body: SizedBox.expand(),
                ),
              ),
            );
          }
          return wrappedApp;
        },
      ),
    );
  }

  String _translationsBase(String apiBase) {
    final uri = Uri.tryParse(apiBase);
    if (uri == null) return apiBase;
    final segments = List.of(uri.pathSegments);
    if (segments.isNotEmpty && RegExp(r'^v\d+$').hasMatch(segments.last)) {
      segments.removeLast();
    }
    final newUri = uri.replace(pathSegments: segments);
    return newUri.toString().replaceAll(RegExp(r'\/+$'), '');
  }

  BrandTheme _brandThemeForConfig(WhiteLabelConfig whiteLabel) {
    if (whiteLabel.slug == 'barberia-tres-amigos') {
      return BrandTheme.barbershop();
    }
    final shortName = whiteLabel.shortName.toLowerCase();
    if (shortName.contains('sal') || shortName.contains('aurora')) {
      return BrandTheme.salon();
    }
    return BrandTheme.generic();
  }

  SystemUiOverlayStyle _overlayStyle(BrandTheme theme) {
    final brightness = theme.themeMode == ThemeMode.light
        ? Brightness.dark
        : Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness,
      statusBarBrightness: theme.themeMode == ThemeMode.light
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarColor: theme.background,
      systemNavigationBarIconBrightness: brightness,
    );
  }
}
