import 'package:get/get.dart';
import 'package:nur_app/app/auth/controller/login_controller.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';

/// Binding para o módulo de autenticação
/// Configura as dependências do módulo usando GetX
/// Garante que o StorageService, AuthService e LoginController estejam disponíveis
class AuthBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra os serviços e controllers para injeção de dependência
  @override
  void dependencies() {
    // StorageService já está registrado no main.dart como permanente
    // Não precisa registrar novamente aqui

    // Registra o AuthService se ainda não estiver registrado
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    }

    // Registra o LoginController sob demanda
    if (!Get.isRegistered<LoginController>()) {
      Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    }
  }
}
