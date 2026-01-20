import 'package:get/get.dart';
import 'package:domrun/app/profile/controller/photo_selector_controller.dart';

/// Binding para o módulo de seleção de fotos
/// Configura as dependências do módulo usando GetX
class PhotoSelectorBinding extends Bindings {
  @override
  void dependencies() {
    // Registra o PhotoSelectorController
    Get.lazyPut<PhotoSelectorController>(() => PhotoSelectorController());
  }
}
