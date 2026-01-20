import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/bindings/initial_binding.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/constants/app_constants.dart';
import 'package:domrun/core/theme/app_theme.dart';
import 'package:domrun/routes/app_pages.dart';
import 'package:domrun/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o GetStorage antes de tudo
  await GetStorage.init();

  // Configura o token do Mapbox usando constantes
  MapboxOptions.setAccessToken(ApiConstants.mapboxAccessToken);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verifica se o usuário está autenticado para definir a rota inicial
    final userService = Get.find<UserService>();
    final initialRoute = userService.hasUser
        ? AppRoutes.map
        : AppRoutes.login;

    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
      initialBinding: InitialBinding(),
      // Configuração de rotas usando GetX
      initialRoute:
          initialRoute, // Inicia no mapa se autenticado, senão no login
      getPages: AppPages.pages,
    );
  }
}
