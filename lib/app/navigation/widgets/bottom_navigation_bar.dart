import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

/// Barra de navegação inferior customizada
/// Estilo moderno com bordas arredondadas e ícones destacados
/// Permite navegar entre as páginas principais do aplicativo

class BottomNavigationBarWidget extends GetView<NavigationController> {
  const BottomNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return Obx(() {
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
              svgPath: 'assets/images/icon_home.svg',
              itemIndex: 0,
              controller: controller,
              responsive: responsive,
            ),
            _buildNavButton(
              svgPath: 'assets/images/icon_map.svg',
              itemIndex: 1,
              controller: controller,
              responsive: responsive,
            ),
            _buildNavButton(
              svgPath: 'assets/images/icon_ranking.svg',
              itemIndex: 2,
              controller: controller,
              responsive: responsive,
            ),
            _buildNavButton(
              svgPath: 'assets/images/icon_person.svg',
              itemIndex: 3,
              controller: controller,
              responsive: responsive,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNavButton({
    required String svgPath,
    required int itemIndex,
    required NavigationController controller,
    required Responsive responsive,
  }) {
    final isSelected = controller.currentIndex.value == itemIndex;
    final selectedColor = isSelected
        ? AppColors.white
        : AppColors.white.withOpacity(0.6);

    return SizedBox(
      width: responsive.width * 0.18,
      height: double.infinity,
      child: InkWell(
        onTap: () => controller.navigateToPage(itemIndex),
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
          ],
        ),
      ),
    );
  }
}
