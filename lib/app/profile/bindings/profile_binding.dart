import 'package:get/get.dart';
import 'package:nur_app/app/profile/controller/profile_controller.dart';
import 'package:nur_app/app/user/service/user_service.dart';

/// Binding para a página de perfil
/// Registra o ProfileController como dependência
class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Registra o ProfileController
    Get.lazyPut<ProfileController>(() => ProfileController());
    Get.lazyPut<UserService>(() => UserService(), fenix: true);
  }
}
