import 'package:get/get.dart';
import 'package:nur_app/routes/app_routes.dart';

/// Controller para gerenciar a navegação entre as páginas principais
/// Controla qual página está ativa na barra de navegação inferior
class NavigationController extends GetxController {
  // Índice da página atual (0 = Home, 1 = Mapa, 2 = Ranking, 3 = Search, 4 = Perfil)
  var currentIndex = 0.obs; // Começa no mapa (página principal)

  // Rotas correspondentes a cada índice
  final List<String> routes = [
    AppRoutes.achievements,
    AppRoutes.map,
    AppRoutes.ranking,
    AppRoutes.profile,
  ];

  /// Navega para uma página específica pelo índice
  /// [index] - Índice da página (0-1)
  /// Usa Get.offNamed para substituir a página atual e evitar empilhamento
  void navigateToPage(int index) {
    final safeIndex = index.clamp(0, routes.length - 1);
    if (currentIndex.value == safeIndex) return;
    currentIndex.value = safeIndex;
    Get.offNamed(routes[safeIndex]);
  }

  /// Navega para a página Home
  void goToHome() {
    navigateToPage(0);
  }

  /// Navega para a página do Mapa
  void goToMap() {
    navigateToPage(1);
  }

  /// Navega para a página de Ranking
  void goToRanking() {
    navigateToPage(2);
  }

  /// Navega para a página de Search
  void goToSearch() {
    navigateToPage(3);
  }

  /// Navega para a página de Perfil
  void goToProfile() {
    navigateToPage(4);
  }
}
