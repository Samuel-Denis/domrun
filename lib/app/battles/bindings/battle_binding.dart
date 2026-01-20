import 'package:get/get.dart';
import 'package:nur_app/app/battles/controller/battle_controller.dart';
import 'package:nur_app/app/battles/service/battle_service.dart';

/// Binding para o módulo de batalhas
/// Configura as dependências do módulo usando GetX
class BattleBinding extends Bindings {
  @override
  void dependencies() {
    // Registra o BattleService se ainda não estiver registrado
    if (!Get.isRegistered<BattleService>()) {
      Get.put<BattleService>(BattleService(), permanent: true);
    }

    // Registra o BattleController
    Get.lazyPut<BattleController>(() => BattleController(), fenix: true);
  }
}
