import 'package:get/get.dart';
import 'package:domrun/app/auth/controller/login_controller.dart';

/// Binding para o módulo de autenticação
/// Configura as dependências do módulo usando GetX
/// Garante que o LoginController esteja disponível
class AuthBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra os serviços e controllers para injeção de dependência
  @override
  void dependencies() {
    // Registra o LoginController sob demanda
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    }
  }
}
