import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'src/config/app_config.dart';
import 'src/config/white_label_config.dart';
import 'src/app.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   runApp(const BarbershopBookingApp());
// }

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final whiteLabelConfig = WhiteLabelConfig.tresAmigos;
  // To test another white-label brand locally:
  // final whiteLabelConfig = WhiteLabelConfig.demoSalon;
  runApp(
    BarbershopBookingApp(
      config: AppConfig.barbershop,
      whiteLabelConfig: whiteLabelConfig,
    ),
  );
}
