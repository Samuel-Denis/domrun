import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';
import 'package:nur_app/app/navigation/controller/navigation_controller.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/constants/app_constants.dart';
import 'package:nur_app/core/services/storage_service.dart';
import 'package:nur_app/core/theme/app_theme.dart';
import 'package:nur_app/routes/app_pages.dart';
import 'package:nur_app/routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o GetStorage antes de tudo
  await GetStorage.init();

  // Registra o StorageService como serviço global
  Get.put(StorageService(), permanent: true);

  // Registra o UserService como serviço global
  Get.put(UserService(), permanent: true);

  // Registra o AuthService como serviço global
  final authService = Get.put(AuthService(), permanent: true);

  // Registra o NavigationController como serviço global
  Get.put(NavigationController(), permanent: true);

  // Configura o token do Mapbox usando constantes
  MapboxOptions.setAccessToken(ApiConstants.mapboxAccessToken);

  // Aguarda a verificação de autenticação antes de iniciar o app
  // Isso garante que os dados do usuário sejam carregados se houver token válido
  await authService.checkAuthStatus();

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
      // Configuração de rotas usando GetX
      initialRoute:
          initialRoute, // Inicia no mapa se autenticado, senão no login
      getPages: AppPages.pages,
    );
  }
}
