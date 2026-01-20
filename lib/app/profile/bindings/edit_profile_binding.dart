import 'package:get/get.dart';
import 'package:nur_app/app/profile/controller/edit_profile_controller.dart';

/// Binding para o módulo de edição de perfil
/// Configura as dependências do módulo usando GetX
class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Registra o EditProfileController
    Get.lazyPut<EditProfileController>(() => EditProfileController());
  }
}
