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
  runApp(
    BarbershopBookingApp(
      config: AppConfig.barbershop,
      whiteLabelConfig: whiteLabelConfig,
    ),
  );
}
