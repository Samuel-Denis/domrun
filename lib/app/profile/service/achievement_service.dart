import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nur_app/app/auth/service/auth_service.dart';
import 'package:nur_app/app/profile/data/achievements_data.dart';
import 'package:nur_app/app/profile/models/achievement_definition.dart';
import 'package:nur_app/app/profile/models/achievement_model.dart';
import 'package:nur_app/app/user/service/user_service.dart';
import 'package:nur_app/core/constants/api_constants.dart';
import 'package:nur_app/core/services/storage_service.dart';
import 'package:http/http.dart' as http;

/// Serviço para gerenciar conquistas localmente
/// As conquistas são salvas localmente e apenas enviadas ao backend quando concluídas
class AchievementService extends GetxService {
  late final StorageService _storage;
  late final AuthService _authService;
  late final UserService _userService;

  // Chave para armazenamento local do progresso de conquistas
  static const String _userAchievementsKey = 'user_achievements_progress';
  static const String _completedAchievementsKey = 'user_achievements_completed';

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _authService = Get.find<AuthService>();
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

  /// Marca uma conquista como concluída
  /// Envia para o backend e salva localmente
  Future<void> _markAsCompleted(String achievementId) async {
    final completedIds = _getCompletedAchievementIds();

    // Se já está completa, não faz nada
    if (completedIds.contains(achievementId)) {
      return;
    }

    // Adiciona aos completos localmente
    completedIds.add(achievementId);
    await _saveCompletedAchievementIds(completedIds);

    // Envia para o backend
    try {
      await _syncCompletedAchievementToBackend(achievementId);
    } catch (e) {
      print('Erro ao sincronizar conquista com backend: $e');
      // Não lança erro - a conquista já foi salva localmente
    }
  }

  /// Sincroniza uma conquista concluída com o backend
  /// Este método é chamado quando uma conquista atinge 100%
  /// Também sincroniza via endpoint de progresso, mas este é um método adicional
  Future<void> _syncCompletedAchievementToBackend(String achievementId) async {
    final accessToken = _storage.getAccessToken();
    if (accessToken == null) {
      print(
        '⚠️ Token de acesso não encontrado - não é possível sincronizar conquista completa',
      );
      return;
    }

    final user = _userService.currentUser.value;
    if (user == null) {
      print(
        '⚠️ Usuário não autenticado - não é possível sincronizar conquista completa',
      );
      return;
    }

    try {
      // Sincroniza via endpoint de conquistas completas (legado, ainda funciona)
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/achievements/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({'achievementId': achievementId, 'userId': user.id}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print(
          '✅ Conquista $achievementId sincronizada via endpoint de conquistas completas',
        );
      } else {
        print(
          '⚠️ Erro ao sincronizar conquista completa: Status ${response.statusCode}',
        );
        print('Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao sincronizar conquista completa: $e');
      // Não lança erro - a conquista já foi salva localmente e será sincronizada via progresso
    }
  }

  /// Obtém o mapa de progresso das conquistas
  Map<String, double> _getProgressMap() {
    final data = _storage.storage.read<Map<String, dynamic>>(
      _userAchievementsKey,
    );
    if (data == null) {
      return {};
    }
    return data.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }

  /// Salva o mapa de progresso
  Future<void> _saveProgressMap(Map<String, double> progressMap) async {
    await _storage.storage.write(_userAchievementsKey, progressMap);
  }

  /// Obtém lista de IDs de conquistas concluídas
  List<String> _getCompletedAchievementIds() {
    final data = _storage.storage.read<List<dynamic>>(
      _completedAchievementsKey,
    );
    if (data == null) {
      return [];
    }
    return data.cast<String>().toList();
  }

  /// Salva lista de IDs de conquistas concluídas
  Future<void> _saveCompletedAchievementIds(List<String> completedIds) async {
    await _storage.storage.write(_completedAchievementsKey, completedIds);
  }

  /// Obtém o caminho da imagem da conquista
  /// Retorna default.png quando não completou, ou a imagem da medalha quando completou
  String _getAchievementImage(String medal, AchievementStatus status) {
    // Se não completou, retorna imagem default
    if (status != AchievementStatus.completed) {
      return 'assets/medal/default.png';
    }

    // Se completou, retorna imagem da medalha
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

  /// Verifica e atualiza progresso de conquistas baseado em eventos
  /// Este método deve ser chamado quando eventos relevantes ocorrem
  /// Por exemplo: após uma corrida, após capturar território, etc.
  Future<void> checkAndUpdateAchievements({
    int? territoryCount,
    double? totalArea,
    double? totalDistance,
    int? runCount,
    int? level,
    // ... outros parâmetros conforme necessário
  }) async {
    print('🏆 [ACHIEVEMENTS] checkAndUpdateAchievements chamado');
    print('   - territoryCount: $territoryCount');
    print('   - totalArea: $totalArea');
    print('   - totalDistance: $totalDistance');
    print('   - runCount: $runCount');
    print('   - level: $level');

    try {
      final definitions = await AchievementsData.getAllAchievements();
      print(
        '📋 [ACHIEVEMENTS] Total de conquistas carregadas: ${definitions.length}',
      );

      int updatedCount = 0;
      int completedCount = 0;
      bool shouldSync = false;
      final progressMap = _getProgressMap();
      final completedIds = _getCompletedAchievementIds();

      for (final def in definitions) {
        double? newProgress;

        switch (def.goalType) {
          case 'territory_count':
            if (territoryCount != null) {
              // goalValue pode ser int ou double, converte para num primeiro
              final goal = (def.goalValue as num).toDouble();
              newProgress = (territoryCount / goal).clamp(0.0, 1.0);
              print(
                '   ✅ ${def.id} (${def.name}): territory_count - $territoryCount / $goal = ${(newProgress * 100).toStringAsFixed(1)}%',
              );
            } else {
              print(
                '   ⏭️  ${def.id} (${def.name}): territory_count - pulando (territoryCount é null)',
              );
            }
            break;
          case 'area_count':
            if (totalArea != null) {
              // goalValue pode ser int ou double, converte para num primeiro
              final goal = (def.goalValue as num).toDouble();
              newProgress = (totalArea / goal).clamp(0.0, 1.0);
              print(
                '   ✅ ${def.id} (${def.name}): area_count - ${totalArea.toStringAsFixed(2)} / $goal = ${(newProgress * 100).toStringAsFixed(1)}%',
              );
            } else {
              print(
                '   ⏭️  ${def.id} (${def.name}): area_count - pulando (totalArea é null)',
              );
            }
            break;
          case 'distance_accumulated':
            if (totalDistance != null) {
              final goal = (def.goalValue as num).toDouble();
              newProgress = (totalDistance / goal).clamp(0.0, 1.0);
              print(
                '   ✅ ${def.id} (${def.name}): distance_accumulated - ${totalDistance.toStringAsFixed(2)} / $goal = ${(newProgress * 100).toStringAsFixed(1)}%',
              );
            }
            break;
          case 'run_count':
            if (runCount != null) {
              final goal = (def.goalValue as num).toDouble();
              newProgress = (runCount / goal).clamp(0.0, 1.0);
              print(
                '   ✅ ${def.id} (${def.name}): run_count - $runCount / $goal = ${(newProgress * 100).toStringAsFixed(1)}%',
              );
            }
            break;
          case 'level':
            if (level != null) {
              final goal = (def.goalValue as num).toDouble();
              newProgress = (level / goal).clamp(0.0, 1.0);
              print(
                '   ✅ ${def.id} (${def.name}): level - $level / $goal = ${(newProgress * 100).toStringAsFixed(1)}%',
              );
            }
            break;
          // Adicionar outros tipos conforme necessário
        }

        if (newProgress != null) {
          final previousProgress = progressMap[def.id] ?? 0.0;
          final wasCompleted = completedIds.contains(def.id);
          final isCompletion = newProgress >= 1.0 && !wasCompleted;

          if (newProgress > previousProgress || isCompletion) {
            await updateAchievementProgress(
              def.id,
              newProgress,
              syncToBackend: false,
            );
            updatedCount++;
            shouldSync = true;
          }

          if (newProgress >= 1.0 && previousProgress < 1.0) {
            completedCount++;
            print('   🎉 CONQUISTA COMPLETA: ${def.id} - ${def.name}');
          } else if (newProgress > previousProgress) {
            print(
              '   📈 Progresso atualizado: ${def.id} - ${(previousProgress * 100).toStringAsFixed(1)}% → ${(newProgress * 100).toStringAsFixed(1)}%',
            );
          }
        }
      }

      if (shouldSync) {
        try {
          print('🔄 [ACHIEVEMENTS] Sincronizando progresso em lote...');
          await syncProgressToBackend();
          print('✅ [ACHIEVEMENTS] Sincronização em lote concluída');
        } catch (e) {
          print('⚠️ [ACHIEVEMENTS] Falha ao sincronizar em lote: $e');
        }
      }

      print('✅ [ACHIEVEMENTS] Atualização concluída:');
      print('   - Conquistas atualizadas: $updatedCount');
      print('   - Conquistas completadas: $completedCount');
    } catch (e, stackTrace) {
      print('❌ [ACHIEVEMENTS] Erro em checkAndUpdateAchievements: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Sincroniza o progresso atual com o backend
  /// Envia todos os progressos parciais e completos
  Future<void> syncProgressToBackend() async {
    final accessToken = _storage.getAccessToken();
    if (accessToken == null) {
      print('⚠️ Token de acesso não encontrado - não é possível sincronizar');
      return;
    }

    final user = _userService.currentUser.value;
    if (user == null) {
      print('⚠️ Usuário não autenticado - não é possível sincronizar');
      return;
    }

    try {
      final progressMap = _getProgressMap();
      final completedIds = _getCompletedAchievementIds();

      // Adiciona conquistas completas com progresso 1.0
      final progressToSync = Map<String, double>.from(progressMap);
      for (final achievementId in completedIds) {
        progressToSync[achievementId] = 1.0;
      }

      // Se não há progresso para sincronizar, não faz nada
      if (progressToSync.isEmpty) {
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/users/achievements/progress/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode({
          'userId': user.id,
          'progress': progressToSync.map((key, value) => MapEntry(key, value)),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Progresso sincronizado: ${data['synced_count']} conquistas');

        // Se houver conquistas completadas no backend, atualiza localmente
        if (data['completed_achievements'] != null) {
          final completed = List<String>.from(
            data['completed_achievements'] as List,
          );
          for (final achievementId in completed) {
            if (!completedIds.contains(achievementId)) {
              completedIds.add(achievementId);
            }
          }
          await _saveCompletedAchievementIds(completedIds);
        }
      } else {
        print(
          '⚠️ Erro ao sincronizar progresso: Status ${response.statusCode}',
        );
        print('Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao sincronizar progresso com backend: $e');
      // Não lança erro - progresso já está salvo localmente
    }
  }

  /// Busca o progresso do usuário do backend
  /// Substitui o progresso local pelo do servidor (servidor sempre tem prioridade)
  Future<void> fetchProgressFromBackend() async {
    final accessToken = _storage.getAccessToken();
    if (accessToken == null) {
      print(
        '⚠️ Token de acesso não encontrado - não é possível buscar progresso',
      );
      return;
    }

    final user = _userService.currentUser.value;
    if (user == null) {
      print('⚠️ Usuário não autenticado - não é possível buscar progresso');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.baseUrl}/users/${user.id}/achievements/progress',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final serverProgress = data['progress'] as Map<String, dynamic>?;
        final serverCompleted =
            data['completed_achievements'] as List<dynamic>?;

        if (serverProgress != null) {
          // Substitui progresso local pelo do servidor (servidor sempre tem prioridade)
          await mergeProgress(serverProgress, serverCompleted);
          print('✅ Progresso recuperado do backend (servidor tem prioridade)');
        }
      } else {
        print('⚠️ Erro ao buscar progresso: Status ${response.statusCode}');
        print('Resposta: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro ao buscar progresso do backend: $e');
      // Não lança erro - app continua funcionando com progresso local
    }
  }

  /// Mescla progresso do servidor com progresso local
  /// IMPORTANTE: Servidor sempre tem prioridade sobre o local para evitar trapaças
  /// O valor do servidor substitui o local, mesmo que o local seja maior
  Future<void> mergeProgress(
    Map<String, dynamic> serverProgress,
    List<dynamic>? serverCompleted,
  ) async {
    final localProgress = _getProgressMap();
    final localCompleted = _getCompletedAchievementIds();
    bool hasChanges = false;

    print(
      '🔄 [ACHIEVEMENTS] Mesclando progresso do servidor (servidor tem prioridade)...',
    );
    print('   - Progresso local antes: ${localProgress.length} conquistas');
    print('   - Progresso do servidor: ${serverProgress.length} conquistas');

    // IMPORTANTE: Servidor sempre tem prioridade (segurança anti-trapaça)
    // Substitui o progresso local pelo do servidor, mesmo que o local seja maior
    for (final entry in serverProgress.entries) {
      final achievementId = entry.key;
      final serverValue = (entry.value as num).toDouble();
      final localValue = localProgress[achievementId] ?? 0.0;

      // SEMPRE usa o valor do servidor (não compara, apenas substitui)
      if (serverValue != localValue) {
        localProgress[achievementId] = serverValue;
        hasChanges = true;
        print(
          '   - ${achievementId}: ${(localValue * 100).toStringAsFixed(1)}% → ${(serverValue * 100).toStringAsFixed(1)}% (servidor)',
        );
      }
    }

    // Adiciona conquistas completas do servidor
    if (serverCompleted != null) {
      for (final achievementId in serverCompleted) {
        final id = achievementId.toString();
        if (!localCompleted.contains(id)) {
          localCompleted.add(id);
          localProgress[id] = 1.0; // Garante que progresso seja 1.0
          hasChanges = true;
          print('   - ${id}: Conquista completa adicionada do servidor');
        }
      }
    }

    // Salva apenas se houver mudanças
    if (hasChanges) {
      await _saveProgressMap(localProgress);
      await _saveCompletedAchievementIds(localCompleted);
      print(
        '✅ [ACHIEVEMENTS] Progresso do servidor aplicado: ${localProgress.length} conquistas',
      );
    } else {
      print(
        'ℹ️ [ACHIEVEMENTS] Nenhuma mudança necessária (progresso local já está sincronizado)',
      );
    }
  }

  /// Limpa todas as conquistas (útil para testes ou reset)
  Future<void> clearAllAchievements() async {
    await _storage.storage.remove(_userAchievementsKey);
    await _storage.storage.remove(_completedAchievementsKey);
  }
}
