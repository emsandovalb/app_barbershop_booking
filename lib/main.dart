import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'src/config/app_config.dart';
import 'src/config/white_label_config.dart';
import 'src/app.dart';
import 'src/services/white_label_config_service.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const BarbershopBookingApp());
// }

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  }

  final apiBase = resolveApiBaseUrl();
  // Deliberately no defaultValue here: String.fromEnvironment returns ''
  // when BUSINESS_SLUG isn't passed at build time, so emptiness reliably
  // means "not explicitly set" rather than "resolved to some fallback".
  const rawBusinessSlug = String.fromEnvironment('BUSINESS_SLUG');
  final trimmedSlug = rawBusinessSlug.trim();

  if (trimmedSlug.isEmpty) {
    if (kReleaseMode) {
      // A release build with no BUSINESS_SLUG must never silently boot as
      // some default business's app — that's exactly how a build shipped
      // under the wrong brand previously. Fail loudly and visibly instead.
      runApp(const _MissingBusinessSlugApp());
      return;
    }
    // Local `flutter run` convenience only — never reached in a release
    // build (see scripts/build_production.ps1, which refuses to build
    // without an explicit --dart-define=BUSINESS_SLUG=...).
    debugPrint(
      '[main] BUSINESS_SLUG not set; using "jc-studio" for local debug '
      'convenience only. Release builds MUST pass '
      '--dart-define=BUSINESS_SLUG=<slug> or they will refuse to start.',
    );
  }

  final normalizedSlug = trimmedSlug.isEmpty ? 'jc-studio' : trimmedSlug;
  // A tenant's first frame must already belong to that tenant. Remote
  // configuration can refine it later, but it must never fall back to a
  // platform/admin-looking surface while that request is in flight.
  final initialWhiteLabel = _initialWhiteLabelFor(normalizedSlug);
  final initialAppConfig = _initialAppConfigFor(normalizedSlug);
  final whiteLabelConfigService = WhiteLabelConfigService(
    baseUrl: apiBase,
    businessSlug: normalizedSlug,
    fallback: initialWhiteLabel,
  );
  unawaited(whiteLabelConfigService.initialize());
  runApp(
    BarbershopBookingApp(
      config: initialAppConfig,
      whiteLabelConfig: initialWhiteLabel,
      whiteLabelConfigService: whiteLabelConfigService,
      businessSlug: normalizedSlug,
    ),
  );
}

WhiteLabelConfig _initialWhiteLabelFor(String businessSlug) {
  switch (businessSlug) {
    case 'barberia-tres-amigos':
      return WhiteLabelConfig.tresAmigos;
    case 'jc-studio':
      return WhiteLabelConfig.jcStudio;
    default:
      return WhiteLabelConfig.generic;
  }
}

AppConfig _initialAppConfigFor(String businessSlug) {
  switch (businessSlug) {
    case 'barberia-tres-amigos':
      return AppConfig.barbershop;
    case 'jc-studio':
      return AppConfig.jcStudio;
    default:
      return AppConfig.generic;
  }
}

/// Shown only when a release build was produced without
/// `--dart-define=BUSINESS_SLUG=<slug>`. Deliberately plain and unmissable —
/// this is a build-configuration failure, not a normal app state, so it
/// must never be mistaken for a working (if generic) app.
class _MissingBusinessSlugApp extends StatelessWidget {
  const _MissingBusinessSlugApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFB3261E),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.error_outline, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Build misconfigured: BUSINESS_SLUG was not set.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This build must never ship without '
                    '--dart-define=BUSINESS_SLUG=<slug>. '
                    'Rebuild using scripts/build_production.ps1.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
