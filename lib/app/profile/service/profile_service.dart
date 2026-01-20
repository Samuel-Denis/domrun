import 'dart:convert';
import 'package:get/get.dart';
import 'package:domrun/app/achievement/local/models/achievement_model.dart';
import 'package:domrun/app/profile/models/user_stats_model.dart';
import 'package:domrun/app/achievement/local/service/achievement_service.dart';
import 'package:domrun/core/constants/api_constants.dart';
import 'package:domrun/core/services/http_service.dart';

/// Serviço para gerenciar dados do perfil do usuário
/// Busca estatísticas e conquistas da API
class ProfileService extends GetxService {
  late final AchievementService? _achievementService;
  late final HttpService _httpService;

  @override
  void onInit() {
    super.onInit();
    _httpService = Get.find<HttpService>();
    // Tenta obter AchievementService se estiver registrado
    if (Get.isRegistered<AchievementService>()) {
      _achievementService = Get.find<AchievementService>();
    }
  }

  /// Busca as estatísticas do usuário da API
  /// Retorna UserStatsModel com os dados do servidor
  /// Por enquanto retorna dados estáticos, mas está preparado para receber da API
  Future<UserStatsModel> getUserStats() async {
    try {
      // TODO: Implementar chamada real à API quando estiver disponível
      final response = await _httpService.get('/users/profile/stats');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return UserStatsModel.fromJson(data['stats'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Erro ao buscar estatísticas: Status ${response.statusCode}',
        );
      }

      // DADOS ESTÁTICOS - Será substituído por dados da API
      // Retorno temporário com dados estáticos. Remover quando a integração com a API estiver finalizada.
    } catch (e) {
      // Em caso de erro, retorna dados estáticos
      return UserStatsModel(
        totalDistance: 0.0,
        territoryPercentageKm2: 0.0,
        totalTerritoryAreaM2: 0.0,
        totalRuns: 0,
        totalTerritories: 0,
        averagePace: 0.0,
        totalTime: 0,
        longestRun: 0.0,
        currentStreak: 0,
      );
    }
  }

  Future<Map<String, dynamic>> getCompleteProfile() async {
    final response = await _httpService.get(
      ApiConstants.profileCompleteEndpoint,
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar perfil: ${response.statusCode}');
    }
    return json.decode(response.body) as Map<String, dynamic>;
  }

  /// Busca as conquistas do usuário
  /// Usa AchievementService para obter conquistas salvas localmente
  /// As conquistas concluídas são sincronizadas com o backend
  Future<List<AchievementModel>> getUserAchievements() async {
    try {
      // Se AchievementService estiver disponível, usa ele
      if (_achievementService != null) {
        return await _achievementService.getUserAchievements();
      }

      // Fallback: retorna lista vazia se o serviço não estiver disponível
      return [];
    } catch (e) {
      print('Erro ao buscar conquistas: $e');
      // Em caso de erro, retorna lista vazia
      return [];
    }
  }
}
