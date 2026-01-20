import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/achievement/local/data/achievements_data.dart';
import 'package:nur_app/app/achievement/local/models/achievement_definition.dart';
import 'package:nur_app/app/achievement/local/models/achievement_model.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:nur_app/core/services/http_service.dart';
import 'package:nur_app/core/services/storage_service.dart';

/// Serviço para gerenciar conquistas localmente
/// As conquistas são salvas localmente e apenas enviadas ao backend quando concluídas
class AchievementService extends GetxService {
  late final StorageService _storage;
  late final UserService _userService;
  late final HttpService _httpService;

  // Chave para armazenamento local do progresso de conquistas
  static const String _userAchievementsKey = 'user_achievements_progress';
  static const String _completedAchievementsKey = 'user_achievements_completed';

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _httpService = Get.find<HttpService>();
    _userService = Get.find<UserService>();
  }

  /// Obtém todas as conquistas com status do usuário
  /// Retorna lista de AchievementModel com status baseado no progresso local
  Future<List<AchievementModel>> getUserAchievements() async {
    final definitions = await AchievementsData.getAllAchievements();
    final progressMap = _getProgressMap();
    final completedIds = _getCompletedAchievementIds();

    return definitions.map((def) {
      final achievementId = def.id;
      final isCompleted = completedIds.contains(achievementId);
      final progress = progressMap[achievementId] ?? 0.0;

      AchievementStatus status;
      double? progressValue;
      String? progressText;

      if (isCompleted) {
        status = AchievementStatus.completed;
      } else {
        // Para conquistas não completadas, sempre mostrar progresso
        progressValue = progress.clamp(0.0, 1.0);
        progressText = '${(progress * 100).toInt()}%';
        // Define status baseado no progresso
        if (progress > 0.0) {
          status = AchievementStatus.inProgress;
        } else {
          status = AchievementStatus.locked;
        }
      }

      return AchievementModel(
        id: achievementId,
        title: def.name,
        description: def.description,
        medal: def.medal,
        icon: _getAchievementImage(def.medal, status),
        status: status,
        progress: progressValue,
        progressText: progressText,
      );
    }).toList();
  }

  /// Obtém todas as conquistas agrupadas por categoria
  /// Retorna um Map onde a chave é o nome da categoria (Explorador, Atleta, etc.)
  /// e o valor é a lista de AchievementModel dessa categoria
  Future<Map<String, List<AchievementModel>>>
  getUserAchievementsByCategory() async {
    final progressMap = _getProgressMap();
    final completedIds = _getCompletedAchievementIds();
    final Map<String, List<AchievementModel>> grouped = {};

    try {
      // Carrega o JSON do asset
      final String jsonString = await rootBundle.loadString(
        'assets/data/cq.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString) as List<dynamic>;

      // Itera sobre as categorias
      for (final categoryData in jsonData) {
        final Map<String, dynamic> categoryMap =
            categoryData as Map<String, dynamic>;
        final String categoryName = categoryMap['category'] as String;
        final List<dynamic> conquistas =
            categoryMap['conquistas'] as List<dynamic>;

        final List<AchievementModel> categoryAchievements = [];

        // Converte cada conquista
        for (final conquistaJson in conquistas) {
          final Map<String, dynamic> conquistaMap =
              conquistaJson as Map<String, dynamic>;
          final AchievementDefinition def = AchievementDefinition.fromJson(
            conquistaMap,
          );

          final achievementId = def.id;
          final isCompleted = completedIds.contains(achievementId);
          final progress = progressMap[achievementId] ?? 0.0;

          AchievementStatus status;
          double? progressValue;
          String? progressText;

          if (isCompleted) {
            status = AchievementStatus.completed;
          } else {
            // Para conquistas não completadas, sempre mostrar progresso
            progressValue = progress.clamp(0.0, 1.0);
            progressText = '${(progress * 100).toInt()}%';
            // Define status baseado no progresso
            if (progress > 0.0) {
              status = AchievementStatus.inProgress;
            } else {
              status = AchievementStatus.locked;
            }
          }

          categoryAchievements.add(
            AchievementModel(
              id: achievementId,
              title: def.name,
              description: def.description,
              medal: def.medal,
              icon: _getAchievementImage(def.medal, status),
              status: status,
              progress: progressValue,
              progressText: progressText,
            ),
          );
        }

        grouped[categoryName] = categoryAchievements;
      }

      return grouped;
    } catch (e) {
      print('Erro ao carregar conquistas agrupadas por categoria: $e');
      return {};
    }
  }

  /// Atualiza o progresso de uma conquista localmente
  /// [achievementId] - ID da conquista
  /// [progress] - Progresso (0.0 a 1.0)
  /// [syncToBackend] - Se true, sincroniza com o backend (padrão: true)
  Future<void> updateAchievementProgress(
    String achievementId,
    double progress, {
    bool syncToBackend = true,
  }) async {
    final progressMap = _getProgressMap();
    final previousProgress = progressMap[achievementId] ?? 0.0;
    final normalizedProgress = progress.clamp(0.0, 1.0);

    final completedIds = _getCompletedAchievementIds();
    final isAlreadyCompleted = completedIds.contains(achievementId);

    if (normalizedProgress == previousProgress &&
        (normalizedProgress < 1.0 || isAlreadyCompleted)) {
      return;
    }

    print('📝 [ACHIEVEMENTS] updateAchievementProgress: $achievementId');
    print(
      '   - Progresso anterior: ${(previousProgress * 100).toStringAsFixed(1)}%',
    );
    print(
      '   - Progresso novo: ${(normalizedProgress * 100).toStringAsFixed(1)}%',
    );

    progressMap[achievementId] = normalizedProgress;
    await _saveProgressMap(progressMap);
    print('   ✅ Progresso salvo localmente');

    // Se a conquista foi completada, marca como concluída
    if (normalizedProgress >= 1.0) {
      print('   🎉 Conquista completada! Marcando como concluída...');
      await _markAsCompleted(achievementId);
    }

    // Sincroniza com o backend se solicitado
    if (syncToBackend) {
      try {
        print('   🔄 Sincronizando com backend...');
        await syncProgressToBackend();
        print('   ✅ Sincronização concluída');
      } catch (e) {
        print('   ⚠️ Erro ao sincronizar progresso com backend: $e');
        // Não lança erro - progresso já foi salvo localmente
      }
    }
  }

  /// Marca uma conquista como completada localmente
  Future<void> _markAsCompleted(String achievementId) async {
    final completedIds = _getCompletedAchievementIds();
    if (!completedIds.contains(achievementId)) {
      completedIds.add(achievementId);
      await _saveCompletedAchievementIds(completedIds);
      print('   ✅ Conquista $achievementId marcada como completada localmente');
    }
  }

  /// Obtém o progresso de uma conquista específica
  double getAchievementProgress(String achievementId) {
    final progressMap = _getProgressMap();
    return progressMap[achievementId] ?? 0.0;
  }

  /// Verifica se uma conquista está completada
  bool isAchievementCompleted(String achievementId) {
    final completedIds = _getCompletedAchievementIds();
    return completedIds.contains(achievementId);
  }

  /// Reseta todas as conquistas (para debug ou reset de conta)
  Future<void> resetAllAchievements() async {
    await _storage.storage.remove(_userAchievementsKey);
    await _storage.storage.remove(_completedAchievementsKey);
    print('🔄 Todas as conquistas foram resetadas');
  }

  /// Sincroniza progresso de conquistas com backend
  Future<void> syncProgressToBackend() async {
    try {
      print('🔄 Sincronizando conquistas com backend...');

      final progressMap = _getProgressMap();
      final completedIds = _getCompletedAchievementIds();

      // Prepara dados para envio
      final achievementsData = progressMap.entries
          .map(
            (entry) => {
              'achievementId': entry.key,
              'progress': entry.value,
              'completed': completedIds.contains(entry.key),
            },
          )
          .toList();

      // Envia para backend
      final response = await _httpService.post(
        '/users/achievements/sync',
        {'achievements': achievementsData},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Conquistas sincronizadas com sucesso');
      } else {
        print(
          '⚠️ Falha ao sincronizar conquistas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('⚠️ Erro ao sincronizar conquistas: $e');
    }
  }

  /// Busca progresso de conquistas do backend e mescla com o local
  Future<void> fetchProgressFromBackend() async {
    try {
      final response = await _httpService.get('/users/achievements/progress');
      if (response.statusCode != 200) {
        return;
      }

      final decoded = json.decode(response.body);
      final Map<String, double> progressMap = _getProgressMap();
      final Set<String> completedIds =
          _getCompletedAchievementIds().toSet();

      List<dynamic> items = [];
      if (decoded is Map && decoded['achievements'] is List) {
        items = decoded['achievements'] as List<dynamic>;
      } else if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded['progress'] is Map) {
        final progress = decoded['progress'] as Map<String, dynamic>;
        progress.forEach((key, value) {
          final progressValue =
              (value is num) ? value.toDouble() : double.tryParse('$value');
          if (progressValue != null) {
            progressMap[key] = progressValue;
          }
        });
        await _saveProgressMap(progressMap);
        return;
      }

      for (final item in items) {
        if (item is! Map) continue;
        final id = item['achievementId'] ?? item['id'];
        if (id == null) continue;
        final progressValue = item['progress'];
        final completedFlag = item['completed'];
        final statusValue = item['status'];

        final progress = (progressValue is num)
            ? progressValue.toDouble()
            : double.tryParse('$progressValue');
        if (progress != null) {
          progressMap[id.toString()] = progress;
        }

        final isCompleted = completedFlag == true ||
            (statusValue is String &&
                statusValue.toLowerCase() == 'completed');
        if (isCompleted) {
          completedIds.add(id.toString());
        }
      }

      await _saveProgressMap(progressMap);
      await _saveCompletedAchievementIds(completedIds.toList());
    } catch (e) {
      print('⚠️ Erro ao buscar progresso de conquistas: $e');
    }
  }

  /// Checa e atualiza conquistas com base em métricas atuais
  Future<void> checkAndUpdateAchievements({
    int? level,
    int? runCount,
    double? totalDistance,
    int? territoryCount,
    double? totalArea,
  }) async {
    try {
      final definitions = await AchievementsData.getAllAchievements();
      bool didUpdate = false;

      for (final def in definitions) {
        final goalValue = (def.goalValue is num)
            ? (def.goalValue as num).toDouble()
            : double.tryParse('${def.goalValue}');

        if (goalValue == null || goalValue <= 0) continue;

        double? progress;
        switch (def.goalType) {
          case 'level':
            if (level != null) {
              progress = level / goalValue;
            }
            break;
          case 'distance_accumulated':
            if (totalDistance != null) {
              progress = totalDistance / goalValue;
            }
            break;
          case 'territory_count':
            if (territoryCount != null) {
              progress = territoryCount / goalValue;
            }
            break;
          case 'area_count':
            if (totalArea != null) {
              progress = totalArea / goalValue;
            }
            break;
          case 'run_count':
            if (runCount != null) {
              progress = runCount / goalValue;
            }
            break;
          default:
            break;
        }

        if (progress == null) continue;
        await updateAchievementProgress(
          def.id,
          progress,
          syncToBackend: false,
        );
        didUpdate = true;
      }

      if (didUpdate) {
        await syncProgressToBackend();
      }
    } catch (e) {
      print('⚠️ Erro ao atualizar conquistas: $e');
    }
  }

  /// Atualiza conquistas baseadas em distância percorrida
  Future<void> updateDistanceAchievements(double distanceInMeters) async {
    final userId = _userService.currentUser.value?.id;
    if (userId == null) return;

    // Lógica para atualizar conquistas de distância
    // Isso deve ser implementado baseado no JSON de conquistas
  }

  /// Atualiza conquistas baseadas em territórios capturados
  Future<void> updateTerritoryAchievements(int territoriesCount) async {
    final userId = _userService.currentUser.value?.id;
    if (userId == null) return;

    // Lógica para atualizar conquistas de território
    // Isso deve ser implementado baseado no JSON de conquistas
  }

  /// Obtém mapa de progresso de conquistas do storage
  Map<String, double> _getProgressMap() {
    final progressJson =
        _storage.storage.read<String>(_userAchievementsKey);
    if (progressJson == null) return {};

    try {
      final Map<String, dynamic> decoded =
          json.decode(progressJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value as double));
    } catch (e) {
      print('Erro ao carregar progresso de conquistas: $e');
      return {};
    }
  }

  /// Salva mapa de progresso de conquistas no storage
  Future<void> _saveProgressMap(Map<String, double> progressMap) async {
    await _storage.storage.write(_userAchievementsKey, json.encode(progressMap));
  }

  /// Obtém IDs de conquistas completadas do storage
  List<String> _getCompletedAchievementIds() {
    final completedJson =
        _storage.storage.read<String>(_completedAchievementsKey);
    if (completedJson == null) return [];

    try {
      final List<dynamic> decoded = json.decode(completedJson) as List<dynamic>;
      return decoded.cast<String>();
    } catch (e) {
      print('Erro ao carregar conquistas completadas: $e');
      return [];
    }
  }

  /// Salva IDs de conquistas completadas no storage
  Future<void> _saveCompletedAchievementIds(List<String> ids) async {
    await _storage.storage.write(
      _completedAchievementsKey,
      json.encode(ids),
    );
  }

  /// Retorna o ícone da conquista baseado no medal e status
  String _getAchievementImage(String medal, AchievementStatus status) {
    if (status != AchievementStatus.completed) {
      return 'assets/medal/default.png';
    }

    switch (medal.toLowerCase()) {
      case 'bronze':
        return 'assets/medal/bronze.png';
      case 'silver':
        return 'assets/medal/silver.png';
      case 'gold':
        return 'assets/medal/gold.png';
      case 'legendary':
      case 'lenda':
        return 'assets/medal/lenda.png';
      default:
        return 'assets/medal/default.png';
    }
  }
}
