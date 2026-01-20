import 'package:get/get.dart';
import 'package:nur_app/app/maps/controller/controller.dart';
import 'package:nur_app/app/maps/service/territory_service.dart';
import 'package:nur_app/app/profile/service/achievement_service.dart';

/// Binding para o módulo de mapas
/// Configura as dependências do módulo usando GetX
/// Garante que os serviços sejam inicializados antes do controller
class MapBinding extends Bindings {
  @override
  void dependencies() {
    // IMPORTANTE: Inicializa os serviços ANTES do controller
    // O TerritoryService precisa do StorageService (já registrado no main.dart)
    // e precisa estar totalmente inicializado antes do MapController
    
    // Verifica se o TerritoryService já existe, se não, cria
    if (!Get.isRegistered<TerritoryService>()) {
      // Cria o serviço - o GetX vai chamar o onInit() automaticamente
      // O onInit() é assíncrono, mas o GetX gerencia isso
      // Usa Get.put() para garantir que seja criado imediatamente
      Get.put<TerritoryService>(TerritoryService(), permanent: true);
    }
    
    // Registra o AchievementService se ainda não estiver registrado
    // Necessário para atualizar conquistas quando territórios são capturados
    if (!Get.isRegistered<AchievementService>()) {
      Get.put<AchievementService>(AchievementService(), permanent: true);
    }
    
    // Registra o MapController como um controller permanente
    // O controller vai acessar os serviços no onInit() assíncrono
    // Usa lazyPut para que seja criado apenas quando necessário
    // IMPORTANTE: O TerritoryService já deve estar registrado acima
    // O MapController.onInit() vai aguardar explicitamente que os serviços estejam prontos
    Get.lazyPut<MapController>(() => MapController(), fenix: true);
  }
}
