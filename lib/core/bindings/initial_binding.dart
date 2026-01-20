import 'package:get/get.dart';
import 'package:domrun/app/auth/service/auth_service.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/services/http_service.dart';
import 'package:domrun/core/services/storage_service.dart';

/// Binding inicial para dependências globais
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.putAsync<StorageService>(() async {
      final service = StorageService();
      await service.init();
      return service;
    }, permanent: true);

    Get.putAsync<HttpService>(() async {
      final service = HttpService();
      await service.init();
      return service;
    }, permanent: true);

    Get.put<UserService>(UserService(), permanent: true);

    Get.putAsync<AuthService>(() async {
      final service = AuthService();
      final httpService = Get.find<HttpService>();
      httpService.setAuthService(service);
      await service.checkAuthStatus();
      return service;
    }, permanent: true);

    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
  }
}
