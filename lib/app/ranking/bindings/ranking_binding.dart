import 'package:get/get.dart';
import 'package:domrun/app/ranking/controller/ranking_controller.dart';
import 'package:domrun/app/ranking/service/ranking_service.dart';

/// Binding para o módulo de ranking
class RankingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RankingService>(() => RankingService());
    Get.lazyPut<RankingController>(
      () => RankingController(Get.find<RankingService>()),
    );
  }
}
