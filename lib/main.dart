import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:domrun/core/bindings/initial_binding.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/constants/app_constants.dart';
import 'package:domrun/core/theme/app_theme.dart';
import 'package:domrun/app/splash/views/splash_page.dart';
import 'package:domrun/routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o GetStorage antes de tudo
  await GetStorage.init();

  // Configura o token do Mapbox usando constantes
  MapboxOptions.setAccessToken(ApiConstants.mapboxAccessToken);

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
        ),
      );
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        // Silencia prints em todo o app.
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      initialBinding: InitialBinding(),
      home: const SplashPage(),
      // Configuração de rotas usando GetX
      getPages: AppPages.pages,
    );
  }
}
