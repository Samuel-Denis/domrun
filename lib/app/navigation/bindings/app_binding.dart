import 'package:get/get.dart';
import 'package:nur_app/app/navigation/controller/navigation_controller.dart';

/// Binding para o módulo de mapas
/// Configura as dependências do módulo usando GetX
/// Garante que os serviços sejam inicializados antes do controller
class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
  }
}
