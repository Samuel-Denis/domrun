import 'package:get/get.dart';
import 'package:domrun/app/auth/controller/forgot_password_controller.dart';

/// Binding para a tela de recuperação de senha
/// Configura as dependências usando GetX
/// Garante que o ForgotPasswordController esteja disponível
class ForgotPasswordBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra o AuthService e ForgotPasswordController para injeção de dependência
  @override
  void dependencies() {
    // Registra o ForgotPasswordController como um controller permanente
    // fenix: true garante que o controller seja recriado se necessário
    Get.lazyPut<ForgotPasswordController>(
      () => ForgotPasswordController(),
      fenix: true,
    );
  }
}
