import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/controller/login_controller.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';
import 'package:nur_app/core/widgets/map_image_background.dart';

/// Tela de login do aplicativo
/// Exibe campos de email/senha e opções de login social
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém o controller de login (já injetado pelo binding)
    final LoginController controller = Get.find<LoginController>();

    final Responsive resp = Responsive(context);

    return Scaffold(
      // Define o fundo da tela com gradiente roxo escuro e padrão de mapa
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
                      opacity: 0.6,
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 40),

                      // Cabeçalho com ícone, título e tagline
                      _buildHeader(),

                      const SizedBox(height: 60),

                      // Campo de email/nome de usuário
                      _buildEmailField(controller),

                      const SizedBox(height: 20),

                      // Campo de senha
                      _buildPasswordField(controller),

                      const SizedBox(height: 12),

                      // Link "Esqueceu a senha?"
                      _buildForgotPasswordLink(controller),

                      const SizedBox(height: 40),

                      // Botão de entrar
                      _buildLoginButton(controller, resp),

                      const SizedBox(height: 40),

                      // Divisor "OU ENTRE COM"
                      _buildDivider(),

                      const SizedBox(height: 30),

                      // Botões de login social
                      _buildSocialLoginButtons(controller, resp),

                      const SizedBox(height: 40),

                      // Link para criar conta
                      _buildSignUpLink(controller, resp),
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
  /// Exibe o ícone, título "Territory Run" e tagline
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ícone circular com pin de localização
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/map_background.webp'),
              fit: BoxFit.cover,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 2),
          ),
          child: const Icon(
            Icons.location_on,
            color: AppColors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 24),

        // Título do app
        const Text(
          'Domrun',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Tagline
        Text(
          'Domine as ruas da sua cidade.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  /// Constrói o campo de email/nome de usuário
  /// Campo de texto com ícone de pessoa
  Widget _buildEmailField(LoginController controller) {
    return TextField(
      controller: controller.emailController,
      // Configura o tipo de teclado para email
      keyboardType: TextInputType.emailAddress,
      // Estiliza o texto digitado
      style: const TextStyle(color: AppColors.background),
      // Configura a decoração do campo
      decoration: InputDecoration(
        // Ícone à esquerda
        prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary),
        // Texto de placeholder
        hintText: 'Email ou Nome de Usuário',
        hintStyle: TextStyle(color: AppColors.background),
        // Fundo do campo
        filled: true,
        fillColor: AppColors.white,
        // Borda arredondada
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Constrói o campo de senha
  /// Campo de texto com ícone de cadeado e botão para mostrar/ocultar senha
  Widget _buildPasswordField(LoginController controller) {
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
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
          // Botão para mostrar/ocultar senha à direita
          suffixIcon: IconButton(
            icon: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.primary,
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
          // Borda arredondada
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  /// Constrói o link "Esqueceu a senha?"
  /// Alinhado à direita e clicável
  Widget _buildForgotPasswordLink(LoginController controller) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: controller.navigateToForgotPassword,
        child: Text(
          'Esqueceu a senha?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Constrói o botão principal de login
  /// Botão com gradiente roxo e ícone de seta
  Widget _buildLoginButton(LoginController controller, Responsive resp) {
    return Obx(
      () => GestureDetector(
        // Desabilita o botão durante o carregamento
        onTap: controller.isLoading.value ? null : controller.loginWithEmail,
        child: Container(
          width: double.infinity,
          height: resp.containerSize(56),
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(25),
          ),
          child: controller.isLoading.value
              // Mostra indicador de carregamento
              ? Center(
                  child: SizedBox(
                    width: resp.containerSize(24),
                    height: resp.containerSize(24),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.white,
                      ),
                    ),
                  ),
                )
              // Mostra texto e ícone quando não está carregando
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ENTRAR',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: AppColors.white),
                  ],
                ),
        ),
      ),
    );
  }

  /// Constrói o divisor "OU ENTRE COM"
  /// Linha horizontal com texto no meio
  Widget _buildDivider() {
    return Row(
      children: [
        // Linha à esquerda
        Expanded(child: Divider(color: AppColors.white, thickness: 1)),
        // Texto no meio
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OU ENTRE COM',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
        // Linha à direita
        Expanded(child: Divider(color: AppColors.white, thickness: 1)),
      ],
    );
  }

  /// Constrói os botões de login social
  /// Botões para Apple e Google lado a lado
  Widget _buildSocialLoginButtons(LoginController controller, Responsive resp) {
    return Row(
      children: [
        // Botão de login com Apple
        Expanded(
          child: _buildSocialButton(
            icon: Icons.apple,
            label: 'Apple',
            onPressed: controller.loginWithApple,
            resp: resp,
          ),
        ),
        const SizedBox(width: 16),
        // Botão de login com Google
        Expanded(
          child: _buildSocialButton(
            label: 'Google',
            onPressed: controller.loginWithGoogle,
            isGoogle: true, // Usa "G" estilizado ao invés de ícone
            resp: resp,
          ),
        ),
      ],
    );
  }

  /// Constrói um botão de login social individual
  /// [icon] - Ícone a ser exibido (opcional, pode ser null para usar texto)
  /// [label] - Texto do botão
  /// [onPressed] - Função chamada ao clicar
  /// [isGoogle] - Se true, usa um "G" estilizado ao invés de ícone
  Widget _buildSocialButton({
    IconData? icon,
    required String label,
    required VoidCallback onPressed,
    bool isGoogle = false,
    required Responsive resp,
  }) {
    return Container(
      height: resp.containerSize(56),
      decoration: BoxDecoration(
        gradient: AppColors.successGradient,
        borderRadius: BorderRadius.circular(25),
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Se for Google, mostra "G" estilizado, senão mostra o ícone
            if (isGoogle)
              Container(
                width: resp.containerSize(24),
                height: resp.containerSize(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            else if (icon != null)
              Icon(icon, color: AppColors.white, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o link para criar conta
  /// Texto com link "Criar Conta" no final
  Widget _buildSignUpLink(LoginController controller, Responsive resp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Ainda não corre com a gente?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: controller.navigateToSignUp,
          child: Text(
            'Criar Conta',
            style: TextStyle(
              color: AppColors.gradient1,
              fontSize: resp.fontSize(17),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
