import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'config/white_label_config.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'services/api.dart';
import 'providers/ground_form_provider.dart';
import 'services/localization_service.dart';
import 'services/white_label_config_service.dart';
import 'widgets/inactivity_listener.dart';
import 'navigation/nav_key.dart';

String resolveApiBaseUrl() {
  const defaultBase = String.fromEnvironment('API_BASE');
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  return defaultBase.isNotEmpty
      ? defaultBase
      : (isAndroid
            ? 'http://10.0.2.2:8000/api/v1'
            : 'http://127.0.0.1:8000/api/v1');
}

class BarbershopBookingApp extends StatelessWidget {
  final AppConfig config;
  final WhiteLabelConfig whiteLabelConfig;
  final WhiteLabelConfigService? whiteLabelConfigService;

  const BarbershopBookingApp({
    super.key,
    required this.config,
    required this.whiteLabelConfig,
    this.whiteLabelConfigService,
  });

  ThemeData _buildTheme(WhiteLabelConfig whiteLabel) {
    final colors = whiteLabel.colors;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      primaryColor: colors.primaryGold,
      colorScheme: ColorScheme.dark(
        primary: colors.primaryGold,
        secondary: colors.primaryGoldLight,
        surface: colors.surface,
        onPrimary: Colors.white,
        onSecondary: colors.background,
        onSurface: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(.08),
        thickness: 1,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF14100E),
        hintStyle: TextStyle(color: Colors.white.withOpacity(.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.primaryGold),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primaryGold,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: .4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: colors.primaryGoldLight.withOpacity(.36)),
          backgroundColor: const Color(0xFF15110E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.primaryGoldLight),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: colors.background,
        headerBackgroundColor: colors.background,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        dayForegroundColor: const WidgetStatePropertyAll(Colors.white),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.primaryGold
              : Colors.transparent,
        ),
        todayForegroundColor: const WidgetStatePropertyAll(Colors.white),
        todayBackgroundColor: WidgetStatePropertyAll(
          colors.primaryGold.withOpacity(.25),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0xFF231C18),
        labelStyle: TextStyle(color: Colors.white),
        selectedColor: Color(0xFFD4A84F),
        shape: StadiumBorder(),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: Colors.white,
        textColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.background,
        selectedItemColor: colors.primaryGold,
        unselectedItemColor: Colors.white.withOpacity(.55),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: TextStyle(color: Colors.white.withOpacity(.78)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF171311),
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = resolveApiBaseUrl();
    final translationsBase = _translationsBase(base);
    // Simple debug log to verify runtime base URL
    // ignore: avoid_print
    print('API base: $base');

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
        ] else ...[
          Provider<WhiteLabelConfig>.value(value: whiteLabelConfig),
        ],
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            ApiClient(
              baseUrl: base,
              resourceEndpointValue: config.resourceEndpoint,
              reservationEndpointValue: config.reservationEndpoint,
              myResourcesEndpointValue: config.myResourcesEndpoint,
            ),
          ),
        ),
        ChangeNotifierProvider(create: (_) => GroundFormProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final service = LocalizationService(
              translationsBaseUrl: translationsBase,
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
          final theme = _buildTheme(whiteLabel);
          final localization = context.watch<LocalizationService>();
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
          if (localization.isLoading) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: const Scaffold(
                backgroundColor: Color(0xFF090909),
                body: SizedBox.expand(),
              ),
            );
          }
          return app;
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
}
