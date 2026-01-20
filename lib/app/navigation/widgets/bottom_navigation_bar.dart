import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/navigation/controller/navigation_controller.dart';
import 'package:nur_app/app/maps/controller/controller.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';

/// Barra de navegação inferior customizada
/// Estilo moderno com bordas arredondadas e ícones destacados
/// Permite navegar entre as páginas principais do aplicativo
class BottomNavigationBarWidget extends StatelessWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final navigationController = Get.find<NavigationController>();
    final mapController = Get.isRegistered<MapController>()
        ? Get.find<MapController>()
        : null;

    return Obx(() {
      final isDisabled =
          (mapController?.isRunSummaryLoading.value ?? false) ||
          (mapController?.isRunSummaryVisible.value ?? false);
      return Container(
        margin: EdgeInsets.only(
          left: responsive.width * 0.02,
          right: responsive.width * 0.02,
          bottom: responsive.spacing(10),
        ),
        width: double.infinity,
        height: responsive.buttonHeight(70),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(responsive.spacing(20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildNavButton(
              context: context,
              svgPath: 'assets/images/icon_home.svg',
              index: 0,
              controller: navigationController,
              responsive: responsive,
            ),
            _buildNavButton(
              context: context,
              svgPath: 'assets/images/icon_map.svg',
              index: 1,
              controller: navigationController,
              responsive: responsive,
            ),
            _buildNavButton(
              context: context,
              svgPath: 'assets/images/icon_ranking.svg',
              index: 2,
              controller: navigationController,
              responsive: responsive,
            ),
            /*   _buildNavButton(
              context: context,
              svgPath: 'assets/images/icon_search.svg',
              index: 3,
              controller: navigationController,
              responsive: responsive,
            ), */
            _buildNavButton(
              context: context,
              svgPath: 'assets/images/icon_person.svg',
              index: 3,
              controller: navigationController,
              responsive: responsive,
            ),
          ],
        ),
      );
    });
  }

  /// Constrói um botão de navegação
  Widget _buildNavButton({
    required BuildContext context,
    required String svgPath,
    required int index,
    required NavigationController controller,
    required Responsive responsive,
  }) {
    final isSelected = controller.currentIndex.value == index;
    final selectedColor = isSelected
        ? AppColors.white
        : AppColors.white.withOpacity(0.6); // Cor quando não selecionado

    return Container(
      color: Colors.transparent,
      width: responsive.width * 0.18,
      height: double.infinity,
      child: InkWell(
        onTap: () {
          controller.navigateToPage(index);
        },
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.only(bottom: responsive.spacing(4)),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? AppColors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: SvgPicture.asset(
                svgPath,
                width: isSelected
                    ? responsive.iconSize(30)
                    : responsive.iconSize(20),
                height: isSelected
                    ? responsive.iconSize(30)
                    : responsive.iconSize(20),
                color: selectedColor,
              ),
            ),
            //  Icon(icon, size: responsive.iconSize(30), color: selectedColor),
          ],
        ),
      ),
    );
  }
}
