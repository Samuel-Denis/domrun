import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';
import 'package:nur_app/routes/app_routes.dart';

/// Controller responsável por gerenciar o estado e lógica da tela de login
/// Utiliza GetX para gerenciamento reativo de estado
class LoginController extends GetxController {
  // Serviço de autenticação (injetado via GetX)
  late final AuthService _authService;

  // Controladores dos campos de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variáveis reativas para controlar o estado da UI
  var isPasswordVisible = false.obs; // Controla a visibilidade da senha
  var isLoading = false.obs; // Indica se está processando o login

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
    // Libera os controladores de texto
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Alterna a visibilidade da senha
  /// Muda o estado de isPasswordVisible entre true e false
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Valida se o email ou nome de usuário está preenchido
  /// Retorna true se válido, false caso contrário
  bool _validateEmail() {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, insira seu email ou nome de usuário',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Valida se a senha está preenchida
  /// Retorna true se válido, false caso contrário
  bool _validatePassword() {
    final password = passwordController.text;
    if (password.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, insira sua senha',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    if (password.length < 6) {
      Get.snackbar(
        'Erro',
        'A senha deve ter pelo menos 6 caracteres',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Realiza o login com email e senha
  /// Valida os campos e chama o serviço de autenticação
  Future<void> loginWithEmail() async {
    // Valida os campos antes de prosseguir
    if (!_validateEmail() || !_validatePassword()) {
      return;
    }

    // Ativa o estado de carregamento
    isLoading.value = true;

    try {
      // Chama o serviço de autenticação para realizar o login
      final user = await _authService.loginWithEmail(
        emailController.text.trim(),
        passwordController.text,
      );

      // Se o login for bem-sucedido, exibe mensagem de sucesso
      Get.snackbar(
        'Sucesso',
        'Bem-vindo, ${user.name ?? user.email}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navega para a tela do mapa após login bem-sucedido
      // offAllNamed remove todas as rotas anteriores da pilha
      Get.offAllNamed(AppRoutes.map);
    } catch (e) {
      // Exibe mensagem de erro se o login falhar
      Get.snackbar(
        'Erro',
        'Erro ao fazer login: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // Desativa o estado de carregamento
      isLoading.value = false;
    }
  }

  /// Realiza login com Apple
  /// Integra com o serviço de autenticação da Apple
  Future<void> loginWithApple() async {
    isLoading.value = true;

    try {
      // Chama o serviço de autenticação para realizar login com Apple
      final user = await _authService.loginWithApple();

      // Se o login for bem-sucedido, exibe mensagem e navega
      Get.snackbar(
        'Sucesso',
        'Bem-vindo, ${user.name ?? user.email}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navega para a tela do mapa após login bem-sucedido
      Get.offAllNamed(AppRoutes.map);
    } catch (e) {
      // Exibe mensagem de erro se o login falhar
      Get.snackbar(
        'Erro',
        'Erro ao fazer login com Apple: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Realiza login com Google
  /// Integra com o serviço de autenticação do Google
  Future<void> loginWithGoogle() async {
    isLoading.value = true;

    try {
      // Chama o serviço de autenticação para realizar login com Google
      final user = await _authService.loginWithGoogle();

      // Se o login for bem-sucedido, exibe mensagem e navega
      Get.snackbar(
        'Sucesso',
        'Bem-vindo, ${user.name ?? user.email}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navega para a tela do mapa após login bem-sucedido
      Get.offAllNamed(AppRoutes.map);
    } catch (e) {
      // Exibe mensagem de erro se o login falhar
      Get.snackbar(
        'Erro',
        'Erro ao fazer login com Google: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Navega para a tela de recuperação de senha
  void navigateToForgotPassword() {
    // Navega para a tela de recuperação de senha
    Get.toNamed(AppRoutes.forgotPassword);
  }

  /// Navega para a tela de criação de conta
  void navigateToSignUp() {
    // Navega para a tela de cadastro
    Get.toNamed(AppRoutes.signUp);
  }
}
