import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/controller/signup_controller.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';
import 'package:nur_app/core/widgets/map_image_background.dart';

/// Tela de cadastro do aplicativo
/// Permite que novos usuários criem uma conta
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém o controller de cadastro (já injetado pelo binding)
    final SignUpController controller = Get.find<SignUpController>();

    final Responsive resp = Responsive(context);

    return Scaffold(
      // Define o fundo da tela com gradiente roxo escuro
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background, // Cor de fundo sólida
        ),

        child: Stack(
          children: [
            // Fundo decorativo com padrão de mapa completo no fundo
            Positioned.fill(
              child: Stack(
                children: [
                  // Mapa decorativo - mostra a imagem completa
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,

                    child: MapImageBackground(
                      imagePath: 'assets/images/background_login.webp',
                      opacity: 1.0,
                    ),
                  ),

                  // Gradiente que faz transição suave e natural da imagem para a cor sólida
                  // A transição começa gradualmente na parte inferior da imagem
                  Positioned.fill(
                    child: Container(
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: AppColors.backgroundGradient,
                      ),
                    ),
                  ),
                ],
              ), // Removida a vírgula extra se este for o último parâmetro
            ),

            // Conteúdo da tela por cima do mapa
            SafeArea(
              child: SingleChildScrollView(
                // Permite rolagem caso o teclado cubra os campos
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Cabeçalho com ícone, título e tagline
                      _buildHeader(),

                      SizedBox(height: resp.spacing(60)),

                      // Campo de email/nome de usuário
                      _buildEmailField(controller),

                      SizedBox(height: resp.spacing(20)),

                      _buildNameField(controller),

                      SizedBox(height: resp.spacing(20)),

                      _buildUsernameField(controller),

                      SizedBox(height: resp.spacing(20)),

                      // Campo de senha
                      _buildPasswordField(controller),

                      SizedBox(height: resp.spacing(20)),

                      _buildConfirmPasswordField(controller),

                      SizedBox(height: resp.spacing(20)),

                      _buildSignUpButton(controller, resp),

                      SizedBox(height: resp.spacing(20)),

                      _buildLoginLink(controller, resp),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cabeçalho da tela
  /// Exibe o título "Criar Conta"
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Criar Conta',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha os dados para começar',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de nome
  /// Campo de texto com ícone de pessoa
  Widget _buildNameField(SignUpController controller) {
    return TextField(
      controller: controller.nameController,
      // Configura o tipo de teclado para texto
      keyboardType: TextInputType.name,
      // Estiliza o texto digitado
      style: const TextStyle(color: AppColors.background),
      // Configura a decoração do campo
      decoration: InputDecoration(
        // Ícone à esquerda
        prefixIcon: const Icon(
          Icons.person_outline,
          color: AppColors.iconActive,
        ),
        // Texto de placeholder
        hintText: 'Nome completo',
        hintStyle: TextStyle(color: AppColors.background),
        // Fundo do campo
        filled: true,
        fillColor: AppColors.white,
        // Borda arredondada
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        // Borda quando focado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.loginInputBorder,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Constrói o campo de username
  /// Campo de texto com ícone de @
  Widget _buildUsernameField(SignUpController controller) {
    return TextField(
      controller: controller.usernameController,
      // Configura o tipo de teclado para texto
      keyboardType: TextInputType.text,
      // Converte automaticamente para minúsculas enquanto digita
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9._-]')),
        TextInputFormatter.withFunction((oldValue, newValue) {
          // Converte para minúsculas
          return TextEditingValue(
            text: newValue.text.toLowerCase(),
            selection: newValue.selection,
          );
        }),
      ],
      // Estiliza o texto digitado
      style: const TextStyle(color: AppColors.background),
      // Configura a decoração do campo
      decoration: InputDecoration(
        // Ícone à esquerda
        prefixIcon: const Icon(
          Icons.alternate_email,
          color: AppColors.iconActive,
        ),
        // Texto de placeholder
        hintText: 'Nome de usuário',
        hintStyle: TextStyle(color: AppColors.background),
        // Fundo do campo
        filled: true,
        fillColor: AppColors.white,
        // Borda arredondada
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        // Borda quando focado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.loginInputBorder,
            width: 2,
          ),
        ),
      ),
    );
  }

  /// Constrói o campo de email
  /// Campo de texto com ícone de email
  Widget _buildEmailField(SignUpController controller) {
    return TextField(
      controller: controller.emailController,
      // Configura o tipo de teclado para email
      keyboardType: TextInputType.emailAddress,
      // Estiliza o texto digitado
      style: const TextStyle(color: AppColors.background),
      // Configura a decoração do campo
      decoration: InputDecoration(
        // Ícone à esquerda
        prefixIcon: const Icon(
          Icons.email_outlined,
          color: AppColors.iconActive,
        ),
        // Texto de placeholder
        hintText: 'Email',
        hintStyle: TextStyle(color: AppColors.background),
        // Fundo do campo
        filled: true,
        fillColor: AppColors.white,
      ),
    );
  }

  /// Constrói o campo de senha
  /// Campo de texto com ícone de cadeado e botão para mostrar/ocultar senha
  Widget _buildPasswordField(SignUpController controller) {
    return Obx(
      () => TextField(
        controller: controller.passwordController,
        // Oculta o texto quando isPasswordVisible é false
        obscureText: !controller.isPasswordVisible.value,
        // Estiliza o texto digitado
        style: const TextStyle(color: AppColors.background),
        // Configura a decoração do campo
        decoration: InputDecoration(
          // Ícone de cadeado à esquerda
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.iconActive,
          ),
          // Botão para mostrar/ocultar senha à direita
          suffixIcon: IconButton(
            icon: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.iconActive,
            ),
            // Alterna a visibilidade da senha ao clicar
            onPressed: controller.togglePasswordVisibility,
          ),
          // Texto de placeholder
          hintText: 'Senha',
          hintStyle: TextStyle(color: AppColors.background),
          // Fundo do campo
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }

  /// Constrói o campo de confirmação de senha
  /// Campo de texto com ícone de cadeado e botão para mostrar/ocultar senha
  Widget _buildConfirmPasswordField(SignUpController controller) {
    return Obx(
      () => TextField(
        controller: controller.confirmPasswordController,
        // Oculta o texto quando isConfirmPasswordVisible é false
        obscureText: !controller.isConfirmPasswordVisible.value,
        // Estiliza o texto digitado
        style: const TextStyle(color: AppColors.background),
        // Configura a decoração do campo
        decoration: InputDecoration(
          // Ícone de cadeado à esquerda
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.iconActive,
          ),
          // Botão para mostrar/ocultar senha à direita
          suffixIcon: IconButton(
            icon: Icon(
              controller.isConfirmPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.iconActive,
            ),
            // Alterna a visibilidade da confirmação de senha ao clicar
            onPressed: controller.toggleConfirmPasswordVisibility,
          ),
          // Texto de placeholder
          hintText: 'Confirmar senha',
          hintStyle: TextStyle(color: AppColors.background),
          // Fundo do campo
          filled: true,
          fillColor: AppColors.white,
        ),
      ),
    );
  }

  /// Constrói o botão principal de cadastro
  /// Botão com gradiente roxo e ícone de seta
  Widget _buildSignUpButton(SignUpController controller, Responsive resp) {
    return Obx(
      () => GestureDetector(
        // Desabilita o botão durante o carregamento
        onTap: controller.isLoading.value ? null : controller.signUp,

        child: Container(
          width: double.infinity,
          height: resp.containerSize(56),
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(25),
          ),
          child: controller.isLoading.value
              // Mostra indicador de carregamento
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              // Mostra texto e ícone quando não está carregando
              : const Center(
                  child: Text(
                    'CRIAR CONTA',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Constrói o link para voltar ao login
  /// Texto com link "Já tem uma conta?"
  Widget _buildLoginLink(SignUpController controller, Responsive resp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Já tem uma conta?',
          style: TextStyle(
            color: AppColors.textPrimary.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),

        GestureDetector(
          onTap: controller.navigateToLogin,
          child: Container(
            width: resp.containerSize(90),
            height: resp.containerSize(35),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Entrar',
                style: TextStyle(
                  color: AppColors.iconActive,
                  fontSize: resp.fontSize(15),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
