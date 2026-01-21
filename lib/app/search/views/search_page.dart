import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:domrun/app/navigation/controller/navigation_controller.dart';
import 'package:domrun/core/theme/app_colors.dart';
import 'package:domrun/core/utils/responsive.dart';

/// Página de busca do aplicativo
/// Exibe a tela de search
/// Totalmente responsiva para diferentes tamanhos de tela
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    // Atualiza o índice da navegação para Search (3)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navController = Get.find<NavigationController>();
      if (navController.currentIndex.value != 3) {
        navController.currentIndex.value = 3;
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Minhas Corridas',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(20),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCardStats(responsive),
              _buildCardStats(responsive),
              _buildCardStats(responsive),
            ],
          ),
        ),
      ),

      // Barra de navegação inferior fixa usando Scaffold
    );
  }

  Widget _buildCardStats(Responsive responsive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(2)),
      width: responsive.width * 0.30,
      height: responsive.height * 0.15,
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.spacing(12)),
        border: Border.all(color: AppColors.textPrimary.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Total de Corridas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(12),
            ),
          ),
          Text(
            'Minhas Corridas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(12),
            ),
          ),
          Text(
            'Minhas Corridas',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: responsive.fontSize(12),
            ),
          ),
        ],
      ),
    );
  }
}
