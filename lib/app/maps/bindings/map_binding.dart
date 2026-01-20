import 'package:get/get.dart';
import 'package:domrun/app/maps/controller/controller.dart';
import 'package:domrun/app/maps/service/territory_service.dart';
import 'package:domrun/app/achievement/local/service/achievement_service.dart';
import 'package:domrun/app/maps/usecases/run_save_usecase.dart';
import 'package:domrun/app/maps/usecases/run_stop_preparation_usecase.dart';

/// Binding para o módulo de mapas
/// Configura as dependências do módulo usando GetX
/// Garante que os serviços sejam inicializados antes do controller
class MapBinding extends Bindings {
  @override
  void dependencies() {
    // IMPORTANTE: Inicializa os serviços ANTES do controller
    // O TerritoryService precisa do StorageService (já registrado no main.dart)
    // e precisa estar totalmente inicializado antes do MapController
    
    // Verifica se o TerritoryService já existe, se não, registra
    if (!Get.isRegistered<TerritoryService>()) {
      Get.lazyPut<TerritoryService>(() => TerritoryService(), fenix: true);
    }
    
    // Registra o AchievementService se ainda não estiver registrado
    // Necessário para atualizar conquistas quando territórios são capturados
    if (!Get.isRegistered<AchievementService>()) {
      Get.lazyPut<AchievementService>(() => AchievementService(), fenix: true);
    }

    if (!Get.isRegistered<RunStopPreparationUseCase>()) {
      Get.lazyPut<RunStopPreparationUseCase>(
        () => RunStopPreparationUseCase(),
        fenix: true,
      );
    }

    if (!Get.isRegistered<RunSaveUseCase>()) {
      Get.lazyPut<RunSaveUseCase>(
        () => RunSaveUseCase(Get.find<TerritoryService>()),
        fenix: true,
      );
    }
    
    // Registra o MapController como um controller permanente
    // O controller vai acessar os serviços no onInit() assíncrono
    // Usa lazyPut para que seja criado apenas quando necessário
    // IMPORTANTE: O TerritoryService já deve estar registrado acima
    // O MapController.onInit() vai aguardar explicitamente que os serviços estejam prontos
    Get.lazyPut<MapController>(() => MapController(), fenix: true);
  }
}
