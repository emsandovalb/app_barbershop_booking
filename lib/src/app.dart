import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/colors.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'services/api.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'providers/ground_form_provider.dart';
import 'services/localization_service.dart';
import 'widgets/inactivity_listener.dart';
import 'navigation/nav_key.dart';

class PlaygroundBookingApp extends StatelessWidget {
  const PlaygroundBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.primaryBackground,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.primaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.black30,
        hintStyle: TextStyle(color: Colors.white.withOpacity(.6)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          minimumSize: const Size.fromHeight(52),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.primaryBackground,
        headerBackgroundColor: AppColors.primaryBackground,
        headerForegroundColor: Colors.white,
        headerHeadlineStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
        dayForegroundColor: const WidgetStatePropertyAll(Colors.white),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : Colors.transparent),
        todayForegroundColor: const WidgetStatePropertyAll(Colors.white),
        todayBackgroundColor: WidgetStatePropertyAll(AppColors.primary.withOpacity(.25)),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.black30,
        labelStyle: TextStyle(color: Colors.white),
        selectedColor: AppColors.primary,
      ),
    );

    // Use emulator-safe base URL on Android emulators
    const defaultBase = String.fromEnvironment('API_BASE');
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    final base = defaultBase.isNotEmpty
        ? defaultBase
        : (isAndroid ? 'http://10.0.2.2:8001/api/v1' : 'http://127.0.0.1:8001/api/v1');
    final translationsBase = _translationsBase(base);
    // Simple debug log to verify runtime base URL
    // ignore: avoid_print
    print('API base: ' + base);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(ApiClient(baseUrl: base)),
        ),
        ChangeNotifierProvider(create: (_) => GroundFormProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final service = LocalizationService(translationsBaseUrl: translationsBase);
            service.init(systemLocale: WidgetsBinding.instance.platformDispatcher.locale);
            return service;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          final localization = context.watch<LocalizationService>();
          final app = InactivityListener(
            timeout: const Duration(minutes: 5),
            child: MaterialApp(
              title: 'Bamos Al Fut',
              debugShowCheckedModeBanner: false,
              theme: theme,
              navigatorKey: appNavigatorKey,
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
                backgroundColor: Colors.black,
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
