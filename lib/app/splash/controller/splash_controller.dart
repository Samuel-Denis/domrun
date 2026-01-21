import 'package:domrun/core/bindings/initial_binding.dart';
import 'package:get/get.dart';
import 'package:domrun/app/auth/service/auth_service.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/routes/app_routes.dart';

class SplashController extends GetxController {
  late AuthService _authService;
  late UserService _userService;

  @override
  void onReady() {
    super.onReady();
    _start();
  }

  Future<void> _start() async {
    // espera o bootstrap terminar
    await Get.find<AppBootstrapper>().init();

    // agora pode pegar normal (já está registrado)
    _authService = Get.find<AuthService>();
    _userService = Get.find<UserService>();

    await _decideRoute();
  }

  Future<void> _decideRoute() async {
    try {
      await _authService.checkAuthStatus();
    } catch (_) {}

    final target = _userService.hasUser ? AppRoutes.map : AppRoutes.login;
    Get.offAllNamed(target);
  }
}
