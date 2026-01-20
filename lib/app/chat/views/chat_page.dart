import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/navigation/controller/navigation_controller.dart';
import 'package:nur_app/app/navigation/widgets/bottom_navigation_bar.dart';
import 'package:nur_app/core/theme/app_colors.dart';
import 'package:nur_app/core/utils/responsive.dart';

/// Página de chat do aplicativo
/// Exibe conversas e mensagens
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    // Atualiza o índice da navegação para Chat (3)
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
        title: Text(
          'Chat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(20),
          ),
        ),
      ),
      body: Center(
        child: Text(
          'Página de Chat',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: responsive.fontSize(24),
          ),
        ),
      ),
      // Barra de navegação inferior fixa usando Scaffold
      bottomNavigationBar: const BottomNavigationBarWidget(),
    );
  }
}
