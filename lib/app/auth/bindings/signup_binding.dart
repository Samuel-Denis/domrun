import 'package:get/get.dart';
import 'package:domrun/app/auth/controller/signup_controller.dart';
import 'package:domrun/app/auth/service/auth_service.dart';

/// Binding para a tela de cadastro
/// Configura as dependências usando GetX
/// Garante que o AuthService e SignUpController estejam disponíveis
class SignUpBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra o AuthService e SignUpController para injeção de dependência
  @override
  void dependencies() {
    // Registra o AuthService como um serviço permanente (se ainda não estiver registrado)
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(
        () => AuthService(),
        fenix: true,
      );
    }

    // Registra o SignUpController como um controller permanente
    // fenix: true garante que o controller seja recriado se necessário
    Get.lazyPut<SignUpController>(
      () => SignUpController(),
      fenix: true,
    );
  }
}
