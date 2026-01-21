import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:get/get.dart';
import 'package:domrun/core/services/storage_service.dart';
import 'package:domrun/core/services/http_service.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/app/auth/service/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<AppBootstrapper>(AppBootstrapper(), permanent: true);

    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
  }
}

class AppBootstrapper {
  Future<void>? _initFuture;

  Future<void> init() {
    return _initFuture ??= _doInit();
  }

  Future<void> _doInit() async {
    // 1) Storage
    final storage = StorageService();
    await storage.init();
    Get.put<StorageService>(storage, permanent: true);

    // 2) Http
    final http = HttpService();
    await http.init();
    Get.put<HttpService>(http, permanent: true);

    // 3) UserService
    final userService = UserService();
    Get.put<UserService>(userService, permanent: true);

    // 4) AuthService (SYNC registration após deps prontas)
    final authService = AuthService();
    http.setAuthService(authService);
    Get.put<AuthService>(authService, permanent: true);
  }
}
