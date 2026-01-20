import 'package:get/get.dart';
import 'package:domrun/app/achievement/controller/achievement_controller.dart';
import 'package:domrun/app/achievement/service/achievement_api_service.dart';

class AchievementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AchievementApiService>(
      () => AchievementApiService(),
      fenix: true,
    );
    Get.lazyPut<AchievementsController>(() => AchievementsController());
  }
}
