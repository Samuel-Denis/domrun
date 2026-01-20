import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:domrun/app/auth/models/user_model.dart';
import 'package:domrun/app/profile/controller/edit_profile_controller.dart';
import 'package:domrun/app/user/service/user_service.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

class EditProfilePage extends GetView<EditProfileController> {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final userService = Get.find<UserService>();
    final user = userService.currentUser.value;
    controller.startEditSession();

    return WillPopScope(
      onWillPop: controller.handleWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _buildAppBar(context, controller, responsive),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeroHeader(context, controller, responsive, user),
            ),

            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.paddingHorizontal,
                vertical: responsive.spacing(20),
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _SectionCard(
                    title: 'Identidade',
                    child: Column(
                      children: [
                        _buildNameField(controller, responsive),
                        SizedBox(height: responsive.spacing(16)),
                        _buildUsernameField(controller, responsive),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.spacing(20)),

                  _SectionCard(
                    title: 'Biografia',
                    child: _buildBiographyField(controller, responsive),
                  ),

                  SizedBox(height: responsive.spacing(20)),

                  _SectionCard(
                    title: 'Segurança',
                    child: _buildSecuritySection(controller, responsive),
                  ),

                  SizedBox(height: responsive.spacing(20)),

                  _SectionCard(
                    title: 'Cor de Domínio',
                    subtitle: 'Esta cor representará seus territórios no mapa.',
                    child: _buildDomainColorSection(controller, responsive),
                  ),

                  SizedBox(height: responsive.spacing(30)),

                  _buildSaveButton(controller, responsive),

                  SizedBox(height: responsive.spacing(40)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildHeroHeader(
  BuildContext context,
  EditProfileController controller,
  Responsive responsive,
  UserModel? user,
) {
  return Obx(() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsive.spacing(24)),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: responsive.containerSize(130),
                height: responsive.containerSize(130),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(
                    color: user?.colorAsColor ?? AppColors.primary,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: controller.selectedPhotoBytes.value != null
                      ? Image.file(
                          controller.selectedPhotoBytes.value!,
                          fit: BoxFit.cover,
                        )
                      : (user?.photoUrl != null
                            ? Image.network(user!.photoUrl!, fit: BoxFit.cover)
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: AppColors.white,
                              )),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: controller.selectPhoto,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          user?.colorAsColor?.withOpacity(0.5) ??
                              AppColors.white.withOpacity(0.35),
                          user?.colorAsColor?.withOpacity(0.5) ??
                              AppColors.white.withOpacity(0.05),
                        ],
                      ),
                      border: Border.all(color: AppColors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user?.name ?? '',
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '@${user?.username ?? ''}',
            style: TextStyle(color: AppColors.textPrimary.withOpacity(0.7)),
          ),
        ],
      ),
    );
  });
}

Widget _buildNameField(
  EditProfileController controller,
  Responsive responsive,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Nome',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller.nameController,
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceDark,

          prefixIcon: const Icon(Icons.person, color: AppColors.white),
          hintText: 'Digite seu nome',
          hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
        ),
      ),
    ],
  );
}

/// Constrói o campo de username
Widget _buildUsernameField(
  EditProfileController controller,
  Responsive responsive,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Username',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller.usernameController,
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
        style: const TextStyle(color: AppColors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          prefixText: '@ ',
          prefixStyle: const TextStyle(color: AppColors.white),
          hintText: 'username',
          hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
        ),
      ),
    ],
  );
}

/// Constrói o campo de biografia
Widget _buildBiographyField(
  EditProfileController controller,
  Responsive responsive,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Biografia',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller.biographyController,
        style: const TextStyle(color: AppColors.white),
        maxLines: 4,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintText: 'Conte um pouco sobre você...',
          hintStyle: TextStyle(color: AppColors.textPrimary.withOpacity(0.5)),
        ),
      ),
    ],
  );
}

/// Constrói a seção de segurança
Widget _buildSecuritySection(
  EditProfileController controller,
  Responsive responsive,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Segurança',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 20),
      // Campo Nova Senha
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nova Senha',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextField(
              controller: controller.newPasswordController,
              obscureText: !controller.isPasswordVisible.value,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: AppColors.white,
                  ),
                  onPressed: () => controller.togglePasswordVisibility(),
                ),
                hintText: '••••••••••',
                hintStyle: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      // Campo Confirmar Senha
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmar Senha',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => TextField(
              controller: controller.confirmPasswordController,
              obscureText: !controller.isConfirmPasswordVisible.value,
              style: const TextStyle(color: AppColors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                hintText: '••••••••••',
                hintStyle: TextStyle(
                  color: AppColors.textPrimary.withOpacity(0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(color: AppColors.textPrimary.withOpacity(0.6)),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

Widget _buildDomainColorSection(
  EditProfileController controller,
  Responsive responsive,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Cor de Domínio',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          /*  TextButton(
              onPressed: () {
                // TODO: Navegar para o mapa para ver a cor
                Get.snackbar(
                  'Em breve',
                  'Visualização no mapa em desenvolvimento',
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.loginInputBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Visto no mapa',
                  style: TextStyle(
                    color: AppColors.loginPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),*/
        ],
      ),
      const SizedBox(height: 12),
      Text(
        'Esta cor representará seus territórios conquistados no mapa para outros jogadores.',
        style: TextStyle(
          color: AppColors.textPrimary.withOpacity(0.5),
          fontSize: 14,
        ),
      ),
      const SizedBox(height: 20),
      // Paleta de cores
      Obx(
        () => Wrap(
          spacing: 20, // Espaçamento horizontal entre as cores
          runSpacing: 12, // Espaçamento vertical entre as linhas
          alignment: WrapAlignment.start,
          children: controller.availableColors.map((colorHex) {
            final isSelected = controller.selectedColor.value == colorHex;
            return GestureDetector(
              onTap: () => controller.selectColor(colorHex),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _hexToColor(colorHex),
                  border: Border.all(color: AppColors.white, width: 3),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: _hexToColor(colorHex).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 24)
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    ],
  );
}

/// Constrói o botão de salvar alterações
Widget _buildSaveButton(
  EditProfileController controller,
  Responsive responsive,
) {
  return Obx(
    () => GestureDetector(
      onTap: controller.isLoading.value ? null : () => controller.saveProfile(),

      child: controller.isLoading.value
          ? const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : Container(
              width: double.infinity,
              height: responsive.containerSize(55),
              decoration: BoxDecoration(
                gradient: AppColors.successGradient,
                borderRadius: BorderRadius.circular(responsive.spacing(12)),
              ),
              child: Center(
                child: Text(
                  'Salvar Alterações',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    ),
  );
}

/// Converte string hexadecimal para Color
Color _hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

PreferredSizeWidget _buildAppBar(
  BuildContext context,
  EditProfileController controller,
  Responsive responsive,
) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    leading: IconButton(
      icon: Icon(
        Icons.arrow_back,
        color: AppColors.white,
        size: responsive.iconSize(24),
      ),
      onPressed: () => controller.cancel(),
    ),
    title: Text(
      'Editar Perfil',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: responsive.fontSize(20),
        fontWeight: FontWeight.bold,
      ),
    ),
    centerTitle: true,
    actions: [
      TextButton(
        onPressed: () => controller.cancel(),
        child: Text(
          'Cancelar',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(16),
          ),
        ),
      ),
    ],
  );
}
