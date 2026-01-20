import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/controller/forgot_password_controller.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';
import 'package:nur_app/core/widgets/map_image_background.dart';

/// Tela de recuperação de senha do aplicativo
/// Permite que usuários solicitem redefinição de senha por email
class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtém o controller de recuperação de senha (já injetado pelo binding)
    final ForgotPasswordController controller =
        Get.find<ForgotPasswordController>();

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

            SafeArea(
              child: SingleChildScrollView(
                // Permite rolagem caso o teclado cubra os campos
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Botão de voltar
                      _buildBackButton(controller),

                      const SizedBox(height: 20),

                      // Cabeçalho com título
                      _buildHeader(resp),

                      const SizedBox(height: 40),

                      // Conteúdo baseado no estado (email enviado ou não)
                      Obx(
                        () => controller.emailSent.value
                            ? _buildSuccessContent(controller, resp)
                            : _buildFormContent(controller, resp),
                      ),
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

  /// Constrói o botão de voltar
  /// Permite retornar à tela de login
  Widget _buildBackButton(ForgotPasswordController controller) {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.white),
      onPressed: controller.navigateToLogin,
    );
  }

  /// Constrói o cabeçalho da tela
  /// Exibe o título "Recuperar Senha"
  Widget _buildHeader(Responsive resp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recuperar Senha',
          style: TextStyle(
            fontSize: resp.fontSize(36),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: resp.spacing(8)),
        Text(
          'Digite seu email para receber o link de recuperação',
          style: TextStyle(
            fontSize: resp.fontSize(16),
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  /// Constrói o conteúdo do formulário
  /// Exibe o campo de email e botão de envio
  Widget _buildFormContent(
    ForgotPasswordController controller,
    Responsive resp,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de email
        _buildEmailField(controller),

        SizedBox(height: resp.spacing(40)),

        // Botão de enviar
        _buildSendButton(controller, resp),
      ],
    );
  }

  /// Constrói o campo de email
  /// Campo de texto com ícone de email
  Widget _buildEmailField(ForgotPasswordController controller) {
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

  /// Constrói o botão de enviar email
  /// Botão com gradiente roxo
  Widget _buildSendButton(
    ForgotPasswordController controller,
    Responsive resp,
  ) {
    return Obx(
      () => GestureDetector(
        onTap: controller.isLoading.value ? null : controller.sendResetEmail,
        child: Container(
          width: double.infinity,
          height: resp.containerSize(56),
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            borderRadius: BorderRadius.circular(25),
          ),
          child: controller.isLoading.value
              // Mostra indicador de carregamento
              ? SizedBox(
                  width: resp.containerSize(24),
                  height: resp.containerSize(24),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              // Mostra texto e ícone quando não está carregando
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ENVIAR',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: resp.fontSize(18),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(width: resp.spacing(8)),
                    Icon(Icons.send, color: AppColors.white),
                  ],
                ),
        ),
      ),
    );
  }

  /// Constrói o conteúdo de sucesso
  /// Exibido após o email ser enviado com sucesso
  Widget _buildSuccessContent(
    ForgotPasswordController controller,
    Responsive resp,
  ) {
    return Column(
      children: [
        // Ícone de sucesso
        Container(
          width: resp.containerSize(100),
          height: resp.containerSize(100),
          decoration: BoxDecoration(
            gradient: AppColors.successGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle_outline,
            color: AppColors.white,
            size: resp.iconSize(60),
          ),
        ),
        SizedBox(height: resp.spacing(30)),

        // Mensagem de sucesso
        Text(
          'Email enviado!',
          style: TextStyle(
            fontSize: resp.fontSize(24),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: resp.spacing(16)),

        // Instruções
        Text(
          'Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: resp.fontSize(16),
            color: AppColors.textPrimary.withOpacity(0.8),
          ),
        ),
        SizedBox(height: resp.spacing(40)),

        // Botão para voltar ao login
        GestureDetector(
          onTap: controller.navigateToLogin,
          child: Container(
            width: double.infinity,
            height: resp.containerSize(56),
            decoration: BoxDecoration(
              gradient: AppColors.successGradient,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Center(
              child: Text(
                'VOLTAR AO LOGIN',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: resp.fontSize(18),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: resp.spacing(20)),
      ],
    );
  }
}
