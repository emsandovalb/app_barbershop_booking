import 'package:app_barbershop_booking/src/providers/auth_provider.dart';
import 'package:app_barbershop_booking/src/services/api.dart';
import 'package:app_barbershop_booking/src/widgets/court_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('CourtImage resolves storage paths through ApiClient', (tester) async {
    final api = ApiClient(baseUrl: 'http://localhost/api/v1');
    final auth = AuthProvider(api);
    await auth.ready;

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: Scaffold(
            body: CourtImage(images: '/storage/courts/service image ñ.png'),
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<NetworkImage>());
    final network = image.image as NetworkImage;
    expect(
      Uri.parse(network.url).queryParameters['path'],
      '/storage/courts/service image ñ.png',
    );
  });

  testWidgets('CourtImage keeps asset images local', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CourtImage(images: 'assets/branding/service_placeholder.png'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<AssetImage>());
    final asset = image.image as AssetImage;
    expect(asset.assetName, 'assets/branding/service_placeholder.png');
  });
}
