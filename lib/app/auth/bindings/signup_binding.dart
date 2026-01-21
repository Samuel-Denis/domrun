import 'package:get/get.dart';
import 'package:domrun/app/auth/controller/signup_controller.dart';

/// Binding para a tela de cadastro
/// Configura as dependências usando GetX
/// Garante que o SignUpController esteja disponível
class SignUpBinding extends Bindings {
  /// Método obrigatório do Bindings
  /// É chamado automaticamente quando a rota associada é acessada
  /// Registra o AuthService e SignUpController para injeção de dependência
  @override
  void dependencies() {
    // Registra o SignUpController como um controller permanente
    // fenix: true garante que o controller seja recriado se necessário
    Get.lazyPut<SignUpController>(
      () => SignUpController(),
      fenix: true,
    );
  }
}
