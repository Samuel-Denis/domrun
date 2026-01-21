import 'package:get/get.dart';
import 'package:domrun/routes/app_routes.dart';

class NavigationController extends GetxController {
  /// 0 = Achievements/Home, 1 = Map, 2 = Ranking, 3 = Profile
  final currentIndex = 0.obs;

  final List<String> routes = [
    AppRoutes.achievements,
    AppRoutes.map,
    AppRoutes.ranking,
    AppRoutes.profile,
  ];

  void navigateToPage(int index) {
    final safeIndex = index.clamp(0, routes.length - 1);
    if (currentIndex.value == safeIndex) return;

    currentIndex.value = safeIndex;
    Get.offNamed(routes[safeIndex]);
  }

  /// Chame isso quando abrir uma rota (middleware recomendado)
  void syncIndexWithCurrentRoute() {
    final route = Get.currentRoute;

    final idx = routes.indexOf(route);
    if (idx != -1 && idx != currentIndex.value) {
      currentIndex.value = idx;
    }
  }

  void goToAchievements() => navigateToPage(0);
  void goToMap() => navigateToPage(1);
  void goToRanking() => navigateToPage(2);
  void goToProfile() => navigateToPage(3);
}
