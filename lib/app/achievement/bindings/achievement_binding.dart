import 'package:get/get.dart';
import 'package:nur_app/app/achievement/controller/achievement_controller.dart';

class AchievementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AchievementsController>(() => AchievementsController());
  }
}
