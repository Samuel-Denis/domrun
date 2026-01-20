import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';

/// Controller responsável por gerenciar o estado e lógica da tela de recuperação de senha
/// Utiliza GetX para gerenciamento reativo de estado
class ForgotPasswordController extends GetxController {
  // Serviço de autenticação (injetado via GetX)
  late final AuthService _authService;

  // Controlador do campo de texto de email
  final TextEditingController emailController = TextEditingController();

  // Variáveis reativas para controlar o estado da UI
  var isLoading = false.obs; // Indica se está processando o envio do email
  var emailSent = false.obs; // Indica se o email foi enviado com sucesso

  /// Método chamado quando o controller é inicializado
  /// Configura valores iniciais e obtém o serviço de autenticação
  @override
  void onInit() {
    super.onInit();
    // Obtém o AuthService injetado pelo binding
    _authService = Get.find<AuthService>();
  }

  /// Método chamado quando o controller é destruído
  /// Limpa os recursos para evitar vazamento de memória
  @override
  void onClose() {
    // Libera o controlador de texto
    emailController.dispose();
    super.onClose();
  }

  /// Valida se o email está preenchido e tem formato válido
  /// Retorna true se válido, false caso contrário
  bool _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, insira seu email',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    // Valida formato de email usando regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      Get.snackbar(
        'Erro',
        'Por favor, insira um email válido',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Envia o email de recuperação de senha
  /// Valida o email e chama o serviço de autenticação
  Future<void> sendResetEmail() async {
    // Valida o email antes de prosseguir
    if (!_validateEmail()) {
      return;
    }

    // Ativa o estado de carregamento
    isLoading.value = true;

    try {
      // Chama o serviço de autenticação para enviar o email de recuperação
      final success = await _authService.sendPasswordResetEmail(
        emailController.text.trim(),
      );

      if (success) {
        // Marca que o email foi enviado
        emailSent.value = true;

        // Exibe mensagem de sucesso
        Get.snackbar(
          'Sucesso',
          'Email de recuperação enviado! Verifique sua caixa de entrada.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      // Exibe mensagem de erro se o envio falhar
      Get.snackbar(
        'Erro',
        'Erro ao enviar email: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Desativa o estado de carregamento
      isLoading.value = false;
    }
  }

  /// Navega de volta para a tela de login
  void navigateToLogin() {
    Get.back();
  }

  /// Reseta o estado da tela para permitir novo envio
  void resetState() {
    emailSent.value = false;
    emailController.clear();
  }
}
