import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/auth/service/auth_service.dart';
import 'package:domrun/core/services/http_service.dart';
import 'package:domrun/routes/app_routes.dart';

/// Controller responsável por gerenciar o estado e lógica da tela de cadastro
/// Utiliza GetX para gerenciamento reativo de estado
class SignUpController extends GetxController {
  // Serviço de autenticação (injetado via GetX)
  late final AuthService _authService;

  // Controladores dos campos de texto
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Variáveis reativas para controlar o estado da UI
  var isPasswordVisible = false.obs; // Controla a visibilidade da senha
  var isConfirmPasswordVisible =
      false.obs; // Controla a visibilidade da confirmação de senha
  var isLoading = false.obs; // Indica se está processando o cadastro

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
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  /// Alterna a visibilidade da senha
  /// Muda o estado de isPasswordVisible entre true e false
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  /// Alterna a visibilidade da confirmação de senha
  /// Muda o estado de isConfirmPasswordVisible entre true e false
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Valida se o nome está preenchido
  /// Retorna true se válido, false caso contrário
  bool _validateName() {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, insira seu nome',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    if (name.length < 3) {
      Get.snackbar(
        'Erro',
        'O nome deve ter pelo menos 3 caracteres',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Valida se o username está preenchido e atende aos requisitos
  /// Retorna true se válido, false caso contrário
  /// Username deve conter apenas letras minúsculas, números e os caracteres especiais: . (ponto), - (hífen), _ (underscore)
  bool _validateUsername() {
    // Converte para minúsculas antes de validar
    final username = usernameController.text.trim().toLowerCase();

    // Atualiza o controller com o valor em minúsculas
    if (usernameController.text.trim() != username) {
      usernameController.value = TextEditingValue(
        text: username,
        selection: TextSelection.collapsed(offset: username.length),
      );
    }

    if (username.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, insira um nome de usuário',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    if (username.length < 3) {
      Get.snackbar(
        'Erro',
        'O nome de usuário deve ter pelo menos 3 caracteres',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    // Valida se contém apenas letras minúsculas, números e os caracteres especiais: . (ponto), - (hífen), _ (underscore)
    final usernameRegex = RegExp(r'^[a-z0-9._-]+$');
    if (!usernameRegex.hasMatch(username)) {
      Get.snackbar(
        'Erro',
        'O nome de usuário deve conter apenas letras minúsculas, números e os caracteres: . (ponto), - (hífen), _ (underscore)',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
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

  /// Valida se a senha está preenchida e atende aos requisitos
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

  /// Valida se a confirmação de senha está preenchida e coincide com a senha
  /// Retorna true se válido, false caso contrário
  bool _validateConfirmPassword() {
    final confirmPassword = confirmPasswordController.text;
    final password = passwordController.text;

    if (confirmPassword.isEmpty) {
      Get.snackbar(
        'Erro',
        'Por favor, confirme sua senha',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (confirmPassword != password) {
      Get.snackbar(
        'Erro',
        'As senhas não coincidem',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Realiza o cadastro do novo usuário
  /// Valida todos os campos e chama o serviço de autenticação
  Future<void> signUp() async {
    // Valida todos os campos antes de prosseguir
    if (!_validateName() ||
        !_validateUsername() ||
        !_validateEmail() ||
        !_validatePassword() ||
        !_validateConfirmPassword()) {
      return;
    }

    // Ativa o estado de carregamento
    isLoading.value = true;

    try {
      // Chama o serviço de autenticação para realizar o cadastro
      final user = await _authService.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        name: nameController.text.trim(),
        username: usernameController.text.trim().toLowerCase(),
      );

      // Se o cadastro for bem-sucedido, exibe mensagem de sucesso
      Get.snackbar(
        'Sucesso',
        'Conta criada com sucesso! Bem-vindo, ${user.name}!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Navega para a tela do mapa após cadastro bem-sucedido
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      final message = e is ApiException ? e.message : e.toString();
      // Exibe mensagem de erro se o cadastro falhar
      Get.snackbar(
        'Erro',
        'Erro ao criar conta: $message',
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
}
