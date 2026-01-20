import 'package:get/get.dart';
import 'package:domrun/app/auth/controller/forgot_password_controller.dart';
import 'package:domrun/app/auth/service/auth_service.dart';

/// Binding para a tela de recuperação de senha
/// Configura as dependências usando GetX
/// Garante que o AuthService e ForgotPasswordController estejam disponíveis
class ForgotPasswordBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra o AuthService e ForgotPasswordController para injeção de dependência
  @override
  void dependencies() {
    // Registra o AuthService como um serviço permanente (se ainda não estiver registrado)
    if (!Get.isRegistered<AuthService>()) {
      Get.lazyPut<AuthService>(
        () => AuthService(),
        fenix: true,
      );
    }

    // Registra o ForgotPasswordController como um controller permanente
    // fenix: true garante que o controller seja recriado se necessário
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(),
      fenix: true,
    );
  }
}
