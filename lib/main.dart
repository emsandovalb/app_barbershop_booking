import 'dart:async';

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

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final apiBase = resolveApiBaseUrl();
  final whiteLabelConfigService = WhiteLabelConfigService(
    baseUrl: apiBase,
    fallback: WhiteLabelConfig.tresAmigos,
  );
  unawaited(whiteLabelConfigService.initialize());
  runApp(
    BarbershopBookingApp(
      config: AppConfig.barbershop,
      whiteLabelConfig: WhiteLabelConfig.tresAmigos,
      whiteLabelConfigService: whiteLabelConfigService,
    ),
  );
}
